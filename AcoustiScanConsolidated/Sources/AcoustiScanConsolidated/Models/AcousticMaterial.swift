// AcousticMaterial.swift
// Acoustic material with frequency-dependent absorption coefficients

import Foundation

/// Acoustic material with frequency-dependent absorption coefficients
public struct AcousticMaterial {
    public let name: String
    public let absorptionCoefficients: [Int: Double] // frequency -> coefficient
    
    public init(name: String, absorptionCoefficients: [Int: Double]) {
        self.name = name
        self.absorptionCoefficients = absorptionCoefficients
    }
    
    public func absorptionCoefficient(at frequency: Int) -> Double {
        return absorptionCoefficients[frequency] ?? 0.1 // Default value
    }
}