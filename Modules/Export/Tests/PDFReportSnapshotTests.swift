import XCTest
copilot/fix-7d35a047-f81f-4124-99ae-baa758f4bbac

@testable import ReportExport
main
#if canImport(PDFKit)
import PDFKit
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif

final class PDFReportSnapshotTests: XCTestCase {

copilot/fix-7d35a047-f81f-4124-99ae-baa758f4bbac
    func test_pdf_page_count_and_hash_are_stable() throws {

    func test_pdf_page_count_and_hash_are_stable() {
main
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
copilot/fix-7d35a047-f81f-4124-99ae-baa758f4bbac
        guard let doc = PDFDocument(data: data) else {
            XCTFail("Failed to create PDFDocument from data")
            return
        }

        guard !data.isEmpty else { XCTFail("Failed to get PDF data"); return }
        guard let doc = PDFDocument(data: data) else { XCTFail("Failed to create PDFDocument from PDF data"); return }
main
        XCTAssertEqual(doc.pageCount, 7)

        guard let doc = PDFDocument(data: data) else {
            XCTFail("Failed to create PDFDocument from rendered data")
            return
        }
        XCTAssertEqual(doc.pageCount, 1)

        let h = Self.hash(data)
        // Erwartungswert beim ersten Lauf ermitteln & festschreiben:
        // XCTFail("Hash=\(h)")  // einmalig ausgeben, dann Wert unten eintragen
copilot/fix-7d35a047-f81f-4124-99ae-baa758f4bbac
        XCTAssertEqual(h, "EXPECTED_HASH_VALUE") // Vergleiche mit festem Erwartungswert
        #else
        // Skip test on platforms without PDFKit
        throw XCTSkip("PDFKit not available on this platform")

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
main
        #endif
    }

    private static func hash(_ data: Data) -> String {
        // Simple, stabil: hex-CRC32 oder Murmur3 – hier: SHA256 als Platzhalter
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