// DIN18041Database.swift
// Volume- and frequency-dependent RT60 targets per DIN 18041:2016-03 (Gruppe A).

import Foundation

/// Builds DIN 18041:2016-03 reverberation-time targets for a usage group.
///
/// The mid-band target `T_soll = a · lg(V) + b` comes from `RoomType`
/// (equations (1)–(6)); the per-octave acceptable range is derived from the
/// Bild 2 tolerance ratios. All normative constants live on `RoomType`, so this
/// type only assembles the per-frequency `DIN18041Target` values.
public struct DIN18041Database {

    /// DIN 18041 targets for a usage group and room volume.
    ///
    /// - Parameters:
    ///   - roomType: DIN 18041 usage group (A1–A5).
    ///   - volume: Room volume in m³.
    /// - Returns: One target per evaluated octave band for the group.
    public static func targets(for roomType: RoomType, volume: Double) -> [DIN18041Target] {
        let targetRT60 = roomType.targetReverberationTime(volume: volume)

        return roomType.evaluationFrequencies.map { frequency in
            let ratios = roomType.toleranceRatios(at: frequency)
            return DIN18041Target(
                frequency: frequency,
                targetRT60: targetRT60,
                lowerRatio: ratios.lower,
                upperRatio: ratios.upper
            )
        }
    }
}
