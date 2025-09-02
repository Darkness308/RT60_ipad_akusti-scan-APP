
import Foundation

/// Labeled surface for acoustic measurements
public struct LabeledSurface: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var area: Double
    public var absorptionCoefficient: Double
    public var colorComponents: [Double] // [red, green, blue, alpha] for cross-platform compatibility
    
    /// Calculated absorption area
    public var absorptionArea: Double {
        return area * absorptionCoefficient
    }

    public init(name: String, area: Double, absorptionCoefficient: Double, colorComponents: [Double] = [0.5, 0.5, 0.5, 1.0]) {
        self.id = UUID()
        self.name = name
        self.area = area
        self.absorptionCoefficient = absorptionCoefficient
        self.colorComponents = colorComponents
    }
}
