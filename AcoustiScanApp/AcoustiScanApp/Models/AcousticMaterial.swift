//
//  AcousticMaterial.swift
//  AcoustiScanApp
//
//  Acoustic material model compatible with both app and package
//

import Foundation

/// Acoustic material with frequency-dependent absorption coefficients
public struct AcousticMaterial: Identifiable, Codable, Equatable {

    /// Unique identifier
    public let id: UUID

    /// Material name
    public var name: String

    /// Absorption data
    public var absorption: AbsorptionData

    /// Initialize a new acoustic material
    /// - Parameters:
    ///   - id: Unique identifier (generates new UUID if not provided)
    ///   - name: Material name
    ///   - absorption: Absorption data for different frequencies
    public init(id: UUID = UUID(), name: String, absorption: AbsorptionData) {
        self.id = id
        self.name = name
        self.absorption = absorption
    }

    /// Get absorption coefficient for a specific frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Absorption coefficient (0.0-1.0)
    public func absorptionCoefficient(at frequency: Int) -> Float {
        return absorption.coefficient(at: frequency)
    }

    /// Check if material has complete absorption data
    public var hasCompleteData: Bool {
        return absorption.isComplete
    }
}
