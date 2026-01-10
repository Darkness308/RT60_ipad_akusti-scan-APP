// AbsorptionRequirement.swift
// Data model for acoustic absorption requirements

import Foundation

/// Acoustic absorption requirement for room improvement
///
/// This structure represents the calculated absorption requirement
/// for a specific frequency band to achieve target RT60 values.
public struct AbsorptionRequirement: Codable, Equatable {

    /// Frequency band in Hz
    public let frequency: Int

    /// Required additional absorption in square meters (Sabine units)
    public let requiredAbsorption: Double

    /// Current absorption in the room at this frequency
    public let currentAbsorption: Double

    /// Target absorption needed for DIN 18041 compliance
    public let targetAbsorption: Double

    /// Initialize a new absorption requirement
    /// - Parameters:
    ///   - frequency: Frequency band in Hz
    ///   - requiredAbsorption: Additional absorption needed in square meters
    ///   - currentAbsorption: Current room absorption
    ///   - targetAbsorption: Target absorption for compliance
    public init(frequency: Int, requiredAbsorption: Double,
                currentAbsorption: Double = 0, targetAbsorption: Double = 0) {
        self.frequency = frequency
        self.requiredAbsorption = requiredAbsorption
        self.currentAbsorption = currentAbsorption
        self.targetAbsorption = targetAbsorption
    }

    /// Percentage increase in absorption needed
    public var improvementPercentage: Double {
        guard currentAbsorption > 0 else { return 100 }
        return (requiredAbsorption / currentAbsorption) * 100
    }

    /// Priority level based on required absorption amount
    public var priority: Priority {
        if requiredAbsorption <= 5 {
            return .low
        } else if requiredAbsorption <= 15 {
            return .medium
        } else {
            return .high
        }
    }

    /// Priority classification for acoustic improvements
    public enum Priority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"

        public var displayName: String {
            switch self {
            case .low: return "Niedrig"
            case .medium: return "Mittel"
            case .high: return "Hoch"
            }
        }
    }
}