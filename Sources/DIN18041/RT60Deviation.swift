// RT60Deviation.swift
// RT60 deviation analysis against DIN 18041 targets

import Foundation

/// Status der RT60-Bewertung nach DIN 18041
public enum EvaluationStatus: String, CaseIterable {
    case withinTolerance = "within_tolerance"
    case tooHigh = "too_high"
    case tooLow = "too_low"
    
    /// Deutsche Bezeichnung des Status
    public var germanName: String {
        switch self {
        case .withinTolerance:
            return "Innerhalb Toleranz"
        case .tooHigh:
            return "Zu hoch"
        case .tooLow:
            return "Zu niedrig"
        }
    }
    
    /// Emoji-Symbol für visuellen Status
    public var emoji: String {
        switch self {
        case .withinTolerance:
            return "✅"
        case .tooHigh:
            return "🔴"
        case .tooLow:
            return "🔵"
        }
    }
}

/// RT60-Abweichung von DIN 18041 Sollwerten
public struct RT60Deviation {
    public let frequency: Int              // Frequenz in Hz
    public let measuredRT60: Double        // Gemessener RT60-Wert
    public let targetRT60: Double          // Sollwert nach DIN 18041
    public let tolerance: Double           // Zulässige Toleranz
    public let status: EvaluationStatus    // Bewertungsstatus
    
    /// Absolute Abweichung vom Sollwert
    public var absoluteDeviation: Double {
        return abs(measuredRT60 - targetRT60)
    }
    
    /// Relative Abweichung in Prozent
    public var relativeDeviation: Double {
        guard targetRT60 > 0 else { return 0 }
        return (measuredRT60 - targetRT60) / targetRT60 * 100
    }
    
    /// Ist die Messung innerhalb der Toleranz?
    public var isWithinTolerance: Bool {
        return status == .withinTolerance
    }
    
    public init(frequency: Int, measuredRT60: Double, targetRT60: Double, tolerance: Double = 0.1) {
        self.frequency = frequency
        self.measuredRT60 = measuredRT60
        self.targetRT60 = targetRT60
        self.tolerance = tolerance
        
        let deviation = measuredRT60 - targetRT60
        
        if abs(deviation) <= tolerance {
            self.status = .withinTolerance
        } else if deviation > 0 {
            self.status = .tooHigh
        } else {
            self.status = .tooLow
        }
    }
}

extension RT60Deviation: Equatable {
    public static func == (lhs: RT60Deviation, rhs: RT60Deviation) -> Bool {
        return lhs.frequency == rhs.frequency &&
               abs(lhs.measuredRT60 - rhs.measuredRT60) < 0.001 &&
               abs(lhs.targetRT60 - rhs.targetRT60) < 0.001
    }
}

extension RT60Deviation: CustomStringConvertible {
    public var description: String {
        let deviationText = String(format: "%.2f", relativeDeviation)
        return "\(frequency) Hz: \(status.emoji) \(deviationText)% (\(status.germanName))"
    }
}