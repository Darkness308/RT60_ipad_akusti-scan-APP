//  ImpulseResponseAnalyzer.swift
//  AcoustiScan
//
//  Created by Sprint 1 on 29.08.25.
//
//  This file contains a simple implementation of the Schroeder
//  integration method to estimate reverberation time (RT60) from an
//  impulse response.  The algorithm follows the basic steps of the
//  ISO 3382 standard: compute the energy decay curve via reverse
//  cumulative integration of the squared impulse response, convert to
//  decibels, and estimate the slope of the decay between defined
//  limits (e.g. 5–25 dB for T20 or 5–35 dB for T30).  The resulting
//  T20/T30 values are extrapolated to RT60 by multiplying by 3 or 2
//  respectively【473764854244230†L186-L204】.

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

public struct ImpulseResponseAnalyzer {
    /// Compute the Schroeder energy decay curve from an impulse response.
    /// - Parameter ir: The impulse response samples (float)
    /// - Returns: Normalised energy decay curve (0 dB at the start)
    static func energyDecayCurve(ir: [Float]) -> [Float] {
        guard !ir.isEmpty else { return [] }
        // Square the impulse response
        var squared = [Float](repeating: 0, count: ir.count)
        #if canImport(Accelerate)
        vDSP_vsq(ir, 1, &squared, 1, vDSP_Length(ir.count))
        #else
        // Fallback implementation without Accelerate
        for i in 0..<ir.count {
            squared[i] = ir[i] * ir[i]
        }
        #endif
        // Reverse and compute cumulative sum
        let reversed = squared.reversed()
        var cumulative = [Float](repeating: 0, count: reversed.count)
        var sum: Float = 0
        for (i, sample) in reversed.enumerated() {
            sum += sample
            cumulative[i] = sum
        }
        // Reverse back to chronological order
        let energy = cumulative.reversed()
        // Normalise to start at 0 dB (divide by max)
        guard let maxVal = energy.first, maxVal > 0 else { return Array(energy) }
        return energy.map { $0 / maxVal }
    }

    /// Convert a linear energy decay curve to decibels (relative to peak).
    static func decayCurveInDecibels(etc: [Float]) -> [Float] {
        etc.map { value in
            let db = 10 * log10(Double(max(value, .leastNonzeroMagnitude)))
            return Float(db)
        }
    }

    /// Find the time (index) when the decay curve crosses a given level.
    /// - Parameters:
    ///   - dbCurve: The energy decay in decibels (negative values)
    ///   - level: The desired level below 0 dB (e.g. -5, -25, -35)
    /// - Returns: Index into the array or nil if not reached
    static func index(ofLevel level: Float, in dbCurve: [Float]) -> Int? {
        for (i, db) in dbCurve.enumerated() {
            if db <= level {
                return i
            }
        }
        return nil
    }

    /// Estimate T20 using the 5–25 dB decay window.  Returns nil if the
    /// required dynamic range is not achieved.
    static func t20FromDecay(_ dbCurve: [Float], sampleRate: Double) -> Double? {
        guard let start = index(ofLevel: -5.0, in: dbCurve),
              let end = index(ofLevel: -25.0, in: dbCurve),
              end > start else {
            return nil
        }
        let dt = Double(end - start) / sampleRate
        return dt * 3.0
    }

    /// Estimate T30 using the 5–35 dB decay window.  Returns nil if the
    /// required dynamic range is not achieved.
    static func t30FromDecay(_ dbCurve: [Float], sampleRate: Double) -> Double? {
        guard let start = index(ofLevel: -5.0, in: dbCurve),
              let end = index(ofLevel: -35.0, in: dbCurve),
              end > start else {
            return nil
        }
        let dt = Double(end - start) / sampleRate
        return dt * 2.0
    }

    /// Compute RT60 from an impulse response using the best available
    /// method.  Tries T30, falls back to T20 if insufficient dynamic
    /// range.  Returns nil if neither can be calculated.
    static func rt60(ir: [Float], sampleRate: Double) -> Double? {
        let etc = energyDecayCurve(ir: ir)
        let db = decayCurveInDecibels(etc: etc)
        // Attempt T30 first (requires >35 dB decay)
        if let t30 = t30FromDecay(db, sampleRate: sampleRate) {
            return t30
        }
        // Fall back to T20
        if let t20 = t20FromDecay(db, sampleRate: sampleRate) {
            return t20
        }
        return nil
    }
}
