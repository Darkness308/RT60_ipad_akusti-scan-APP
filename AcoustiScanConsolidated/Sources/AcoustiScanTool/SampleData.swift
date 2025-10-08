// SampleData.swift
// Shared demo data for the AcoustiScan CLI so the sample configuration
// lives in a single place.

import Foundation
import AcoustiScanConsolidated

struct SampleRoomConfiguration {
    let roomType: RoomType
    let volume: Double
    let surfaces: [AcousticSurface]
}

struct SampleDataset {
    let configuration: SampleRoomConfiguration
    let measurements: [RT60Measurement]
    let dinResults: [RT60Deviation]
    let frameworkScores: [String: Double]
    let recommendations: [String]
}

enum SampleData {
    static func baselineDataset() -> SampleDataset {
        let configuration = SampleRoomConfiguration(
            roomType: .classroom,
            volume: 150.0,
            surfaces: [
                AcousticSurface(
                    name: "Decke",
                    area: 50.0,
                    material: AcousticMaterial(
                        name: "Gipskarton",
                        absorptionCoefficients: [
                            125: 0.10, 250: 0.08, 500: 0.05, 1000: 0.04,
                            2000: 0.07, 4000: 0.09, 8000: 0.11
                        ]
                    )
                ),
                AcousticSurface(
                    name: "Boden",
                    area: 50.0,
                    material: AcousticMaterial(
                        name: "Linoleum",
                        absorptionCoefficients: [
                            125: 0.02, 250: 0.03, 500: 0.03, 1000: 0.04,
                            2000: 0.04, 4000: 0.04, 8000: 0.04
                        ]
                    )
                ),
                AcousticSurface(
                    name: "Wände",
                    area: 120.0,
                    material: AcousticMaterial(
                        name: "Putz auf Mauerwerk",
                        absorptionCoefficients: [
                            125: 0.02, 250: 0.02, 500: 0.03, 1000: 0.04,
                            2000: 0.05, 4000: 0.05, 8000: 0.05
                        ]
                    )
                )
            ]
        )

        let measurements = RT60Calculator.calculateFrequencySpectrum(
            volume: configuration.volume,
            surfaces: configuration.surfaces
        )

        let dinResults = RT60Calculator.evaluateDINCompliance(
            measurements: measurements,
            roomType: configuration.roomType,
            volume: configuration.volume
        )

        let frameworkScores: [String: Double] = [
            "Klangfarbe hell-dunkel": 0.7,
            "Schärfe": 0.4,
            "Nachhallstärke": 0.8,
            "Lautheit": 0.6
        ]

        let recommendations = [
            "Absorberfläche an der Decke um 15% vergrößern",
            "Materialien mit höherem Absorptionsgrad einsetzen",
            "Schallabsorber in kritischen Bereichen installieren",
            "Nachmessung nach 3 Monaten durchführen"
        ]

        return SampleDataset(
            configuration: configuration,
            measurements: measurements,
            dinResults: dinResults,
            frameworkScores: frameworkScores,
            recommendations: recommendations
        )
    }
}
