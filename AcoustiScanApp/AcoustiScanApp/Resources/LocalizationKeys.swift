//
//  LocalizationKeys.swift
//  AcoustiScanApp
//
//  Type-safe localization keys for the application
//

import Foundation

/// Type-safe localization keys to prevent typos and ensure consistency
enum LocalizationKeys {

    // MARK: - Room & General

    static let unnamedRoom = "unnamed_room"
    static let room = "room"
    static let volume = "volume"
    static let surfaces = "surfaces"
    static let surface = "surface"
    static let date = "date"

    // MARK: - Room Dimensions

    static let roomDimensions = "room_dimensions"
    static let roomDimensionsInMeters = "room_dimensions_in_meters"
    static let length = "length"
    static let width = "width"
    static let height = "height"
    static let totalArea = "total_area"
    static let roomVolume = "room_volume"

    // MARK: - Material

    static let newMaterial = "new_material"
    static let savedMaterials = "saved_materials"
    static let addButton = "add_button"
    static let material = "material"
    static let materialOverview = "material_overview"

    // MARK: - Export

    static let dataExport = "data_export"
    static let exportRT60AsPDF = "export_rt60_as_pdf"
    static let export = "export"
    static let pdfExport = "pdf_export"
    static let featureInIntegration = "feature_in_integration"

    // MARK: - Scanning

    static let scanning = "scanning"
    static let scanReady = "scan_ready"
    static let stopScan = "stop_scan"
    static let startScan = "start_scan"
    static let lidarScan = "lidar_scan"
    static let floor = "floor"
    static let wall = "wall"

    // MARK: - Report

    static let rt60Report = "rt60_report"
    static let metadata = "metadata"
    static let device = "device"
    static let version = "version"
    static let currentDevice = "current_device"
    static let currentVersion = "current_version"
    static let validity = "validity"
    static let validityUncertainties = "validity_uncertainties"
    static let coreTokens = "core_tokens"

    // MARK: - RT60 Measurements

    static let rt60PerFrequency = "rt60_per_frequency"
    static let frequencyHz = "frequency_hz"
    static let t20Seconds = "t20_seconds"
    static let frequencyHeader = "frequency_header"
    static let rt60Measurements = "rt60_measurements"
    static let measured = "measured"
    static let target = "target"
    static let status = "status"

    // MARK: - DIN 18041

    static let dinTargetTolerance = "din_target_tolerance"
    static let dinTargetToleranceHeader = "din_target_tolerance_header"
    static let dinClassification = "din_classification"
    static let dinConformNote = "din_conform_note"
    static let auditSourceNote = "audit_source_note"
    static let frequency = "frequency"
    static let tolerance = "tolerance"

    // MARK: - Status & Classification

    static let recommendations = "recommendations"
    static let recommendationsTitle = "recommendations_title"
    static let recommendationsIntro = "recommendations_intro"
    static let audit = "audit"
    static let compliant = "compliant"
    static let warning = "warning"
    static let critical = "critical"
    static let statusOk = "status_ok"
    static let statusTolerance = "status_tolerance"
    static let statusCritical = "status_critical"
    static let criticalActionRequired = "critical_action_required"
    static let partiallyCompliant = "partially_compliant"
    static let conformDIN = "conform_din"
    static let results = "results"
    static let noDataAvailable = "no_data_available"
    static let scanRoomToSeeResults = "scan_room_to_see_results"
    static let classificationResultsPlaceholder = "classification_results_placeholder"

    // MARK: - Enhanced PDF Report

    static let acousticReport = "acoustic_report"
    static let dinStandard = "din_standard"
    static let areaSquareMeters = "area_square_meters"

    // MARK: - Errors

    static let formatError = "format_error"
    static let checksumInvalid = "checksum_invalid"
}

/// Extension to provide convenient localized string access
extension String {
    /// Returns the localized string for this key
    /// - Parameter comment: Optional comment to provide context for translators
    /// - Returns: Localized string
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
