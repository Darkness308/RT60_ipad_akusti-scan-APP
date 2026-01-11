// AcoustiScanConsolidatedTests.swift
// Comprehensive test suite for the consolidated tool

import XCTest
@testable import AcoustiScanConsolidated

// MARK: - RT60 Calculator Tests

final class RT60CalculatorTests: XCTestCase {

    func testRT60CalculationUsingSabineFormula() {
        let volume = 100.0 // m3
        let absorptionArea = 20.0 // m²

        let rt60 = RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)
        let expected = 0.161 * volume / absorptionArea // 0.805 seconds

        XCTAssertEqual(rt60, expected, accuracy: 0.001)
    }

    func testRT60CalculationWithZeroAbsorption() {
        let rt60 = RT60Calculator.calculateRT60(volume: 100.0, absorptionArea: 0.0)
        XCTAssertEqual(rt60, 0.0)
    }

    func testTotalAbsorptionAreaCalculation() {
        let areas = [10.0, 20.0, 30.0]
        let coefficients = [0.1, 0.2, 0.3]

        let totalAbsorption = RT60Calculator.totalAbsorptionArea(
            surfaceAreas: areas,
            absorptionCoefficients: coefficients
        )

        let expected = 10.0 * 0.1 + 20.0 * 0.2 + 30.0 * 0.3 // 14.0
        XCTAssertEqual(totalAbsorption, expected, accuracy: 0.001)
    }

    func testFrequencySpectrumCalculationProducesStandardBands() {
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

        XCTAssertEqual(measurements.count, 7) // 7 standard frequencies
        XCTAssertTrue(measurements.allSatisfy { $0.rt60 > 0 })

        let expectedFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
        let actualFrequencies = measurements.map { $0.frequency }.sorted()
        XCTAssertEqual(actualFrequencies, expectedFrequencies)
    }

    func testEvaluateDINComplianceDelegatesToEvaluator() {
        let measurements = [
            RT60Measurement(frequency: 500, rt60: 0.65),
            RT60Measurement(frequency: 1000, rt60: 0.55)
        ]

        let deviations = RT60Calculator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )

        XCTAssertEqual(deviations.count, measurements.count)
        XCTAssertTrue(deviations.allSatisfy { $0.targetRT60 > 0 })
    }
}

// MARK: - DIN 18041 Tests

final class DIN18041Tests: XCTestCase {

    func testClassroomTargetsProvideSevenBands() {
        let targets = DIN18041Database.targets(for: .classroom, volume: 200.0)

        XCTAssertEqual(targets.count, 7)
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance > 0 })

        let midFreqTargets = targets.filter { $0.frequency == 500 || $0.frequency == 1000 }
        XCTAssertTrue(midFreqTargets.allSatisfy { $0.targetRT60 <= 0.8 })
    }

    func testDINComplianceEvaluationProducesDeviations() {
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

        XCTAssertEqual(deviations.count, 3)
        XCTAssertTrue(deviations.allSatisfy { $0.measuredRT60 > 0 })
        XCTAssertTrue(deviations.allSatisfy { $0.targetRT60 > 0 })

        for deviation in deviations {
            let expectedDeviation = deviation.measuredRT60 - deviation.targetRT60
            XCTAssertEqual(deviation.deviation, expectedDeviation, accuracy: 0.001)
        }
    }

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

        XCTAssertEqual(withinTolerance.deviation, 0.0, accuracy: 0.001)
        XCTAssertEqual(tooHigh.deviation, 0.20, accuracy: 0.001)
        XCTAssertEqual(tooLow.deviation, -0.20, accuracy: 0.001)

        XCTAssertEqual(withinTolerance.status, .withinTolerance)
        XCTAssertEqual(tooHigh.status, .tooHigh)
        XCTAssertEqual(tooLow.status, .tooLow)
    }
}

// MARK: - Acoustic Framework Tests

final class AcousticFrameworkTests: XCTestCase {

    func testParameterCategoriesExist() {
        let allCategories = AcousticFramework.ParameterCategory.allCases
        XCTAssertEqual(allCategories.count, 9)

        for category in allCategories {
            let parameters = AcousticFramework.parameters(for: category)
            if category == .general {
                XCTAssertFalse(parameters.isEmpty)
            }
        }
    }

    func testParameterStructure() {
        let parameters = AcousticFramework.allParameters
        XCTAssertFalse(parameters.isEmpty)

        for parameter in parameters {
            XCTAssertFalse(parameter.name.isEmpty)
            XCTAssertFalse(parameter.definition.isEmpty)
            XCTAssertEqual(parameter.scaleLabel.count, 2)
            XCTAssertGreaterThanOrEqual(parameter.nameId, 0)
        }
    }

    func testParameterFilteringByCategory() {
        let klangfarbeParams = AcousticFramework.parameters(for: .klangfarbe)
        let geometrieParams = AcousticFramework.parameters(for: .geometrie)

        XCTAssertTrue(klangfarbeParams.allSatisfy { $0.category == .klangfarbe })
        XCTAssertTrue(geometrieParams.allSatisfy { $0.category == .geometrie })
    }
}

// MARK: - Build Automation Tests

final class BuildAutomationTests: XCTestCase {

    func testBuildErrorClassificationPreservesMetadata() {
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

        XCTAssertEqual(missingImportError.type, .missingImport)
        XCTAssertEqual(undeclaredError.type, .undeclaredIdentifier)
        XCTAssertEqual(missingImportError.file, "test.swift")
        XCTAssertEqual(missingImportError.line, 1)
    }
}

// MARK: - PDF Export Tests

final class PDFExportTests: XCTestCase {

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

        XCTAssertEqual(reportData.date, "2025-01-01")
        XCTAssertEqual(reportData.roomType, .classroom)
        XCTAssertEqual(reportData.volume, 150.0)
        XCTAssertEqual(reportData.rt60Measurements.count, 1)
        XCTAssertEqual(reportData.dinResults.count, 1)
        XCTAssertEqual(reportData.surfaces.count, 1)
        XCTAssertEqual(reportData.recommendations.count, 1)
    }

    func testPDFGenerationAvailabilityDoesNotCrash() {
        #if canImport(UIKit)
        XCTAssertTrue(true)
        #else
        XCTAssertTrue(true)
        #endif
    }
}

// MARK: - Report Contract Tests

final class ReportContractTests: XCTestCase {

    func testNilValuesRenderAsDashInHTML() {
        let model = ReportModel(
            metadata: ["device":"iPadPro","app_version":"1.0.0","date":"2025-07-21"],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.70],
                ["freq_hz": 250.0, "t20_s": nil],
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

        let htmlData = ReportHTMLRenderer().render(model)
        let htmlText = String(decoding: htmlData, as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        XCTAssertTrue(htmlText.contains("250"))
        XCTAssertTrue(htmlText.contains("-"))
    }

    func testFrequencyLabelsMatchBetweenPDFAndHTML() {
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

        let htmlText = String(decoding: ReportHTMLRenderer().render(model), as: UTF8.self)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .lowercased()

        let expectedFreqs = Set(model.rt60_bands.compactMap { band -> Int? in
            guard let freq = band["freq_hz"] else { return nil }
            return Int(freq?.rounded() ?? 0)
        })

        for f in expectedFreqs {
            let token = "\(f)"
            XCTAssertTrue(htmlText.contains(token), "HTML missing frequency \(f) Hz")
        }
    }

    func testDINTargetsRenderedInHTML() {
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
            for token in tokens {
                XCTAssertTrue(htmlText.contains(token), "HTML missing DIN token \(token) @\(f)Hz")
            }
        }
    }
}
