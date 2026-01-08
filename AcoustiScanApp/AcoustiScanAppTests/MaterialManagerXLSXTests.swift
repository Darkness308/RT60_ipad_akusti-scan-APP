//
//  MaterialManagerXLSXTests.swift
//  AcoustiScanAppTests
//
//  Tests for XLSX import/export functionality in MaterialManager
//

import XCTest
@testable import AcoustiScanApp

class MaterialManagerXLSXTests: XCTestCase {

    var materialManager: MaterialManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        materialManager = MaterialManager()
    }

    override func tearDownWithError() throws {
        materialManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Export Tests

    func testExportToXLSX_EmptyMaterials_ReturnsValidXLSX() throws {
        // Given
        let emptyMaterials: [AcousticMaterial] = []

        // When
        let xlsxData = materialManager.exportToXLSX(materials: emptyMaterials)

        // Then
        XCTAssertNotNil(xlsxData, "XLSX data should not be nil even for empty materials")

        // Verify it's a valid ZIP file by checking signature
        if let data = xlsxData {
            XCTAssertGreaterThan(data.count, 0, "XLSX data should not be empty")

            // Check ZIP signature (PK\x03\x04)
            let signature = data.withUnsafeBytes { $0.load(as: UInt32.self) }
            XCTAssertEqual(signature, 0x04034b50, "XLSX should have valid ZIP signature")
        }
    }

    func testExportToXLSX_SingleMaterial_ReturnsValidXLSX() throws {
        // Given
        let material = AcousticMaterial(
            name: "Test Material",
            absorption: AbsorptionData(values: [
                125: 0.10,
                250: 0.20,
                500: 0.30,
                1000: 0.40,
                2000: 0.50,
                4000: 0.60
            ])
        )

        // When
        let xlsxData = materialManager.exportToXLSX(materials: [material])

        // Then
        XCTAssertNotNil(xlsxData, "XLSX data should not be nil")

        if let data = xlsxData {
            XCTAssertGreaterThan(data.count, 0, "XLSX data should not be empty")
        }
    }

    func testExportToXLSX_MultipleMaterials_ReturnsValidXLSX() throws {
        // Given
        let materials = [
            AcousticMaterial(
                name: "Material 1",
                absorption: AbsorptionData(values: [
                    125: 0.10, 250: 0.20, 500: 0.30,
                    1000: 0.40, 2000: 0.50, 4000: 0.60
                ])
            ),
            AcousticMaterial(
                name: "Material 2",
                absorption: AbsorptionData(values: [
                    125: 0.15, 250: 0.25, 500: 0.35,
                    1000: 0.45, 2000: 0.55, 4000: 0.65
                ])
            ),
            AcousticMaterial(
                name: "Material 3",
                absorption: AbsorptionData(values: [
                    125: 0.05, 250: 0.10, 500: 0.15,
                    1000: 0.20, 2000: 0.25, 4000: 0.30
                ])
            )
        ]

        // When
        let xlsxData = materialManager.exportToXLSX(materials: materials)

        // Then
        XCTAssertNotNil(xlsxData, "XLSX data should not be nil")
    }

    func testExportToXLSX_MaterialWithSpecialCharacters_HandlesCorrectly() throws {
        // Given
        let material = AcousticMaterial(
            name: "Test & \"Material\" <With> 'Special' Characters",
            absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.20, 500: 0.30,
                1000: 0.40, 2000: 0.50, 4000: 0.60
            ])
        )

        // When
        let xlsxData = materialManager.exportToXLSX(materials: [material])

        // Then
        XCTAssertNotNil(xlsxData, "XLSX data should handle special characters")
    }

    // MARK: - Import Tests

    func testImportFromXLSX_RoundTrip_PreservesData() throws {
        // Given
        let originalMaterials = [
            AcousticMaterial(
                name: "Concrete",
                absorption: AbsorptionData(values: [
                    125: 0.01, 250: 0.01, 500: 0.02,
                    1000: 0.02, 2000: 0.02, 4000: 0.03
                ])
            ),
            AcousticMaterial(
                name: "Carpet",
                absorption: AbsorptionData(values: [
                    125: 0.08, 250: 0.24, 500: 0.57,
                    1000: 0.69, 2000: 0.71, 4000: 0.73
                ])
            )
        ]

        // When - Export
        guard let xlsxData = materialManager.exportToXLSX(materials: originalMaterials) else {
            XCTFail("Export should succeed")
            return
        }

        // When - Import
        let importedMaterials = try materialManager.importFromXLSX(xlsxData)

        // Then
        XCTAssertEqual(importedMaterials.count, originalMaterials.count,
                       "Should import same number of materials")

        for (index, original) in originalMaterials.enumerated() {
            let imported = importedMaterials[index]

            XCTAssertEqual(imported.name, original.name,
                          "Material name should match")

            for frequency in AbsorptionData.standardFrequencies {
                let originalValue = original.absorption.coefficient(at: frequency)
                let importedValue = imported.absorption.coefficient(at: frequency)

                XCTAssertEqual(importedValue, originalValue, accuracy: 0.01,
                              "Absorption coefficient at \(frequency) Hz should match")
            }
        }
    }

    func testImportFromXLSX_InvalidData_ThrowsError() throws {
        // Given - Invalid ZIP data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        // When & Then
        XCTAssertThrowsError(try materialManager.importFromXLSX(invalidData)) { error in
            XCTAssertTrue(error is XLSXImportError,
                         "Should throw XLSXImportError")
        }
    }

    func testImportFromXLSX_EmptyXLSX_ReturnsEmptyArray() throws {
        // Given - Export empty materials list
        guard let xlsxData = materialManager.exportToXLSX(materials: []) else {
            XCTFail("Export should succeed")
            return
        }

        // When
        let importedMaterials = try materialManager.importFromXLSX(xlsxData)

        // Then
        XCTAssertEqual(importedMaterials.count, 0,
                       "Should import empty array from empty XLSX")
    }

    // MARK: - Integration Tests

    func testImportAndAdd_FromXLSX_AddsToCustomMaterials() throws {
        // Given
        let initialCount = materialManager.customMaterials.count

        let testMaterial = AcousticMaterial(
            name: "New Test Material",
            absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.30, 500: 0.45,
                1000: 0.60, 2000: 0.75, 4000: 0.90
            ])
        )

        guard let xlsxData = materialManager.exportToXLSX(materials: [testMaterial]) else {
            XCTFail("Export should succeed")
            return
        }

        // When
        try materialManager.importAndAdd(fromXLSX: xlsxData)

        // Then
        XCTAssertEqual(materialManager.customMaterials.count, initialCount + 1,
                       "Should add one material to custom materials")

        let addedMaterial = materialManager.customMaterials.last
        XCTAssertNotNil(addedMaterial)
        XCTAssertEqual(addedMaterial?.name, testMaterial.name)
    }

    // MARK: - Performance Tests

    func testExportPerformance_LargeDataset() throws {
        // Given - Create 100 materials
        var materials: [AcousticMaterial] = []
        for i in 0..<100 {
            materials.append(AcousticMaterial(
                name: "Material \(i)",
                absorption: AbsorptionData(values: [
                    125: Float.random(in: 0...1),
                    250: Float.random(in: 0...1),
                    500: Float.random(in: 0...1),
                    1000: Float.random(in: 0...1),
                    2000: Float.random(in: 0...1),
                    4000: Float.random(in: 0...1)
                ])
            ))
        }

        // When & Then
        measure {
            _ = materialManager.exportToXLSX(materials: materials)
        }
    }

    func testImportPerformance_LargeDataset() throws {
        // Given - Create and export 100 materials
        var materials: [AcousticMaterial] = []
        for i in 0..<100 {
            materials.append(AcousticMaterial(
                name: "Material \(i)",
                absorption: AbsorptionData(values: [
                    125: Float.random(in: 0...1),
                    250: Float.random(in: 0...1),
                    500: Float.random(in: 0...1),
                    1000: Float.random(in: 0...1),
                    2000: Float.random(in: 0...1),
                    4000: Float.random(in: 0...1)
                ])
            ))
        }

        guard let xlsxData = materialManager.exportToXLSX(materials: materials) else {
            XCTFail("Export should succeed")
            return
        }

        // When & Then
        measure {
            _ = try? materialManager.importFromXLSX(xlsxData)
        }
    }

    // MARK: - Edge Cases

    func testExportImport_MaterialWithZeroCoefficients_PreservesData() throws {
        // Given
        let material = AcousticMaterial(
            name: "Zero Absorption Material",
            absorption: AbsorptionData(values: [
                125: 0.0, 250: 0.0, 500: 0.0,
                1000: 0.0, 2000: 0.0, 4000: 0.0
            ])
        )

        // When
        guard let xlsxData = materialManager.exportToXLSX(materials: [material]) else {
            XCTFail("Export should succeed")
            return
        }

        let imported = try materialManager.importFromXLSX(xlsxData)

        // Then
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].name, material.name)

        for frequency in AbsorptionData.standardFrequencies {
            XCTAssertEqual(imported[0].absorption.coefficient(at: frequency), 0.0)
        }
    }

    func testExportImport_MaterialWithMaxCoefficients_PreservesData() throws {
        // Given
        let material = AcousticMaterial(
            name: "Perfect Absorber",
            absorption: AbsorptionData(values: [
                125: 1.0, 250: 1.0, 500: 1.0,
                1000: 1.0, 2000: 1.0, 4000: 1.0
            ])
        )

        // When
        guard let xlsxData = materialManager.exportToXLSX(materials: [material]) else {
            XCTFail("Export should succeed")
            return
        }

        let imported = try materialManager.importFromXLSX(xlsxData)

        // Then
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].name, material.name)

        for frequency in AbsorptionData.standardFrequencies {
            XCTAssertEqual(imported[0].absorption.coefficient(at: frequency), 1.0, accuracy: 0.01)
        }
    }

    func testExportImport_MaterialWithLongName_PreservesData() throws {
        // Given
        let longName = String(repeating: "A", count: 500)
        let material = AcousticMaterial(
            name: longName,
            absorption: AbsorptionData(values: [
                125: 0.5, 250: 0.5, 500: 0.5,
                1000: 0.5, 2000: 0.5, 4000: 0.5
            ])
        )

        // When
        guard let xlsxData = materialManager.exportToXLSX(materials: [material]) else {
            XCTFail("Export should succeed")
            return
        }

        let imported = try materialManager.importFromXLSX(xlsxData)

        // Then
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].name, longName)
    }
}
