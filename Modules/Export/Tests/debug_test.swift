import XCTest
@testable import ReportExport

// Create a test that should reveal the issue mentioned in the problem statement
class DebugPDFTests: XCTestCase {
    
    func testProblemScenario() {
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
        let pdfText = String(decoding: pdfData, as: UTF8.self).lowercased()
        
        print("Generated PDF text:")
        print(pdfText)
        print("\n=== Checking Requirements ===")
        
        // Check required frequencies - these should ALWAYS be present
        let requiredFrequencies = ["125", "1000", "4000"]
        var missingFreqs: [String] = []
        for freq in requiredFrequencies {
            if !pdfText.contains(freq) {
                missingFreqs.append(freq)
            }
        }
        
        // Check required DIN values - these should ALWAYS be present  
        let requiredDINValues = ["0.65", "0.55", "0.15", "0.12"]
        var missingDINs: [String] = []
        for value in requiredDINValues {
            if !pdfText.contains(value) {
                missingDINs.append(value)
            }
        }
        
        // Check core tokens
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]
        var missingTokens: [String] = []
        for token in coreTokens {
            if !pdfText.contains(token) {
                missingTokens.append(token)
            }
        }
        
        print("Missing frequencies: \(missingFreqs)")
        print("Missing DIN values: \(missingDINs)")
        print("Missing core tokens: \(missingTokens)")
        
        // These assertions should fail if the problem exists
        XCTAssertTrue(missingFreqs.isEmpty, "PDF missing required frequencies: \(missingFreqs)")
        XCTAssertTrue(missingDINs.isEmpty, "PDF missing required DIN values: \(missingDINs)")
        XCTAssertTrue(missingTokens.isEmpty, "PDF missing core tokens: \(missingTokens)")
    }
}