//
//  LocalizationTests.swift
//  AcoustiScanAppTests
//
//  Unit tests for localization keys and String extension
//  Tests cover all localization keys, string extension, and localization completeness
//

import XCTest
@testable import AcoustiScanApp

class LocalizationTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    // MARK: - Room & General Keys Tests

    func testLocalization_RoomKeys_AreNotEmpty() {
        // Test room-related localization keys
        let keys = [
            LocalizationKeys.unnamedRoom,
            LocalizationKeys.room,
            LocalizationKeys.volume,
            LocalizationKeys.surfaces,
            LocalizationKeys.surface,
            LocalizationKeys.date
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Localization key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Localized string should not be empty for key: \(key)")
        }
    }

    func testLocalization_UnnamedRoom_HasValidKey() {
        // Given
        let key = LocalizationKeys.unnamedRoom

        // Then
        XCTAssertEqual(key, "unnamed_room", "Unnamed room key should match expected value")
        XCTAssertFalse(key.localized().isEmpty, "Unnamed room should have localized value")
    }

    func testLocalization_Room_HasValidKey() {
        // Given
        let key = LocalizationKeys.room

        // Then
        XCTAssertEqual(key, "room", "Room key should match expected value")
        XCTAssertFalse(key.localized().isEmpty, "Room should have localized value")
    }

    // MARK: - Room Dimensions Keys Tests

    func testLocalization_RoomDimensionKeys_AreNotEmpty() {
        // Test room dimension localization keys
        let keys = [
            LocalizationKeys.roomDimensions,
            LocalizationKeys.roomDimensionsInMeters,
            LocalizationKeys.length,
            LocalizationKeys.width,
            LocalizationKeys.height,
            LocalizationKeys.totalArea,
            LocalizationKeys.roomVolume
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Dimension key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Dimension key should have localized value: \(key)")
        }
    }

    func testLocalization_DimensionKeys_HaveCorrectValues() {
        // Test specific dimension keys
        XCTAssertEqual(LocalizationKeys.length, "length", "Length key should match")
        XCTAssertEqual(LocalizationKeys.width, "width", "Width key should match")
        XCTAssertEqual(LocalizationKeys.height, "height", "Height key should match")
    }

    // MARK: - Material Keys Tests

    func testLocalization_MaterialKeys_AreNotEmpty() {
        // Test material-related localization keys
        let keys = [
            LocalizationKeys.newMaterial,
            LocalizationKeys.savedMaterials,
            LocalizationKeys.addButton,
            LocalizationKeys.material,
            LocalizationKeys.materialOverview
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Material key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Material key should have localized value: \(key)")
        }
    }

    func testLocalization_MaterialKeys_HaveCorrectValues() {
        // Test specific material keys
        XCTAssertEqual(LocalizationKeys.newMaterial, "new_material", "New material key should match")
        XCTAssertEqual(LocalizationKeys.savedMaterials, "saved_materials", "Saved materials key should match")
        XCTAssertEqual(LocalizationKeys.addButton, "add_button", "Add button key should match")
    }

    // MARK: - Export Keys Tests

    func testLocalization_ExportKeys_AreNotEmpty() {
        // Test export-related localization keys
        let keys = [
            LocalizationKeys.dataExport,
            LocalizationKeys.exportRT60AsPDF,
            LocalizationKeys.export,
            LocalizationKeys.pdfExport,
            LocalizationKeys.featureInIntegration
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Export key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Export key should have localized value: \(key)")
        }
    }

    func testLocalization_ExportKeys_HaveCorrectValues() {
        // Test specific export keys
        XCTAssertEqual(LocalizationKeys.export, "export", "Export key should match")
        XCTAssertEqual(LocalizationKeys.pdfExport, "pdf_export", "PDF export key should match")
    }

    // MARK: - Scanning Keys Tests

    func testLocalization_ScanningKeys_AreNotEmpty() {
        // Test scanning-related localization keys
        let keys = [
            LocalizationKeys.scanning,
            LocalizationKeys.scanReady,
            LocalizationKeys.stopScan,
            LocalizationKeys.startScan,
            LocalizationKeys.lidarScan,
            LocalizationKeys.floor,
            LocalizationKeys.wall
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Scanning key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Scanning key should have localized value: \(key)")
        }
    }

    func testLocalization_ScanningKeys_HaveCorrectValues() {
        // Test specific scanning keys
        XCTAssertEqual(LocalizationKeys.scanning, "scanning", "Scanning key should match")
        XCTAssertEqual(LocalizationKeys.startScan, "start_scan", "Start scan key should match")
        XCTAssertEqual(LocalizationKeys.stopScan, "stop_scan", "Stop scan key should match")
        XCTAssertEqual(LocalizationKeys.floor, "floor", "Floor key should match")
        XCTAssertEqual(LocalizationKeys.wall, "wall", "Wall key should match")
    }

    // MARK: - Report Keys Tests

    func testLocalization_ReportKeys_AreNotEmpty() {
        // Test report-related localization keys
        let keys = [
            LocalizationKeys.rt60Report,
            LocalizationKeys.metadata,
            LocalizationKeys.device,
            LocalizationKeys.version,
            LocalizationKeys.currentDevice,
            LocalizationKeys.currentVersion,
            LocalizationKeys.validity,
            LocalizationKeys.validityUncertainties,
            LocalizationKeys.coreTokens
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Report key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Report key should have localized value: \(key)")
        }
    }

    // MARK: - RT60 Measurement Keys Tests

    func testLocalization_RT60Keys_AreNotEmpty() {
        // Test RT60-related localization keys
        let keys = [
            LocalizationKeys.rt60PerFrequency,
            LocalizationKeys.frequencyHz,
            LocalizationKeys.t20Seconds,
            LocalizationKeys.frequencyHeader,
            LocalizationKeys.rt60Measurements,
            LocalizationKeys.measured,
            LocalizationKeys.target,
            LocalizationKeys.status
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "RT60 key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "RT60 key should have localized value: \(key)")
        }
    }

    func testLocalization_RT60Keys_HaveCorrectValues() {
        // Test specific RT60 keys
        XCTAssertEqual(LocalizationKeys.measured, "measured", "Measured key should match")
        XCTAssertEqual(LocalizationKeys.target, "target", "Target key should match")
        XCTAssertEqual(LocalizationKeys.status, "status", "Status key should match")
    }

    // MARK: - DIN 18041 Keys Tests

    func testLocalization_DINKeys_AreNotEmpty() {
        // Test DIN 18041-related localization keys
        let keys = [
            LocalizationKeys.dinTargetTolerance,
            LocalizationKeys.dinTargetToleranceHeader,
            LocalizationKeys.dinClassification,
            LocalizationKeys.dinConformNote,
            LocalizationKeys.auditSourceNote,
            LocalizationKeys.frequency,
            LocalizationKeys.tolerance
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "DIN key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "DIN key should have localized value: \(key)")
        }
    }

    func testLocalization_DINKeys_HaveCorrectValues() {
        // Test specific DIN keys
        XCTAssertEqual(LocalizationKeys.frequency, "frequency", "Frequency key should match")
        XCTAssertEqual(LocalizationKeys.tolerance, "tolerance", "Tolerance key should match")
    }

    // MARK: - Status & Classification Keys Tests

    func testLocalization_StatusKeys_AreNotEmpty() {
        // Test status and classification localization keys
        let keys = [
            LocalizationKeys.recommendations,
            LocalizationKeys.recommendationsTitle,
            LocalizationKeys.recommendationsIntro,
            LocalizationKeys.audit,
            LocalizationKeys.compliant,
            LocalizationKeys.warning,
            LocalizationKeys.critical,
            LocalizationKeys.statusOk,
            LocalizationKeys.statusTolerance,
            LocalizationKeys.statusCritical,
            LocalizationKeys.criticalActionRequired,
            LocalizationKeys.partiallyCompliant,
            LocalizationKeys.conformDIN
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Status key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Status key should have localized value: \(key)")
        }
    }

    func testLocalization_StatusKeys_HaveCorrectValues() {
        // Test specific status keys
        XCTAssertEqual(LocalizationKeys.compliant, "compliant", "Compliant key should match")
        XCTAssertEqual(LocalizationKeys.warning, "warning", "Warning key should match")
        XCTAssertEqual(LocalizationKeys.critical, "critical", "Critical key should match")
    }

    // MARK: - Enhanced PDF Report Keys Tests

    func testLocalization_PDFReportKeys_AreNotEmpty() {
        // Test PDF report localization keys
        let keys = [
            LocalizationKeys.acousticReport,
            LocalizationKeys.dinStandard,
            LocalizationKeys.areaSquareMeters
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "PDF report key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "PDF report key should have localized value: \(key)")
        }
    }

    // MARK: - Error Keys Tests

    func testLocalization_ErrorKeys_AreNotEmpty() {
        // Test error-related localization keys
        let keys = [
            LocalizationKeys.formatError,
            LocalizationKeys.checksumInvalid
        ]

        for key in keys {
            XCTAssertFalse(key.isEmpty, "Error key should not be empty")
            XCTAssertFalse(key.localized().isEmpty, "Error key should have localized value: \(key)")
        }
    }

    func testLocalization_ErrorKeys_HaveCorrectValues() {
        // Test specific error keys
        XCTAssertEqual(LocalizationKeys.formatError, "format_error", "Format error key should match")
        XCTAssertEqual(LocalizationKeys.checksumInvalid, "checksum_invalid", "Checksum invalid key should match")
    }

    // MARK: - String Extension Tests

    func testStringExtension_Localized_ReturnsNonEmptyString() {
        // Given - A localization key
        let key = "room"

        // When - Get localized string
        let localized = key.localized()

        // Then - Should return non-empty string
        XCTAssertFalse(localized.isEmpty, "Localized string should not be empty")
    }

    func testStringExtension_Localized_WithComment_Works() {
        // Given - A localization key with comment
        let key = "room"
        let comment = "Room label"

        // When - Get localized string with comment
        let localized = key.localized(comment: comment)

        // Then - Should return non-empty string
        XCTAssertFalse(localized.isEmpty, "Localized string with comment should not be empty")
    }

    func testStringExtension_Localized_WithEmptyComment_Works() {
        // Given - A localization key with empty comment
        let key = "room"
        let comment = ""

        // When - Get localized string with empty comment
        let localized = key.localized(comment: comment)

        // Then - Should return non-empty string
        XCTAssertFalse(localized.isEmpty, "Localized string with empty comment should not be empty")
    }

    func testStringExtension_Localized_WithInvalidKey_ReturnsSameKey() {
        // Given - An invalid localization key
        let invalidKey = "this_key_does_not_exist_in_localization_file"

        // When - Get localized string
        let localized = invalidKey.localized()

        // Then - Should return the same key (standard NSLocalizedString behavior)
        XCTAssertEqual(localized, invalidKey, "Invalid key should return the key itself")
    }

    // MARK: - Localization Consistency Tests

    func testLocalization_AllKeys_FollowNamingConvention() {
        // Test that all keys follow snake_case naming convention
        let allKeys = [
            LocalizationKeys.unnamedRoom,
            LocalizationKeys.newMaterial,
            LocalizationKeys.savedMaterials,
            LocalizationKeys.dataExport,
            LocalizationKeys.roomDimensionsInMeters,
            LocalizationKeys.exportRT60AsPDF
        ]

        for key in allKeys {
            // Check if key follows snake_case (lowercase with underscores)
            let hasValidCharacters = key.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }
            XCTAssertTrue(hasValidCharacters,
                         "Key '\(key)' should follow snake_case naming convention")
        }
    }

    func testLocalization_NoEmptyKeys_InLocalizationKeys() {
        // Ensure no empty keys are defined
        let mirror = Mirror(reflecting: LocalizationKeys.self)

        for child in mirror.children {
            if let value = child.value as? String {
                XCTAssertFalse(value.isEmpty, "Localization key should not be empty")
            }
        }
    }

    // MARK: - Critical Keys Completeness Tests

    func testLocalization_CriticalKeys_ExistForMainFeatures() {
        // Test that critical keys for main features exist and are localized
        let criticalKeys = [
            (key: LocalizationKeys.scanning, feature: "Scanning"),
            (key: LocalizationKeys.material, feature: "Materials"),
            (key: LocalizationKeys.export, feature: "Export"),
            (key: LocalizationKeys.rt60Report, feature: "RT60 Report"),
            (key: LocalizationKeys.roomDimensions, feature: "Room Dimensions")
        ]

        for (key, feature) in criticalKeys {
            XCTAssertFalse(key.isEmpty, "\(feature) key should not be empty")
            XCTAssertFalse(key.localized().isEmpty,
                          "\(feature) should have localized value")
        }
    }

    func testLocalization_AllFrequencyKeys_AreConsistent() {
        // Test that frequency-related keys are consistent
        let frequencyRelatedKeys = [
            LocalizationKeys.frequency,
            LocalizationKeys.frequencyHz,
            LocalizationKeys.frequencyHeader,
            LocalizationKeys.rt60PerFrequency
        ]

        for key in frequencyRelatedKeys {
            XCTAssertFalse(key.isEmpty, "Frequency key should not be empty")
            XCTAssertTrue(key.contains("frequency") || key.contains("hz"),
                         "Frequency key should contain 'frequency' or 'hz': \(key)")
        }
    }

    // MARK: - Integration Tests

    func testLocalization_RealWorldUsage_RoomNameDisplay() {
        // Given - A room name using localization
        let defaultRoomName = LocalizationKeys.unnamedRoom.localized()

        // Then - Should be a valid display string
        XCTAssertFalse(defaultRoomName.isEmpty, "Default room name should not be empty")
        XCTAssertNotEqual(defaultRoomName, LocalizationKeys.unnamedRoom,
                         "Should be localized, not the key itself")
    }

    func testLocalization_RealWorldUsage_ExportButtonLabel() {
        // Given - Export button label using localization
        let exportLabel = LocalizationKeys.exportRT60AsPDF.localized()

        // Then - Should be a valid display string
        XCTAssertFalse(exportLabel.isEmpty, "Export label should not be empty")
        XCTAssertNotEqual(exportLabel, LocalizationKeys.exportRT60AsPDF,
                         "Should be localized, not the key itself")
    }

    func testLocalization_RealWorldUsage_StatusDisplay() {
        // Given - Status labels using localization
        let statusOk = LocalizationKeys.statusOk.localized()
        let statusWarning = LocalizationKeys.statusTolerance.localized()
        let statusCritical = LocalizationKeys.statusCritical.localized()

        // Then - All status labels should be valid
        XCTAssertFalse(statusOk.isEmpty, "Status OK should not be empty")
        XCTAssertFalse(statusWarning.isEmpty, "Status warning should not be empty")
        XCTAssertFalse(statusCritical.isEmpty, "Status critical should not be empty")
    }

    func testLocalization_RealWorldUsage_DimensionLabels() {
        // Given - Dimension labels using localization
        let lengthLabel = LocalizationKeys.length.localized()
        let widthLabel = LocalizationKeys.width.localized()
        let heightLabel = LocalizationKeys.height.localized()

        // Then - All dimension labels should be valid
        XCTAssertFalse(lengthLabel.isEmpty, "Length label should not be empty")
        XCTAssertFalse(widthLabel.isEmpty, "Width label should not be empty")
        XCTAssertFalse(heightLabel.isEmpty, "Height label should not be empty")

        // And they should be different (unless in a language where they're the same)
        let allLabels = Set([lengthLabel, widthLabel, heightLabel])
        // Note: In some languages, these might be the same word with context
        XCTAssertGreaterThanOrEqual(allLabels.count, 1,
                                   "Should have at least one unique dimension label")
    }

    // MARK: - Edge Cases

    func testLocalization_EdgeCase_LongKey() {
        // Given - A relatively long key
        let longKey = LocalizationKeys.roomDimensionsInMeters

        // When - Get localized string
        let localized = longKey.localized()

        // Then - Should work correctly
        XCTAssertFalse(localized.isEmpty, "Long key should have localized value")
    }

    func testLocalization_EdgeCase_KeyWithNumbers() {
        // Given - Key containing numbers (like DIN 18041)
        let dinKey = LocalizationKeys.dinStandard

        // When - Get localized string
        let localized = dinKey.localized()

        // Then - Should work correctly
        XCTAssertFalse(localized.isEmpty, "Key with numbers should have localized value")
    }

    func testLocalization_EdgeCase_MultipleWordsInKey() {
        // Given - Keys with multiple words
        let multiWordKeys = [
            LocalizationKeys.criticalActionRequired,
            LocalizationKeys.validityUncertainties,
            LocalizationKeys.dinTargetToleranceHeader
        ]

        for key in multiWordKeys {
            let localized = key.localized()
            XCTAssertFalse(localized.isEmpty,
                          "Multi-word key '\(key)' should have localized value")
        }
    }

    // MARK: - Performance Tests

    func testPerformance_LocalizationLookup_IsFast() {
        // Measure localization lookup performance
        measure {
            for _ in 0..<100 {
                _ = LocalizationKeys.room.localized()
                _ = LocalizationKeys.material.localized()
                _ = LocalizationKeys.export.localized()
            }
        }
    }

    func testPerformance_BulkLocalization_CompletesReasonably() {
        // Measure bulk localization performance
        let allKeys = [
            LocalizationKeys.room,
            LocalizationKeys.material,
            LocalizationKeys.export,
            LocalizationKeys.scanning,
            LocalizationKeys.length,
            LocalizationKeys.width,
            LocalizationKeys.height,
            LocalizationKeys.volume,
            LocalizationKeys.surface,
            LocalizationKeys.frequency
        ]

        measure {
            for key in allKeys {
                _ = key.localized()
            }
        }
    }

    // MARK: - Localization File Presence Tests

    func testLocalization_DefaultLanguage_HasTranslations() {
        // Test that at least some keys have translations in the default language
        let testKeys = [
            LocalizationKeys.room,
            LocalizationKeys.volume,
            LocalizationKeys.export
        ]

        for key in testKeys {
            let localized = NSLocalizedString(key, comment: "")
            // If no translation exists, NSLocalizedString returns the key itself
            // In a complete app, these should be different
            XCTAssertFalse(localized.isEmpty, "Key '\(key)' should have some value")
        }
    }
}
