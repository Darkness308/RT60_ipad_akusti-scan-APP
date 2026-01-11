// DIN18041Database.swift
// DIN 18041 target database for different room types
// Implements volume-dependent RT60 targets according to DIN 18041 standard

import Foundation

/// DIN 18041 target database with volume-dependent calculations
public struct DIN18041Database {

    /// Reference volume for base RT60 values (100 m^3 is typical reference)
    private static let referenceVolume: Double = 100.0

    /// Get DIN 18041 targets for specific room type and volume
    public static func targets(for roomType: RoomType, volume: Double) -> [DIN18041Target] {
        switch roomType {
        case .classroom:
            return classroomTargets(volume: volume)
        case .officeSpace:
            return officeTargets(volume: volume)
        case .conference:
            return conferenceTargets(volume: volume)
        case .lecture:
            return lectureTargets(volume: volume)
        case .music:
            return musicTargets(volume: volume)
        case .sports:
            return sportsTargets(volume: volume)
        }
    }

    /// Calculate volume-adjusted RT60 target using DIN 18041 formula
    /// T_soll = T_base * (V / V_ref)^exponent
    /// - Parameters:
    ///   - baseRT60: Base RT60 value for reference volume
    ///   - volume: Actual room volume in m^3
    ///   - exponent: Volume scaling exponent (typically 0.05-0.15)
    /// - Returns: Volume-adjusted RT60 target
    private static func volumeAdjustedRT60(baseRT60: Double, volume: Double, exponent: Double = 0.1) -> Double {
        guard volume > 0 else { return baseRT60 }
        let ratio = volume / referenceVolume
        // Apply logarithmic scaling: larger rooms need proportionally longer RT60
        return baseRT60 * pow(ratio, exponent)
    }

    private static func classroomTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Classrooms require speech intelligibility
        // Base RT60 = 0.6s for 100 m^3, with volume scaling exponent 0.08
        let baseRT60 = 0.6
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.08)
        let tolerance = 0.1

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Frequency-dependent adjustments per DIN 18041
            if frequency <= 250 {
                targetRT60 *= 1.2 // Allow slightly higher RT60 at low frequencies
            } else if frequency >= 2000 {
                targetRT60 *= 0.8 // Require lower RT60 at high frequencies for clarity
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }

    private static func officeTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Open plan offices need acoustic privacy
        // Base RT60 = 0.5s, lower exponent (0.05) as offices vary less with size
        let baseRT60 = 0.5
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.05)
        let tolerance = 0.1

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Speech-frequency optimization
            if frequency >= 500 && frequency <= 2000 {
                targetRT60 *= 0.95 // Slightly lower in speech range
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }

    private static func conferenceTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Conference rooms need good speech intelligibility
        // Base RT60 = 0.7s with moderate volume scaling
        let baseRT60 = 0.7
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.1)
        let tolerance = 0.15

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Optimize for speech frequencies
            if frequency >= 500 && frequency <= 4000 {
                targetRT60 *= 0.9
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }

    private static func lectureTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Lecture halls need projection but clarity
        // Base RT60 = 0.8s with higher volume scaling for larger auditoriums
        let baseRT60 = 0.8
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.12)
        let tolerance = 0.15

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Frequency-dependent adjustments for lecture clarity
            if frequency <= 250 {
                targetRT60 *= 1.1 // Allow some warmth at low frequencies
            } else if frequency >= 4000 {
                targetRT60 *= 0.85 // Control high-frequency reflections
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }

    private static func musicTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Music rooms need longer reverberation for richness
        // Base RT60 = 1.5s with significant volume scaling
        let baseRT60 = 1.5
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.15)
        let tolerance = 0.2

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Music benefits from balanced frequency response
            if frequency <= 125 {
                targetRT60 *= 1.15 // Fuller bass response
            } else if frequency >= 4000 {
                targetRT60 *= 0.9 // Controlled brilliance
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }

    private static func sportsTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041: Sports halls prioritize speech/announcement clarity
        // Base RT60 = 2.0s but with strict volume scaling for large spaces
        let baseRT60 = 2.0
        let volumeAdjusted = volumeAdjustedRT60(baseRT60: baseRT60, volume: volume, exponent: 0.12)
        // Larger tolerance for sports halls due to their size and variable use
        let tolerance = 0.3

        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = volumeAdjusted

            // Optimize for PA announcements
            if frequency >= 500 && frequency <= 2000 {
                targetRT60 *= 0.9 // Better speech clarity in PA range
            }

            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }
}
