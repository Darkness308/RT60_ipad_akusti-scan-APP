//  ReportBuilder.swift
//  AcoustiScanApp
//
//  Maps the app's room state (SurfaceStore) + selected DIN room type into the
//  package's `ReportData`, so the norm-faithful `ConsolidatedPDFExporter` can
//  render the PDF. The package `AcousticMaterial` is fully qualified to avoid a
//  name clash with the app's own `AcousticMaterial`.

import Foundation
import AcoustiScanConsolidated

enum ReportBuilder {

    private static let standardFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]

    /// Build `ReportData` for the PDF report from the current room state.
    static func makeReportData(store: SurfaceStore, roomType: RoomType) -> ReportData {
        let spectrum = store.calculateRT60Spectrum()

        let measurements = spectrum
            .sorted { $0.key < $1.key }
            .map { RT60Measurement(frequency: $0.key, rt60: $0.value) }

        let dinResults = DINEvaluation.deviations(
            spectrum: spectrum,
            roomType: roomType,
            volume: store.roomVolume
        )

        let surfaces: [AcousticSurface] = store.surfaces.map { surface in
            let coefficients: [Int: Double] = standardFrequencies.reduce(into: [:]) { dict, frequency in
                dict[frequency] = surface.material.map { Double($0.absorptionCoefficient(at: frequency)) } ?? 0.0
            }
            let material = AcoustiScanConsolidated.AcousticMaterial(
                name: surface.material?.name ?? "—",
                absorptionCoefficients: coefficients
            )
            return AcousticSurface(name: surface.name, area: surface.area, material: material)
        }

        return ReportData(
            date: ISO8601DateFormatter().string(from: Date()),
            roomType: roomType,
            volume: store.roomVolume,
            rt60Measurements: measurements,
            dinResults: dinResults,
            acousticFrameworkResults: [:],   // 48-parameter framework not computed in-app
            surfaces: surfaces,
            recommendations: [],
            metadata: ["roomName": store.roomName]
        )
    }
}
