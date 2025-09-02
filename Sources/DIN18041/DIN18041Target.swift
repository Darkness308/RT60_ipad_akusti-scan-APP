// DIN18041Target.swift
// DIN 18041 target values and specifications

import Foundation

/// DIN 18041 Sollwert für eine bestimmte Frequenz
public struct DIN18041Target {
    public let frequency: Int        // Frequenz in Hz
    public let targetRT60: Double    // Sollwert RT60 in Sekunden
    public let tolerance: Double     // Zulässige Toleranz in Sekunden
    public let roomType: RoomType    // Raumtyp
    
    /// Minimaler zulässiger RT60-Wert
    public var minimumRT60: Double {
        return targetRT60 - tolerance
    }
    
    /// Maximaler zulässiger RT60-Wert  
    public var maximumRT60: Double {
        return targetRT60 + tolerance
    }
    
    public init(frequency: Int, targetRT60: Double, tolerance: Double, roomType: RoomType) {
        self.frequency = frequency
        self.targetRT60 = targetRT60
        self.tolerance = tolerance
        self.roomType = roomType
    }
}

extension DIN18041Target: Equatable {
    public static func == (lhs: DIN18041Target, rhs: DIN18041Target) -> Bool {
        return lhs.frequency == rhs.frequency &&
               lhs.roomType == rhs.roomType &&
               abs(lhs.targetRT60 - rhs.targetRT60) < 0.001
    }
}

/// DIN 18041 Sollwert-Datenbank
public struct DIN18041Database {
    
    /// Standard-Frequenzen für RT60-Messungen nach DIN 18041
    public static let standardFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
    
    /// Ermittelt DIN 18041 Sollwerte für bestimmten Raumtyp und Volumen
    public static func targets(for roomType: RoomType, volume: Double) -> [DIN18041Target] {
        switch roomType {
        case .classroom:
            return classroomTargets(volume: volume, roomType: roomType)
        case .officeSpace:
            return officeTargets(volume: volume, roomType: roomType)
        case .conference:
            return conferenceTargets(volume: volume, roomType: roomType)
        case .lecture:
            return lectureTargets(volume: volume, roomType: roomType)
        case .music:
            return musicTargets(volume: volume, roomType: roomType)
        case .sports:
            return sportsTargets(volume: volume, roomType: roomType)
        }
    }
    
    // MARK: - Private Target Calculations
    
    private static func classroomTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .classroom, volume: volume)
        let tolerance = 0.1
        
        return standardFrequencies.map { frequency in
            var targetRT60 = baseRT60
            
            // Frequenzabhängige Anpassungen für Unterrichtsräume
            switch frequency {
            case 125, 250:
                targetRT60 *= 1.2  // Tiefe Frequenzen: etwas höhere RT60 erlaubt
            case 2000, 4000, 8000:
                targetRT60 *= 0.8  // Hohe Frequenzen: niedrigere RT60 erforderlich
            default:
                break
            }
            
            return DIN18041Target(
                frequency: frequency,
                targetRT60: targetRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    private static func officeTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .officeSpace, volume: volume)
        let tolerance = 0.1
        
        return standardFrequencies.map { frequency in
            DIN18041Target(
                frequency: frequency,
                targetRT60: baseRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    private static func conferenceTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .conference, volume: volume)
        let tolerance = 0.15
        
        return standardFrequencies.map { frequency in
            DIN18041Target(
                frequency: frequency,
                targetRT60: baseRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    private static func lectureTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .lecture, volume: volume)
        let tolerance = 0.15
        
        return standardFrequencies.map { frequency in
            DIN18041Target(
                frequency: frequency,
                targetRT60: baseRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    private static func musicTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .music, volume: volume)
        let tolerance = 0.2
        
        return standardFrequencies.map { frequency in
            DIN18041Target(
                frequency: frequency,
                targetRT60: baseRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    private static func sportsTargets(volume: Double, roomType: RoomType) -> [DIN18041Target] {
        let baseRT60 = calculateBaseRT60(for: .sports, volume: volume)
        let tolerance = 0.3
        
        return standardFrequencies.map { frequency in
            DIN18041Target(
                frequency: frequency,
                targetRT60: baseRT60,
                tolerance: tolerance,
                roomType: roomType
            )
        }
    }
    
    /// Berechnet den Basis-RT60-Wert für Raumtyp und Volumen
    private static func calculateBaseRT60(for roomType: RoomType, volume: Double) -> Double {
        switch roomType {
        case .classroom:
            return 0.6
        case .officeSpace:
            return 0.5
        case .conference:
            return 0.7
        case .lecture:
            return 0.8 + min(0.2, volume / 1000.0 * 0.1) // Leicht volumenabhängig
        case .music:
            return 1.5 + min(0.5, volume / 500.0 * 0.2) // Deutlich volumenabhängig
        case .sports:
            return 2.0 + min(1.0, volume / 2000.0 * 0.5) // Stark volumenabhängig
        }
    }
}