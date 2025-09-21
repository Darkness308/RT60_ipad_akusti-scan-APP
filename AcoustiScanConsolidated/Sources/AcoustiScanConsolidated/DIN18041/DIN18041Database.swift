// DIN18041Database.swift
// DIN 18041 target database for different room types

import Foundation

/// DIN 18041 target database
public struct DIN18041Database {
    
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
    
    private static func classroomTargets(volume: Double) -> [DIN18041Target] {
        // DIN 18041 targets for classrooms
        let baseRT60 = 0.6 // Base reverberation time for classrooms
        let tolerance = 0.1
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = baseRT60
            
            // Frequency-dependent adjustments
            if frequency <= 250 {
                targetRT60 *= 1.2 // Allow slightly higher RT60 at low frequencies
            } else if frequency >= 2000 {
                targetRT60 *= 0.8 // Require lower RT60 at high frequencies
            }
            
            return DIN18041Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }
    
    private static func officeTargets(volume: Double) -> [DIN18041Target] {
        let baseRT60 = 0.5
        let tolerance = 0.1
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            DIN18041Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func conferenceTargets(volume: Double) -> [DIN18041Target] {
        let baseRT60 = 0.7
        let tolerance = 0.15
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            DIN18041Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func lectureTargets(volume: Double) -> [DIN18041Target] {
        let baseRT60 = 0.8
        let tolerance = 0.15
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            DIN18041Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func musicTargets(volume: Double) -> [DIN18041Target] {
        let baseRT60 = 1.5
        let tolerance = 0.2
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            DIN18041Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func sportsTargets(volume: Double) -> [DIN18041Target] {
        let baseRT60 = 2.0
        let tolerance = 0.3
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            DIN18041Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
}