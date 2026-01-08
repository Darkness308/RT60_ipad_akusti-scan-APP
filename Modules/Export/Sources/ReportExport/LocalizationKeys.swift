//
//  LocalizationKeys.swift
//  ReportExport
//
//  Type-safe localization keys for the export module
//

import Foundation

/// Type-safe localization keys to prevent typos and ensure consistency
/// Note: This is a shared copy for the Export module to avoid circular dependencies
public enum LocalizationKeys {

    // MARK: - Room & General

    public static let unnamedRoom = "unnamed_room"
    public static let room = "room"
    public static let volume = "volume"
    public static let surfaces = "surfaces"
    public static let surface = "surface"
    public static let date = "date"

    // MARK: - Room Dimensions

    public static let roomDimensions = "room_dimensions"
    public static let roomDimensionsInMeters = "room_dimensions_in_meters"
    public static let length = "length"
    public static let width = "width"
    public static let height = "height"
    public static let totalArea = "total_area"
    public static let roomVolume = "room_volume"

    // MARK: - Material

    public static let newMaterial = "new_material"
    public static let savedMaterials = "saved_materials"
    public static let addButton = "add_button"
    public static let material = "material"
    public static let materialOverview = "material_overview"

    // MARK: - Export

    public static let dataExport = "data_export"
    public static let exportRT60AsPDF = "export_rt60_as_pdf"
    public static let export = "export"
    public static let pdfExport = "pdf_export"
    public static let featureInIntegration = "feature_in_integration"

    // MARK: - Scanning

    public static let scanning = "scanning"
    public static let scanReady = "scan_ready"
    public static let stopScan = "stop_scan"
    public static let startScan = "start_scan"
    public static let lidarScan = "lidar_scan"
    public static let floor = "floor"
    public static let wall = "wall"

    // MARK: - Report

    public static let rt60Report = "rt60_report"
    public static let metadata = "metadata"
    public static let device = "device"
    public static let version = "version"
    public static let currentDevice = "current_device"
    public static let currentVersion = "current_version"
    public static let validity = "validity"
    public static let validityUncertainties = "validity_uncertainties"
    public static let coreTokens = "core_tokens"

    // MARK: - RT60 Measurements

    public static let rt60PerFrequency = "rt60_per_frequency"
    public static let frequencyHz = "frequency_hz"
    public static let t20Seconds = "t20_seconds"
    public static let frequencyHeader = "frequency_header"
    public static let rt60Measurements = "rt60_measurements"
    public static let measured = "measured"
    public static let target = "target"
    public static let status = "status"

    // MARK: - DIN 18041

    public static let dinTargetTolerance = "din_target_tolerance"
    public static let dinTargetToleranceHeader = "din_target_tolerance_header"
    public static let dinClassification = "din_classification"
    public static let dinConformNote = "din_conform_note"
    public static let auditSourceNote = "audit_source_note"
    public static let frequency = "frequency"
    public static let tolerance = "tolerance"

    // MARK: - Status & Classification

    public static let recommendations = "recommendations"
    public static let recommendationsTitle = "recommendations_title"
    public static let recommendationsIntro = "recommendations_intro"
    public static let audit = "audit"
    public static let compliant = "compliant"
    public static let warning = "warning"
    public static let critical = "critical"
    public static let statusOk = "status_ok"
    public static let statusTolerance = "status_tolerance"
    public static let statusCritical = "status_critical"
    public static let criticalActionRequired = "critical_action_required"
    public static let partiallyCompliant = "partially_compliant"
    public static let conformDIN = "conform_din"

    // MARK: - Enhanced PDF Report

    public static let acousticReport = "acoustic_report"
    public static let dinStandard = "din_standard"
    public static let areaSquareMeters = "area_square_meters"

    // MARK: - Errors

    public static let formatError = "format_error"
    public static let checksumInvalid = "checksum_invalid"
}

/// Extension to provide convenient localized string access
public extension String {
    /// Returns the localized string for this key
    /// - Parameter comment: Optional comment to provide context for translators
    /// - Returns: Localized string
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
