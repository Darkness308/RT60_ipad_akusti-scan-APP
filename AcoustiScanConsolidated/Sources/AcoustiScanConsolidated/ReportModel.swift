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
        
        let din_targets = reportData.dinResults.map { deviation in
            [
                "freq_hz": Double(deviation.frequency),
                "t_soll": deviation.targetRT60,
                "tol": abs(deviation.deviation) // Approximate tolerance from deviation
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