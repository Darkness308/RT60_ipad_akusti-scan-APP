import XCTest
#if canImport(PDFKit)
import PDFKit
#endif
@testable import ReportExport

/// Additional tests for edge cases based on the problem statement
final class PDFRobustnessTests: XCTestCase {

    func test_pdf_handles_empty_model_gracefully() {
        // Arrange - Completely empty model
        let emptyModel = ReportModel(
            metadata: [:],
            rt60_bands: [],
            din_targets: [],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(emptyModel)
        let pdfText = extractPDFText(pdfData).lowercased()

        // Assert - Required elements should still appear even with empty model
        let requiredFrequencies = ["125", "1000", "4000"]  // Representative frequencies as per DIN 18041
        for freq in requiredFrequencies {
            XCTAssertTrue(pdfText.contains(freq), "PDF fehlt erforderliche Frequenz: \(freq) bei leerem Model")
        }

        // An empty model has no DIN targets, so the section must show the header
        // and a dash placeholder rather than fabricated standard values.
        XCTAssertTrue(pdfText.contains("din 18041"), "PDF fehlt DIN-18041-Abschnitt bei leerem Model")
        XCTAssertTrue(pdfText.contains("t_soll=-"), "PDF sollte '-' statt erfundener DIN-Werte zeigen")

        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]
        for token in coreTokens {
            XCTAssertTrue(pdfText.contains(token), "PDF fehlt Core-Token: \(token) bei leerem Model")
        }
    }

    func test_pdf_handles_null_values_gracefully() {
        // Arrange - Model with null/missing values
        let modelWithNulls = ReportModel(
            metadata: ["device": "iPadPro", "app_version": "1.0.0"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": nil], // null t20_s value
                ["freq_hz": nil, "t20_s": 0.5]     // null freq_hz value
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": nil, "tol": nil], // null DIN values
                ["freq_hz": nil, "t_soll": 0.6, "tol": 0.2]    // null frequency
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(modelWithNulls)
        let pdfText = extractPDFText(pdfData)

        // Assert - Missing/null values should show as "-"
        XCTAssertTrue(pdfText.contains("-"), "PDF sollte '-' für null/fehlende Werte enthalten")
    }

    func test_pdf_data_is_not_empty() {
        // Arrange
        let model = ReportModel(
            metadata: ["device": "iPadPro", "app_version": "1.0.0"],
            rt60_bands: [["freq_hz": 125.0, "t20_s": 0.7]],
            din_targets: [["freq_hz": 125.0, "t_soll": 0.6, "tol": 0.2]],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        // Act
        let pdfData = PDFReportRenderer().render(model)

        // Assert - PDF data should not be empty
        XCTAssertFalse(pdfData.isEmpty, "PDF data should not be empty")
        XCTAssertGreaterThan(pdfData.count, 100, "PDF data should contain substantial content")
    }

    func test_pdf_always_includes_required_elements_even_with_partial_data() {
        // This model has SOME data, but not the required frequencies and DIN values
        let modelWithPartialData = ReportModel(
            metadata: ["device": "TestDevice", "room": "Meeting Room"],
            rt60_bands: [
                ["freq_hz": 500.0, "t20_s": 0.8]  // Only 500 Hz, missing 125, 1000, 4000
            ],
            din_targets: [
                ["freq_hz": 500.0, "t_soll": 0.7, "tol": 0.1]  // Only for 500 Hz, missing required DIN values
            ],
            validity: [:],
            recommendations: ["Some recommendation"],
            audit: [:]
        )

        let pdfData = PDFReportRenderer().render(modelWithPartialData)
        let pdfText = extractPDFText(pdfData).lowercased()

        print("Generated PDF text for debugging:")
        print(pdfText)
        print("\n=== Checking Requirements ===")

        // Check required frequencies - these should ALWAYS be present
        let requiredFrequencies = ["125", "1000", "4000"]
        for freq in requiredFrequencies {
            XCTAssertTrue(pdfText.contains(freq), "PDF missing required frequency: \(freq)")
        }

        // The DIN section must reflect the model's ACTUAL target (500 Hz, T_soll 0.70),
        // not fabricated standard values.
        XCTAssertTrue(pdfText.contains("500 hz: t_soll=0.70"), "PDF should render the model's real DIN target")
        XCTAssertFalse(pdfText.contains("0.48"), "PDF must not contain the old fabricated DIN value 0.48")

        // Check core tokens
        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]
        for token in coreTokens {
            XCTAssertTrue(pdfText.contains(token), "PDF missing core token: \(token)")
        }
    }

    func test_pdf_problem_statement_requirements() {
        // Test specifically with the values mentioned in the problem statement
        let emptyModel = ReportModel(
            metadata: [:],
            rt60_bands: [],
            din_targets: [],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        let pdfData = PDFReportRenderer().render(emptyModel)
        let pdfText = extractPDFText(pdfData).lowercased()

        // An empty model must NOT fabricate DIN target values. Earlier the renderer
        // hardcoded representative values (0.6 / 0.5 / 0.48) that overwrote the room's
        // real T_soll; this test now guards against that regression.
        for fabricated in ["0.48", "t_soll=0.6", "t_soll=0.5"] {
            XCTAssertFalse(pdfText.contains(fabricated),
                           "PDF must not contain fabricated DIN value '\(fabricated)' for an empty model")
        }

        // Instead, the DIN section shows its header and a dash placeholder.
        XCTAssertTrue(pdfText.contains("din 18041"), "PDF should still contain the DIN 18041 section header")
        XCTAssertTrue(pdfText.contains("t_soll=-"), "Empty model should show '-' for DIN targets")
    }

    func test_pdf_edge_cases_that_might_cause_failures() {
        // Test various edge cases that could cause PDF generation to fail

        // Case 1: Model with very long strings
        let modelWithLongStrings = ReportModel(
            metadata: ["device": String(repeating: "A", count: 1000), "app_version": "1.0.0"],
            rt60_bands: [],
            din_targets: [],
            validity: [:],
            recommendations: [String(repeating: "Very long recommendation ", count: 50)],
            audit: [:]
        )

        let pdfData1 = PDFReportRenderer().render(modelWithLongStrings)
        XCTAssertFalse(pdfData1.isEmpty, "PDF should handle long strings")

        // Case 2: Model with special characters and nil values mixed
        let modelWithSpecialChars = ReportModel(
            metadata: ["device": "iPad<>Pro&", "special": "üöäß@#$%"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": nil],
                ["freq_hz": nil, "t20_s": 0.5],
                ["freq_hz": Double.nan, "t20_s": Double.infinity] // Edge case values
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": nil, "tol": nil],
                ["freq_hz": -1.0, "t_soll": Double.nan, "tol": Double.infinity] // Invalid values
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        let pdfData2 = PDFReportRenderer().render(modelWithSpecialChars)
        XCTAssertFalse(pdfData2.isEmpty, "PDF should handle special characters and invalid values")

        // Case 3: Completely null model (all possible nil values)
        let modelWithNulls = ReportModel(
            metadata: [:],
            rt60_bands: [
                ["freq_hz": nil, "t20_s": nil]
            ],
            din_targets: [
                ["freq_hz": nil, "t_soll": nil, "tol": nil]
            ],
            validity: [:],
            recommendations: [],
            audit: [:]
        )

        let pdfData3 = PDFReportRenderer().render(modelWithNulls)
        XCTAssertFalse(pdfData3.isEmpty, "PDF should handle all null values")
        let pdfText3 = extractPDFText(pdfData3).lowercased()

        // Should still contain the required RT60 display frequencies
        XCTAssertTrue(pdfText3.contains("125"), "PDF should contain required frequency 125")
        XCTAssertTrue(pdfText3.contains("1000"), "PDF should contain required frequency 1000")
        XCTAssertTrue(pdfText3.contains("4000"), "PDF should contain required frequency 4000")
        // With only null DIN targets, the section must show a dash placeholder,
        // not a fabricated standard value.
        XCTAssertTrue(pdfText3.contains("t_soll=-"), "Null DIN targets should render as '-'")
        XCTAssertFalse(pdfText3.contains("0.6"), "PDF must not contain a fabricated DIN value")
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
