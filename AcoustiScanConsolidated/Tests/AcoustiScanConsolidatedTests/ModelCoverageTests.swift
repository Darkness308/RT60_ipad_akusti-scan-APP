import XCTest
@testable import AcoustiScanConsolidated

final class ModelCoverageTests: XCTestCase {

    private func makeMaterial(
        name: String = "Absorber",
        coefficients: [Int: Double] = [
            125: 0.10, 250: 0.15, 500: 0.20, 1000: 0.30, 2000: 0.40, 4000: 0.50, 8000: 0.60
        ]
    ) -> AcousticMaterial {
        AcousticMaterial(name: name, absorptionCoefficients: coefficients)
    }

    private func makeQuality(
        correlation: Double,
        snr: Double,
        dynamicRange: Double,
        positionCount: Int = 1,
        evaluationRange: EvaluationRange = .t20,
        uncertainty: Double = 0.05
    ) -> MeasurementQuality {
        MeasurementQuality(
            correlationCoefficient: correlation,
            uncertainty: uncertainty,
            signalToNoiseRatio: snr,
            dynamicRange: dynamicRange,
            positionCount: positionCount,
            evaluationRange: evaluationRange
        )
    }

    func testMeasurementQualityClassificationAndCalculatedDefaults() {
        let excellent = makeQuality(correlation: 0.99, snr: 50, dynamicRange: 20, positionCount: 3)
        let good = makeQuality(correlation: 0.95, snr: 35, dynamicRange: 20)
        let acceptable = makeQuality(correlation: 0.90, snr: 20, dynamicRange: 10)
        let poor = makeQuality(correlation: 0.89, snr: 20, dynamicRange: 10)

        XCTAssertTrue(excellent.isISOCompliant)
        XCTAssertEqual(excellent.qualityClass, .excellent)
        XCTAssertEqual(excellent.expandedUncertainty, 0.10, accuracy: 0.0001)

        XCTAssertTrue(good.isISOCompliant)
        XCTAssertEqual(good.qualityClass, .good)

        XCTAssertFalse(acceptable.isISOCompliant)
        XCTAssertEqual(acceptable.qualityClass, .acceptable)

        XCTAssertFalse(poor.isISOCompliant)
        XCTAssertEqual(poor.qualityClass, .poor)

        let calculated = MeasurementQuality.calculated
        XCTAssertTrue(calculated.isISOCompliant)
        XCTAssertEqual(calculated.qualityClass, .good)
        XCTAssertEqual(calculated.expandedUncertainty, 0)
        XCTAssertEqual(calculated.positionCount, 0)
        XCTAssertEqual(calculated.evaluationRange, .calculated)
    }

    func testEvaluationRangesQualityClassesAndMicrophoneSourceCoding() throws {
        let expectedRanges: [(EvaluationRange, Double, Double)] = [
            (.t20, 20, 35),
            (.t30, 30, 45),
            (.t60, 60, 65),
            (.calculated, 0, 0)
        ]

        for (range, expectedDynamicRange, expectedSNR) in expectedRanges {
            XCTAssertEqual(
                range.minimumDynamicRange,
                expectedDynamicRange,
                accuracy: 0.0001,
                "Unexpected minimum dynamic range for \(range)"
            )
            XCTAssertEqual(
                range.minimumSNR,
                expectedSNR,
                accuracy: 0.0001,
                "Unexpected minimum SNR for \(range)"
            )
        }

        let expectedQualityDescriptions: [(QualityClass, String, Bool)] = [
            (.excellent, "Gerichtsfest - Exceeds ISO 3382-1 requirements", true),
            (.good, "ISO-compliant measurement", true),
            (.acceptable, "Acceptable for estimation purposes", false),
            (.poor, "Below minimum quality standards", false)
        ]

        for (qualityClass, description, isLegallyDefensible) in expectedQualityDescriptions {
            XCTAssertEqual(qualityClass.description, description)
            XCTAssertEqual(qualityClass.isLegallyDefensible, isLegallyDefensible)
        }

        let decoder = JSONDecoder()
        let legacyCases: [(String, MicrophoneSource)] = [
            (#""Built-in""#, .builtIn),
            (#""USB""#, .usb),
            (#""Bluetooth""#, .bluetooth),
            (#""External""#, .external)
        ]

        for (json, expectedSource) in legacyCases {
            let decoded = try decoder.decode(MicrophoneSource.self, from: Data(json.utf8))
            XCTAssertEqual(decoded, expectedSource)
        }

        XCTAssertThrowsError(try decoder.decode(MicrophoneSource.self, from: Data(#""invalid""#.utf8)))
        XCTAssertEqual(try JSONEncoder().encode(MicrophoneSource.usb), Data(#""usb""#.utf8))
    }

    func testUncertaintyCalculatorUtilities() {
        let typeA = UncertaintyCalculator.typeAUncertainty(from: [1.0, 2.0, 3.0])
        XCTAssertEqual(typeA, 1.0 / sqrt(3.0), accuracy: 0.0001)
        XCTAssertEqual(UncertaintyCalculator.typeAUncertainty(from: [1.0]), 0.0)

        let combined = UncertaintyCalculator.combinedUncertainty(from: [3.0, 4.0])
        XCTAssertEqual(combined, 5.0, accuracy: 0.0001)

        let perfectlyCorrelated = UncertaintyCalculator.correlationCoefficient(
            x: [1, 2, 3, 4],
            y: [2, 4, 6, 8]
        )
        XCTAssertEqual(perfectlyCorrelated, 1.0, accuracy: 0.0001)

        XCTAssertEqual(UncertaintyCalculator.correlationCoefficient(x: [1, 2], y: [3]), 0.0)
        XCTAssertEqual(UncertaintyCalculator.correlationCoefficient(x: [1, 1], y: [2, 2]), 0.0)
    }

    func testExtendedMeasurementAndSessionComputedProperties() {
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.82, timestamp: .distantPast)
        let excellentQuality = makeQuality(correlation: 0.99, snr: 50, dynamicRange: 20, positionCount: 3)
        let acceptableQuality = makeQuality(correlation: 0.90, snr: 20, dynamicRange: 10)
        let validCalibration = CalibrationRecord(
            calibrationDate: Date(),
            validityPeriod: 24 * 60 * 60,
            calibratedBy: "Lab",
            microphoneIdentifier: "Mic-1",
            source: .usb,
            sensitivity: 10.0
        )
        let expiredCalibration = CalibrationRecord(
            calibrationDate: Date(timeIntervalSinceNow: -(2 * 24 * 60 * 60)),
            validityPeriod: 24 * 60 * 60,
            calibratedBy: "Lab",
            microphoneIdentifier: "Mic-2",
            source: .usb,
            sensitivity: 10.0
        )

        let legallyDefensibleMeasurement = RT60MeasurementWithQuality(
            measurement: measurement,
            quality: excellentQuality,
            calibration: validCalibration
        )
        let notLegallyDefensibleMeasurement = RT60MeasurementWithQuality(
            measurement: measurement,
            quality: acceptableQuality,
            calibration: expiredCalibration
        )

        XCTAssertTrue(legallyDefensibleMeasurement.isLegallyDefensible)
        XCTAssertFalse(notLegallyDefensibleMeasurement.isLegallyDefensible)
        XCTAssertEqual(legallyDefensibleMeasurement.formattedWithUncertainty, "0.82 +/- 0.10 s (k=2)")

        let calculated = RT60MeasurementWithQuality.fromCalculated(frequency: 500, rt60: 0.70)
        XCTAssertEqual(calculated.measurement.frequency, 500)
        XCTAssertEqual(calculated.measurement.rt60, 0.70, accuracy: 0.0001)
        XCTAssertEqual(calculated.quality, .calculated)
        XCTAssertNil(calculated.calibration)

        let session = MeasurementSession(
            projectName: "Room A",
            roomVolume: 150,
            measurements: [legallyDefensibleMeasurement, notLegallyDefensibleMeasurement],
            calibration: validCalibration
        )
        XCTAssertFalse(session.isFullyLegallyDefensible)
        XCTAssertEqual(session.overallQualityClass, .acceptable)
        XCTAssertEqual(session.isoComplianceSummary, "1/2 measurements ISO 3382-1 compliant")

        let emptySession = MeasurementSession(projectName: "Empty", roomVolume: 100)
        XCTAssertEqual(emptySession.overallQualityClass, .poor)
    }

    func testReportDataComputedProperties() throws {
        let surfaceA = AcousticSurface(name: "Wall", area: 10, material: makeMaterial())
        let surfaceB = AcousticSurface(name: "Ceiling", area: 5, material: makeMaterial())
        let compliant = RT60Deviation(frequency: 500, measuredRT60: 0.60, targetRT60: 0.60, status: .withinTolerance)
        let nonCompliant = RT60Deviation(frequency: 4000, measuredRT60: 0.90, targetRT60: 0.60, status: .tooHigh)
        let reportData = ReportData(
            date: "2026-05-29",
            roomType: .classroom,
            volume: 150,
            rt60Measurements: [
                RT60Measurement(frequency: 125, rt60: 0.90),
                RT60Measurement(frequency: 500, rt60: 0.60),
                RT60Measurement(frequency: 1000, rt60: 0.50),
                RT60Measurement(frequency: 2000, rt60: 0.70),
                RT60Measurement(frequency: 4000, rt60: 0.80)
            ],
            dinResults: [compliant, nonCompliant],
            acousticFrameworkResults: ["Clarity": 0.8],
            surfaces: [surfaceA, surfaceB],
            recommendations: ["Add absorber"]
        )

        XCTAssertFalse(reportData.overallCompliance)
        XCTAssertEqual(reportData.frequencyBandCount, 5)
        XCTAssertEqual(reportData.totalSurfaceArea, 15, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(reportData.averageSpeechRT60), 0.60, accuracy: 0.0001)

        let missingSpeechBands = ReportData(
            date: "2026-05-29",
            roomType: .conference,
            volume: 75,
            rt60Measurements: [RT60Measurement(frequency: 125, rt60: 0.9)],
            dinResults: [compliant],
            acousticFrameworkResults: [:],
            surfaces: [],
            recommendations: []
        )
        XCTAssertNil(missingSpeechBands.averageSpeechRT60)
    }

    func testReportModelFromReportDataUsesMappedMetadataAndDINTolerances() throws {
        let deviation = RT60Deviation(frequency: 500, measuredRT60: 0.55, targetRT60: 0.60, status: .withinTolerance)
        let reportData = ReportData(
            date: "2026-05-29",
            roomType: .classroom,
            volume: 150,
            rt60Measurements: [
                RT60Measurement(frequency: 500, rt60: 0.55),
                RT60Measurement(frequency: 1000, rt60: 0.60)
            ],
            dinResults: [deviation],
            acousticFrameworkResults: [:],
            surfaces: [],
            recommendations: ["Tune ceiling"]
        )

        let model = ReportModel.from(reportData)
        XCTAssertEqual(model.metadata["device"], "iPadPro")
        XCTAssertEqual(model.metadata["app_version"], "1.0.0")
        XCTAssertEqual(model.metadata["date"], "2026-05-29")
        XCTAssertEqual(model.metadata["room"], RoomType.classroom.displayName)
        XCTAssertEqual(model.validity, ["method": "ISO3382-1", "bands": "octave"])
        XCTAssertEqual(model.recommendations, ["Tune ceiling"])
        XCTAssertEqual(model.audit["source"], "consolidated")
        XCTAssertTrue((model.audit["hash"] ?? "").hasPrefix("DEMO"))

        XCTAssertEqual(model.rt60_bands.count, 2)
        let firstFrequency = try XCTUnwrap(model.rt60_bands[0]["freq_hz"] ?? nil)
        let firstRT60 = try XCTUnwrap(model.rt60_bands[0]["t20_s"] ?? nil)
        XCTAssertEqual(firstFrequency, 500, accuracy: 0.0001)
        XCTAssertEqual(firstRT60, 0.55, accuracy: 0.0001)

        let expectedTolerance = try XCTUnwrap(
            DIN18041Database.targets(for: .classroom, volume: 150)
                .first(where: { $0.frequency == 500 })?
                .tolerance
        )
        XCTAssertEqual(model.din_targets.count, 1)
        XCTAssertEqual(try XCTUnwrap(model.din_targets[0]["freq_hz"]), 500, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(model.din_targets[0]["t_soll"]), 0.60, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(model.din_targets[0]["tol"]), expectedTolerance, accuracy: 0.0001)
    }

    func testDIN18041TargetAndEvaluationStatusComputedProperties() {
        let target = DIN18041Target(frequency: 1000, targetRT60: 0.60, tolerance: 0.10)
        XCTAssertEqual(target.lowerBound, 0.50, accuracy: 0.0001)
        XCTAssertEqual(target.upperBound, 0.70, accuracy: 0.0001)
        XCTAssertTrue(target.isWithinTolerance(0.50))
        XCTAssertTrue(target.isWithinTolerance(0.70))
        XCTAssertFalse(target.isWithinTolerance(0.71))

        XCTAssertEqual(target.evaluateCompliance(0.60), .withinTolerance)
        XCTAssertEqual(target.evaluateCompliance(0.71), .tooHigh)
        XCTAssertEqual(target.evaluateCompliance(0.49), .tooLow)

        let expectedStatusProperties: [(EvaluationStatus, String, Bool, String)] = [
            (.withinTolerance, "Erfüllt", true, "green"),
            (.tooHigh, "Überschritten", false, "red"),
            (.tooLow, "Unterschritten", false, "orange"),
            (.partiallyCompliant, "Teilweise konform", false, "yellow")
        ]

        for (status, displayName, isCompliant, color) in expectedStatusProperties {
            XCTAssertEqual(status.displayName, displayName)
            XCTAssertEqual(status.isCompliant, isCompliant)
            XCTAssertEqual(status.color, color)
        }
    }

    func testRoomTypesAcousticSurfacesAndMaterialHelpers() throws {
        let expectedRoomMetadata: [(RoomType, String, String, ClosedRange<Double>)] = [
            (.classroom, "Klassenzimmer", "Speech", 120...300),
            (.officeSpace, "Büroraum", "Speech", 30...150),
            (.conference, "Konferenzraum", "Speech", 50...200),
            (.lecture, "Hörsaal", "Speech", 300...2000),
            (.music, "Musikraum", "Music", 150...1000),
            (.sports, "Sporthalle", "Sports", 1000...10000)
        ]

        for (roomType, displayName, primaryUse, range) in expectedRoomMetadata {
            XCTAssertEqual(roomType.displayName, displayName)
            XCTAssertEqual(roomType.primaryUse, primaryUse)
            XCTAssertEqual(roomType.typicalVolumeRange, range)
        }

        let sparseMaterial = AcousticMaterial(name: "Sparse", absorptionCoefficients: [500: 0.20, 1000: 0.40, 2000: 0.60])
        XCTAssertEqual(sparseMaterial.absorptionCoefficient(at: 125), 0.10, accuracy: 0.0001)
        XCTAssertEqual(sparseMaterial.speechAbsorption, 0.40, accuracy: 0.0001)
        XCTAssertFalse(sparseMaterial.hasCompleteData)

        let completeMaterial = makeMaterial()
        XCTAssertTrue(completeMaterial.hasCompleteData)

        let surface = AcousticSurface(name: "Wall", area: 12, material: completeMaterial)
        XCTAssertEqual(surface.absorptionArea(at: 1000), 3.6, accuracy: 0.0001)
        XCTAssertEqual(surface.averageAbsorption, 0.30, accuracy: 0.0001)
        XCTAssertEqual(surface.totalAbsorptionAreas.keys.sorted(), [125, 250, 500, 1000, 2000, 4000])
        XCTAssertEqual(try XCTUnwrap(surface.totalAbsorptionAreas[4000]), 6.0, accuracy: 0.0001)
        XCTAssertNil(surface.totalAbsorptionAreas[8000])
    }

    func testLabeledSurfaceConversionPreservesGeometryAndAbsorption() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
        let labeledSurface = LabeledSurface(id: id, name: "North Wall", area: 8, absorptionCoefficient: 0.35)

        XCTAssertEqual(labeledSurface.absorptionArea, 2.8, accuracy: 0.0001)

        let converted = labeledSurface.toAcousticSurface(materialName: "Converted Material")
        XCTAssertEqual(converted.name, "North Wall")
        XCTAssertEqual(converted.area, 8, accuracy: 0.0001)
        XCTAssertEqual(converted.material.name, "Converted Material")

        for frequency in [125, 250, 500, 1000, 2000, 4000] {
            XCTAssertEqual(
                try XCTUnwrap(converted.material.absorptionCoefficients[frequency]),
                0.35,
                accuracy: 0.0001,
                "Converted coefficient mismatch at \(frequency) Hz"
            )
        }
        XCTAssertNil(converted.material.absorptionCoefficients[8000])
    }

    func testAbsorberModelsAndRequirementCalculations() {
        let product = AbsorberProduct(
            name: "Foam Panel",
            frequencyBand: 1000,
            absorptionCoefficient: 0.80,
            pricePerSquareMeter: 25,
            category: .foam,
            thickness: 50,
            manufacturer: "Acme"
        )

        XCTAssertEqual(product.totalCost(for: 4), 100, accuracy: 0.0001)
        XCTAssertEqual(product.costEfficiency, 0.032, accuracy: 0.0001)
        XCTAssertEqual(AbsorberProduct.ProductCategory.mineral.displayName, "Mineralfaser")

        let freeProduct = AbsorberProduct(
            name: "Reuse",
            frequencyBand: 500,
            absorptionCoefficient: 0.50,
            pricePerSquareMeter: 0
        )
        XCTAssertEqual(freeProduct.costEfficiency, 0)

        let autoCostRecommendation = AbsorberRecommendation(
            frequency: 1000,
            product: product,
            areaNeeded: 3,
            expectedAbsorption: 2,
            priority: .high
        )
        XCTAssertEqual(autoCostRecommendation.totalCost, 75, accuracy: 0.0001)
        XCTAssertEqual(autoCostRecommendation.costEffectiveness, 37.5, accuracy: 0.0001)
        XCTAssertEqual(AbsorberRecommendation.Priority.critical.displayName, "Kritisch")

        let infiniteCostEffectiveness = AbsorberRecommendation(
            frequency: 500,
            product: product,
            areaNeeded: 1,
            totalCost: 25,
            expectedAbsorption: 0,
            priority: .low
        )
        XCTAssertEqual(infiniteCostEffectiveness.costEffectiveness, .infinity)

        let low = AbsorptionRequirement(frequency: 125, requiredAbsorption: 5, currentAbsorption: 10)
        let medium = AbsorptionRequirement(frequency: 250, requiredAbsorption: 15, currentAbsorption: 20)
        let high = AbsorptionRequirement(frequency: 500, requiredAbsorption: 20, currentAbsorption: 0)

        XCTAssertEqual(low.improvementPercentage, 50, accuracy: 0.0001)
        XCTAssertEqual(high.improvementPercentage, 100, accuracy: 0.0001)
        XCTAssertEqual(low.priority, .low)
        XCTAssertEqual(medium.priority, .medium)
        XCTAssertEqual(high.priority, .high)
        XCTAssertEqual(AbsorptionRequirement.Priority.medium.displayName, "Mittel")
    }

    func testAcousticFrameworkLookupHelpersAndRT60DeviationMath() {
        XCTAssertEqual(AcousticFramework.parameterCount, 48)
        XCTAssertEqual(AcousticFramework.categoryNames.count, AcousticFramework.ParameterCategory.allCases.count)
        XCTAssertEqual(AcousticFramework.categoryNames.first, "Allgemein")

        let parameter = AcousticFramework.parameter(withId: 13)
        XCTAssertEqual(parameter?.name, "Quellenbreite")
        XCTAssertEqual(parameter?.category, .geometrie)
        XCTAssertNil(AcousticFramework.parameter(withId: 999))

        let geometryParameters = AcousticFramework.parameters(for: .geometrie)
        XCTAssertEqual(geometryParameters.count, 5)
        for parameter in geometryParameters {
            XCTAssertEqual(parameter.category, .geometrie)
        }

        let deviation = RT60Deviation(
            frequency: 1000,
            measuredRT60: 0.72,
            targetRT60: 0.60,
            status: .tooHigh
        )
        XCTAssertEqual(deviation.deviation, 0.12, accuracy: 0.0001)
        XCTAssertEqual(deviation.relativeDeviation, 20, accuracy: 0.0001)

        let zeroTarget = RT60Deviation(
            frequency: 125,
            measuredRT60: 0.50,
            targetRT60: 0.0,
            status: .withinTolerance
        )
        XCTAssertEqual(zeroTarget.relativeDeviation, 0)
    }
}
