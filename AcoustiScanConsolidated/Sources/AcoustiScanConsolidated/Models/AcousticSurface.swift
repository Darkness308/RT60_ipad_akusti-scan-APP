// AcousticSurface.swift

// Data model for room surfaces with acoustic properties

import Foundation

/// Room surface with area and associated acoustic material
///
/// This structure represents a room surface (wall, ceiling, floor) with its
/// geometric properties and acoustic material assignment for RT60 calculations.
public struct AcousticSurface: Codable, Equatable {
    
    /// Surface name (e.g., "Decke", "Nordwand", "Boden")
    public let name: String
    
    /// Surface area in square meters
    public let area: Double
    
    /// Associated acoustic material with absorption properties
    public let material: AcousticMaterial
    
    /// Initialize a new acoustic surface
    /// - Parameters:
    ///   - name: Surface name
    ///   - area: Surface area in square meters
    ///   - material: Associated acoustic material

// Acoustic surface representation

import Foundation

/// Acoustic surface representation
public struct AcousticSurface {
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