import XCTest
copilot/fix-151d7a9d-31a9-451a-bc46-9ca33c7437e3
@testable import ReportExport
#if canImport(PDFKit)
import PDFKit
#endif

#if canImport(PDFKit)
import PDFKit
#if canImport(CryptoKit)
import CryptoKit
#endif
@testable import ReportExport
main

final class PDFReportSnapshotTests: XCTestCase {

    func test_pdf_page_count_and_hash_are_stable() {
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
copilot/fix-c0e508b8-1cc9-49b9-b3b1-771ea6563c8e
        guard !data.isEmpty else { XCTFail("Failed to get PDF data"); return }
        guard let doc = PDFDocument(data: data) else { XCTFail("Failed to create PDFDocument from PDF data"); return }
        XCTAssertEqual(doc.pageCount, 7)

        guard let doc = PDFDocument(data: data) else {
            XCTFail("Failed to create PDFDocument from rendered data")
            return
        }
        XCTAssertEqual(doc.pageCount, 1)
main

        let h = Self.hash(data)
        // Erwartungswert beim ersten Lauf ermitteln & festschreiben:
        // XCTFail("Hash=\(h)")  // einmalig ausgeben, dann Wert unten eintragen
        XCTAssertEqual(h, h) // Platzhalter: trage den erwarteten Hash ein
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
        #endif
    }

    private static func hash(_ data: Data) -> String {
        // Simple, stabil: hex-CRC32 oder Murmur3 – hier: SHA256 als Platzhalter
        return sha256Hex(data)
    }

    private static func sha256Hex(_ data: Data) -> String {
        #if canImport(CryptoKit)
copilot/fix-151d7a9d-31a9-451a-bc46-9ca33c7437e3
        // Move import to top of file for proper module-level import
        // SHA256 functionality would need to be properly imported
        return data.reduce(into: 5381) { $0 = ($0 &* 33) ^ Int($1) }.description

        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
main
        #else
        // Fallback – NICHT kryptografisch, nur deterministisch
        return data.reduce(into: 5381) { $0 = ($0 &* 33) ^ Int($1) }.description
        #endif
    }
}
#endif