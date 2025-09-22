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
        let requiredFrequencies = ["125", "1000", "4000"] 
        for freq in requiredFrequencies {
            XCTAssertTrue(pdfText.contains(freq), "PDF fehlt erforderliche Frequenz: \(freq) bei leerem Model")
        }
        
        let requiredDINValues = ["0.65", "0.55", "0.15", "0.12"]
        for value in requiredDINValues {
            XCTAssertTrue(pdfText.contains(value), "PDF fehlt erforderlichen DIN-Wert: \(value) bei leerem Model")
        }
        
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]
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