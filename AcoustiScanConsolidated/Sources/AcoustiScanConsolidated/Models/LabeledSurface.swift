// LabeledSurface.swift
// Data model for UI-labeled room surfaces (legacy compatibility)

import Foundation

/// UI-labeled room surface with simplified acoustic properties
///
/// This structure represents a room surface with user-friendly labeling
/// and simplified acoustic properties. It's provided for compatibility
/// with earlier app versions that used this model.
///
/// - Note: For new development, prefer `AcousticSurface` which provides
///   more detailed acoustic material properties.
public struct LabeledSurface: Identifiable, Codable, Equatable {

    /// Unique identifier for the surface
    public let id: UUID

    /// User-friendly surface name
    public var name: String

    /// Surface area in square meters
    public var area: Double

    /// Single absorption coefficient (simplified from frequency-dependent)
    public var absorptionCoefficient: Double

    /// Initialize a new labeled surface
    /// - Parameters:
    ///   - name: Surface name
    ///   - area: Surface area in square meters
    ///   - absorptionCoefficient: Single absorption coefficient (0.0-1.0)
    public init(name: String, area: Double, absorptionCoefficient: Double) {
        self.id = UUID()
        self.name = name
        self.area = area
        self.absorptionCoefficient = absorptionCoefficient
    }

    /// Initialize with specific ID (for testing)
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Surface name
    ///   - area: Surface area in square meters
    ///   - absorptionCoefficient: Single absorption coefficient (0.0-1.0)
    public init(id: UUID, name: String, area: Double, absorptionCoefficient: Double) {
        self.id = id
        self.name = name
        self.area = area
        self.absorptionCoefficient = absorptionCoefficient
    }

    /// Calculate absorption area (area × absorption coefficient)
    public var absorptionArea: Double {
        return area * absorptionCoefficient
    }

    /// Convert to full AcousticSurface with material
    /// - Parameter materialName: Name for the created acoustic material
    /// - Returns: AcousticSurface with equivalent properties
    public func toAcousticSurface(materialName: String? = nil) -> AcousticSurface {
        let material = AcousticMaterial(
            name: materialName ?? "Material for \(name)",
            absorptionCoefficients: [
                125: absorptionCoefficient,
                250: absorptionCoefficient,
                500: absorptionCoefficient,
                1000: absorptionCoefficient,
                2000: absorptionCoefficient,
                4000: absorptionCoefficient
            ]
        )

        return AcousticSurface(
            name: name,
            area: area,
            material: material
        )
    }
}
