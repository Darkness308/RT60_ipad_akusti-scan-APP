// RoomType.swift
// Room usage classification according to DIN 18041:2016-03 (Gruppe A).

import Foundation

/// Room usage groups of DIN 18041:2016-03, table 5 / equations (1)–(6).
///
/// Each group defines a volume-dependent target reverberation time
/// `T_soll = a · lg(V) + b` (V in m³, `lg` = log base 10) and a frequency
/// dependent tolerance band (Bild 2). The previous, invented room types
/// (classroom/office/…) did not correspond to the standard and were replaced
/// by the normative groups A1–A5.
public enum RoomType: String, CaseIterable, Codable {

    /// A1 – Music
    case a1Music = "A1"

    /// A2 – Speech/lecture
    case a2Speech = "A2"

    /// A3 – Teaching/communication
    case a3Education = "A3"

    /// A4 – Teaching/communication, inclusive
    case a4EducationInclusive = "A4"

    /// A5 – Sport
    case a5Sports = "A5"

    /// Group label as used by the standard ("A1" … "A5").
    public var groupLabel: String { rawValue }

    /// Human-readable display name (German).
    public var displayName: String {
        switch self {
        case .a1Music:
            return "A1 – Musik"
        case .a2Speech:
            return "A2 – Sprache/Vortrag"
        case .a3Education:
            return "A3 – Unterricht/Kommunikation"
        case .a4EducationInclusive:
            return "A4 – Unterricht/Kommunikation inklusiv"
        case .a5Sports:
            return "A5 – Sport"
        }
    }

    /// Volume range [m³] for which the target equation is defined
    /// (DIN 18041:2016-03, table 5).
    public var validVolumeRange: ClosedRange<Double> {
        switch self {
        case .a1Music:
            return 30...1000
        case .a2Speech:
            return 50...5000
        case .a3Education:
            return 30...5000
        case .a4EducationInclusive:
            return 30...500
        case .a5Sports:
            return 200...10000
        }
    }

    /// Whether the given room volume lies within this group's validity range.
    public func isVolumeWithinValidRange(_ volume: Double) -> Bool {
        validVolumeRange.contains(volume)
    }

    /// Mid-band target reverberation time `T_soll` [s] for the given volume.
    ///
    /// `T_soll = a · lg(V) + b` per DIN 18041:2016-03, equations (1)–(6).
    /// For A5 the value is capped at 2.0 s from 10 000 m³ upwards (the equation
    /// already yields 2.0 s at 10 000 m³).
    public func targetReverberationTime(volume: Double) -> Double {
        let lg = log10(max(volume, 1.0))
        switch self {
        case .a1Music:
            return 0.45 * lg + 0.07
        case .a2Speech:
            return 0.37 * lg - 0.14
        case .a3Education:
            return 0.32 * lg - 0.17
        case .a4EducationInclusive:
            return 0.26 * lg - 0.14
        case .a5Sports:
            return min(0.75 * lg - 1.00, 2.0)
        }
    }

    /// Octave-band centre frequencies [Hz] at which compliance is verified.
    ///
    /// A1–A4 are evaluated across 125–4000 Hz; A5 is only specified for
    /// 250–2000 Hz (DIN 18041:2016-03, Bild 2 / 5.2).
    public var evaluationFrequencies: [Int] {
        switch self {
        case .a5Sports:
            return [250, 500, 1000, 2000]
        default:
            return [125, 250, 500, 1000, 2000, 4000]
        }
    }

    /// Tolerance band as ratio `T / T_soll` (lower, upper) for the given octave,
    /// per DIN 18041:2016-03, Bild 2.
    ///
    /// - A1–A4: 0.80–1.20 in the mid band, widening to 0.65–1.45 at the
    ///   125 Hz and 4000 Hz edges.
    /// - A5: ±20 % (0.80–1.20) across the specified 250–2000 Hz range.
    public func toleranceRatios(at frequency: Int) -> (lower: Double, upper: Double) {
        switch self {
        case .a5Sports:
            return (0.80, 1.20)
        default:
            if frequency <= 125 || frequency >= 4000 {
                return (0.65, 1.45)
            } else {
                return (0.80, 1.20)
            }
        }
    }
}
