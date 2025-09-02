import Foundation

struct MaterialDatabase {
    
    /// Helper function to create AcousticMaterial from frequency dictionary
    private static func createMaterial(name: String, values: [Int: Double]) -> AcousticMaterial {
        return AcousticMaterial(
            name: name,
            coefficients: values,
            absorption: AbsorptionData(values: values)
        )
    }
    
    static let materials: [AcousticMaterial] = [
        createMaterial(name: "Betonwand", values: [
            125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02, 2000: 0.02, 4000: 0.02, 8000: 0.02
        ]),
        createMaterial(name: "Gipskarton", values: [
            125: 0.29, 250: 0.10, 500: 0.05, 1000: 0.04, 2000: 0.07, 4000: 0.09, 8000: 0.12
        ]),
        createMaterial(name: "Holztäfelung", values: [
            125: 0.09, 250: 0.10, 500: 0.11, 1000: 0.08, 2000: 0.08, 4000: 0.11, 8000: 0.10
        ]),
        createMaterial(name: "Teppichboden", values: [
            125: 0.08, 250: 0.24, 500: 0.57, 1000: 0.69, 2000: 0.71, 4000: 0.73, 8000: 0.73
        ]),
        createMaterial(name: "Akustikdecke", values: [
            125: 0.15, 250: 0.70, 500: 0.90, 1000: 0.95, 2000: 0.90, 4000: 0.85, 8000: 0.85
        ]),
        createMaterial(name: "Vorhang", values: [
            125: 0.07, 250: 0.31, 500: 0.49, 1000: 0.75, 2000: 0.70, 4000: 0.60, 8000: 0.60
        ]),
        createMaterial(name: "Glasfenster", values: [
            125: 0.18, 250: 0.06, 500: 0.04, 1000: 0.03, 2000: 0.02, 4000: 0.02, 8000: 0.02
        ]),
        createMaterial(name: "Publikum sitzend", values: [
            125: 0.60, 250: 0.74, 500: 0.88, 1000: 0.96, 2000: 0.93, 4000: 0.85, 8000: 0.85
        ]),
        createMaterial(name: "Schaumstoffabsorber", values: [
            125: 0.11, 250: 0.44, 500: 0.95, 1000: 0.98, 2000: 0.96, 4000: 0.98, 8000: 0.98
        ]),
        createMaterial(name: "Steinwolle", values: [
            125: 0.20, 250: 0.65, 500: 0.90, 1000: 0.95, 2000: 0.98, 4000: 0.95, 8000: 0.95
        ])
    ]

    static func absorption(for materialName: String) -> AbsorptionData? {
        return materials.first(where: { $0.name == materialName })?.absorption
    }
}

public struct AbsorptionData: Codable {
    public let f125: Double
    public let f250: Double
    public let f500: Double
    public let f1000: Double
    public let f2000: Double
    public let f4000: Double
    public let f8000: Double
    
    public init(f125: Double, f250: Double, f500: Double, f1000: Double, f2000: Double, f4000: Double, f8000: Double) {
        self.f125 = f125
        self.f250 = f250
        self.f500 = f500
        self.f1000 = f1000
        self.f2000 = f2000
        self.f4000 = f4000
        self.f8000 = f8000
    }
    
    /// Create from frequency-coefficient dictionary (for compatibility)
    public init(values: [Int: Double]) {
        self.f125 = values[125] ?? 0.1
        self.f250 = values[250] ?? 0.1
        self.f500 = values[500] ?? 0.1
        self.f1000 = values[1000] ?? 0.1
        self.f2000 = values[2000] ?? 0.1
        self.f4000 = values[4000] ?? 0.1
        self.f8000 = values[8000] ?? 0.1
    }
    
    /// Get absorption coefficient for frequency
    public func coefficient(at frequency: Int) -> Double {
        switch frequency {
        case 125: return f125
        case 250: return f250
        case 500: return f500
        case 1000: return f1000
        case 2000: return f2000
        case 4000: return f4000
        case 8000: return f8000
        default: return 0.1
        }
    }
}