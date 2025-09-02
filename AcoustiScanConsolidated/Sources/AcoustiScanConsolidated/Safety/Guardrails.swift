// Guardrails.swift
// Data validation and boundary protection

import Foundation

/// Data validation and boundary protection for acoustic measurements
public struct Guardrails {
    
    /// Clamp SPL values to reasonable physical limits
    public static func clampSPL(_ db: Double, min: Double = -10, max: Double = 130) -> Double {
        guard SafeMath.isValid(db) else { return .nan }
        return Swift.max(min, Swift.min(max, db))
    }
    
    /// Clamp RT60 values to reasonable physical limits (0.1s to 10s)
    public static func clampRT60(_ rt60: Double, min: Double = 0.1, max: Double = 10.0) -> Double {
        guard SafeMath.isValid(rt60) else { return .nan }
        return Swift.max(min, Swift.min(max, rt60))
    }
    
    /// Clamp frequency values to audio range
    public static func clampFrequency(_ freq: Double, min: Double = 20, max: Double = 20000) -> Double {
        guard SafeMath.isValid(freq) else { return .nan }
        return Swift.max(min, Swift.min(max, freq))
    }
    
    /// Return finite value or nil for invalid inputs
    public static func finiteOrNil(_ x: Double?) -> Double? {
        guard let x = x, SafeMath.isValid(x) else { return nil }
        return x
    }
    
    /// Validate absorption coefficient (0.0 to 1.0)
    public static func validateAbsorptionCoefficient(_ alpha: Double) -> Double? {
        guard SafeMath.isValid(alpha) && alpha >= 0.0 && alpha <= 1.0 else { return nil }
        return alpha
    }
    
    /// Validate volume (positive, reasonable architectural limits)
    public static func validateVolume(_ volume: Double, min: Double = 1.0, max: Double = 100000.0) -> Double? {
        guard SafeMath.isValid(volume) && volume >= min && volume <= max else { return nil }
        return volume
    }
    
    /// Validate correlation coefficient (0.0 to 1.0)
    public static func validateCorrelation(_ correlation: Double) -> Double? {
        guard SafeMath.isValid(correlation) && correlation >= 0.0 && correlation <= 1.0 else { return nil }
        return correlation
    }
}