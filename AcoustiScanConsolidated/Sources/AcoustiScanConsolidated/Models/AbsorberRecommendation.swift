// AbsorberRecommendation.swift
// Data model for absorber product recommendations

import Foundation

/// Acoustic absorber product recommendation for room improvement
///
/// This structure represents a specific recommendation for acoustic treatment,
/// combining a product with the calculated area needed and associated costs.
public struct AbsorberRecommendation: Codable, Equatable {

    /// Frequency band this recommendation targets (Hz)
    public let frequency: Int

    /// Recommended absorber product
    public let product: AbsorberProduct

    /// Required area of this product in square meters
    public let areaNeeded: Double

    /// Total cost for the recommended area in euros
    public let totalCost: Double

    /// Expected absorption improvement in Sabine units
    public let expectedAbsorption: Double

    /// Recommendation priority based on acoustic analysis
    public let priority: Priority

    /// Priority classification for recommendations
    public enum Priority: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"

        public var displayName: String {
            switch self {
            case .low: return "Niedrig"
            case .medium: return "Mittel"
            case .high: return "Hoch"
            case .critical: return "Kritisch"
            }
        }
    }

    /// Initialize a new absorber recommendation
    /// - Parameters:
    ///   - frequency: Target frequency band in Hz
    ///   - product: Recommended absorber product
    ///   - areaNeeded: Required area in square meters
    ///   - totalCost: Total cost in euros
    ///   - expectedAbsorption: Expected absorption improvement
    ///   - priority: Recommendation priority
    public init(frequency: Int, product: AbsorberProduct, areaNeeded: Double,
                totalCost: Double, expectedAbsorption: Double, priority: Priority) {
        self.frequency = frequency
        self.product = product
        self.areaNeeded = areaNeeded
        self.totalCost = totalCost
        self.expectedAbsorption = expectedAbsorption
        self.priority = priority
    }

    /// Convenience initializer that calculates total cost automatically
    /// - Parameters:
    ///   - frequency: Target frequency band in Hz
    ///   - product: Recommended absorber product
    ///   - areaNeeded: Required area in square meters
    ///   - expectedAbsorption: Expected absorption improvement
    ///   - priority: Recommendation priority
    public init(frequency: Int, product: AbsorberProduct, areaNeeded: Double,
                expectedAbsorption: Double, priority: Priority) {
        self.frequency = frequency
        self.product = product
        self.areaNeeded = areaNeeded
        self.totalCost = product.totalCost(for: areaNeeded)
        self.expectedAbsorption = expectedAbsorption
        self.priority = priority
    }

    /// Cost per unit of absorption improvement (EUR/Sabine)
    public var costEffectiveness: Double {
        guard expectedAbsorption > 0 else { return Double.infinity }
        return totalCost / expectedAbsorption
    }
}
