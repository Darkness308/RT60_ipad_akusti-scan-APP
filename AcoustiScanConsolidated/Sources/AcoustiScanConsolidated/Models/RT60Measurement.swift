// RT60Measurement.swift
copilot/fix-aa461d06-db9a-46a8-a69e-81cd537f46e8
// Data model for room acoustics measurement data

import Foundation

/// Room acoustics measurement data structure for RT60 analysis
///
/// This structure represents a single RT60 measurement at a specific frequency band.
/// RT60 is the time required for sound to decay 60 decibels after the source has stopped,
/// which is a key parameter in room acoustics analysis according to ISO 3382-1.
public struct RT60Measurement: Codable, Equatable {
    
    /// Frequency band in Hz (typically octave bands: 125, 250, 500, 1000, 2000, 4000)
    public let frequency: Int
    
    /// Measured RT60 value in seconds
    public let rt60: Double
    
    /// Timestamp when the measurement was taken
    public let timestamp: Date
    
    /// Initialize a new RT60 measurement
    /// - Parameters:
    ///   - frequency: Frequency band in Hz
    ///   - rt60: RT60 value in seconds
    ///   - timestamp: Measurement timestamp (defaults to current time)

// Room acoustics measurement data structure

import Foundation

/// Room acoustics measurement data structure
public struct RT60Measurement {
    public let frequency: Int
    public let rt60: Double
    public let timestamp: Date
    
main
    public init(frequency: Int, rt60: Double, timestamp: Date = Date()) {
        self.frequency = frequency
        self.rt60 = rt60
        self.timestamp = timestamp
    }
}