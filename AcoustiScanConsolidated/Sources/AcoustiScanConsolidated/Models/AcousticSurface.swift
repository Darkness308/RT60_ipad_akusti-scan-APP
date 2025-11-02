// AcousticSurface.swift
// Data model for room surfaces with acoustic properties

import Foundation

/// Acoustic surface representation
public struct AcousticSurface: Codable, Equatable {
    public let name: String
    public let area: Double
    public let material: AcousticMaterial
    
    public init(name: String, area: Double, material: AcousticMaterial) {
        self.name = name
        self.area = area
        self.material = material
    }
    
    /// Calculate absorption area for a specific frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Absorption area in square meters (area × absorption coefficient)
    public func absorptionArea(at frequency: Int) -> Double {
        return area * material.absorptionCoefficient(at: frequency)
    }
    
    /// Total absorption area across all standard frequencies
    public var totalAbsorptionAreas: [Int: Double] {
        let standardFrequencies = [125, 250, 500, 1000, 2000, 4000]
        var result: [Int: Double] = [:]
        for frequency in standardFrequencies {
            result[frequency] = absorptionArea(at: frequency)
        }
        return result
    }
    
    /// Average absorption coefficient of the material
    public var averageAbsorption: Double {
        return material.speechAbsorption
    }
}