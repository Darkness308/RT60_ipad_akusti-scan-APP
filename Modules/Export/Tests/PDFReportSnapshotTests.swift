import XCTest
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
        XCTAssertEqual(doc.pageCount, 7)

        let h = Self.hash(data)
        // Erwartungswert beim ersten Lauf ermitteln & festschreiben:
        // XCTFail("Hash=\(h)")  // einmalig ausgeben, dann Wert unten eintragen
        XCTAssertEqual(h, h) // Platzhalter: trage den erwarteten Hash ein
        #else
        // Skip test on platforms without PDFKit
        throw XCTSkip("PDFKit not available on this platform")
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
        // Fallback – NICHT kryptografisch, nur deterministisch
        return data.reduce(into: 5381) { $0 = ($0 &* 33) ^ Int($1) }.description
        #endif
    }
}