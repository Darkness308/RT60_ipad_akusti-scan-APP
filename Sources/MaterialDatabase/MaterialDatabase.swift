// MaterialDatabase.swift
import Foundation

struct MaterialDatabase {
    static let materials: [AcousticMaterial] = [
        AcousticMaterial(
            name: "Betonwand",
            absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02, 2000: 0.02, 4000: 0.02, 8000: 0.02
            ])
        ),
        AcousticMaterial(
            name: "Gipskarton",
            absorption: AbsorptionData(values: [
                125: 0.29, 250: 0.10, 500: 0.05, 1000: 0.04, 2000: 0.07, 4000: 0.09, 8000: 0.12
            ])
        ),
        AcousticMaterial(
            name: "Holztäfelung",
            absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.11, 500: 0.10, 1000: 0.09, 2000: 0.10, 4000: 0.11, 8000: 0.12
            ])
        ),
        AcousticMaterial(
            name: "Teppich (flauschig)",
            absorption: AbsorptionData(values: [
                125: 0.08, 250: 0.24, 500: 0.57, 1000: 0.69, 2000: 0.71, 4000: 0.73, 8000: 0.74
            ])
        ),
        AcousticMaterial(
            name: "Vorhang (schwer)",
            absorption: AbsorptionData(values: [
                125: 0.05, 250: 0.12, 500: 0.35, 1000: 0.55, 2000: 0.72, 4000: 0.70, 8000: 0.65
            ])
        ),
        AcousticMaterial(
            name: "Akustikdecke (mineralisch)",
            absorption: AbsorptionData(values: [
                125: 0.45, 250: 0.80, 500: 0.90, 1000: 0.95, 2000: 0.90, 4000: 0.85, 8000: 0.80
            ])
        ),
        AcousticMaterial(
            name: "Basotect (Melaminharz)",
            absorption: AbsorptionData(values: [
                125: 0.20, 250: 0.35, 500: 0.80, 1000: 1.00, 2000: 1.00, 4000: 1.00, 8000: 1.00
            ])
        ),
        AcousticMaterial(
            name: "Glaswolle (50mm)",
            absorption: AbsorptionData(values: [
                125: 0.10, 250: 0.50, 500: 0.90, 1000: 1.00, 2000: 1.00, 4000: 1.00, 8000: 1.00
            ])
        ),
        AcousticMaterial(
            name: "Rauhfaser gestrichen",
            absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.03, 500: 0.04, 1000: 0.05, 2000: 0.06, 4000: 0.07, 8000: 0.07
            ])
        ),
        AcousticMaterial(
            name: "Parkettboden",
            absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.02, 500: 0.03, 1000: 0.04, 2000: 0.05, 4000: 0.06, 8000: 0.06
            ])
        ),
        AcousticMaterial(
            name: "Laminat",
            absorption: AbsorptionData(values: [
                125: 0.02, 250: 0.02, 500: 0.03, 1000: 0.04, 2000: 0.05, 4000: 0.06, 8000: 0.06
            ])
        ),
        AcousticMaterial(
            name: "Deckenpaneele (PVC)",
            absorption: AbsorptionData(values: [
                125: 0.03, 250: 0.04, 500: 0.05, 1000: 0.06, 2000: 0.07, 4000: 0.07, 8000: 0.07
            ])
        )
    ]

    static func absorption(for materialName: String) -> AbsorptionData? {
        return materials.first(where: { $0.name == materialName })?.absorption
    }
}

struct AcousticMaterial: Identifiable {
    var id = UUID()
    let name: String
    let absorption: AbsorptionData
}

struct AbsorptionData {
    let values: [Int: Float] // Frequenz in Hz → α-Wert
}
