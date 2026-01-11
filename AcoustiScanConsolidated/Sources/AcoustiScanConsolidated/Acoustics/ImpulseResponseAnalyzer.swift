//  ImpulseResponseAnalyzer.swift
//  AcoustiScan
//
//  Created by Sprint 1 on 29.08.25.
//
//  This file contains a simple implementation of the Schroeder
//  integration method to estimate reverberation time (RT60) from an
//  impulse response.  The algorithm follows the basic steps of the
//  ISO 3382 standard: compute the energy decay curve via reverse
//  cumulative integration of the squared impulse response, convert to
//  decibels, and estimate the slope of the decay between defined
//  limits (e.g. 5-25 dB for T20 or 5-35 dB for T30).  The resulting
//  T20/T30 values are extrapolated to RT60 by multiplying by 3 or 2
//  respectively[473764854244230+L186-L204].

import Foundation

public struct ImpulseResponseAnalyzer {
    /// Simple logging utility for debugging
    private static func log(_ level: String, _ message: String) {
        print("[\(level)] ImpulseResponseAnalyzer: \(message)")
    }

    private static func logError(_ message: String) { log("ERROR", message) }
    private static func logWarning(_ message: String) { log("WARNING", message) }
    private static func logInfo(_ message: String) { log("INFO", message) }
    private static func logDebug(_ message: String) { log("DEBUG", message) }

    /// Error types for impulse response analysis
    public enum AnalysisError: Error {
        case emptyInput
        case insufficientData(String)
        case invalidSampleRate(Double)
        case noValidDecay(String)

        var localizedDescription: String {
            switch self {
            case .emptyInput:
                return "Empty impulse response provided"
            case .insufficientData(let details):
                return "Insufficient data for analysis: \(details)"
            case .invalidSampleRate(let rate):
                return "Invalid sample rate: \(rate)"
            case .noValidDecay(let details):
                return "No valid decay curve found: \(details)"
            }
        }
    }
    /// Compute the Schroeder energy decay curve from an impulse response.
    /// - Parameter ir: The impulse response samples (float)
    /// - Returns: Normalised energy decay curve (0 dB at the start)
    /// - Throws: AnalysisError if input is invalid
    public static func energyDecayCurve(ir: [Float]) throws -> [Float] {
        guard !ir.isEmpty else {
            logError("Empty impulse response provided for energy decay calculation")
            throw AnalysisError.emptyInput
        }

        guard ir.count > 1 else {
            logError("Insufficient impulse response data: \(ir.count) samples")
            throw AnalysisError.insufficientData("Need at least 2 samples, got \(ir.count)")
        }

        // Square the impulse response using standard Swift
        let squared = ir.map { $0 * $0 }

        // Reverse and compute cumulative sum
        let reversed = squared.reversed()
        var cumulative = [Float](repeating: 0, count: reversed.count)
        var sum: Float = 0
        for (i, sample) in reversed.enumerated() {
            sum += sample
            cumulative[i] = sum
        }

        // Reverse back to chronological order
        let energy = Array(cumulative.reversed())

        // Normalise to start at 0 dB (divide by max)
        guard let maxVal = energy.first, maxVal > 0 else {
            logWarning("Energy curve has zero or negative maximum value")
            return energy
        }

        let normalized = energy.map { $0 / maxVal }
        logDebug("Successfully computed energy decay curve with \(normalized.count) samples")
        return normalized
    }

    /// Convert a linear energy decay curve to decibels (relative to peak).
    /// - Parameter etc: Linear energy decay curve values
    /// - Returns: Energy decay curve in decibels
    public static func decayCurveInDecibels(etc: [Float]) -> [Float] {
        guard !etc.isEmpty else {
            logWarning("Empty energy decay curve provided for dB conversion")
            return []
        }

        return etc.map { value in
            let clampedValue = max(value, .leastNonzeroMagnitude)
            let db = 10 * log10(Double(clampedValue))
            return Float(db)
        }
    }

    /// Find the time (index) when the decay curve crosses a given level.
    /// - Parameters:
    ///   - dbCurve: The energy decay in decibels (negative values)
    ///   - level: The desired level below 0 dB (e.g. -5, -25, -35)
    /// - Returns: Index into the array or nil if not reached
    public static func index(ofLevel level: Float, in dbCurve: [Float]) -> Int? {
        guard !dbCurve.isEmpty else {
            logWarning("Empty dB curve provided for level search")
            return nil
        }

        for (i, db) in dbCurve.enumerated() {
            if db <= level {
                logDebug("Found level \(level) dB at index \(i)")
                return i
            }
        }

        logDebug("Level \(level) dB not reached in decay curve")
        return nil
    }

    /// Estimate T20 using the 5-25 dB decay window.  Returns nil if the
    /// required dynamic range is not achieved.
    /// - Parameters:
    ///   - dbCurve: Energy decay curve in decibels
    ///   - sampleRate: Audio sample rate in Hz
    /// - Returns: T20 value in seconds, or nil if insufficient decay
    public static func t20FromDecay(_ dbCurve: [Float], sampleRate: Double) -> Double? {
        guard sampleRate > 0 else {
            logError("Invalid sample rate for T20 calculation: \(sampleRate)")
            return nil
        }

        guard let start = index(ofLevel: -5.0, in: dbCurve),
              let end = index(ofLevel: -25.0, in: dbCurve),
              end > start else {
            logWarning("Insufficient dynamic range for T20 calculation (need 5-25 dB decay)")
            return nil
        }

        let dt = Double(end - start) / sampleRate
        let t20 = dt * 3.0

        logDebug("T20 calculated: \(t20)s from \(end - start) samples at \(sampleRate) Hz")
        return t20
    }

    /// Estimate T30 using the 5-35 dB decay window.  Returns nil if the
    /// required dynamic range is not achieved.
    /// - Parameters:
    ///   - dbCurve: Energy decay curve in decibels
    ///   - sampleRate: Audio sample rate in Hz
    /// - Returns: T30 value in seconds, or nil if insufficient decay
    public static func t30FromDecay(_ dbCurve: [Float], sampleRate: Double) -> Double? {
        guard sampleRate > 0 else {
            logError("Invalid sample rate for T30 calculation: \(sampleRate)")
            return nil
        }

        guard let start = index(ofLevel: -5.0, in: dbCurve),
              let end = index(ofLevel: -35.0, in: dbCurve),
              end > start else {
            logWarning("Insufficient dynamic range for T30 calculation (need 5-35 dB decay)")
            return nil
        }

        let dt = Double(end - start) / sampleRate
        let t30 = dt * 2.0

        logDebug("T30 calculated: \(t30)s from \(end - start) samples at \(sampleRate) Hz")
        return t30
    }

    /// Compute RT60 from an impulse response using the best available
    /// method.  Tries T30, falls back to T20 if insufficient dynamic
    /// range.  Returns nil if neither can be calculated.
    /// - Parameters:
    ///   - ir: Impulse response samples
    ///   - sampleRate: Audio sample rate in Hz
    /// - Returns: RT60 value in seconds, or nil if calculation fails
    /// - Throws: AnalysisError for invalid input parameters
    public static func rt60(ir: [Float], sampleRate: Double) throws -> Double? {
        guard sampleRate > 0 else {
            logError("Invalid sample rate for RT60 calculation: \(sampleRate)")
            throw AnalysisError.invalidSampleRate(sampleRate)
        }

        let etc = try energyDecayCurve(ir: ir)
        let db = decayCurveInDecibels(etc: etc)

        // Attempt T30 first (requires >35 dB decay)
        if let t30 = t30FromDecay(db, sampleRate: sampleRate) {
            logInfo("RT60 calculated using T30 method: \(t30)s")
            return t30
        }

        // Fall back to T20
        if let t20 = t20FromDecay(db, sampleRate: sampleRate) {
            logInfo("RT60 calculated using T20 method: \(t20)s")
            return t20
        }

        logWarning("No valid RT60 calculation possible - insufficient decay range")
        return nil
    }

    /// Calculate correlation coefficient for linear regression on decay curve
    /// to validate measurement quality according to ISO 3382-1
    /// - Parameters:
    ///   - dbCurve: Energy decay curve in decibels
    ///   - startIndex: Start index for linear regression
    ///   - endIndex: End index for linear regression
    /// - Returns: Correlation coefficient (0.0 to 1.0)
    public static func calculateCorrelation(dbCurve: [Float], startIndex: Int, endIndex: Int) -> Double {
        guard startIndex < endIndex && endIndex < dbCurve.count else {
            logWarning("Invalid indices for correlation calculation")
            return 0.0
        }

        let segment = Array(dbCurve[startIndex...endIndex])
        let n = Double(segment.count)

        guard n > 1 else { return 0.0 }

        let xValues = Array(0..<segment.count).map(Double.init)
        let yValues = segment.map(Double.init)

        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        let sumY2 = yValues.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0.0 }

        let correlation = abs(numerator / denominator)
        logDebug("Correlation calculated: \(correlation) for decay segment")
        return correlation
    }
}
