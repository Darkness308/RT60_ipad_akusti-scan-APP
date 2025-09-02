// RT60Measurement.swift
// RT60 measurement data structure

import Foundation

/// RT60-Messwert für eine bestimmte Frequenz
public struct RT60Measurement {
    public let frequency: Int        // Frequenz in Hz
    public let rt60: Double         // RT60-Wert in Sekunden
    public let confidence: Double   // Vertrauensbereich (0.0 - 1.0)
    
    public init(frequency: Int, rt60: Double, confidence: Double = 1.0) {
        self.frequency = frequency
        self.rt60 = rt60
        self.confidence = confidence
    }
}

extension RT60Measurement: Equatable {
    public static func == (lhs: RT60Measurement, rhs: RT60Measurement) -> Bool {
        return lhs.frequency == rhs.frequency &&
               abs(lhs.rt60 - rhs.rt60) < 0.001 &&
               abs(lhs.confidence - rhs.confidence) < 0.001
    }
}

extension RT60Measurement: Comparable {
    public static func < (lhs: RT60Measurement, rhs: RT60Measurement) -> Bool {
        return lhs.frequency < rhs.frequency
    }
}

extension RT60Measurement: CustomStringConvertible {
    public var description: String {
        return "\(frequency) Hz: RT60 = \(String(format: "%.2f", rt60))s"
    }
}