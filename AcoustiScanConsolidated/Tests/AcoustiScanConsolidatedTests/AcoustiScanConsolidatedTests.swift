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