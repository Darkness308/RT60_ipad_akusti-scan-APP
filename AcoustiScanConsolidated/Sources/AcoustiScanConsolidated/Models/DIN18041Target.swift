// DIN18041Target.swift
// DIN 18041 target specification

import Foundation

/// DIN 18041 target specification
public struct DIN18041Target {
    public let frequency: Int
    public let targetRT60: Double
    public let tolerance: Double
    
    public init(frequency: Int, targetRT60: Double, tolerance: Double) {
        self.frequency = frequency
        self.targetRT60 = targetRT60
        self.tolerance = tolerance
    }
}