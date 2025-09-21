// RoomType.swift
// Data model for room classification according to DIN 18041

import Foundation

/// Room type classification according to DIN 18041 standard
///
/// This enumeration defines the supported room types according to DIN 18041,
/// which determines the target RT60 values and tolerance ranges for acoustic evaluation.
/// Each room type has specific requirements based on its intended use.
public enum RoomType: String, CaseIterable, Codable {
    
    /// Classroom or teaching room
    case classroom = "classroom"
    
    /// Office space for speech communication
    case officeSpace = "office_space"
    
    /// Conference room for meetings and presentations
    case conference = "conference"
    
    /// Lecture hall or auditorium
    case lecture = "lecture"
    
    /// Music room or rehearsal space
    case music = "music"
    
    /// Sports hall or gymnasium
    case sports = "sports"
    
    /// Human-readable display name in German
    public var displayName: String {
        switch self {
        case .classroom:
            return "Klassenzimmer"
        case .officeSpace:
            return "Büroraum"
        case .conference:
            return "Konferenzraum"
        case .lecture:
            return "Hörsaal"
        case .music:
            return "Musikraum"
        case .sports:
            return "Sporthalle"
        }
    }
    
    /// Primary use category for acoustic planning
    public var primaryUse: String {
        switch self {
        case .classroom, .officeSpace, .conference, .lecture:
            return "Speech"
        case .music:
            return "Music"
        case .sports:
            return "Sports"
        }
    }
    
    /// Typical volume range for this room type (in cubic meters)
    public var typicalVolumeRange: ClosedRange<Double> {
        switch self {
        case .classroom:
            return 120...300
        case .officeSpace:
            return 30...150
        case .conference:
            return 50...200
        case .lecture:
            return 300...2000
        case .music:
            return 150...1000
        case .sports:
            return 1000...10000
        }
    }
}