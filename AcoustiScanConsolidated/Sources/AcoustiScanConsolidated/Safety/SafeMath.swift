// SafeMath.swift
// Safe mathematical operations with NaN/Inf protection

import Foundation

/// Safe mathematical operations to prevent NaN and infinite values
public enum SafeMath {
    
    /// Safe logarithm base 10 with epsilon protection
    @inline(__always) 
    public static func safeLog10(_ x: Double, eps: Double = 1e-12) -> Double {
        guard x.isFinite else { return .nan }
        let v = max(x, eps)
        return log10(v)
    }
    
    /// Safe natural logarithm with epsilon protection
    @inline(__always)
    public static func safeLn(_ x: Double, eps: Double = 1e-12) -> Double {
        guard x.isFinite else { return .nan }
        let v = max(x, eps)
        return log(v)
    }
    
    /// Safe mean calculation excluding invalid values
    @inline(__always) 
    public static func mean(_ xs: [Double]) -> Double? {
        let validValues = xs.filter { isValid($0) }
        guard !validValues.isEmpty else { return nil }
        return validValues.reduce(0, +) / Double(validValues.count)
    }
    
    /// Check if a double value is valid (finite and not NaN)
    @inline(__always) 
    public static func isValid(_ x: Double?) -> Bool {
        guard let x = x else { return false }
        return x.isFinite && !x.isNaN
    }
    
    /// Safe division with zero protection
    @inline(__always)
    public static func safeDivision(_ numerator: Double, _ denominator: Double, eps: Double = 1e-12) -> Double {
        guard isValid(numerator) && isValid(denominator) else { return .nan }
        let safeDenominator = abs(denominator) < eps ? eps : denominator
        return numerator / safeDenominator
    }
    
    /// Safe square root
    @inline(__always)
    public static func safeSqrt(_ x: Double) -> Double {
        guard isValid(x) && x >= 0 else { return .nan }
        return sqrt(x)
    }
}