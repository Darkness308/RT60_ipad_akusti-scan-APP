// DIN18041Target.swift
// Data model for DIN 18041 target values

import Foundation

/// DIN 18041 target RT60 with an (asymmetric) tolerance band for one octave.
///
/// The tolerance per DIN 18041:2016-03 Bild 2 is expressed as a ratio of the
/// measured RT60 to the target `T_soll` and is generally asymmetric (e.g.
/// 0.65–1.45 at the band edges), so the acceptable range is stored as explicit
/// lower/upper bounds in seconds rather than a single symmetric tolerance.
public struct DIN18041Target: Codable, Equatable {

    /// Frequency band in Hz
    public let frequency: Int

    /// Mid-band target RT60 value `T_soll` in seconds.
    public let targetRT60: Double

    /// Lower bound of the acceptable RT60 range in seconds.
    public let lowerBound: Double

    /// Upper bound of the acceptable RT60 range in seconds.
    public let upperBound: Double

    /// Initialize with explicit bounds in seconds.
    public init(frequency: Int, targetRT60: Double, lowerBound: Double, upperBound: Double) {
        self.frequency = frequency
        self.targetRT60 = targetRT60
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// Initialize from tolerance ratios (T / T_soll), as given by Bild 2.
    public init(frequency: Int, targetRT60: Double, lowerRatio: Double, upperRatio: Double) {
        self.init(
            frequency: frequency,
            targetRT60: targetRT60,
            lowerBound: targetRT60 * lowerRatio,
            upperBound: targetRT60 * upperRatio
        )
    }

    /// Check if a measured RT60 value is within the tolerance band.
    public func isWithinTolerance(_ measuredRT60: Double) -> Bool {
        return measuredRT60 >= lowerBound && measuredRT60 <= upperBound
    }

    /// Evaluate compliance status for a measured value.
    public func evaluateCompliance(_ measuredRT60: Double) -> EvaluationStatus {
        if measuredRT60 > upperBound {
            return .tooHigh
        } else if measuredRT60 < lowerBound {
            return .tooLow
        } else {
            return .withinTolerance
        }
    }
}
