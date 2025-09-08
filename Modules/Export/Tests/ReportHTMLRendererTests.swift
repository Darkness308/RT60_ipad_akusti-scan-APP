import XCTest
@testable import ReportExport

final class ReportHTMLRendererTests: XCTestCase {

    func test_html_contains_core_sections_and_values() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21","room":"Demo A"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": nil]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: ["method":"ISO3382-1","bands":"octave"],
            recommendations: ["Wandabsorber ergänzen"],
            audit: ["hash":"DEMOHASH","source":"fixtures"]
        )

        let html = ReportHTMLRenderer().render(model)
        let text = String(decoding: html, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        // Kernabschnitte
        for token in ["rt60 bericht","metadaten","rt60 je frequenz","din 18041","validität","empfehlungen","audit"] {
            XCTAssertTrue(text.contains(token), "Fehlender Abschnitt: \(token)")
        }
        // Werte
        XCTAssertTrue(text.contains("ipadpro"))
        XCTAssertTrue(text.contains("1.0.0"))
        XCTAssertTrue(text.contains("125"))
        XCTAssertTrue(text.contains("0.70"))
        // nil -> "-"
        XCTAssertTrue(text.contains("250"))
        XCTAssertTrue(text.contains("-"))
    }

    func test_html_is_utf8_and_sanitized() {
        let model = ReportModel(
            metadata: ["device":"<iPad&Pro>","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [["freq_hz": 125.0, "t20_s": 0.70]],
            din_targets: [],
            validity: [:],
            recommendations: ["<b>Keine Tags rendern</b>"],
            audit: [:]
        )
        let data = ReportHTMLRenderer().render(model)
        // UTF-8 roundtrip
        XCTAssertNotNil(String(data: data, encoding: .utf8))
        let html = String(decoding: data, as: UTF8.self)
        // Grundlegende Entschärfung (Escape) wird erwartet
        XCTAssertTrue(html.contains("&lt;iPad&amp;Pro&gt;"))
        XCTAssertFalse(html.contains("<b>Keine Tags rendern</b>"))
    }
}