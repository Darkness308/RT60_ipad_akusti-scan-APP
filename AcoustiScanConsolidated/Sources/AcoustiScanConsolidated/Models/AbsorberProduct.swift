// AbsorberProduct.swift
// Data model for commercial absorber products

import Foundation

/// Commercial acoustic absorber product for recommendations
///
/// This structure represents a commercial acoustic product that can be
/// recommended for improving room acoustics, with cost and performance data.
public struct AbsorberProduct: Codable, Equatable {
    
    /// Product name (e.g., "Akustikschaumplatten", "Glasfaserplatten")
    public let name: String
    
    /// Primary frequency band where the product is most effective (Hz)
    public let frequencyBand: Int
    
    /// Absorption coefficient at the primary frequency band
    public let absorptionCoefficient: Double
    
    /// Cost per square meter in euros
    public let pricePerSquareMeter: Double
    
    /// Product category for grouping
    public let category: ProductCategory
    
    /// Thickness in millimeters (if applicable)
    public let thickness: Double?
    
    /// Manufacturer or supplier name
    public let manufacturer: String?
    
    /// Product category classification
    public enum ProductCategory: String, CaseIterable, Codable {
        case foam = "foam"
        case fabric = "fabric"
        case wood = "wood"
        case mineral = "mineral"
        case perforated = "perforated"
        case other = "other"
        
        public var displayName: String {
            switch self {
            case .foam: return "Schaumstoff"
            case .fabric: return "Textil"
            case .wood: return "Holz"
            case .mineral: return "Mineralfaser"
            case .perforated: return "Perforiert"
            case .other: return "Sonstige"
            }
        }
    }
    
    /// Initialize a new absorber product
    /// - Parameters:
    ///   - name: Product name
    ///   - frequencyBand: Primary effective frequency in Hz
    ///   - absorptionCoefficient: Absorption coefficient (0.0-1.0)
    ///   - pricePerSquareMeter: Cost per square meter in euros
    ///   - category: Product category
    ///   - thickness: Product thickness in mm (optional)
    ///   - manufacturer: Manufacturer name (optional)
    public init(name: String, frequencyBand: Int, absorptionCoefficient: Double,
                pricePerSquareMeter: Double, category: ProductCategory = .other,
                thickness: Double? = nil, manufacturer: String? = nil) {
        self.name = name
        self.frequencyBand = frequencyBand
        self.absorptionCoefficient = absorptionCoefficient
        self.pricePerSquareMeter = pricePerSquareMeter
        self.category = category
        self.thickness = thickness
        self.manufacturer = manufacturer
    }
    
    /// Calculate cost for a given area
    /// - Parameter area: Required area in square meters
    /// - Returns: Total cost in euros
    public func totalCost(for area: Double) -> Double {
        return area * pricePerSquareMeter
    }
    
    /// Performance-to-cost ratio (absorption coefficient per euro per m²)
    public var costEfficiency: Double {
        guard pricePerSquareMeter > 0 else { return 0 }
        return absorptionCoefficient / pricePerSquareMeter
    }
}
