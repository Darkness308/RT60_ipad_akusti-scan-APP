// RoomType.swift
// DIN 18041 room type definitions

import Foundation

/// Raumtypen nach DIN 18041 für akustische Messungen
public enum RoomType: String, CaseIterable {
    case classroom = "classroom"
    case officeSpace = "office"
    case conference = "conference"
    case lecture = "lecture"
    case music = "music"
    case sports = "sports"
    
    /// Deutsche Bezeichnung des Raumtyps
    public var germanName: String {
        switch self {
        case .classroom:
            return "Unterrichtsraum"
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
    
    /// Beschreibung des Raumtyps
    public var description: String {
        switch self {
        case .classroom:
            return "Klassenräume und Unterrichtsräume"
        case .officeSpace:
            return "Büros und Arbeitsplätze"
        case .conference:
            return "Besprechungs- und Konferenzräume"
        case .lecture:
            return "Hörsäle und große Unterrichtsräume"
        case .music:
            return "Musikräume und Proberäume"
        case .sports:
            return "Sporthallen und große Räume"
        }
    }
}