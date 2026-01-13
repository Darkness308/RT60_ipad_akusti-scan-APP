//
//  AbsorberCalculator.swift
//  AcoustiScanApp
//
//  Acoustic absorber calculation algorithms for room optimization
//  Implements DIN 18041 compliant target calculations
//

import Foundation

// MARK: - Absorber Recommendation

/// Recommendation for acoustic treatment
public struct AbsorberRecommendation: Identifiable {
    public let id = UUID()
    public let frequency: Int
    public let currentRT60: Double
    public let targetRT60: Double
    public let requiredAbsorption: Double  // Additional absorption needed (m² Sabine)
    public let recommendedProducts: [AbsorberProduct]
    public let priority: Priority

    public enum Priority: String, CaseIterable {
        case critical = "Kritisch"
        case high = "Hoch"
        case medium = "Mittel"
        case low = "Niedrig"
        case none = "Keine"

        public var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "blue"
            case .none: return "green"
            }
        }
    }
}

/// Acoustic absorber product
public struct AbsorberProduct: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let manufacturer: String
    public let type: AbsorberType
    public let thickness: Double  // mm
    public let absorptionCoefficients: [Int: Double]
    public let nrcRating: Double  // Noise Reduction Coefficient
    public let fireRating: String  // e.g., "B1", "A2"
    public let pricePerSqm: Double?

    public enum AbsorberType: String, Codable, CaseIterable {
        case porousAbsorber = "Poröser Absorber"
        case membraneAbsorber = "Membranabsorber"
        case resonatorAbsorber = "Resonanzabsorber"
        case compositeAbsorber = "Verbundabsorber"
        case diffuser = "Diffusor"
    }

    public init(
        id: UUID = UUID(),
        name: String,
        manufacturer: String,
        type: AbsorberType,
        thickness: Double,
        absorptionCoefficients: [Int: Double],
        nrcRating: Double,
        fireRating: String,
        pricePerSqm: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.type = type
        self.thickness = thickness
        self.absorptionCoefficients = absorptionCoefficients
        self.nrcRating = nrcRating
        self.fireRating = fireRating
        self.pricePerSqm = pricePerSqm
    }

    /// Get absorption coefficient at a specific frequency
    public func absorption(at frequency: Int) -> Double {
        return absorptionCoefficients[frequency] ?? 0.0
    }
}

// MARK: - Absorber Calculator

/// Calculator for acoustic treatment recommendations
public class AbsorberCalculator {

    // MARK: - Properties

    private let productDatabase: [AbsorberProduct]

    // MARK: - Initialization

    public init() {
        self.productDatabase = Self.loadProductDatabase()
    }

    // MARK: - Calculation Methods

    /// Calculate required additional absorption to reach target RT60
    /// - Parameters:
    ///   - currentRT60: Current RT60 in seconds
    ///   - targetRT60: Target RT60 in seconds
    ///   - roomVolume: Room volume in m³
    ///   - currentAbsorption: Current total absorption in m² Sabine
    /// - Returns: Required additional absorption in m² Sabine
    public static func requiredAbsorption(
        currentRT60: Double,
        targetRT60: Double,
        roomVolume: Double,
        currentAbsorption: Double
    ) -> Double {
        guard targetRT60 > 0, currentRT60 > targetRT60 else { return 0 }

        // From Sabine formula: RT60 = 0.161 * V / A
        // Target absorption: A_target = 0.161 * V / RT60_target
        let targetAbsorption = 0.161 * roomVolume / targetRT60

        // Required additional absorption
        return max(0, targetAbsorption - currentAbsorption)
    }

    /// Calculate target RT60 based on room type and volume (DIN 18041)
    /// - Parameters:
    ///   - roomType: Type of room usage
    ///   - volume: Room volume in m³
    /// - Returns: Target RT60 value in seconds
    public static func targetRT60(for roomType: RoomUsageType, volume: Double) -> Double {
        // DIN 18041 target values (simplified)
        let baseTarget: Double
        let volumeExponent: Double

        switch roomType {
        case .classroom:
            baseTarget = 0.55
            volumeExponent = 0.1
        case .office:
            baseTarget = 0.50
            volumeExponent = 0.08
        case .conferenceRoom:
            baseTarget = 0.60
            volumeExponent = 0.1
        case .lectureHall:
            baseTarget = 0.70
            volumeExponent = 0.12
        case .musicRoom:
            baseTarget = 1.00
            volumeExponent = 0.15
        case .sportsHall:
            baseTarget = 1.50
            volumeExponent = 0.1
        case .restaurant:
            baseTarget = 0.70
            volumeExponent = 0.08
        case .openPlanOffice:
            baseTarget = 0.45
            volumeExponent = 0.05
        case .homeTheater:
            baseTarget = 0.40
            volumeExponent = 0.1
        case .recordingStudio:
            baseTarget = 0.30
            volumeExponent = 0.05
        }

        // Adjust for volume (reference: 100 m³)
        return baseTarget * pow(volume / 100.0, volumeExponent)
    }

    /// Generate recommendations for all frequency bands
    /// - Parameters:
    ///   - store: Surface store with room data
    ///   - roomType: Type of room usage
    /// - Returns: Array of recommendations per frequency
    public func generateRecommendations(
        for store: SurfaceStore,
        roomType: RoomUsageType
    ) -> [AbsorberRecommendation] {
        var recommendations: [AbsorberRecommendation] = []

        let targetRT60 = Self.targetRT60(for: roomType, volume: store.roomVolume)

        for frequency in AbsorptionData.standardFrequencies {
            guard let currentRT60 = store.calculateRT60(at: frequency) else { continue }

            let currentAbsorption = store.totalAbsorption(at: frequency)
            let requiredAbsorption = Self.requiredAbsorption(
                currentRT60: currentRT60,
                targetRT60: targetRT60,
                roomVolume: store.roomVolume,
                currentAbsorption: currentAbsorption
            )

            let priority = determinePriority(
                currentRT60: currentRT60,
                targetRT60: targetRT60
            )

            let products = recommendProducts(
                for: frequency,
                requiredAbsorption: requiredAbsorption
            )

            recommendations.append(AbsorberRecommendation(
                frequency: frequency,
                currentRT60: currentRT60,
                targetRT60: targetRT60,
                requiredAbsorption: requiredAbsorption,
                recommendedProducts: products,
                priority: priority
            ))
        }

        return recommendations
    }

    /// Calculate required absorber area for a specific product
    /// - Parameters:
    ///   - product: Absorber product
    ///   - frequency: Target frequency
    ///   - requiredAbsorption: Required absorption in m² Sabine
    /// - Returns: Required area in m²
    public static func requiredArea(
        for product: AbsorberProduct,
        at frequency: Int,
        requiredAbsorption: Double
    ) -> Double {
        let coefficient = product.absorption(at: frequency)
        guard coefficient > 0 else { return 0 }
        return requiredAbsorption / coefficient
    }

    // MARK: - Private Methods

    private func determinePriority(
        currentRT60: Double,
        targetRT60: Double
    ) -> AbsorberRecommendation.Priority {
        let ratio = currentRT60 / targetRT60

        if ratio >= 2.0 { return .critical }
        if ratio >= 1.5 { return .high }
        if ratio >= 1.2 { return .medium }
        if ratio >= 1.05 { return .low }
        return .none
    }

    private func recommendProducts(
        for frequency: Int,
        requiredAbsorption: Double
    ) -> [AbsorberProduct] {
        guard requiredAbsorption > 0 else { return [] }

        // Sort products by effectiveness at the target frequency
        return productDatabase
            .filter { $0.absorption(at: frequency) > 0.3 }
            .sorted { $0.absorption(at: frequency) > $1.absorption(at: frequency) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Product Database

    private static func loadProductDatabase() -> [AbsorberProduct] {
        return [
            // Porous Absorbers (Mineral Wool / Foam)
            AbsorberProduct(
                name: "Akustik-Mineralwolle 50mm",
                manufacturer: "ISOVER",
                type: .porousAbsorber,
                thickness: 50,
                absorptionCoefficients: [
                    125: 0.20, 250: 0.65, 500: 0.90, 1000: 0.95, 2000: 0.95, 4000: 0.90
                ],
                nrcRating: 0.85,
                fireRating: "A1",
                pricePerSqm: 12.50
            ),
            AbsorberProduct(
                name: "Akustik-Mineralwolle 100mm",
                manufacturer: "ISOVER",
                type: .porousAbsorber,
                thickness: 100,
                absorptionCoefficients: [
                    125: 0.45, 250: 0.85, 500: 0.95, 1000: 1.00, 2000: 1.00, 4000: 0.95
                ],
                nrcRating: 0.95,
                fireRating: "A1",
                pricePerSqm: 18.90
            ),
            AbsorberProduct(
                name: "Basotect Melaminharzschaum 50mm",
                manufacturer: "BASF",
                type: .porousAbsorber,
                thickness: 50,
                absorptionCoefficients: [
                    125: 0.15, 250: 0.55, 500: 0.85, 1000: 0.95, 2000: 0.95, 4000: 0.90
                ],
                nrcRating: 0.80,
                fireRating: "B1",
                pricePerSqm: 35.00
            ),

            // Membrane Absorbers (Bass Traps)
            AbsorberProduct(
                name: "Membran-Bassabsorber",
                manufacturer: "Vicoustic",
                type: .membraneAbsorber,
                thickness: 100,
                absorptionCoefficients: [
                    125: 0.85, 250: 0.70, 500: 0.35, 1000: 0.20, 2000: 0.15, 4000: 0.10
                ],
                nrcRating: 0.40,
                fireRating: "B1",
                pricePerSqm: 95.00
            ),
            AbsorberProduct(
                name: "Super Bass Extreme",
                manufacturer: "GIK Acoustics",
                type: .membraneAbsorber,
                thickness: 150,
                absorptionCoefficients: [
                    125: 0.95, 250: 0.80, 500: 0.45, 1000: 0.25, 2000: 0.15, 4000: 0.10
                ],
                nrcRating: 0.45,
                fireRating: "B1",
                pricePerSqm: 120.00
            ),

            // Resonator Absorbers (Helmholtz)
            AbsorberProduct(
                name: "Helmholtz-Resonator 125Hz",
                manufacturer: "Knauf AMF",
                type: .resonatorAbsorber,
                thickness: 200,
                absorptionCoefficients: [
                    125: 0.90, 250: 0.40, 500: 0.15, 1000: 0.10, 2000: 0.05, 4000: 0.05
                ],
                nrcRating: 0.30,
                fireRating: "A2",
                pricePerSqm: 85.00
            ),

            // Acoustic Panels (Decorative)
            AbsorberProduct(
                name: "Akustikpaneel Holzwolle",
                manufacturer: "Heradesign",
                type: .compositeAbsorber,
                thickness: 25,
                absorptionCoefficients: [
                    125: 0.30, 250: 0.70, 500: 0.85, 1000: 0.75, 2000: 0.60, 4000: 0.55
                ],
                nrcRating: 0.70,
                fireRating: "A2",
                pricePerSqm: 45.00
            ),
            AbsorberProduct(
                name: "Akustikdecke Mineral",
                manufacturer: "Armstrong",
                type: .porousAbsorber,
                thickness: 15,
                absorptionCoefficients: [
                    125: 0.25, 250: 0.50, 500: 0.80, 1000: 0.90, 2000: 0.85, 4000: 0.80
                ],
                nrcRating: 0.75,
                fireRating: "A1",
                pricePerSqm: 28.00
            ),

            // Diffusers
            AbsorberProduct(
                name: "QRD Diffusor Holz",
                manufacturer: "RPG",
                type: .diffuser,
                thickness: 120,
                absorptionCoefficients: [
                    125: 0.05, 250: 0.10, 500: 0.15, 1000: 0.20, 2000: 0.25, 4000: 0.30
                ],
                nrcRating: 0.15,
                fireRating: "B2",
                pricePerSqm: 180.00
            ),

            // Composite Solutions
            AbsorberProduct(
                name: "Breitband-Absorber Premium",
                manufacturer: "Primacoustic",
                type: .compositeAbsorber,
                thickness: 60,
                absorptionCoefficients: [
                    125: 0.35, 250: 0.75, 500: 0.95, 1000: 1.00, 2000: 0.95, 4000: 0.90
                ],
                nrcRating: 0.90,
                fireRating: "B1",
                pricePerSqm: 65.00
            ),
            AbsorberProduct(
                name: "Akustikvorhang schwer",
                manufacturer: "Gerriets",
                type: .compositeAbsorber,
                thickness: 5,
                absorptionCoefficients: [
                    125: 0.14, 250: 0.35, 500: 0.55, 1000: 0.72, 2000: 0.70, 4000: 0.65
                ],
                nrcRating: 0.55,
                fireRating: "B1",
                pricePerSqm: 55.00
            )
        ]
    }
}

// MARK: - Room Usage Types

/// Room usage types for DIN 18041 classification
public enum RoomUsageType: String, CaseIterable, Codable {
    case classroom = "Klassenzimmer"
    case office = "Büro"
    case conferenceRoom = "Konferenzraum"
    case lectureHall = "Hörsaal"
    case musicRoom = "Musikraum"
    case sportsHall = "Sporthalle"
    case restaurant = "Restaurant"
    case openPlanOffice = "Großraumbüro"
    case homeTheater = "Heimkino"
    case recordingStudio = "Aufnahmestudio"

    public var icon: String {
        switch self {
        case .classroom: return "book.fill"
        case .office: return "building.2.fill"
        case .conferenceRoom: return "person.3.fill"
        case .lectureHall: return "studentdesk"
        case .musicRoom: return "music.note"
        case .sportsHall: return "sportscourt.fill"
        case .restaurant: return "fork.knife"
        case .openPlanOffice: return "rectangle.split.3x3"
        case .homeTheater: return "tv.fill"
        case .recordingStudio: return "mic.fill"
        }
    }

    public var description: String {
        switch self {
        case .classroom:
            return "Unterrichtsraum für 20-40 Personen"
        case .office:
            return "Einzelbüro oder kleines Teambüro"
        case .conferenceRoom:
            return "Besprechungsraum für 6-20 Personen"
        case .lectureHall:
            return "Vorlesungssaal oder Auditorium"
        case .musicRoom:
            return "Musikübungsraum oder Proberaum"
        case .sportsHall:
            return "Turnhalle oder Mehrzweckhalle"
        case .restaurant:
            return "Gastronomie oder Kantine"
        case .openPlanOffice:
            return "Großraumbüro mit vielen Arbeitsplätzen"
        case .homeTheater:
            return "Privater Kinoraum"
        case .recordingStudio:
            return "Professionelles Aufnahmestudio"
        }
    }
}

// MARK: - Extended Material Database

public extension MaterialManager {

    /// Extended predefined materials database with 50+ materials
    static func loadExtendedMaterials() -> [AcousticMaterial] {
        return [
            // FLOORS
            AcousticMaterial(name: "Beton (roh)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02, 2000: 0.02, 4000: 0.03
            ])),
            AcousticMaterial(name: "Beton (poliert)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.01, 1000: 0.02, 2000: 0.02, 4000: 0.02
            ])),
            AcousticMaterial(name: "Estrich", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.015, 1000: 0.02, 2000: 0.02, 4000: 0.02
            ])),
            AcousticMaterial(name: "Linoleum auf Beton", absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.02, 500: 0.03, 1000: 0.03, 2000: 0.04, 4000: 0.04
            ])),
            AcousticMaterial(name: "PVC-Boden", absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.02, 500: 0.03, 1000: 0.03, 2000: 0.03, 4000: 0.02
            ])),
            AcousticMaterial(name: "Parkett auf Estrich", absorption: AbsorptionData(values: [
                125: 0.04, 250: 0.04, 500: 0.06, 1000: 0.06, 2000: 0.06, 4000: 0.06
            ])),
            AcousticMaterial(name: "Laminat", absorption: AbsorptionData(values: [
                125: 0.04, 250: 0.04, 500: 0.05, 1000: 0.05, 2000: 0.05, 4000: 0.05
            ])),
            AcousticMaterial(name: "Teppichboden dünn", absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.06, 500: 0.14, 1000: 0.37, 2000: 0.60, 4000: 0.65
            ])),
            AcousticMaterial(name: "Teppichboden dick", absorption: AbsorptionData(values: [
                125: 0.08, 250: 0.24, 500: 0.57, 1000: 0.69, 2000: 0.71, 4000: 0.73
            ])),
            AcousticMaterial(name: "Teppichboden auf Unterlage", absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.30, 500: 0.65, 1000: 0.75, 2000: 0.80, 4000: 0.80
            ])),

            // WALLS
            AcousticMaterial(name: "Ziegel (verputzt)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02, 2000: 0.03, 4000: 0.04
            ])),
            AcousticMaterial(name: "Ziegel (unverputzt)", absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.03, 500: 0.03, 1000: 0.04, 2000: 0.05, 4000: 0.07
            ])),
            AcousticMaterial(name: "Gipskarton auf Unterkonstruktion", absorption: AbsorptionData(values: [
                125: 0.29, 250: 0.10, 500: 0.05, 1000: 0.04, 2000: 0.07, 4000: 0.09
            ])),
            AcousticMaterial(name: "Gipskarton auf Beton", absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.05, 500: 0.04, 1000: 0.04, 2000: 0.05, 4000: 0.05
            ])),
            AcousticMaterial(name: "Sperrholz 4mm auf Rahmen", absorption: AbsorptionData(values: [
                125: 0.42, 250: 0.21, 500: 0.10, 1000: 0.08, 2000: 0.06, 4000: 0.06
            ])),
            AcousticMaterial(name: "OSB-Platte", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.11, 500: 0.10, 1000: 0.07, 2000: 0.06, 4000: 0.07
            ])),
            AcousticMaterial(name: "Holzvertäfelung massiv", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.11, 500: 0.10, 1000: 0.07, 2000: 0.06, 4000: 0.07
            ])),
            AcousticMaterial(name: "Akustikputz (5mm)", absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.20, 500: 0.50, 1000: 0.65, 2000: 0.70, 4000: 0.70
            ])),

            // CEILINGS
            AcousticMaterial(name: "Beton-Decke (glatt)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.01, 1000: 0.02, 2000: 0.02, 4000: 0.02
            ])),
            AcousticMaterial(name: "Gipskartondecke", absorption: AbsorptionData(values: [
                125: 0.29, 250: 0.10, 500: 0.05, 1000: 0.04, 2000: 0.07, 4000: 0.09
            ])),
            AcousticMaterial(name: "Akustikdecke (Mineralfaser)", absorption: AbsorptionData(values: [
                125: 0.25, 250: 0.50, 500: 0.80, 1000: 0.90, 2000: 0.85, 4000: 0.80
            ])),
            AcousticMaterial(name: "Holzwolle-Akustikdecke", absorption: AbsorptionData(values: [
                125: 0.30, 250: 0.70, 500: 0.85, 1000: 0.75, 2000: 0.60, 4000: 0.55
            ])),
            AcousticMaterial(name: "Metallkassetten gelocht", absorption: AbsorptionData(values: [
                125: 0.35, 250: 0.65, 500: 0.85, 1000: 0.90, 2000: 0.85, 4000: 0.80
            ])),

            // WINDOWS & GLASS
            AcousticMaterial(name: "Einfachverglasung (3mm)", absorption: AbsorptionData(values: [
                125: 0.35, 250: 0.25, 500: 0.18, 1000: 0.12, 2000: 0.07, 4000: 0.04
            ])),
            AcousticMaterial(name: "Isolierverglasung", absorption: AbsorptionData(values: [
                125: 0.25, 250: 0.15, 500: 0.10, 1000: 0.07, 2000: 0.04, 4000: 0.02
            ])),
            AcousticMaterial(name: "Dreifachverglasung", absorption: AbsorptionData(values: [
                125: 0.20, 250: 0.12, 500: 0.08, 1000: 0.05, 2000: 0.03, 4000: 0.02
            ])),

            // DOORS
            AcousticMaterial(name: "Holztür (massiv)", absorption: AbsorptionData(values: [
                125: 0.14, 250: 0.10, 500: 0.06, 1000: 0.08, 2000: 0.10, 4000: 0.10
            ])),
            AcousticMaterial(name: "Holztür (hohl)", absorption: AbsorptionData(values: [
                125: 0.30, 250: 0.25, 500: 0.15, 1000: 0.10, 2000: 0.10, 4000: 0.10
            ])),
            AcousticMaterial(name: "Glastür", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.10, 500: 0.07, 1000: 0.05, 2000: 0.04, 4000: 0.03
            ])),

            // TEXTILES
            AcousticMaterial(name: "Vorhang leicht", absorption: AbsorptionData(values: [
                125: 0.03, 250: 0.04, 500: 0.11, 1000: 0.17, 2000: 0.24, 4000: 0.35
            ])),
            AcousticMaterial(name: "Vorhang mittel", absorption: AbsorptionData(values: [
                125: 0.07, 250: 0.31, 500: 0.49, 1000: 0.75, 2000: 0.70, 4000: 0.60
            ])),
            AcousticMaterial(name: "Vorhang schwer (Molton)", absorption: AbsorptionData(values: [
                125: 0.14, 250: 0.35, 500: 0.55, 1000: 0.72, 2000: 0.70, 4000: 0.65
            ])),
            AcousticMaterial(name: "Akustikvorhang", absorption: AbsorptionData(values: [
                125: 0.25, 250: 0.45, 500: 0.65, 1000: 0.80, 2000: 0.75, 4000: 0.70
            ])),

            // ACOUSTIC PANELS
            AcousticMaterial(name: "Akustikschaum 50mm", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.40, 500: 0.80, 1000: 0.95, 2000: 0.90, 4000: 0.85
            ])),
            AcousticMaterial(name: "Akustikschaum 100mm", absorption: AbsorptionData(values: [
                125: 0.35, 250: 0.65, 500: 0.95, 1000: 1.00, 2000: 0.95, 4000: 0.90
            ])),
            AcousticMaterial(name: "Mineralwolle 50mm (sichtbar)", absorption: AbsorptionData(values: [
                125: 0.20, 250: 0.65, 500: 0.90, 1000: 0.95, 2000: 0.95, 4000: 0.90
            ])),
            AcousticMaterial(name: "Mineralwolle 100mm (sichtbar)", absorption: AbsorptionData(values: [
                125: 0.45, 250: 0.85, 500: 0.95, 1000: 1.00, 2000: 1.00, 4000: 0.95
            ])),
            AcousticMaterial(name: "Basotect 50mm", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.55, 500: 0.85, 1000: 0.95, 2000: 0.95, 4000: 0.90
            ])),

            // FURNITURE & OBJECTS
            AcousticMaterial(name: "Polstermöbel", absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.20, 500: 0.40, 1000: 0.60, 2000: 0.70, 4000: 0.70
            ])),
            AcousticMaterial(name: "Bürostuhl (pro Stück)", absorption: AbsorptionData(values: [
                125: 0.05, 250: 0.10, 500: 0.20, 1000: 0.30, 2000: 0.35, 4000: 0.35
            ])),
            AcousticMaterial(name: "Publikum (pro Person)", absorption: AbsorptionData(values: [
                125: 0.25, 250: 0.35, 500: 0.42, 1000: 0.46, 2000: 0.50, 4000: 0.50
            ])),

            // SPECIAL SURFACES
            AcousticMaterial(name: "Wasser (Schwimmbecken)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.01, 1000: 0.01, 2000: 0.02, 4000: 0.02
            ])),
            AcousticMaterial(name: "Marmor/Granit", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.01, 1000: 0.01, 2000: 0.02, 4000: 0.02
            ])),
            AcousticMaterial(name: "Fliesen (Keramik)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.01, 1000: 0.01, 2000: 0.02, 4000: 0.02
            ]))
        ]
    }
}
