import XCTest
@testable import ReportExport

final class DebugTest: XCTestCase {

    func test_debug_pdf_content() {
        // Create a test model with minimal data - matching problem statement scenario
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
        
        // Render PDF
        let pdfData = PDFReportRenderer().render(model)
        let pdfText = String(decoding: pdfData, as: UTF8.self)
        
        print("=== PDF Content ===")
        print(pdfText)
        print("=== End PDF Content ===")
        
        // Check for required elements mentioned in problem statement
        let requiredFrequencies = [125, 250, 500, 1000, 2000, 4000]
        let requiredDINValues = [0.6, 0.5, 0.48]
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "din 18041"]
        
        print("\n=== Required Frequencies Check ===")
        for freq in requiredFrequencies {
            let contains = pdfText.lowercased().contains("\(freq)")
            print("Frequency \(freq): \(contains ? "✓" : "✗")")
        }
        
        print("\n=== Required DIN Values Check ===")
        for din in requiredDINValues {
            let contains = pdfText.lowercased().contains("\(din)")
            print("DIN \(din): \(contains ? "✓" : "✗")")
        }
        
        print("\n=== Core Tokens Check ===")
        for token in coreTokens {
            let contains = pdfText.lowercased().contains(token.lowercased())
            print("Token '\(token)': \(contains ? "✓" : "✗")")
        }
        
        // These should fail according to the problem statement
        XCTAssertTrue(pdfText.lowercased().contains("125"), "Should contain required frequency 125")
        XCTAssertTrue(pdfText.lowercased().contains("500"), "Should contain required frequency 500") 
        XCTAssertTrue(pdfText.lowercased().contains("2000"), "Should contain required frequency 2000")
        XCTAssertTrue(pdfText.lowercased().contains("0.6"), "Should contain required DIN value 0.6")
        XCTAssertTrue(pdfText.lowercased().contains("0.5"), "Should contain required DIN value 0.5")
        XCTAssertTrue(pdfText.lowercased().contains("0.48"), "Should contain required DIN value 0.48")
        XCTAssertTrue(pdfText.lowercased().contains("din 18041"), "Should contain core token 'din 18041'")
    }
}