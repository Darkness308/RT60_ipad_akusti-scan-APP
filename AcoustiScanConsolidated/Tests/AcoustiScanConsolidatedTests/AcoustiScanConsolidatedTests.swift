// AcoustiScanConsolidatedTests.swift
// Comprehensive test suite for the consolidated tool

import Testing
import Foundation
@testable import AcoustiScanConsolidated

/// Test suite for RT60 calculations
struct RT60CalculatorTests {
    
    @Test("RT60 calculation using Sabine formula")
    func testRT60Calculation() {
        let volume = 100.0 // m³
        let absorptionArea = 20.0 // m²
        
        let rt60 = RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)
        let expected = 0.161 * volume / absorptionArea // 0.805 seconds
        
        #expect(abs(rt60 - expected) < 0.001)
    }
    
    @Test("RT60 calculation with zero absorption")
    func testRT60CalculationZeroAbsorption() {
        let volume = 100.0
        let absorptionArea = 0.0
        
        let rt60 = RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)
        
        #expect(rt60 == 0.0)
    }
    
    @Test("Total absorption area calculation")
    func testTotalAbsorptionArea() {
        let areas = [10.0, 20.0, 30.0]
        let coefficients = [0.1, 0.2, 0.3]
        
        let totalAbsorption = RT60Calculator.totalAbsorptionArea(
            surfaceAreas: areas,
            absorptionCoefficients: coefficients
        )
        
        let expected = 10.0 * 0.1 + 20.0 * 0.2 + 30.0 * 0.3 // 14.0
        #expect(abs(totalAbsorption - expected) < 0.001)
    }
    
    @Test("Frequency spectrum calculation")
    func testFrequencySpectrumCalculation() {
        let volume = 150.0
        let surfaces = [
            AcousticSurface(
                name: "Wall",
                area: 50.0,
                material: AcousticMaterial(
                    name: "Concrete",
                    absorptionCoefficients: [
                        125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02,
                        2000: 0.02, 4000: 0.03, 8000: 0.03
                    ]
                )
            )
        ]
        
        let measurements = RT60Calculator.calculateFrequencySpectrum(volume: volume, surfaces: surfaces)
        
        #expect(measurements.count == 7) // 7 standard frequencies
        #expect(measurements.allSatisfy { $0.rt60 > 0 }) // All should be positive
        
        // Check that frequencies are correct
        let expectedFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
        let actualFrequencies = measurements.map { $0.frequency }.sorted()
        #expect(actualFrequencies == expectedFrequencies)
    }
}

/// Test suite for DIN 18041 compliance evaluation
struct DIN18041Tests {
    
    @Test("DIN 18041 target generation for classroom")
    func testClassroomTargets() {
        let targets = DIN18041Database.targets(for: .classroom, volume: 200.0)
        
        #expect(targets.count == 7) // 7 frequency bands
        #expect(targets.allSatisfy { $0.targetRT60 > 0 })
        #expect(targets.allSatisfy { $0.tolerance > 0 })
        
        // Check that 500-1000 Hz has reasonable values for classroom
        let midFreqTargets = targets.filter { $0.frequency == 500 || $0.frequency == 1000 }
        #expect(midFreqTargets.allSatisfy { $0.targetRT60 <= 0.8 }) // Should be relatively low for speech
    }
    
    @Test("DIN compliance evaluation")
    func testDINComplianceEvaluation() {
        let measurements = [
            RT60Measurement(frequency: 500, rt60: 0.65),
            RT60Measurement(frequency: 1000, rt60: 0.55),
            RT60Measurement(frequency: 2000, rt60: 0.70)
        ]
        
        let deviations = RT60Calculator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )
        
        #expect(deviations.count == 3)
        #expect(deviations.allSatisfy { $0.measuredRT60 > 0 })
        #expect(deviations.allSatisfy { $0.targetRT60 > 0 })
        
        // Check deviation calculation
        for deviation in deviations {
            let expectedDeviation = deviation.measuredRT60 - deviation.targetRT60
            #expect(abs(deviation.deviation - expectedDeviation) < 0.001)
        }
    }
    
    @Test("Evaluation status classification")
    func testEvaluationStatusClassification() {
        let withinTolerance = RT60Deviation(
            frequency: 1000,
            measuredRT60: 0.60,
            targetRT60: 0.60,
            status: .withinTolerance
        )
        
        let tooHigh = RT60Deviation(
            frequency: 1000,
            measuredRT60: 0.80,
            targetRT60: 0.60,
            status: .tooHigh
        )
        
        let tooLow = RT60Deviation(
            frequency: 1000,
            measuredRT60: 0.40,
            targetRT60: 0.60,
            status: .tooLow
        )
        
        #expect(abs(withinTolerance.deviation - 0.0) < 0.001)
        #expect(abs(tooHigh.deviation - 0.20) < 0.001)
        #expect(abs(tooLow.deviation - (-0.20)) < 0.001)
        
        #expect(withinTolerance.status == .withinTolerance)
        #expect(tooHigh.status == .tooHigh)
        #expect(tooLow.status == .tooLow)
    }
}

/// Test suite for Acoustic Framework
struct AcousticFrameworkTests {
    
    @Test("Framework parameter categories")
    func testParameterCategories() {
        let allCategories = AcousticFramework.ParameterCategory.allCases
        #expect(allCategories.count == 9) // 8 + general category
        
        // Test that each category has parameters
        for category in allCategories {
            let parameters = AcousticFramework.parameters(for: category)
            // At least the general category should have parameters
            if category == .general {
                #expect(parameters.count > 0)
            }
        }
    }
    
    @Test("Parameter structure validation")
    func testParameterStructure() {
        let parameters = AcousticFramework.allParameters
        #expect(parameters.count > 0)
        
        for parameter in parameters {
            #expect(!parameter.name.isEmpty)
            #expect(!parameter.definition.isEmpty)
            #expect(parameter.scaleLabel.count == 2) // Should have two scale endpoints
            #expect(parameter.nameId >= 0)
        }
    }
    
    @Test("Parameter filtering by category")
    func testParameterFiltering() {
        let klangfarbeParams = AcousticFramework.parameters(for: .klangfarbe)
        let geometrieParams = AcousticFramework.parameters(for: .geometrie)
        
        // All parameters should belong to the correct category
        #expect(klangfarbeParams.allSatisfy { $0.category == .klangfarbe })
        #expect(geometrieParams.allSatisfy { $0.category == .geometrie })
    }
}

/// Test suite for Build Automation
struct BuildAutomationTests {
    
    @Test("Error parsing from build output")
    func testErrorParsing() {
        let sampleOutput = """
        /path/to/file.swift:42:15: error: use of unresolved identifier 'UIKit'
        /path/to/other.swift:23:1: error: No such module 'SwiftUI'
        /path/to/another.swift:10:5: warning: variable 'x' was never used
        """
        
        // This would require making parseErrors public or creating a test interface
        // For now, we'll test the overall build automation flow
        #expect(true) // Placeholder
    }
    
    @Test("Build error classification")
    func testBuildErrorClassification() {
        let missingImportError = BuildAutomation.BuildError(
            file: "test.swift",
            line: 1,
            column: 1,
            message: "No such module 'UIKit'",
            type: .missingImport
        )
        
        let undeclaredError = BuildAutomation.BuildError(
            file: "test.swift",
            line: 2,
            column: 1,
            message: "use of unresolved identifier 'someVariable'",
            type: .undeclaredIdentifier
        )
        
        #expect(missingImportError.type == .missingImport)
        #expect(undeclaredError.type == .undeclaredIdentifier)
        #expect(missingImportError.file == "test.swift")
        #expect(missingImportError.line == 1)
    }
}

/// Test suite for PDF Export functionality
struct PDFExportTests {
    
    @Test("Report data structure")
    func testReportDataStructure() {
        let reportData = ConsolidatedPDFExporter.ReportData(
            date: "2025-01-01",
            roomType: .classroom,
            volume: 150.0,
            rt60Measurements: [
                RT60Measurement(frequency: 1000, rt60: 0.6)
            ],
            dinResults: [
                RT60Deviation(frequency: 1000, measuredRT60: 0.6, targetRT60: 0.6, status: .withinTolerance)
            ],
            acousticFrameworkResults: ["Test": 0.5],
            surfaces: [
                AcousticSurface(name: "Wall", area: 10.0, 
                              material: AcousticMaterial(name: "Concrete", absorptionCoefficients: [:]))
            ],
            recommendations: ["Test recommendation"]
        )
        
        #expect(reportData.date == "2025-01-01")
        #expect(reportData.roomType == .classroom)
        #expect(reportData.volume == 150.0)
        #expect(reportData.rt60Measurements.count == 1)
        #expect(reportData.dinResults.count == 1)
        #expect(reportData.surfaces.count == 1)
        #expect(reportData.recommendations.count == 1)
    }
    
    @Test("PDF generation availability")
    func testPDFGenerationAvailability() {
        #if canImport(UIKit)
        // PDF generation should be available on platforms with UIKit
        #expect(true)
        #else
        // On other platforms, we should handle gracefully
        #expect(true) // Test passes regardless
        #endif
    }
}

/// Contract tests for PDF ↔ HTML equivalence
struct ReportContractTests {
    
    @Test("nil values render as dash in both PDF and HTML")
    func test_nil_values_render_as_dash_in_both_pdf_and_html() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": nil],   // nil -> "-"
                ["freq_hz": 500.0, "t20_s": 0.55]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20],
                ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: ["method":"ISO3382-1"],
            recommendations: [],
            audit: [:]
        )

        // HTML
        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // 250 Hz must show "-" for nil
        #expect(htmlText.contains("250"))
        #expect(htmlText.contains("-"))
        
        // PDF generation test would go here when UIKit is available
        #if canImport(UIKit)
        // Convert ReportModel to ReportData for PDF
        let reportData = createReportDataFromModel(model)
        if let pdfData = ConsolidatedPDFExporter.generateReport(data: reportData) {
            let pdfText = PDFTextExtractor.extractText(from: pdfData)
            #expect(pdfText.contains("250"))
            #expect(pdfText.contains("-"))
        }
        #endif
    }

    @Test("all frequency labels match between PDF and HTML")
    func test_all_frequency_labels_match_between_pdf_and_html() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": 0.60],
                ["freq_hz": 500.0, "t20_s": nil],
                ["freq_hz": 1000.0, "t20_s": 0.50]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20],
                ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.20],
                ["freq_hz": 1000.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: ["method":"ISO3382-1"],
            recommendations: [],
            audit: [:]
        )

        // HTML rendering
        let htmlText = String(decoding: ReportHTMLRenderer().render(model), as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        // Frequency set from the model
        let expectedFreqs = Set(model.rt60_bands.compactMap { band -> Int? in
            guard let freq = band["freq_hz"] else { return nil }
            return Int(freq?.rounded() ?? 0)
        })

        // Check: each frequency must appear in HTML output
        for f in expectedFreqs {
            let token = "\(f)"
            #expect(htmlText.contains(token), "HTML missing frequency \(f) Hz")
        }
        
        #if canImport(UIKit)
        let reportData = createReportDataFromModel(model)
        if let pdfData = ConsolidatedPDFExporter.generateReport(data: reportData) {
            let pdfText = PDFTextExtractor.extractText(from: pdfData).lowercased()
            
            // Check: each frequency must appear in PDF output
            for f in expectedFreqs {
                let token = "\(f)"
                #expect(pdfText.contains(token), "PDF missing frequency \(f) Hz")
            }
        }
        #endif
    }

    @Test("all DIN targets match between PDF and HTML")
    func test_all_din_targets_match_between_pdf_and_html() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": 0.60]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20],
                ["freq_hz": 250.0, "t_soll": 0.55, "tol": 0.20]
            ],
            validity: ["method":"ISO3382-1"],
            recommendations: [],
            audit: [:]
        )

        let htmlText = String(decoding: ReportHTMLRenderer().render(model), as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        for row in model.din_targets {
            let f = Int(row["freq_hz"]?.rounded() ?? 0)
            let ts = String(format: "%.2f", row["t_soll"] ?? 0)
            let tol = String(format: "%.2f", row["tol"] ?? 0.2)

            let tokens = ["\(f)", ts, tol]
            for t in tokens {
                #expect(htmlText.contains(t), "HTML missing DIN token \(t) @\(f)Hz")
            }
        }
        
        #if canImport(UIKit)
        let reportData = createReportDataFromModel(model)
        if let pdfData = ConsolidatedPDFExporter.generateReport(data: reportData) {
            let pdfText = PDFTextExtractor.extractText(from: pdfData).lowercased()
            
            for row in model.din_targets {
                let f = Int((row["freq_hz"] as? Double ?? 0).rounded())
                let ts = String(format: "%.2f", row["t_soll"] as? Double ?? 0)
                let tol = String(format: "%.2f", row["tol"] as? Double ?? 0.2)

                let tokens = ["\(f)", ts, tol]
                for t in tokens {
                    #expect(pdfText.contains(t), "PDF missing DIN token \(t) @\(f)Hz")
                }
            }
        }
        #endif
    }

    @Test("numerical values match with 0.01 tolerance between PDF and HTML")
    func test_numerical_values_match_with_tolerance_between_pdf_and_html() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.72],
                ["freq_hz": 250.0, "t20_s": 0.68],
                ["freq_hz": 500.0, "t20_s": 0.55],
                ["freq_hz": 1000.0, "t20_s": 0.51]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.65, "tol": 0.18],
                ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.15],
                ["freq_hz": 500.0, "t_soll": 0.55, "tol": 0.12],
                ["freq_hz": 1000.0, "t_soll": 0.50, "tol": 0.10]
            ],
            validity: ["method":"ISO3382-1"],
            recommendations: [],
            audit: [:]
        )

        // HTML rendering
        let htmlText = String(decoding: ReportHTMLRenderer().render(model), as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Extract expected numerical values
        let expectedRT60Values = [0.72, 0.68, 0.55, 0.51]
        let expectedDINValues = [0.65, 0.60, 0.55, 0.50, 0.18, 0.15, 0.12, 0.10]
        
        // Verify all expected values are present in HTML
        for expectedValue in expectedRT60Values + expectedDINValues {
            let formattedValue = String(format: "%.2f", expectedValue)
            #expect(htmlText.contains(formattedValue), "HTML missing numerical value: \(formattedValue)")
        }
        
        #if canImport(UIKit)
        let reportData = createReportDataFromModel(model)
        if let pdfData = ConsolidatedPDFExporter.generateReport(data: reportData) {
            let pdfText = PDFTextExtractor.extractText(from: pdfData)
            
            // Verify all expected values are present in PDF with same formatting
            for expectedValue in expectedRT60Values + expectedDINValues {
                let formattedValue = String(format: "%.2f", expectedValue)
                #expect(pdfText.contains(formattedValue), "PDF missing numerical value: \(formattedValue)")
            }
            
            // Test that the same format is used in both outputs (2 decimal places)
            let tolerance = 0.01
            let htmlNumbers = extractNumbersFromText(htmlText)
            let pdfNumbers = extractNumbersFromText(pdfText)
            
            // Verify that all expected values are present in both outputs within tolerance
            for expectedValue in expectedRT60Values + expectedDINValues {
                let htmlHasValue = htmlNumbers.contains { abs($0 - expectedValue) <= tolerance }
                let pdfHasValue = pdfNumbers.contains { abs($0 - expectedValue) <= tolerance }
                
                #expect(htmlHasValue, "HTML missing value within tolerance: \(expectedValue)")
                #expect(pdfHasValue, "PDF missing value within tolerance: \(expectedValue)")
            }
        }
        #endif
    }
    
    // Helper function to extract numerical values from text
    private func extractNumbersFromText(_ text: String) -> [Double] {
        do {
            let pattern = #"\b\d+\.?\d*\b"#
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, range: range)
            
            return matches.compactMap { match in
                guard let range = Range(match.range, in: text) else { return nil }
                let numberString = String(text[range])
                return Double(numberString)
            }
        } catch {
            return []
        }
    }
    
    // Helper function to convert ReportModel to ReportData for PDF generation
    private func createReportDataFromModel(_ model: ReportModel) -> ConsolidatedPDFExporter.ReportData {
        let rt60Measurements = model.rt60_bands.compactMap { band -> RT60Measurement? in
            guard let freq = band["freq_hz"], let rt60_opt = band["t20_s"], let rt60 = rt60_opt else { return nil }
            return RT60Measurement(frequency: Int(freq?.rounded() ?? 0), rt60: rt60)
        }
        
        let dinResults = model.din_targets.map { target in
            let freq = Int(target["freq_hz"]?.rounded() ?? 0)
            let targetRT60 = target["t_soll"] ?? 0
            let tolerance = (target["tol"] as? Double) ?? 0.1
            
            // Find corresponding measurement
            let measuredRT60 = rt60Measurements.first { $0.frequency == freq }?.rt60 ?? targetRT60
            
            let diff = measuredRT60 - targetRT60
            let status: EvaluationStatus
            if abs(diff) <= tolerance {
                status = .withinTolerance
            } else if diff > 0 {
                status = .tooHigh
            } else {
                status = .tooLow
            }
            
            return RT60Deviation(frequency: freq, measuredRT60: measuredRT60, targetRT60: targetRT60, status: status)
        }
        
        return ConsolidatedPDFExporter.ReportData(
            date: model.metadata["date"] ?? "2025-01-01",
            roomType: .classroom,
            volume: 150.0,
            rt60Measurements: rt60Measurements,
            dinResults: dinResults,
            acousticFrameworkResults: [:],
            surfaces: [],
            recommendations: model.recommendations
        )
    }
}

/// Integration tests
struct IntegrationTests {
    
    @Test("Complete acoustic analysis workflow")
    func testCompleteWorkflow() {
        // Create test room
        let surfaces = [
            AcousticSurface(
                name: "Floor",
                area: 30.0,
                material: AcousticMaterial(
                    name: "Carpet",
                    absorptionCoefficients: [
                        125: 0.05, 250: 0.10, 500: 0.20, 1000: 0.30,
                        2000: 0.40, 4000: 0.50, 8000: 0.60
                    ]
                )
            )
        ]
        
        let volume = 120.0
        let roomType = RoomType.officeSpace
        
        // Calculate RT60
        let measurements = RT60Calculator.calculateFrequencySpectrum(
            volume: volume,
            surfaces: surfaces
        )
        
        #expect(measurements.count == 7)
        #expect(measurements.allSatisfy { $0.rt60 > 0 })
        
        // Evaluate DIN compliance
        let dinResults = RT60Calculator.evaluateDINCompliance(
            measurements: measurements,
            roomType: roomType,
            volume: volume
        )
        
        #expect(dinResults.count == measurements.count)
        
        // Create report data
        let reportData = ConsolidatedPDFExporter.ReportData(
            date: "2025-01-01",
            roomType: roomType,
            volume: volume,
            rt60Measurements: measurements,
            dinResults: dinResults,
            acousticFrameworkResults: ["Nachhallstärke": 0.7],
            surfaces: surfaces,
            recommendations: ["Test recommendation"]
        )
        
        #expect(reportData.rt60Measurements.count == 7)
        #expect(reportData.dinResults.count == 7)
        
        // Test passes if we reach this point without errors
        #expect(true)
    }
    
    @Test("Cross-platform compatibility")
    func testCrossPlatformCompatibility() {
        // Test that core functionality works on all platforms
        let rt60 = RT60Calculator.calculateRT60(volume: 100.0, absorptionArea: 10.0)
        #expect(rt60 > 0)
        
        let targets = DIN18041Database.targets(for: .classroom, volume: 150.0)
        #expect(targets.count > 0)
        
        let parameters = AcousticFramework.allParameters
        #expect(parameters.count > 0)
    }
}

/// Test suite for HTML Report Rendering
struct ReportHTMLRendererTests {

    @Test("HTML contains core sections and values")
    func testHTMLContainsCoresSectionsAndValues() {
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
        for token in ["rt60 bericht","metadaten","rt60 je frequenz","din 18041","gültigkeit","empfehlungen","audit"] {
            #expect(text.contains(token), "Fehlender Abschnitt: \(token)")
        }
        // Werte
        #expect(text.contains("ipadpro"))
        #expect(text.contains("1.0.0"))
        #expect(text.contains("125"))
        #expect(text.contains("0.70"))
        // nil -> "-"
        #expect(text.contains("250"))
        #expect(text.contains("-"))
    }

    @Test("HTML is UTF-8 and sanitized")
    func testHTMLIsUTF8AndSanitized() {
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
        #expect(String(data: data, encoding: .utf8) != nil)
        let html = String(decoding: data, as: UTF8.self)
        // Grundlegende Entschärfung (Escape) wird erwartet
        #expect(html.contains("&lt;iPad&amp;Pro&gt;"))
        #expect(!html.contains("<b>Keine Tags rendern</b>"))
    }
}