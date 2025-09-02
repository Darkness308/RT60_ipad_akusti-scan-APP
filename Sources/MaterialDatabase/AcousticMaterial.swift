
import Foundation

public struct AcousticMaterial: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var coefficients: [Int: Double]
    public var absorption: AbsorptionData

    public init(id: UUID = UUID(), name: String, coefficients: [Int: Double], absorption: AbsorptionData) {
        self.id = id
        self.name = name
        self.coefficients = coefficients
        self.absorption = absorption
    }
    
    /// Get absorption coefficient for specific frequency
    public func absorptionCoefficient(at frequency: Int) -> Double {
        return coefficients[frequency] ?? 0.1
    }
}
