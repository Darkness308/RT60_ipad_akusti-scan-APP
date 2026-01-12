// MeasurementQuality.swift
// Framework for legally defensible (gerichtsfest) acoustic measurements
// Implements ISO 3382-1 and DIN 18041 compliance tracking

import Foundation

// MARK: - Measurement Quality

/// Quality metrics for an RT60 measurement according to ISO 3382-1
public struct MeasurementQuality: Codable, Equatable {

    /// Correlation coefficient (r²) of the decay curve fit
    /// ISO 3382-1 requires r² >= 0.95 for valid measurements
    public let correlationCoefficient: Double

    /// Standard uncertainty of the RT60 value in seconds
    /// Calculated from the linear regression of the decay curve
    public let uncertainty: Double

    /// Signal-to-noise ratio in dB
    /// ISO 3382-1 requires SNR >= 35 dB for T20, >= 45 dB for T30
    public let signalToNoiseRatio: Double

    /// Dynamic range of the decay curve in dB
    /// Minimum 20 dB for T20, 30 dB for T30, 60 dB for T60
    public let dynamicRange: Double

    /// Number of valid measurement positions averaged
    public let positionCount: Int

    /// Evaluation range used (T20, T30, or T60)
    public let evaluationRange: EvaluationRange

    /// Whether the measurement meets ISO 3382-1 criteria
    public var isISOCompliant: Bool {
        return correlationCoefficient >= 0.95 &&
               signalToNoiseRatio >= evaluationRange.minimumSNR &&
               dynamicRange >= evaluationRange.minimumDynamicRange
    }

    /// Quality classification based on measurement metrics
    public var qualityClass: QualityClass {
        if correlationCoefficient >= 0.99 &&
           signalToNoiseRatio >= 50 &&
           positionCount >= 3 {
            return .excellent
        } else if isISOCompliant {
            return .good
        } else if correlationCoefficient >= 0.90 {
            return .acceptable
        } else {
            return .poor
        }
    }

    /// Expanded uncertainty at 95% confidence level (k=2)
    public var expandedUncertainty: Double {
        return uncertainty * 2.0
    }

    /// Initialize measurement quality metrics
    public init(
        correlationCoefficient: Double,
        uncertainty: Double,
        signalToNoiseRatio: Double,
        dynamicRange: Double,
        positionCount: Int = 1,
        evaluationRange: EvaluationRange = .t20
    ) {
        self.correlationCoefficient = correlationCoefficient
        self.uncertainty = uncertainty
        self.signalToNoiseRatio = signalToNoiseRatio
        self.dynamicRange = dynamicRange
        self.positionCount = positionCount
        self.evaluationRange = evaluationRange
    }

    /// Create default quality metrics for calculated (not measured) values
    public static var calculated: MeasurementQuality {
        return MeasurementQuality(
            correlationCoefficient: 1.0,
            uncertainty: 0.0,
            signalToNoiseRatio: .infinity,
            dynamicRange: 60.0,
            positionCount: 0,
            evaluationRange: .calculated
        )
    }
}

// MARK: - Evaluation Range

/// Evaluation range for RT60 measurement according to ISO 3382-1
public enum EvaluationRange: String, Codable, CaseIterable {
    /// T20: Decay from -5 dB to -25 dB (extrapolated to 60 dB)
    case t20 = "T20"

    /// T30: Decay from -5 dB to -35 dB (extrapolated to 60 dB)
    case t30 = "T30"

    /// T60: Full 60 dB decay (rarely achievable in practice)
    case t60 = "T60"

    /// Calculated value (not directly measured)
    case calculated = "Calculated"

    /// Minimum required dynamic range in dB
    public var minimumDynamicRange: Double {
        switch self {
        case .t20: return 20.0
        case .t30: return 30.0
        case .t60: return 60.0
        case .calculated: return 0.0
        }
    }

    /// Minimum required signal-to-noise ratio in dB
    public var minimumSNR: Double {
        switch self {
        case .t20: return 35.0
        case .t30: return 45.0
        case .t60: return 65.0
        case .calculated: return 0.0
        }
    }
}

// MARK: - Quality Class

/// Quality classification for measurement validity
public enum QualityClass: String, Codable, CaseIterable {
    /// Excellent: Exceeds ISO requirements, suitable for legal/regulatory use
    case excellent = "Excellent"

    /// Good: Meets ISO 3382-1 requirements
    case good = "Good"

    /// Acceptable: Below ISO standard but usable for estimates
    case acceptable = "Acceptable"

    /// Poor: Does not meet minimum quality standards
    case poor = "Poor"

    /// Human-readable description
    public var description: String {
        switch self {
        case .excellent:
            return "Gerichtsfest - Exceeds ISO 3382-1 requirements"
        case .good:
            return "ISO-compliant measurement"
        case .acceptable:
            return "Acceptable for estimation purposes"
        case .poor:
            return "Below minimum quality standards"
        }
    }

    /// Whether this class is suitable for legal/regulatory purposes
    public var isLegallyDefensible: Bool {
        return self == .excellent || self == .good
    }
}

// MARK: - Calibration Record

/// Microphone calibration record for traceability
public struct CalibrationRecord: Codable, Equatable {

    /// Unique identifier for this calibration
    public let id: UUID

    /// Date when calibration was performed
    public let calibrationDate: Date

    /// Date when calibration expires
    public let expirationDate: Date

    /// Calibration certificate number (if available)
    public let certificateNumber: String?

    /// Calibrating laboratory or entity
    public let calibratedBy: String

    /// Microphone model/serial number
    public let microphoneIdentifier: String

    /// Sensitivity in mV/Pa at 1 kHz
    public let sensitivity: Double

    /// Frequency response correction factors (frequency -> dB correction)
    public let frequencyCorrections: [Int: Double]

    /// Whether calibration is still valid
    public var isValid: Bool {
        return Date() < expirationDate
    }

    /// Days until calibration expires
    public var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day ?? 0
    }

    /// Initialize a calibration record
    public init(
        id: UUID = UUID(),
        calibrationDate: Date,
        validityPeriod: TimeInterval = 365 * 24 * 60 * 60, // 1 year default
        certificateNumber: String? = nil,
        calibratedBy: String,
        microphoneIdentifier: String,
        sensitivity: Double,
        frequencyCorrections: [Int: Double] = [:]
    ) {
        self.id = id
        self.calibrationDate = calibrationDate
        self.expirationDate = calibrationDate.addingTimeInterval(validityPeriod)
        self.certificateNumber = certificateNumber
        self.calibratedBy = calibratedBy
        self.microphoneIdentifier = microphoneIdentifier
        self.sensitivity = sensitivity
        self.frequencyCorrections = frequencyCorrections
    }

    /// Create a record for the built-in iPad microphone (uncalibrated)
    public static var builtInMicrophone: CalibrationRecord {
        return CalibrationRecord(
            calibrationDate: Date(),
            validityPeriod: 0, // Already expired - indicates uncalibrated
            certificateNumber: nil,
            calibratedBy: "Factory Default",
            microphoneIdentifier: "iPad Built-in Microphone",
            sensitivity: 1.0,
            frequencyCorrections: [:]
        )
    }
}

// MARK: - Extended RT60 Measurement

/// Extended RT60 measurement with quality metrics for legal defensibility
public struct RT60MeasurementWithQuality: Codable, Equatable {

    /// Basic measurement data
    public let measurement: RT60Measurement

    /// Quality metrics for this measurement
    public let quality: MeasurementQuality

    /// Calibration record used for this measurement
    public let calibration: CalibrationRecord?

    /// Source position identifier
    public let sourcePosition: String?

    /// Receiver position identifier
    public let receiverPosition: String?

    /// Room temperature during measurement in Celsius
    public let temperature: Double?

    /// Relative humidity during measurement in percent
    public let humidity: Double?

    /// Whether this measurement is suitable for legal/regulatory purposes
    public var isLegallyDefensible: Bool {
        return quality.qualityClass.isLegallyDefensible &&
               (calibration?.isValid ?? false)
    }

    /// RT60 value with uncertainty notation (e.g., "0.82 +/- 0.05 s")
    public var formattedWithUncertainty: String {
        let rt60 = measurement.rt60
        let uncertainty = quality.expandedUncertainty
        return String(format: "%.2f +/- %.2f s (k=2)", rt60, uncertainty)
    }

    /// Initialize extended measurement
    public init(
        measurement: RT60Measurement,
        quality: MeasurementQuality,
        calibration: CalibrationRecord? = nil,
        sourcePosition: String? = nil,
        receiverPosition: String? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil
    ) {
        self.measurement = measurement
        self.quality = quality
        self.calibration = calibration
        self.sourcePosition = sourcePosition
        self.receiverPosition = receiverPosition
        self.temperature = temperature
        self.humidity = humidity
    }

    /// Create from basic measurement with calculated quality
    public static func fromCalculated(
        frequency: Int,
        rt60: Double
    ) -> RT60MeasurementWithQuality {
        return RT60MeasurementWithQuality(
            measurement: RT60Measurement(frequency: frequency, rt60: rt60),
            quality: .calculated,
            calibration: nil
        )
    }
}

// MARK: - Measurement Session

/// Complete measurement session with all data for a room
public struct MeasurementSession: Codable, Identifiable {

    /// Unique session identifier
    public let id: UUID

    /// Session creation date
    public let date: Date

    /// Project or room name
    public let projectName: String

    /// Room description
    public let roomDescription: String?

    /// Room volume in m³
    public let roomVolume: Double

    /// All frequency-band measurements with quality data
    public var measurements: [RT60MeasurementWithQuality]

    /// Calibration record for this session
    public let calibration: CalibrationRecord?

    /// Environmental conditions
    public let temperature: Double?
    public let humidity: Double?

    /// Measurement equipment description
    public let equipment: String?

    /// Operator/technician name
    public let operatorName: String?

    /// Whether all measurements in session are legally defensible
    public var isFullyLegallyDefensible: Bool {
        guard let calibration = calibration, calibration.isValid else {
            return false
        }
        return measurements.allSatisfy { $0.quality.qualityClass.isLegallyDefensible }
    }

    /// Overall quality class for the session
    public var overallQualityClass: QualityClass {
        if measurements.isEmpty { return .poor }

        let classes = measurements.map { $0.quality.qualityClass }

        // Return worst quality class
        if classes.contains(.poor) { return .poor }
        if classes.contains(.acceptable) { return .acceptable }
        if classes.contains(.good) { return .good }
        return .excellent
    }

    /// ISO 3382-1 compliance summary
    public var isoComplianceSummary: String {
        let compliantCount = measurements.filter { $0.quality.isISOCompliant }.count
        let totalCount = measurements.count
        return "\(compliantCount)/\(totalCount) measurements ISO 3382-1 compliant"
    }

    /// Initialize a measurement session
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        projectName: String,
        roomDescription: String? = nil,
        roomVolume: Double,
        measurements: [RT60MeasurementWithQuality] = [],
        calibration: CalibrationRecord? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil,
        equipment: String? = nil,
        operatorName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.projectName = projectName
        self.roomDescription = roomDescription
        self.roomVolume = roomVolume
        self.measurements = measurements
        self.calibration = calibration
        self.temperature = temperature
        self.humidity = humidity
        self.equipment = equipment
        self.operatorName = operatorName
    }
}

// MARK: - Uncertainty Calculator

/// Utility for calculating measurement uncertainties
public struct UncertaintyCalculator {

    /// Calculate Type A uncertainty from repeated measurements
    /// - Parameter values: Array of measured values
    /// - Returns: Standard uncertainty (standard deviation of the mean)
    public static func typeAUncertainty(from values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        let standardDeviation = sqrt(variance)

        // Standard uncertainty of the mean
        return standardDeviation / sqrt(Double(values.count))
    }

    /// Calculate combined uncertainty from multiple sources
    /// - Parameter uncertainties: Array of individual uncertainties
    /// - Returns: Combined standard uncertainty
    public static func combinedUncertainty(from uncertainties: [Double]) -> Double {
        let sumOfSquares = uncertainties.map { $0 * $0 }.reduce(0, +)
        return sqrt(sumOfSquares)
    }

    /// Calculate correlation coefficient (r²) for linear regression
    /// - Parameters:
    ///   - x: Independent variable values (e.g., time)
    ///   - y: Dependent variable values (e.g., sound level in dB)
    /// - Returns: Correlation coefficient r²
    public static func correlationCoefficient(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0.0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map { $0 * $1 }.reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominatorX = n * sumX2 - sumX * sumX
        let denominatorY = n * sumY2 - sumY * sumY

        guard denominatorX > 0, denominatorY > 0 else { return 0.0 }

        let r = numerator / sqrt(denominatorX * denominatorY)
        return r * r // Return r²
    }
}
