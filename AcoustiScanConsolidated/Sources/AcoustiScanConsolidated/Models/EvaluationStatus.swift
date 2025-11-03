// EvaluationStatus.swift
// Data model for RT60 evaluation status

import Foundation

/// Status indicating how measured RT60 values compare to DIN 18041 targets
///
/// This enumeration represents the compliance status of RT60 measurements
/// against DIN 18041 standard tolerances for different room types.
public enum EvaluationStatus: String, CaseIterable, Codable {
    
    /// RT60 value is within acceptable tolerance range
    case withinTolerance = "within_tolerance"
    
    /// RT60 value exceeds the upper tolerance limit (room too reverberant)
    case tooHigh = "too_high"
    
    /// RT60 value is below the lower tolerance limit (room too dry)
    case tooLow = "too_low"
    
    /// Partially compliant - some frequencies meet standards
    case partiallyCompliant = "partially_compliant"
    
    /// Human-readable description of the status
    public var displayName: String {
        switch self {
        case .withinTolerance:
            return "Erfüllt"
        case .tooHigh:
            return "Überschritten"
        case .tooLow:
            return "Unterschritten"
        case .partiallyCompliant:
            return "Teilweise konform"
        }
    }
    
    /// Color indication for UI display
    public var isCompliant: Bool {
        return self == .withinTolerance
    }
    
    /// Color code for visual representation
    public var color: String {
        switch self {
        case .withinTolerance:
            return "green"
        case .tooHigh:
            return "red"
        case .tooLow:
            return "orange"
        case .partiallyCompliant:
            return "yellow"
        }
    }
}
