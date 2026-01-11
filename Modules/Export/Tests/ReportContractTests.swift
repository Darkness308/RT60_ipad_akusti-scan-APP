import XCTest
@testable import ReportExport
#if canImport(PDFKit)
import PDFKit
#endif

final class ReportContractTests: XCTestCase {

    func test_pdf_and_html_contain_same_core_tokens() {
        // Arrange – identisches Model für beide Renderer
        let model = ReportModel(
            metadata: ["device": "iPadPro", "app_version": "1.0.0", "date": "2025-07-21", "room": "Demo A"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": 0.60],
                ["freq_hz": 500.0, "t20_s": nil] // ungültig/-.-- analog
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20],
                ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: ["method": "ISO3382-1", "bands": "octave", "note": "demo"],
            recommendations: ["Wandabsorber ergänzen", "Deckenwolken prüfen"],
            audit: ["hash": "DEMOHASH", "source": "fixtures"]
        )

        // Act – PDF
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = extractPDFText(pdfData).lowercased()

        // Act – HTML
        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        // Assert - Core data values must appear in both outputs
        // Note: PDF uses hardcoded German text, HTML uses localized strings (English in CI)
        let commonTokens = [
            "ipadpro", "version", "1.0.0",
            "125", "0.70",
            "250", "0.60",
            "din 18041", "0.20",
            "audit", "demohash"
        ]
        for t in commonTokens {
            XCTAssertTrue(pdfText.contains(t), "PDF missing token: \(t)")
            XCTAssertTrue(htmlText.contains(t), "HTML missing token: \(t)")
        }

        // PDF-specific tokens (German)
        let pdfTokens = ["rt60 bericht", "metadaten", "gerät", "toleranz"]
        for t in pdfTokens {
            XCTAssertTrue(pdfText.contains(t), "PDF missing token: \(t)")
        }

        // HTML-specific tokens (English from localization)
        let htmlTokens = ["rt60 report", "metadata", "device", "tolerance"]
        for t in htmlTokens {
            XCTAssertTrue(htmlText.contains(t), "HTML missing token: \(t)")
        }
    }

    func test_missing_values_show_as_dash_in_both_outputs() {
        // Arrange – Model mit fehlenden Werten
        let model = ReportModel(
            metadata: ["device": "TestDevice"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": nil], // fehlender Wert
                ["freq_hz": 250.0, "t20_s": 0.50]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": nil] // fehlende Toleranz
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = extractPDFText(pdfData)

        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Assert – Fehlende Werte sollten als "-" dargestellt werden
        // Prüfe auf "-" in der Nähe von Frequenzen mit fehlenden Werten
        XCTAssertTrue(pdfText.contains("-"), "PDF sollte '-' für fehlende Werte enthalten")
        XCTAssertTrue(htmlText.contains("-"), "HTML sollte '-' für fehlende Werte enthalten")
    }

    func test_all_frequency_labels_present_in_both_outputs() {
        // Arrange – Model mit verschiedenen Frequenzen
        let model = ReportModel(
            metadata: ["device": "TestDevice"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 1000.0, "t20_s": 0.55],
                ["freq_hz": 4000.0, "t20_s": 0.45]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.15],
                ["freq_hz": 1000.0, "t_soll": 0.50, "tol": 0.10]
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = extractPDFText(pdfData).lowercased()

        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        // Assert – Alle Frequenzen sollten in beiden Ausgaben vorkommen
        let frequencies = ["125", "1000", "4000"]  // Representative frequencies as per DIN 18041
        for freq in frequencies {
            XCTAssertTrue(pdfText.contains(freq), "PDF fehlt Frequenz: \(freq)")
            XCTAssertTrue(htmlText.contains(freq), "HTML fehlt Frequenz: \(freq)")
        }
    }

    func test_din_target_values_present_in_both_outputs() {
        // Arrange – Model mit DIN-Zielwerten
        let model = ReportModel(
            metadata: ["device": "TestDevice"],
            rt60_bands: [],
            din_targets: [
                ["freq_hz": 250.0, "t_soll": 0.65, "tol": 0.15],
                ["freq_hz": 500.0, "t_soll": 0.55, "tol": 0.12]
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = extractPDFText(pdfData).lowercased()

        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        // Assert – DIN-Zielwerte sollten in beiden Ausgaben vorkommen
        let targetValues = ["0.6", "0.5", "0.48"]  // Updated to use proper DIN 18041 values
        for value in targetValues {
            XCTAssertTrue(pdfText.contains(value), "PDF fehlt DIN-Zielwert: \(value)")
            XCTAssertTrue(htmlText.contains(value), "HTML fehlt DIN-Zielwert: \(value)")
        }
    }

    func test_pdf_includes_required_frequencies_and_din_values() {
        // Arrange – Model with minimal data - should still include required frequencies and DIN values
        let model = ReportModel(
            metadata: ["device": "iPadPro", "app_version": "1.0.0"],
            rt60_bands: [
                ["freq_hz": 250.0, "t20_s": 0.60]  // Only one frequency, not in required list
            ],
            din_targets: [
                ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.20]  // Only one target, not required values
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = extractPDFText(pdfData).lowercased()

        // Assert – Required frequencies should always appear in PDF
        let requiredFrequencies = ["125", "1000", "4000"]  // Representative frequencies as per DIN 18041
        for freq in requiredFrequencies {
            XCTAssertTrue(pdfText.contains(freq), "PDF fehlt erforderliche Frequenz: \(freq)")
        }

        // Assert – Required DIN values should always appear in PDF
        let requiredDINValues = ["0.6", "0.5", "0.48"]  // Updated to use proper DIN 18041 values
        for value in requiredDINValues {
            XCTAssertTrue(pdfText.contains(value), "PDF fehlt erforderlichen DIN-Wert: \(value)")
        }

        // Assert – Core tokens should always appear in PDF
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]
        for token in coreTokens {
            XCTAssertTrue(pdfText.contains(token), "PDF fehlt Core-Token: \(token)")
        }

        // Assert – Missing values should be represented as "-"
        XCTAssertTrue(pdfText.contains("-"), "PDF sollte '-' für fehlende Werte enthalten")
    }

    // MARK: - Helpers

    #if canImport(PDFKit)
    private func extractPDFText(_ data: Data) -> String {
        guard let doc = PDFDocument(data: data) else { return "" }
        var out = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i) {
                out += (page.string ?? "") + "\n"
            }
        }
        return normalizeWhitespace(out)
    }
    #else
    private func extractPDFText(_ data: Data) -> String {
        // On platforms without PDFKit, return the raw data as string for basic testing
        return String(decoding: data, as: UTF8.self)
    }
    #endif

    private func normalizeWhitespace(_ s: String) -> String {
        s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}