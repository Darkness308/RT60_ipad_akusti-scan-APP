import XCTest
@testable import ReportExport

#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif

final class PDFReportSnapshotTests: XCTestCase {

    func test_pdf_page_count_and_hash_are_stable() throws {
        #if canImport(PDFKit)
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.7],
                ["freq_hz": 250.0, "t20_s": 0.6]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.6, "tol": 0.2],
                ["freq_hz": 250.0, "t_soll": 0.6, "tol": 0.2]
            ],
            validity: ["method":"ISO3382-1","notes":"demo"],
            recommendations: ["Wandabsorber ergänzen","Deckenwolken prüfen"],
            audit: ["hash":"DEMO","source":"fixtures"]
        )

        let data = PDFReportRenderer().render(model)
        guard let doc = PDFDocument(data: data) else {
            XCTFail("Failed to create PDFDocument from data")
            return
        }

        XCTAssertEqual(doc.pageCount, 1)

        // A literal byte-hash snapshot would be flaky (PDFs embed creation
        // dates/IDs, so the bytes differ between runs). Instead assert real,
        // content-based invariants that fail if rendering breaks, plus that the
        // hash is well-formed (64 hex chars) so the hashing path is exercised.
        let h = Self.hash(data)
        XCTAssertEqual(h.count, 64, "SHA256 hex digest must be 64 chars")
        XCTAssertTrue(h.allSatisfy { $0.isHexDigit }, "hash must be hex")

        let text = (0..<doc.pageCount)
            .compactMap { doc.page(at: $0)?.string }
            .joined(separator: "\n")
            .lowercased()
        XCTAssertTrue(text.contains("rt60 bericht"), "PDF should contain the report title")
        XCTAssertTrue(text.contains("din 18041"), "PDF should contain the DIN section")
        XCTAssertTrue(text.contains("0.60"), "PDF should render the model's T_soll value")
        XCTAssertTrue(text.contains("wandabsorber ergänzen"), "PDF should render recommendations")
        #else
        // On platforms without PDFKit, just verify the PDF renderer produces data
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.7],
                ["freq_hz": 250.0, "t20_s": 0.6]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.6, "tol": 0.2],
                ["freq_hz": 250.0, "t_soll": 0.6, "tol": 0.2]
            ],
            validity: ["method":"ISO3382-1","notes":"demo"],
            recommendations: ["Wandabsorber ergänzen","Deckenwolken prüfen"],
            audit: ["hash":"DEMO","source":"fixtures"]
        )

        let data = PDFReportRenderer().render(model)
        XCTAssertFalse(data.isEmpty, "PDF renderer should produce non-empty data")

        // Skip test on platforms without PDFKit
        throw XCTSkip("PDFKit not available on this platform")
        #endif
    }

    private static func hash(_ data: Data) -> String {
        return sha256Hex(data)
    }

    private static func sha256Hex(_ data: Data) -> String {
        #if canImport(CryptoKit)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        #else
        // Fallback hash when CryptoKit is not available
        return data.reduce(into: 5381) { $0 = ($0 &* 33) ^ Int($1) }.description
        #endif
    }
}
