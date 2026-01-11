// ReportModel.swift
// JSON-serializable report model for contract tests and HTML export

import Foundation

/// JSON-serializable report model matching the schema requirements
public struct ReportModel: Codable {
    public let metadata: [String: String]
    public let rt60_bands: [[String: Double?]]
    public let din_targets: [[String: Double]]
    public let validity: [String: String]
    public let recommendations: [String]
    public let audit: [String: String]

    public init(
        metadata: [String: String],
        rt60_bands: [[String: Double?]],
        din_targets: [[String: Double]],
        validity: [String: String],
        recommendations: [String],
        audit: [String: String]
    ) {
        self.metadata = metadata
        self.rt60_bands = rt60_bands
        self.din_targets = din_targets
        self.validity = validity
        self.recommendations = recommendations
        self.audit = audit
    }
}

/// Extension to convert between existing ReportData and new ReportModel
extension ReportModel {

    /// Create ReportModel from existing ReportData
    /// - Parameter reportData: Source report data with measurements and evaluation results
    /// - Returns: ReportModel suitable for PDF/HTML rendering
    public static func from(_ reportData: ReportData) -> ReportModel {
        let metadata = [
            "device": "iPadPro",
            "app_version": "1.0.0",
            "date": reportData.date,
            "room": reportData.roomType.displayName
        ]

        let rt60_bands = reportData.rt60Measurements.map { measurement in
            [
                "freq_hz": Double(measurement.frequency),
                "t20_s": measurement.rt60
            ]
        }

        // Get actual DIN 18041 targets with correct tolerance values from database
        let dinTargets = DIN18041Database.targets(for: reportData.roomType, volume: reportData.volume)

        let din_targets = reportData.dinResults.map { deviation -> [String: Double] in
            // Look up the actual tolerance from DIN database for this frequency
            let actualTolerance = dinTargets
                .first { $0.frequency == deviation.frequency }?
                .tolerance ?? 0.1 // Fallback to 0.1s if not found

            return [
                "freq_hz": Double(deviation.frequency),
                "t_soll": deviation.targetRT60,
                "tol": actualTolerance  // Use actual DIN tolerance, not deviation
            ]
        }

        let validity = [
            "method": "ISO3382-1",
            "bands": "octave"
        ]

        let audit = [
            "hash": "DEMO\(abs(reportData.date.hashValue))",
            "source": "consolidated"
        ]

        return ReportModel(
            metadata: metadata,
            rt60_bands: rt60_bands,
            din_targets: din_targets,
            validity: validity,
            recommendations: reportData.recommendations,
            audit: audit
        )
    }
}
