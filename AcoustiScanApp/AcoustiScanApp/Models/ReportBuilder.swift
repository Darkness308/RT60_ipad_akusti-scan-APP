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

    /// Build `ReportData` for the PDF report from the current room state.
    static func makeReportData(store: SurfaceStore, roomType: RoomType) -> ReportData {
        // Restrict to the bands DIN actually evaluates for this group so that
        // rt60Measurements and dinResults align (no "Status: Unbekannt" rows,
        // e.g. 8000 Hz, or 125/4000 Hz for A5).
        let evaluated = Set(roomType.evaluationFrequencies)
        let spectrum = store.calculateRT60Spectrum().filter { evaluated.contains($0.key) }

        let measurements = spectrum
            .sorted { $0.key < $1.key }
            .map { RT60Measurement(frequency: $0.key, rt60: $0.value) }

        let dinResults = DINEvaluation.deviations(
            spectrum: spectrum,
            roomType: roomType,
            volume: store.roomVolume
        )

        let surfaces: [AcousticSurface] = store.surfaces.map { surface in
            let coefficients: [Int: Double] = AbsorptionData.standardFrequencies.reduce(into: [:]) { dict, frequency in
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
