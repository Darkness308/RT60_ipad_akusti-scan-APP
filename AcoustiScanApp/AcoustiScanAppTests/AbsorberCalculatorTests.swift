//
//  AbsorberCalculatorTests.swift
//  AcoustiScanAppTests
//
//  Unit tests for AbsorberCalculator DIN 18041 compliant calculations
//

import XCTest
@testable import AcoustiScanApp

final class AbsorberCalculatorTests: XCTestCase {

    var calculator: AbsorberCalculator!

    override func setUp() {
        calculator = AbsorberCalculator()
    }

    override func tearDown() {
        calculator = nil
    }

    // MARK: - Required Absorption Tests

    func testRequiredAbsorptionCalculation() {
        // When current RT60 > target RT60, additional absorption is needed
        let required = AbsorberCalculator.requiredAbsorption(
            currentRT60: 2.0,
            targetRT60: 1.0,
            roomVolume: 100.0,
            currentAbsorption: 8.05  // Sabine: 0.161 * 100 / 2.0 = 8.05
        )

        // Target absorption: 0.161 * 100 / 1.0 = 16.1
        // Required additional: 16.1 - 8.05 = 8.05
        XCTAssertEqual(required, 8.05, accuracy: 0.01)
    }

    func testRequiredAbsorptionReturnsZeroWhenTargetMet() {
        let required = AbsorberCalculator.requiredAbsorption(
            currentRT60: 0.8,
            targetRT60: 1.0,
            roomVolume: 100.0,
            currentAbsorption: 20.0
        )

        XCTAssertEqual(required, 0.0)
    }

    func testRequiredAbsorptionReturnsZeroForInvalidTarget() {
        let required = AbsorberCalculator.requiredAbsorption(
            currentRT60: 1.5,
            targetRT60: 0.0,  // Invalid
            roomVolume: 100.0,
            currentAbsorption: 10.0
        )

        XCTAssertEqual(required, 0.0)
    }

    func testRequiredAbsorptionNeverNegative() {
        let required = AbsorberCalculator.requiredAbsorption(
            currentRT60: 0.5,
            targetRT60: 1.0,
            roomVolume: 100.0,
            currentAbsorption: 50.0  // Very high absorption
        )

        XCTAssertGreaterThanOrEqual(required, 0.0)
    }

    // MARK: - Target RT60 Tests (DIN 18041)

    func testTargetRT60Classroom() {
        let target = AbsorberCalculator.targetRT60(for: .classroom, volume: 100.0)
        // Base: 0.55, exponent: 0.1 -> 0.55 * (100/100)^0.1 = 0.55
        XCTAssertEqual(target, 0.55, accuracy: 0.01)
    }

    func testTargetRT60ClassroomLargeRoom() {
        let target = AbsorberCalculator.targetRT60(for: .classroom, volume: 200.0)
        // 0.55 * (200/100)^0.1 = 0.55 * 2^0.1 ≈ 0.59
        XCTAssertGreaterThan(target, 0.55)
        XCTAssertLessThan(target, 0.65)
    }

    func testTargetRT60Office() {
        let target = AbsorberCalculator.targetRT60(for: .office, volume: 100.0)
        XCTAssertEqual(target, 0.50, accuracy: 0.01)
    }

    func testTargetRT60ConferenceRoom() {
        let target = AbsorberCalculator.targetRT60(for: .conferenceRoom, volume: 100.0)
        XCTAssertEqual(target, 0.60, accuracy: 0.01)
    }

    func testTargetRT60LectureHall() {
        let target = AbsorberCalculator.targetRT60(for: .lectureHall, volume: 100.0)
        XCTAssertEqual(target, 0.70, accuracy: 0.01)
    }

    func testTargetRT60MusicRoom() {
        let target = AbsorberCalculator.targetRT60(for: .musicRoom, volume: 100.0)
        XCTAssertEqual(target, 1.00, accuracy: 0.01)
    }

    func testTargetRT60SportsHall() {
        let target = AbsorberCalculator.targetRT60(for: .sportsHall, volume: 100.0)
        XCTAssertEqual(target, 1.50, accuracy: 0.01)
    }

    func testTargetRT60Restaurant() {
        let target = AbsorberCalculator.targetRT60(for: .restaurant, volume: 100.0)
        XCTAssertEqual(target, 0.70, accuracy: 0.01)
    }

    func testTargetRT60OpenPlanOffice() {
        let target = AbsorberCalculator.targetRT60(for: .openPlanOffice, volume: 100.0)
        XCTAssertEqual(target, 0.45, accuracy: 0.01)
    }

    func testTargetRT60HomeTheater() {
        let target = AbsorberCalculator.targetRT60(for: .homeTheater, volume: 100.0)
        XCTAssertEqual(target, 0.40, accuracy: 0.01)
    }

    func testTargetRT60RecordingStudio() {
        let target = AbsorberCalculator.targetRT60(for: .recordingStudio, volume: 100.0)
        XCTAssertEqual(target, 0.30, accuracy: 0.01)
    }

    // MARK: - Required Area Tests

    func testRequiredAreaCalculation() {
        let product = AbsorberProduct(
            name: "Test Absorber",
            manufacturer: "Test",
            type: .porousAbsorber,
            thickness: 50,
            absorptionCoefficients: [1000: 0.8],
            nrcRating: 0.8,
            fireRating: "A1"
        )

        // For 10 m² Sabine at 0.8 coefficient: 10 / 0.8 = 12.5 m²
        let area = AbsorberCalculator.requiredArea(
            for: product,
            at: 1000,
            requiredAbsorption: 10.0
        )

        XCTAssertEqual(area, 12.5, accuracy: 0.01)
    }

    func testRequiredAreaReturnsZeroForZeroCoefficient() {
        let product = AbsorberProduct(
            name: "Test Absorber",
            manufacturer: "Test",
            type: .porousAbsorber,
            thickness: 50,
            absorptionCoefficients: [1000: 0.0],
            nrcRating: 0.0,
            fireRating: "A1"
        )

        let area = AbsorberCalculator.requiredArea(
            for: product,
            at: 1000,
            requiredAbsorption: 10.0
        )

        XCTAssertEqual(area, 0.0)
    }

    func testRequiredAreaReturnsZeroForMissingFrequency() {
        let product = AbsorberProduct(
            name: "Test Absorber",
            manufacturer: "Test",
            type: .porousAbsorber,
            thickness: 50,
            absorptionCoefficients: [500: 0.8],  // Only 500 Hz
            nrcRating: 0.8,
            fireRating: "A1"
        )

        let area = AbsorberCalculator.requiredArea(
            for: product,
            at: 1000,  // Request 1000 Hz which is missing
            requiredAbsorption: 10.0
        )

        XCTAssertEqual(area, 0.0)
    }
}

// MARK: - AbsorberProduct Tests

final class AbsorberProductTests: XCTestCase {

    func testAbsorberProductInitialization() {
        let product = AbsorberProduct(
            name: "Mineralwolle 50mm",
            manufacturer: "ISOVER",
            type: .porousAbsorber,
            thickness: 50,
            absorptionCoefficients: [
                125: 0.20, 250: 0.65, 500: 0.90, 1000: 0.95, 2000: 0.95, 4000: 0.90, 8000: 0.85
            ],
            nrcRating: 0.85,
            fireRating: "A1",
            pricePerSqm: 12.50
        )

        XCTAssertEqual(product.name, "Mineralwolle 50mm")
        XCTAssertEqual(product.manufacturer, "ISOVER")
        XCTAssertEqual(product.type, .porousAbsorber)
        XCTAssertEqual(product.thickness, 50)
        XCTAssertEqual(product.nrcRating, 0.85)
        XCTAssertEqual(product.fireRating, "A1")
        XCTAssertEqual(product.pricePerSqm, 12.50)
    }

    func testAbsorberProductAbsorptionAtFrequency() {
        let product = AbsorberProduct(
            name: "Test",
            manufacturer: "Test",
            type: .porousAbsorber,
            thickness: 50,
            absorptionCoefficients: [1000: 0.95, 8000: 0.85],
            nrcRating: 0.90,
            fireRating: "A1"
        )

        XCTAssertEqual(product.absorption(at: 1000), 0.95)
        XCTAssertEqual(product.absorption(at: 8000), 0.85)
        XCTAssertEqual(product.absorption(at: 125), 0.0)  // Not defined
    }

    func testAbsorberTypeRawValues() {
        XCTAssertEqual(AbsorberProduct.AbsorberType.porousAbsorber.rawValue, "Poröser Absorber")
        XCTAssertEqual(AbsorberProduct.AbsorberType.membraneAbsorber.rawValue, "Membranabsorber")
        XCTAssertEqual(AbsorberProduct.AbsorberType.resonatorAbsorber.rawValue, "Resonanzabsorber")
        XCTAssertEqual(AbsorberProduct.AbsorberType.compositeAbsorber.rawValue, "Verbundabsorber")
        XCTAssertEqual(AbsorberProduct.AbsorberType.diffuser.rawValue, "Diffusor")
    }

    func testAbsorberTypeCaseIterable() {
        XCTAssertEqual(AbsorberProduct.AbsorberType.allCases.count, 5)
    }
}

// MARK: - AbsorberRecommendation Tests

final class AbsorberRecommendationTests: XCTestCase {

    func testRecommendationPriorityColors() {
        XCTAssertEqual(AbsorberRecommendation.Priority.critical.color, "red")
        XCTAssertEqual(AbsorberRecommendation.Priority.high.color, "orange")
        XCTAssertEqual(AbsorberRecommendation.Priority.medium.color, "yellow")
        XCTAssertEqual(AbsorberRecommendation.Priority.low.color, "blue")
        XCTAssertEqual(AbsorberRecommendation.Priority.none.color, "green")
    }

    func testRecommendationPriorityRawValues() {
        XCTAssertEqual(AbsorberRecommendation.Priority.critical.rawValue, "Kritisch")
        XCTAssertEqual(AbsorberRecommendation.Priority.high.rawValue, "Hoch")
        XCTAssertEqual(AbsorberRecommendation.Priority.medium.rawValue, "Mittel")
        XCTAssertEqual(AbsorberRecommendation.Priority.low.rawValue, "Niedrig")
        XCTAssertEqual(AbsorberRecommendation.Priority.none.rawValue, "Keine")
    }

    func testRecommendationPriorityCaseIterable() {
        XCTAssertEqual(AbsorberRecommendation.Priority.allCases.count, 5)
    }
}

// MARK: - RoomUsageType Tests

final class RoomUsageTypeTests: XCTestCase {

    func testRoomUsageTypeRawValues() {
        XCTAssertEqual(RoomUsageType.classroom.rawValue, "Klassenzimmer")
        XCTAssertEqual(RoomUsageType.office.rawValue, "Büro")
        XCTAssertEqual(RoomUsageType.conferenceRoom.rawValue, "Konferenzraum")
        XCTAssertEqual(RoomUsageType.lectureHall.rawValue, "Hörsaal")
        XCTAssertEqual(RoomUsageType.musicRoom.rawValue, "Musikraum")
        XCTAssertEqual(RoomUsageType.sportsHall.rawValue, "Sporthalle")
        XCTAssertEqual(RoomUsageType.restaurant.rawValue, "Restaurant")
        XCTAssertEqual(RoomUsageType.openPlanOffice.rawValue, "Großraumbüro")
        XCTAssertEqual(RoomUsageType.homeTheater.rawValue, "Heimkino")
        XCTAssertEqual(RoomUsageType.recordingStudio.rawValue, "Aufnahmestudio")
    }

    func testRoomUsageTypeIcons() {
        XCTAssertEqual(RoomUsageType.classroom.icon, "book.fill")
        XCTAssertEqual(RoomUsageType.office.icon, "building.2.fill")
        XCTAssertEqual(RoomUsageType.conferenceRoom.icon, "person.3.fill")
        XCTAssertEqual(RoomUsageType.lectureHall.icon, "studentdesk")
        XCTAssertEqual(RoomUsageType.musicRoom.icon, "music.note")
        XCTAssertEqual(RoomUsageType.sportsHall.icon, "sportscourt.fill")
        XCTAssertEqual(RoomUsageType.restaurant.icon, "fork.knife")
        XCTAssertEqual(RoomUsageType.openPlanOffice.icon, "rectangle.split.3x3")
        XCTAssertEqual(RoomUsageType.homeTheater.icon, "tv.fill")
        XCTAssertEqual(RoomUsageType.recordingStudio.icon, "mic.fill")
    }

    func testRoomUsageTypeDescriptions() {
        XCTAssertFalse(RoomUsageType.classroom.description.isEmpty)
        XCTAssertFalse(RoomUsageType.office.description.isEmpty)
        XCTAssertFalse(RoomUsageType.conferenceRoom.description.isEmpty)
        XCTAssertFalse(RoomUsageType.lectureHall.description.isEmpty)
        XCTAssertFalse(RoomUsageType.musicRoom.description.isEmpty)
        XCTAssertFalse(RoomUsageType.sportsHall.description.isEmpty)
        XCTAssertFalse(RoomUsageType.restaurant.description.isEmpty)
        XCTAssertFalse(RoomUsageType.openPlanOffice.description.isEmpty)
        XCTAssertFalse(RoomUsageType.homeTheater.description.isEmpty)
        XCTAssertFalse(RoomUsageType.recordingStudio.description.isEmpty)
    }

    func testRoomUsageTypeCaseIterable() {
        XCTAssertEqual(RoomUsageType.allCases.count, 10)
    }
}

// MARK: - Extended Material Database Tests

final class ExtendedMaterialDatabaseTests: XCTestCase {

    func testExtendedMaterialsLoadSuccessfully() {
        let materials = MaterialManager.loadExtendedMaterials()
        XCTAssertGreaterThan(materials.count, 40)
    }

    func testExtendedMaterialsHave8000HzValues() {
        let materials = MaterialManager.loadExtendedMaterials()

        for material in materials {
            XCTAssertNotNil(
                material.absorption.values[8000],
                "Material '\(material.name)' missing 8000 Hz value"
            )
        }
    }

    func testExtendedMaterialsHaveAllStandardFrequencies() {
        let materials = MaterialManager.loadExtendedMaterials()

        for material in materials {
            XCTAssertTrue(
                material.absorption.isComplete,
                "Material '\(material.name)' is missing standard frequencies"
            )
        }
    }

    func testExtendedMaterialsContainFloorMaterials() {
        let materials = MaterialManager.loadExtendedMaterials()
        let floorMaterials = materials.filter {
            $0.name.contains("Beton") ||
            $0.name.contains("Teppich") ||
            $0.name.contains("Parkett") ||
            $0.name.contains("Laminat")
        }
        XCTAssertGreaterThan(floorMaterials.count, 5)
    }

    func testExtendedMaterialsContainWallMaterials() {
        let materials = MaterialManager.loadExtendedMaterials()
        let wallMaterials = materials.filter {
            $0.name.contains("Ziegel") ||
            $0.name.contains("Gipskarton") ||
            $0.name.contains("Holz")
        }
        XCTAssertGreaterThan(wallMaterials.count, 3)
    }

    func testExtendedMaterialsContainAcousticPanels() {
        let materials = MaterialManager.loadExtendedMaterials()
        let acousticPanels = materials.filter {
            $0.name.contains("Akustik") ||
            $0.name.contains("Mineralwolle") ||
            $0.name.contains("Basotect")
        }
        XCTAssertGreaterThan(acousticPanels.count, 5)
    }

    func testAbsorptionCoefficientsInValidRange() {
        let materials = MaterialManager.loadExtendedMaterials()

        for material in materials {
            for (freq, coeff) in material.absorption.values {
                XCTAssertGreaterThanOrEqual(
                    coeff, 0.0,
                    "Material '\(material.name)' has negative coefficient at \(freq) Hz"
                )
                XCTAssertLessThanOrEqual(
                    coeff, 1.0,
                    "Material '\(material.name)' has coefficient > 1.0 at \(freq) Hz"
                )
            }
        }
    }
}
