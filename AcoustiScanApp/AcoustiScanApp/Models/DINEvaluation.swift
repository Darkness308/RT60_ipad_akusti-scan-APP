//  DINEvaluation.swift
//  AcoustiScanApp
//
//  Bridges the app's (Sabine-)calculated RT60 spectrum to the package's
//  norm-faithful DIN 18041 evaluation (asymmetric Bild-2 tolerance band).
//  Kept separate from SurfaceStore on purpose: importing AcoustiScanConsolidated
//  here avoids an `AcousticMaterial` name clash with the app's own model.

import Foundation
import AcoustiScanConsolidated

enum DINEvaluation {

    /// Evaluate a calculated RT60 spectrum (Hz → seconds) against DIN 18041 for
    /// the given room usage group and volume.
    /// - Returns: per-octave-band deviations; empty if the volume is not set.
    static func deviations(
        spectrum: [Int: Double],
        roomType: RoomType,
        volume: Double
    ) -> [RT60Deviation] {
        guard volume > 0 else { return [] }
        let measurements = spectrum
            .sorted { $0.key < $1.key }
            .map { RT60Measurement(frequency: $0.key, rt60: $0.value) }
        return RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: roomType,
            volume: volume
        )
    }
}
