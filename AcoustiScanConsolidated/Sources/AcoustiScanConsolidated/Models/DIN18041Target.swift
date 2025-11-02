// DIN18041Target.swift
// Data model for DIN 18041 target values

import Foundation

copilot/fix-failing-job-issue
/// DIN 18041 target specification
public struct DIN18041Target: Codable, Equatable {
    public let frequency: Int
    public let targetRT60: Double
    public let tolerance: Double
    

/// DIN 18041 target RT60 value with tolerance for a specific frequency
///
/// This structure represents the target reverberation time and tolerance
/// for a specific frequency band according to DIN 18041 standard.
public struct DIN18041Target: Codable, Equatable {

    /// Frequency band in Hz
    public let frequency: Int

    /// Target RT60 value in seconds according to DIN 18041
    public let targetRT60: Double

    /// Tolerance range in seconds (±tolerance)
    public let tolerance: Double

    /// Initialize a new DIN 18041 target
    /// - Parameters:
    ///   - frequency: Frequency band in Hz
    ///   - targetRT60: Target RT60 value in seconds
    ///   - tolerance: Tolerance range in seconds
main
    public init(frequency: Int, targetRT60: Double, tolerance: Double) {
        self.frequency = frequency
        self.targetRT60 = targetRT60
        self.tolerance = tolerance
    }
copilot/fix-failing-job-issue
    


main
    /// Lower bound of acceptable RT60 range
    public var lowerBound: Double {
        return targetRT60 - tolerance
    }

    /// Upper bound of acceptable RT60 range
    public var upperBound: Double {
        return targetRT60 + tolerance
    }

    /// Check if a measured RT60 value is within tolerance
    /// - Parameter measuredRT60: Measured RT60 value in seconds
    /// - Returns: True if within acceptable range
    public func isWithinTolerance(_ measuredRT60: Double) -> Bool {
        return measuredRT60 >= lowerBound && measuredRT60 <= upperBound
    }

    /// Evaluate compliance status for a measured value
    /// - Parameter measuredRT60: Measured RT60 value in seconds
    /// - Returns: Evaluation status
    public func evaluateCompliance(_ measuredRT60: Double) -> EvaluationStatus {
        if measuredRT60 > upperBound {
            return .tooHigh
        } else if measuredRT60 < lowerBound {
            return .tooLow
        } else {
            return .withinTolerance
        }
    }
copilot/fix-failing-job-issue
}

}
main
