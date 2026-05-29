// PDFTextExtractor.swift
// Extracts text content from PDF data with full fallback and error handling.

import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// Errors that can occur during PDF text extraction.
public enum PDFTextExtractorError: Error, Equatable {
    /// The supplied data is not a valid PDF (corrupt header, truncated file, etc.).
    case corruptOrInvalidPDF
    /// An I/O error occurred while reading from a file URL.
    case ioError(String)
    /// The document is valid but contains no extractable text layers.
    case noTextContent
}

/// Extracts plain text from PDF data.
///
/// The implementation uses PDFKit when available and falls back to a
/// byte-level BT/ET stream parser on platforms where PDFKit is absent
/// (e.g. Linux CI runners).  Both paths surface structured errors instead
/// of silently returning empty strings, making integration failures
/// diagnosable in test output.
public struct PDFTextExtractor {

    // MARK: - Public API

    /// Extracts text from in-memory PDF data.
    ///
    /// - Parameter pdfData: Raw PDF bytes.
    /// - Returns: The concatenated text of all pages, separated by newlines.
    /// - Throws: `PDFTextExtractorError` when the data cannot be parsed or
    ///   yields no text.
    public static func extractText(from pdfData: Data) throws -> String {
        guard !pdfData.isEmpty else { throw PDFTextExtractorError.corruptOrInvalidPDF }
        guard isPDFHeader(pdfData) else { throw PDFTextExtractorError.corruptOrInvalidPDF }

        #if canImport(PDFKit)
        return try extractViaPDFKit(pdfData)
        #else
        return try extractViaStreamParser(pdfData)
        #endif
    }

    /// Extracts text from a PDF file on disk.
    ///
    /// - Parameter url: File URL of the PDF.
    /// - Returns: The concatenated text of all pages.
    /// - Throws: `PDFTextExtractorError.ioError` when the file cannot be
    ///   read, or other `PDFTextExtractorError` values on parse failures.
    public static func extractText(from url: URL) throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw PDFTextExtractorError.ioError(error.localizedDescription)
        }
        return try extractText(from: data)
    }

    // MARK: - Private helpers

    /// Returns `true` when the first bytes match the `%PDF-` magic number.
    private static func isPDFHeader(_ data: Data) -> Bool {
        guard data.count >= 5 else { return false }
        return data.prefix(5) == Data("%PDF-".utf8)
    }

    // MARK: PDFKit path

    #if canImport(PDFKit)
    private static func extractViaPDFKit(_ pdfData: Data) throws -> String {
        guard let document = PDFDocument(data: pdfData) else {
            throw PDFTextExtractorError.corruptOrInvalidPDF
        }

        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let pageText = page.string ?? ""
            if !pageText.isEmpty {
                pages.append(pageText)
            }
        }

        let result = pages.joined(separator: "\n")
        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PDFTextExtractorError.noTextContent
        }
        return result
    }
    #endif

    // MARK: Fallback stream parser (no PDFKit)

    /// Byte-level BT/ET content-stream parser for platforms without PDFKit.
    ///
    /// Handles:
    /// - Text in parentheses: `(Hello World) Tj`
    /// - Hex-encoded strings: `<48656C6C6F> Tj`
    /// - Multi-line BT/ET blocks with interleaved operators
    private static func extractViaStreamParser(_ pdfData: Data) throws -> String {
        // Attempt UTF-8 first, fall back to ASCII lossy decoding so that
        // binary object streams don't cause a nil return.
        let raw = String(data: pdfData, encoding: .utf8)
            ?? String(data: pdfData, encoding: .ascii)
            ?? String(bytes: pdfData, encoding: .isoLatin1)
            ?? ""

        guard !raw.isEmpty else { throw PDFTextExtractorError.corruptOrInvalidPDF }

        var tokens: [String] = []

        // Iterate BT … ET blocks
        var searchRange = raw.startIndex..<raw.endIndex
        while let btRange = raw.range(of: "BT", range: searchRange) {
            // Find the matching ET after this BT
            let afterBT = btRange.upperBound..<raw.endIndex
            guard let etRange = raw.range(of: "ET", range: afterBT) else { break }

            let block = String(raw[btRange.upperBound..<etRange.lowerBound])
            tokens.append(contentsOf: extractTokensFromBlock(block))

            searchRange = etRange.upperBound..<raw.endIndex
        }

        let result = tokens.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if result.isEmpty { throw PDFTextExtractorError.noTextContent }
        return result
    }

    /// Extracts string tokens from a single BT/ET content-stream block.
    private static func extractTokensFromBlock(_ block: String) -> [String] {
        var result: [String] = []
        var index = block.startIndex

        while index < block.endIndex {
            let ch = block[index]

            if ch == "(" {
                // Literal string — scan to matching unescaped ")"
                if let text = scanLiteralString(block, from: block.index(after: index)) {
                    let cleaned = text.token
                    if !cleaned.isEmpty { result.append(cleaned) }
                    index = text.end
                } else {
                    index = block.index(after: index)
                }
            } else if ch == "<", block.index(after: index) < block.endIndex,
                      block[block.index(after: index)] != "<" {
                // Hex string — scan to ">"
                if let text = scanHexString(block, from: block.index(after: index)) {
                    if !text.token.isEmpty { result.append(text.token) }
                    index = text.end
                } else {
                    index = block.index(after: index)
                }
            } else {
                index = block.index(after: index)
            }
        }

        return result
    }

    private struct ScannedToken {
        let token: String
        let end: String.Index
    }

    /// Scans a PDF literal string `(…)` with escape handling.
    private static func scanLiteralString(_ s: String, from start: String.Index) -> ScannedToken? {
        var i = start
        var chars: [Character] = []
        var depth = 1

        while i < s.endIndex {
            let c = s[i]
            if c == "\\" {
                let next = s.index(after: i)
                if next < s.endIndex {
                    chars.append(s[next])
                    i = s.index(after: next)
                } else {
                    i = next
                }
                continue
            }
            if c == "(" { depth += 1 }
            if c == ")" {
                depth -= 1
                if depth == 0 {
                    return ScannedToken(token: String(chars), end: s.index(after: i))
                }
            }
            chars.append(c)
            i = s.index(after: i)
        }
        return nil
    }

    /// Scans a PDF hex string `<HEXDIGITS>` and decodes it.
    private static func scanHexString(_ s: String, from start: String.Index) -> ScannedToken? {
        var i = start
        var hexChars = ""

        while i < s.endIndex {
            let c = s[i]
            if c == ">" {
                // Pad to even length
                if hexChars.count % 2 != 0 { hexChars += "0" }
                let decoded = decodeHex(hexChars)
                return ScannedToken(token: decoded, end: s.index(after: i))
            }
            if c.isHexDigit { hexChars.append(c) }
            i = s.index(after: i)
        }
        return nil
    }

    /// Decodes a hex string to UTF-8 text, falling back to Latin-1.
    private static func decodeHex(_ hex: String) -> String {
        var bytes: [UInt8] = []
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let byte = UInt8(hex[idx..<next], radix: 16) {
                bytes.append(byte)
            }
            idx = next
        }
        let data = Data(bytes)
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }
}
