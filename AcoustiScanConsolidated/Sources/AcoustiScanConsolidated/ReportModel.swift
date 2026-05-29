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
    public let sourceOrigin: String

    public init(
        metadata: [String: String],
        rt60_bands: [[String: Double?]],
        din_targets: [[String: Double]],
        validity: [String: String],
        recommendations: [String],
        audit: [String: String],
        sourceOrigin: String = "unknown"
    ) {
        self.metadata = metadata
        self.rt60_bands = rt60_bands
        self.din_targets = din_targets
        self.validity = validity
        self.recommendations = recommendations
        self.audit = audit
        self.sourceOrigin = sourceOrigin
    }

    enum CodingKeys: String, CodingKey {
        case metadata
        case rt60_bands
        case din_targets
        case validity
        case recommendations
        case audit
        case sourceOrigin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode([String: String].self, forKey: .metadata)
        self.rt60_bands = try container.decode([[String: Double?]].self, forKey: .rt60_bands)
        self.din_targets = try container.decode([[String: Double]].self, forKey: .din_targets)
        self.validity = try container.decode([String: String].self, forKey: .validity)
        self.recommendations = try container.decode([String].self, forKey: .recommendations)
        self.audit = try container.decode([String: String].self, forKey: .audit)
        self.sourceOrigin = try container.decodeIfPresent(String.self, forKey: .sourceOrigin) ?? "unknown"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(rt60_bands, forKey: .rt60_bands)
        try container.encode(din_targets, forKey: .din_targets)
        try container.encode(validity, forKey: .validity)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(audit, forKey: .audit)
        try container.encode(sourceOrigin, forKey: .sourceOrigin)
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
            audit: audit,
            sourceOrigin: "report-data:\(reportData.date)"
        )
    }
}
