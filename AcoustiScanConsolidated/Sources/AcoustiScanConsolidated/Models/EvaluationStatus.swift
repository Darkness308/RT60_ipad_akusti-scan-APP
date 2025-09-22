// EvaluationStatus.swift
// DIN 18041 evaluation status types

import Foundation

public enum EvaluationStatus: String, CaseIterable {
    case withinTolerance = "within_tolerance"
    case tooHigh = "too_high"
    case tooLow = "too_low"
    case partiallyCompliant = "partially_compliant"
    
    public var displayName: String {
        switch self {
        case .withinTolerance: return "Innerhalb Toleranz"
        case .tooHigh: return "Zu hoch"
        case .tooLow: return "Zu niedrig"
        case .partiallyCompliant: return "Teilweise konform"
        }
    }
    
    public var color: String {
        switch self {
        case .withinTolerance: return "green"
        case .tooHigh: return "red"
        case .tooLow: return "orange"
        case .partiallyCompliant: return "yellow"
        }
    }
}