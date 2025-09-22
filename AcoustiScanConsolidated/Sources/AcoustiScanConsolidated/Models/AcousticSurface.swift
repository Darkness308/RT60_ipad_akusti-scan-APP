// AcousticSurface.swift
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
}