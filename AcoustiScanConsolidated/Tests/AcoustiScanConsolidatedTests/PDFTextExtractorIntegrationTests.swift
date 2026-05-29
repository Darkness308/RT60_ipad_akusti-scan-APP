import XCTest
@testable import AcoustiScanConsolidated

/// Integration tests for PDFTextExtractor covering real extraction paths,
/// fallback parsing, corrupt / empty / IO-error scenarios.
final class PDFTextExtractorIntegrationTests: XCTestCase {

    // MARK: - Corrupt / invalid data

    func test_emptyData_throwsCorruptOrInvalid() {
        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: Data())) { error in
            XCTAssertEqual(error as? PDFTextExtractorError, .corruptOrInvalidPDF)
        }
    }

    func test_randomBytes_throwsCorruptOrInvalid() {
        let garbage = Data([0x00, 0xFF, 0x42, 0x13, 0x37, 0xAB, 0xCD])
        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: garbage)) { error in
            XCTAssertEqual(error as? PDFTextExtractorError, .corruptOrInvalidPDF)
        }
    }

    func test_truncatedPDFHeader_throwsCorruptOrInvalid() {
        // Starts with %PDF but is too short and has no real structure
        let truncated = Data("%PD".utf8)
        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: truncated)) { error in
            XCTAssertEqual(error as? PDFTextExtractorError, .corruptOrInvalidPDF)
        }
    }

    func test_validHeaderButNoText_throwsNoTextContent() {
        // Well-formed PDF header but no BT/ET blocks and no text layers
        let noText = Data("%PDF-1.4\n1 0 obj\n<</Type /Catalog>>\nendobj\n".utf8)
        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: noText)) { error in
            XCTAssertEqual(error as? PDFTextExtractorError, .noTextContent)
        }
    }

    // MARK: - Fallback stream-parser (no PDFKit path)

    func test_btEtLiteralString_extracted() throws {
        let pdf = Data("%PDF-1.4\nBT (AcoustiScan RT60 Report) Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertTrue(text.contains("AcoustiScan RT60 Report"),
                      "Expected literal string to be extracted; got: \(text)")
    }

    func test_multipleBtEtBlocks_allExtracted() throws {
        let pdf = Data("%PDF-1.4\nBT (Block One) Tj ET\nBT (Block Two) Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertTrue(text.contains("Block One"), "First block missing; got: \(text)")
        XCTAssertTrue(text.contains("Block Two"), "Second block missing; got: \(text)")
    }

    func test_escapedParenthesisInLiteralString_handledCorrectly() throws {
        // PDF allows \( and \) inside literal strings
        let pdf = Data("%PDF-1.4\nBT (Hello \\(World\\)) Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertFalse(text.isEmpty, "Escaped parentheses should not prevent extraction; got empty")
    }

    func test_nestedParenthesesInLiteralString_balanced() throws {
        // Nested balanced parens are valid in PDF literal strings
        let pdf = Data("%PDF-1.4\nBT (outer (inner) outer) Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertFalse(text.isEmpty, "Nested parens should parse; got empty")
        XCTAssertTrue(text.contains("outer"), "Outer text missing; got: \(text)")
    }

    func test_hexEncodedString_decodedCorrectly() throws {
        // "Hi" in hex is 4869
        let pdf = Data("%PDF-1.4\nBT <4869> Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertTrue(text.contains("Hi"), "Hex string 4869 should decode to 'Hi'; got: \(text)")
    }

    func test_mixedLiteralAndHexStrings_bothExtracted() throws {
        // "A" is 41 in hex
        let pdf = Data("%PDF-1.4\nBT (Literal) Tj <41> Tj ET\n".utf8)
        let text = try PDFTextExtractor.extractText(from: pdf)
        XCTAssertTrue(text.contains("Literal"), "Literal missing; got: \(text)")
        XCTAssertTrue(text.contains("A"), "Hex-decoded 'A' missing; got: \(text)")
    }

    // MARK: - IO error path

    func test_nonexistentFileURL_throwsIOError() {
        let missing = URL(fileURLWithPath: "/tmp/this-file-does-not-exist-12345.pdf")
        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: missing)) { error in
            if case .ioError = error as? PDFTextExtractorError {
                // expected
            } else {
                XCTFail("Expected .ioError, got \(error)")
            }
        }
    }

    func test_fileWithCorruptContent_throwsCorruptOrInvalid() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("corrupt_\(UUID().uuidString).pdf")
        try Data([0xDE, 0xAD, 0xBE, 0xEF]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try PDFTextExtractor.extractText(from: url)) { error in
            XCTAssertEqual(error as? PDFTextExtractorError, .corruptOrInvalidPDF)
        }
    }

    func test_fileWithValidPDFContent_returnsText() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("valid_\(UUID().uuidString).pdf")
        let content = "%PDF-1.4\nBT (RT60 from file) Tj ET\n"
        try Data(content.utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let text = try PDFTextExtractor.extractText(from: url)
        XCTAssertTrue(text.contains("RT60 from file"), "File-based extraction failed; got: \(text)")
    }

    // MARK: - Error type conformance

    func test_errorEquality_corruptOrInvalid() {
        XCTAssertEqual(PDFTextExtractorError.corruptOrInvalidPDF, .corruptOrInvalidPDF)
    }

    func test_errorEquality_noTextContent() {
        XCTAssertEqual(PDFTextExtractorError.noTextContent, .noTextContent)
    }

    func test_errorEquality_ioError() {
        XCTAssertEqual(PDFTextExtractorError.ioError("msg"), .ioError("msg"))
        XCTAssertNotEqual(PDFTextExtractorError.ioError("a"), .ioError("b"))
    }
}
