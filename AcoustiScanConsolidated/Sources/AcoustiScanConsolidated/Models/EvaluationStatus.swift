// EvaluationStatus.swift
// DIN 18041 evaluation status types

import Foundation

public enum EvaluationStatus: String, CaseIterable {
    case withinTolerance = "within_tolerance"
    case tooHigh = "too_high"
    case tooLow = "too_low"
    
    public var displayName: String {
        switch self {
        case .withinTolerance: return "Innerhalb Toleranz"
        case .tooHigh: return "Zu hoch"
        case .tooLow: return "Zu niedrig"
        }
    }
    
    public var color: String {
        switch self {
        case .withinTolerance: return "green"
        case .tooHigh: return "red"
        case .tooLow: return "orange"
        }
    }
}