// RT60Deviation.swift
copilot/fix-aa461d06-db9a-46a8-a69e-81cd537f46e8
// Data model for DIN 18041 compliance evaluation

import Foundation

/// DIN 18041 compliance evaluation result for a specific frequency band
///
/// This structure represents the evaluation of measured RT60 values against
/// DIN 18041 standard targets, including the deviation and compliance status.
public struct RT60Deviation: Codable, Equatable {
    
    /// Frequency band in Hz
    public let frequency: Int
    
    /// Measured RT60 value in seconds
    public let measuredRT60: Double
    
    /// Target RT60 value according to DIN 18041 in seconds
    public let targetRT60: Double
    
    /// Compliance status relative to tolerance range
    public let status: EvaluationStatus
    
    /// Calculated deviation from target (measured - target)

// DIN 18041 compliance evaluation

import Foundation

/// DIN 18041 compliance evaluation
public struct RT60Deviation {
    public let frequency: Int
    public let measuredRT60: Double
    public let targetRT60: Double
    public let status: EvaluationStatus
    
main
    public var deviation: Double {
        return measuredRT60 - targetRT60
    }
    
copilot/fix-aa461d06-db9a-46a8-a69e-81cd537f46e8
    /// Relative deviation as percentage
    public var relativeDeviation: Double {
        guard targetRT60 > 0 else { return 0 }
        return (deviation / targetRT60) * 100
    }
    
    /// Initialize a new RT60 deviation analysis
    /// - Parameters:
    ///   - frequency: Frequency band in Hz
    ///   - measuredRT60: Measured RT60 value in seconds
    ///   - targetRT60: Target RT60 value according to DIN 18041
    ///   - status: Compliance status

main
    public init(frequency: Int, measuredRT60: Double, targetRT60: Double, status: EvaluationStatus) {
        self.frequency = frequency
        self.measuredRT60 = measuredRT60
        self.targetRT60 = targetRT60
        self.status = status
    }
}