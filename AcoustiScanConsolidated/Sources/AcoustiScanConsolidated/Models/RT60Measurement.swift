// RT60Measurement.swift
// Room acoustics measurement data structure

import Foundation

/// Room acoustics measurement data structure
public struct RT60Measurement {
    public let frequency: Int
    public let rt60: Double
    public let timestamp: Date
    
    public init(frequency: Int, rt60: Double, timestamp: Date = Date()) {
        self.frequency = frequency
        self.rt60 = rt60
        self.timestamp = timestamp
    }
}