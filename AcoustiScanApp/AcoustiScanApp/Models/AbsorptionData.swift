//
//  AbsorptionData.swift
//  AcoustiScanApp
//
//  Model for frequency-dependent absorption coefficients
//

import Foundation

/// Holds absorption coefficients for different frequencies
public struct AbsorptionData: Codable, Equatable {
    /// Absorption values indexed by frequency (Hz)
    public var values: [Int: Float]
    
    /// Initialize with frequency-value pairs
    /// - Parameter values: Dictionary mapping frequency (Hz) to absorption coefficient (0.0-1.0)
    public init(values: [Int: Float]) {
        var sanitizedValues: [Int: Float] = [:]
        for (frequency, coefficient) in values {
            // Clamp coefficient to the valid physical range [0.0, 1.0]
            let clamped = max(0.0, min(1.0, coefficient))
            sanitizedValues[frequency] = clamped
        }
        self.values = sanitizedValues
    }
    
    /// Get absorption coefficient for a specific frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Absorption coefficient or 0.0 if not found (default)
    public func coefficient(at frequency: Int) -> Float {
        return values[frequency] ?? 0.0
    }
    
    /// Standard octave band frequencies used in acoustic measurements
    public static let standardFrequencies = [125, 250, 500, 1000, 2000, 4000]
    
    /// Check if all standard frequencies have data
    public var isComplete: Bool {
        return Self.standardFrequencies.allSatisfy { values[$0] != nil }
    }
}
