// RoomType.swift
// Room type classification according to DIN 18041

import Foundation

/// Room type classification according to DIN 18041
public enum RoomType: String, CaseIterable {
    case classroom = "classroom"
    case officeSpace = "office_space"
    case conference = "conference"
    case lecture = "lecture"
    case music = "music"
    case sports = "sports"
    
    public var displayName: String {
        switch self {
        case .classroom: return "Klassenzimmer"
        case .officeSpace: return "Büroraum"
        case .conference: return "Konferenzraum"
        case .lecture: return "Hörsaal"
        case .music: return "Musikraum"
        case .sports: return "Sporthalle"
        }
    }
}