//
//  XLSXImporter.swift
//  AcoustiScanApp
//
//  Pure Swift XLSX importer without external dependencies
//  Reads .xlsx files by extracting ZIP archives and parsing XML
//

import Foundation

/// Error types for XLSX import operations
public enum XLSXImportError: Error, LocalizedError {
    case invalidFormat
    case decompressionFailed
    case xmlParsingFailed
    case missingWorksheet
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid XLSX file format"
        case .decompressionFailed:
            return "Failed to decompress XLSX data"
        case .xmlParsingFailed:
            return "Failed to parse XML content"
        case .missingWorksheet:
            return "Worksheet not found in XLSX file"
        case .invalidData(let detail):
            return "Invalid data in XLSX file: \(detail)"
        }
    }
}

/// XLSX file importer using pure Swift
public class XLSXImporter {

    /// Import acoustic materials from XLSX format
    /// - Parameter data: Data representing the XLSX file
    /// - Returns: Array of imported materials
    /// - Throws: XLSXImportError if import fails
    public static func `import`(data: Data) throws -> [AcousticMaterial] {
        // Extract ZIP archive
        let zipReader = try ZIPReader(data: data)
        let files = try zipReader.extractAll()

        // Find and parse the worksheet
        guard let worksheetData = files["xl/worksheets/sheet1.xml"] else {
            throw XLSXImportError.missingWorksheet
        }

        guard let worksheetXML = String(data: worksheetData, encoding: .utf8) else {
            throw XLSXImportError.xmlParsingFailed
        }

        // Parse worksheet to extract data
        let parser = WorksheetParser()
        let rows = try parser.parse(xml: worksheetXML)

        // Convert rows to materials
        return try convertRowsToMaterials(rows)
    }

    private static func convertRowsToMaterials(_ rows: [[String]]) throws -> [AcousticMaterial] {
        var materials: [AcousticMaterial] = []

        // Skip header row (first row)
        for row in rows.dropFirst() {
            guard !row.isEmpty else { continue }

            // Ensure we have at least name + 6 frequency values
            guard row.count >= 7 else {
                continue
            }

            let name = row[0].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }

            var values: [Int: Float] = [:]

            // Parse absorption coefficients for each frequency
            for (index, frequency) in AbsorptionData.standardFrequencies.enumerated() {
                let valueString = row[index + 1].trimmingCharacters(in: .whitespaces)
                if let value = Float(valueString) {
                    values[frequency] = value
                }
            }

            // Only add material if it has at least some data
            guard !values.isEmpty else { continue }

            let material = AcousticMaterial(
                name: name,
                absorption: AbsorptionData(values: values)
            )
            materials.append(material)
        }

        return materials
    }
}

/// Simple XML worksheet parser
private class WorksheetParser {
    func parse(xml: String) throws -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentCellValue = ""
        var insideValue = false
        var insideInlineString = false

        let parser = SimpleXMLParser(xml: xml)

        while let event = parser.next() {
            switch event {
            case .startElement(let name, _):
                if name == "row" {
                    currentRow = []
                } else if name == "v" {
                    insideValue = true
                    currentCellValue = ""
                } else if name == "t" && insideInlineString {
                    insideValue = true
                    currentCellValue = ""
                } else if name == "is" || name == "si" {
                    insideInlineString = true
                }

            case .endElement(let name):
                if name == "row" {
                    if !currentRow.isEmpty {
                        rows.append(currentRow)
                    }
                } else if name == "c" {
                    // End of cell - add value to current row
                    if !currentCellValue.isEmpty {
                        currentRow.append(currentCellValue)
                        currentCellValue = ""
                    }
                } else if name == "v" || (name == "t" && insideInlineString) {
                    insideValue = false
                } else if name == "is" || name == "si" {
                    insideInlineString = false
                }

            case .text(let text):
                if insideValue {
                    currentCellValue += text
                }
            }
        }

        return rows
    }
}

/// Simple XML parser for extracting data
private class SimpleXMLParser {
    private let xml: String
    private var currentIndex: String.Index

    init(xml: String) {
        self.xml = xml
        self.currentIndex = xml.startIndex
    }

    func next() -> XMLEvent? {
        while currentIndex < xml.endIndex {
            let char = xml[currentIndex]

            if char == "<" {
                return parseTag()
            } else {
                return parseText()
            }
        }

        return nil
    }

    private func parseTag() -> XMLEvent? {
        guard currentIndex < xml.endIndex else { return nil }

        currentIndex = xml.index(after: currentIndex)

        // Check for closing tag
        if currentIndex < xml.endIndex && xml[currentIndex] == "/" {
            currentIndex = xml.index(after: currentIndex)
            let tagName = readUntil(">")
            return .endElement(tagName)
        }

        // Check for comment or processing instruction
        if currentIndex < xml.endIndex && xml[currentIndex] == "?" {
            // Skip processing instruction
            _ = readUntil(">")
            return next()
        }

        if currentIndex < xml.endIndex && xml[currentIndex] == "!" {
            // Skip comment or CDATA
            _ = readUntil(">")
            return next()
        }

        // Parse element name and attributes
        let tagContent = readUntil(">")
        let parts = tagContent.split(separator: " ", maxSplits: 1)
        let tagName = String(parts[0])

        var attributes: [String: String] = [:]
        if parts.count > 1 {
            attributes = parseAttributes(String(parts[1]))
        }

        // Check for self-closing tag
        if tagContent.hasSuffix("/") {
            let cleanName = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return .startElement(cleanName, attributes)
        }

        return .startElement(tagName, attributes)
    }

    private func parseText() -> XMLEvent? {
        var text = ""

        while currentIndex < xml.endIndex && xml[currentIndex] != "<" {
            text.append(xml[currentIndex])
            currentIndex = xml.index(after: currentIndex)
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            return .text(xmlUnescape(trimmedText))
        }

        return next()
    }

    private func readUntil(_ char: Character) -> String {
        var result = ""

        while currentIndex < xml.endIndex && xml[currentIndex] != char {
            result.append(xml[currentIndex])
            currentIndex = xml.index(after: currentIndex)
        }

        if currentIndex < xml.endIndex {
            currentIndex = xml.index(after: currentIndex)
        }

        return result
    }

    private func parseAttributes(_ attributeString: String) -> [String: String] {
        var attributes: [String: String] = [:]
        var currentKey = ""
        var currentValue = ""
        var inValue = false
        var quoteChar: Character?

        for char in attributeString {
            if char == "=" && !inValue {
                currentKey = currentKey.trimmingCharacters(in: .whitespaces)
                inValue = true
            } else if (char == "\"" || char == "'") && inValue {
                if let quote = quoteChar {
                    if char == quote {
                        attributes[currentKey] = currentValue
                        currentKey = ""
                        currentValue = ""
                        inValue = false
                        quoteChar = nil
                    } else {
                        currentValue.append(char)
                    }
                } else {
                    quoteChar = char
                }
            } else if inValue {
                currentValue.append(char)
            } else if char != " " && char != "/" {
                currentKey.append(char)
            }
        }

        return attributes
    }

    private func xmlUnescape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}

private enum XMLEvent {
    case startElement(String, [String: String])
    case endElement(String)
    case text(String)
}

/// Simple ZIP reader for extracting XLSX contents
private class ZIPReader {
    private let data: Data

    init(data: Data) throws {
        self.data = data

        // Verify ZIP signature
        guard data.count >= 4 else {
            throw XLSXImportError.invalidFormat
        }

        let signature = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard signature == 0x04034b50 || signature == 0x06054b50 else {
            throw XLSXImportError.invalidFormat
        }
    }

    func extractAll() throws -> [String: Data] {
        var files: [String: Data] = [:]

        // Find end of central directory record
        guard let endOfCentralDir = findEndOfCentralDirectory() else {
            throw XLSXImportError.invalidFormat
        }

        // Parse central directory entries
        let centralDirOffset = Int(endOfCentralDir.centralDirectoryOffset)
        let numberOfEntries = Int(endOfCentralDir.totalEntries)

        var offset = centralDirOffset

        for _ in 0..<numberOfEntries {
            guard offset + 46 <= data.count else { break }

            // Verify central directory signature
            let signature = data.subdata(in: offset..<(offset + 4))
                .withUnsafeBytes { $0.load(as: UInt32.self) }

            guard signature == 0x02014b50 else { break }

            // Read file name length and extra field length
            let fileNameLength = Int(data.subdata(in: (offset + 28)..<(offset + 30))
                .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })
            let extraFieldLength = Int(data.subdata(in: (offset + 30)..<(offset + 32))
                .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })
            let commentLength = Int(data.subdata(in: (offset + 32)..<(offset + 34))
                .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })

            // Read file name
            let fileNameData = data.subdata(in: (offset + 46)..<(offset + 46 + fileNameLength))
            guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                offset += 46 + fileNameLength + extraFieldLength + commentLength
                continue
            }

            // Read local header offset
            let localHeaderOffset = Int(data.subdata(in: (offset + 42)..<(offset + 46))
                .withUnsafeBytes { $0.load(as: UInt32.self).littleEndian })

            // Extract file data from local header
            if let fileData = extractFileData(at: localHeaderOffset) {
                files[fileName] = fileData
            }

            offset += 46 + fileNameLength + extraFieldLength + commentLength
        }

        return files
    }

    private func extractFileData(at offset: Int) -> Data? {
        guard offset + 30 <= data.count else { return nil }

        // Verify local file header signature
        let signature = data.subdata(in: offset..<(offset + 4))
            .withUnsafeBytes { $0.load(as: UInt32.self) }

        guard signature == 0x04034b50 else { return nil }

        // Read compression method
        let compressionMethod = data.subdata(in: (offset + 8)..<(offset + 10))
            .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }

        // Read compressed and uncompressed sizes
        let compressedSize = Int(data.subdata(in: (offset + 18)..<(offset + 22))
            .withUnsafeBytes { $0.load(as: UInt32.self).littleEndian })
        let uncompressedSize = Int(data.subdata(in: (offset + 22)..<(offset + 26))
            .withUnsafeBytes { $0.load(as: UInt32.self).littleEndian })

        // Read file name and extra field lengths
        let fileNameLength = Int(data.subdata(in: (offset + 26)..<(offset + 28))
            .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })
        let extraFieldLength = Int(data.subdata(in: (offset + 28)..<(offset + 30))
            .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian })

        // Calculate data offset
        let dataOffset = offset + 30 + fileNameLength + extraFieldLength

        guard dataOffset + compressedSize <= data.count else { return nil }

        let compressedData = data.subdata(in: dataOffset..<(dataOffset + compressedSize))

        // Handle uncompressed (stored) files
        if compressionMethod == 0 {
            return compressedData
        }

        // For deflate compression (method 8), try to decompress
        if compressionMethod == 8 {
            return try? decompressDeflate(data: compressedData, expectedSize: uncompressedSize)
        }

        return nil
    }

    private func decompressDeflate(data: Data, expectedSize: Int) throws -> Data {
        var decompressed = Data(count: expectedSize)
        let decompressedCount = decompressed.withUnsafeMutableBytes { destBuffer -> Int in
            return data.withUnsafeBytes { sourceBuffer -> Int in
                var stream = compression_stream()
                stream.dst_ptr = destBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                stream.dst_size = expectedSize
                stream.src_ptr = sourceBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                stream.src_size = data.count

                let initResult = compression_stream_init(
                    &stream,
                    COMPRESSION_STREAM_DECODE,
                    COMPRESSION_ZLIB
                )
                guard initResult == COMPRESSION_STATUS_OK else {
                    return 0
                }

                defer {
                    compression_stream_destroy(&stream)
                }

                let status = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))

                if status == COMPRESSION_STATUS_END {
                    return expectedSize - stream.dst_size
                }

                return 0
            }
        }

        if decompressedCount > 0 {
            decompressed.count = decompressedCount
            return decompressed
        }

        throw XLSXImportError.decompressionFailed
    }

    private func findEndOfCentralDirectory() -> EndOfCentralDirectory? {
        // Search for end of central directory signature from the end of file
        let signatureBytes: [UInt8] = [0x50, 0x4b, 0x05, 0x06]

        // Start from the end and search backwards
        let searchRange = max(0, data.count - 65557)  // Max comment size + EOCD size

        for i in stride(from: data.count - 22, through: searchRange, by: -1) {
            if data[i] == signatureBytes[0] &&
               data[i + 1] == signatureBytes[1] &&
               data[i + 2] == signatureBytes[2] &&
               data[i + 3] == signatureBytes[3] {

                // Found the signature, parse the EOCD
                let totalEntries = data.subdata(in: (i + 10)..<(i + 12))
                    .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
                let centralDirectoryOffset = data.subdata(in: (i + 16)..<(i + 20))
                    .withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }

                return EndOfCentralDirectory(
                    totalEntries: totalEntries,
                    centralDirectoryOffset: centralDirectoryOffset
                )
            }
        }

        return nil
    }

    private struct EndOfCentralDirectory {
        let totalEntries: UInt16
        let centralDirectoryOffset: UInt32
    }
}
