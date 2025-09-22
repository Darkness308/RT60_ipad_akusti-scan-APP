// RT60Deviation.swift
// DIN 18041 compliance evaluation

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
    
    public init(frequency: Int, measuredRT60: Double, targetRT60: Double, status: EvaluationStatus) {
        self.frequency = frequency
        self.measuredRT60 = measuredRT60
        self.targetRT60 = targetRT60
        self.status = status
    }
}