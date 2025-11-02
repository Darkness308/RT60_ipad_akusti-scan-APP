// RT60Deviation.swift
// Data model for DIN 18041 compliance evaluation

import Foundation

/// DIN 18041 compliance evaluation
public struct RT60Deviation: Codable, Equatable {
    public let frequency: Int
    public let measuredRT60: Double
    public let targetRT60: Double
    public let status: EvaluationStatus
    
    public var deviation: Double {
        return measuredRT60 - targetRT60
    }
    
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
    public init(frequency: Int, measuredRT60: Double, targetRT60: Double, status: EvaluationStatus) {
        self.frequency = frequency
        self.measuredRT60 = measuredRT60
        self.targetRT60 = targetRT60
        self.status = status
    }
}