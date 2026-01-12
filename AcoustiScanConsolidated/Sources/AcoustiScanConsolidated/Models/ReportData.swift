// ReportData.swift
// Data model for comprehensive acoustic analysis reports

import Foundation

/// Comprehensive report data container for acoustic analysis
///
/// This structure contains all data needed for generating PDF and HTML reports
/// of acoustic measurements and DIN 18041 compliance evaluations.
public struct ReportData: Codable, Equatable {

    /// Report generation date in ISO format
    public let date: String

    /// Room classification according to DIN 18041
    public let roomType: RoomType

    /// Room volume in cubic meters
    public let volume: Double

    /// RT60 measurements across frequency bands
    public let rt60Measurements: [RT60Measurement]

    /// DIN 18041 compliance evaluation results
    public let dinResults: [RT60Deviation]

    /// 48-parameter acoustic framework results (parameter name → value)
    public let acousticFrameworkResults: [String: Double]

    /// Room surfaces with acoustic properties
    public let surfaces: [AcousticSurface]

    /// Improvement recommendations
    public let recommendations: [String]

    /// Additional room metadata
    public let metadata: [String: String]

    /// Initialize comprehensive report data
    /// - Parameters:
    ///   - date: Report date in ISO format
    ///   - roomType: Room classification
    ///   - volume: Room volume in cubic meters
    ///   - rt60Measurements: RT60 measurement data
    ///   - dinResults: DIN compliance evaluation
    ///   - acousticFrameworkResults: 48-parameter framework results
    ///   - surfaces: Room surface data
    ///   - recommendations: Improvement recommendations
    ///   - metadata: Additional room information
    public init(date: String, roomType: RoomType, volume: Double,
                rt60Measurements: [RT60Measurement], dinResults: [RT60Deviation],
                acousticFrameworkResults: [String: Double], surfaces: [AcousticSurface],
                recommendations: [String], metadata: [String: String] = [:]) {
        self.date = date
        self.roomType = roomType
        self.volume = volume
        self.rt60Measurements = rt60Measurements
        self.dinResults = dinResults
        self.acousticFrameworkResults = acousticFrameworkResults
        self.surfaces = surfaces
        self.recommendations = recommendations
        self.metadata = metadata
    }

    /// Overall DIN 18041 compliance status
    public var overallCompliance: Bool {
        return dinResults.allSatisfy { $0.status == .withinTolerance }
    }

    /// Count of frequency bands with measurements
    public var frequencyBandCount: Int {
        return rt60Measurements.count
    }

    /// Total room surface area
    public var totalSurfaceArea: Double {
        return surfaces.reduce(0) { $0 + $1.area }
    }

    /// Average RT60 across speech frequencies (500-2000 Hz)
    public var averageSpeechRT60: Double? {
        let speechMeasurements = rt60Measurements.filter { [500, 1000, 2000].contains($0.frequency) }
        guard !speechMeasurements.isEmpty else { return nil }
        return speechMeasurements.reduce(0) { $0 + $1.rt60 } / Double(speechMeasurements.count)
    }
}