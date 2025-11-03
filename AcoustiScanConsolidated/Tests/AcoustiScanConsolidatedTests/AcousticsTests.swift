// AcousticsTests.swift
// Unit tests for the ImpulseResponseAnalyzer in the Acoustics module

import XCTest
import Foundation
@testable import AcoustiScanConsolidated

/// Test suite for Impulse Response Analysis and RT60 calculations
final class AcousticsTests: XCTestCase {
    
    // MARK: - Energy Decay Curve Tests
    
    func testEnergyDecayCurveSimpleImpulse() throws {
        // Create a simple exponentially decaying impulse response
        let length = 1000
        let decay = Float(0.999) // Decay factor per sample
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let energyCurve = try ImpulseResponseAnalyzer.energyDecayCurve(ir: impulse)
        
        XCTAssertEqual(energyCurve.count, length)
        XCTAssertEqual(energyCurve.first, 1.0) // Normalized to start at 1.0
        XCTAssertTrue((energyCurve.last ?? 0) > 0) // Should not be zero
        
        // Energy curve should be monotonically decreasing
        for i in 1..<energyCurve.count {
            XCTAssertTrue(energyCurve[i] <= energyCurve[i-1])
        }
    }
    
    func testEnergyDecayCurveEmptyInput() {
        XCTAssertThrowsError(try ImpulseResponseAnalyzer.energyDecayCurve(ir: []))
    }
    
    func testEnergyDecayCurveInsufficientData() {
        XCTAssertThrowsError(try ImpulseResponseAnalyzer.energyDecayCurve(ir: [1.0]))
    }
    
    func testEnergyDecayCurveKnownValues() throws {
        // Simple test case with known values
        let impulse: [Float] = [1.0, 0.8, 0.6, 0.4, 0.2]
        let energyCurve = try ImpulseResponseAnalyzer.energyDecayCurve(ir: impulse)
        
        XCTAssertEqual(energyCurve.count, 5)
        XCTAssertEqual(energyCurve.first, 1.0) // Normalized
        
        // Verify monotonic decrease
        XCTAssertTrue(energyCurve[1] < energyCurve[0])
        XCTAssertTrue(energyCurve[2] < energyCurve[1])
        XCTAssertTrue(energyCurve[3] < energyCurve[2])
        XCTAssertTrue(energyCurve[4] < energyCurve[3])
    }
    
    // MARK: - Decibel Conversion Tests
    
    func testDecayCurveInDecibels() {
        let linearCurve: [Float] = [1.0, 0.5, 0.25, 0.125, 0.0625]
        let dbCurve = ImpulseResponseAnalyzer.decayCurveInDecibels(etc: linearCurve)
        
        XCTAssertEqual(dbCurve.count, 5)
        XCTAssertEqual(dbCurve[0], 0.0, accuracy: 0.001) // 1.0 -> 0 dB
        XCTAssertEqual(dbCurve[1], -3.0, accuracy: 0.1) // 0.5 -> ~-3 dB
        XCTAssertEqual(dbCurve[2], -6.0, accuracy: 0.1) // 0.25 -> ~-6 dB
        XCTAssertEqual(dbCurve[3], -9.0, accuracy: 0.1) // 0.125 -> ~-9 dB
        XCTAssertEqual(dbCurve[4], -12.0, accuracy: 0.1) // 0.0625 -> ~-12 dB
    }
    
    func testDecayCurveInDecibelsEmpty() {
        let dbCurve = ImpulseResponseAnalyzer.decayCurveInDecibels(etc: [])
        XCTAssertTrue(dbCurve.isEmpty)
    }
    
    // MARK: - Level Index Finding Tests
    
    func testIndexOfLevel() {
        let dbCurve: [Float] = [0.0, -3.0, -6.0, -9.0, -12.0, -15.0, -18.0, -21.0, -24.0, -27.0, -30.0]
        
        let index5dB = ImpulseResponseAnalyzer.index(ofLevel: -5.0, in: dbCurve)
        let index25dB = ImpulseResponseAnalyzer.index(ofLevel: -25.0, in: dbCurve)
        let index35dB = ImpulseResponseAnalyzer.index(ofLevel: -35.0, in: dbCurve)
        
        XCTAssertEqual(index5dB, 2) // -6 dB is the first to reach or exceed -5 dB
        XCTAssertEqual(index25dB, 9) // -27 dB is the first to reach or exceed -25 dB
        XCTAssertNil(index35dB) // -35 dB is not reached
    }
    
    func testIndexOfLevelEmpty() {
        let index = ImpulseResponseAnalyzer.index(ofLevel: -5.0, in: [])
        XCTAssertNil(index)
    }
    
    // MARK: - T20 Calculation Tests
    
    func testT20FromDecay() {
        // Create a decay curve that goes from 0 to -30 dB linearly
        let dbCurve = (0...300).map { Float($0) * -0.1 } // 0 to -30 dB in 301 samples
        let sampleRate = 44100.0
        
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: sampleRate)
        
        XCTAssertNotNil(t20)
        if let t20Value = t20 {
            // Should be approximately (200 samples / 44100 Hz) * 3
            let expectedDuration = (200.0 / sampleRate) * 3.0
            XCTAssertEqual(t20Value, expectedDuration, accuracy: 0.001)
        }
    }
    
    func testT20FromDecayInsufficient() {
        // Decay curve that only goes to -10 dB (insufficient for T20)
        let dbCurve = (0...100).map { Float($0) * -0.1 } // 0 to -10 dB
        let sampleRate = 44100.0
        
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: sampleRate)
        XCTAssertNil(t20)
    }
    
    func testT20FromDecayInvalidSampleRate() {
        let dbCurve: [Float] = [0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -30.0]
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: 0.0)
        XCTAssertNil(t20)
    }
    
    // MARK: - T30 Calculation Tests
    
    func testT30FromDecay() {
        // Create a decay curve that goes from 0 to -40 dB linearly
        let dbCurve = (0...400).map { Float($0) * -0.1 } // 0 to -40 dB in 401 samples
        let sampleRate = 44100.0
        
        let t30 = ImpulseResponseAnalyzer.t30FromDecay(dbCurve, sampleRate: sampleRate)
        
        XCTAssertNotNil(t30)
        if let t30Value = t30 {
            // Should be approximately (300 samples / 44100 Hz) * 2
            let expectedDuration = (300.0 / sampleRate) * 2.0
            XCTAssertEqual(t30Value, expectedDuration, accuracy: 0.001)
        }
    }
    
    func testT30FromDecayInsufficient() {
        // Decay curve that only goes to -20 dB (insufficient for T30)
        let dbCurve = (0...200).map { Float($0) * -0.1 } // 0 to -20 dB
        let sampleRate = 44100.0
        
        let t30 = ImpulseResponseAnalyzer.t30FromDecay(dbCurve, sampleRate: sampleRate)
        XCTAssertNil(t30)
    }
    
    // MARK: - RT60 Calculation Tests
    
    func testRT60UsingT30() throws {
        // Create impulse response that decays sufficiently for T30
        let length = 5000
        let decay = Float(0.9995) // Strong decay
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        
        XCTAssertNotNil(rt60)
        if let rt60Value = rt60 {
            // RT60 should be positive and reasonable (0.1 to 10 seconds)
            XCTAssertTrue(rt60Value > 0.0)
            XCTAssertTrue(rt60Value < 10.0)
        }
    }
    
    func testRT60UsingT20Fallback() throws {
        // Create impulse response that decays enough for T20 but not T30
        let length = 2000
        let decay = Float(0.999) // Moderate decay
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        
        XCTAssertNotNil(rt60)
        if let rt60Value = rt60 {
            XCTAssertTrue(rt60Value > 0.0)
            XCTAssertTrue(rt60Value < 10.0)
        }
    }
    
    func testRT60InsufficientDecay() throws {
        // Create impulse response with minimal decay - constant values should not produce valid RT60
        let impulse: [Float] = Array(repeating: 1.0, count: 100) // Very short, no decay
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        XCTAssertNil(rt60)
    }
    
    func testRT60InvalidSampleRate() {
        let impulse: [Float] = [1.0, 0.5, 0.25]
        
        XCTAssertThrowsError(try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 0.0))
copilot/fix-acoustics-tests-import-error
        

main
        XCTAssertThrowsError(try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: -44100.0))
    }
    
    // MARK: - Correlation Tests
    
    func testCalculateCorrelationLinearDecay() {
        // Create perfectly linear decay
        let dbCurve = (0...100).map { Float($0) * -0.2 } // Linear decay
        
        let correlation = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 10,
            endIndex: 90
        )
        
        // Perfect linear correlation should be close to 1.0
        XCTAssertTrue(correlation > 0.99)
    }
    
    func testCalculateCorrelationInvalidIndices() {
        let dbCurve: [Float] = [0.0, -1.0, -2.0, -3.0, -4.0]
        
        // End index before start index
        let correlation1 = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 3,
            endIndex: 1
        )
        XCTAssertEqual(correlation1, 0.0)
        
        // Index out of bounds
        let correlation2 = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 1,
            endIndex: 10
        )
        XCTAssertEqual(correlation2, 0.0)
    }
    
    // MARK: - Integration Tests with Known Values
    
    func testKnownRT60Value() throws {
        // Create a theoretical impulse response for a room with known RT60
        // Using exponential decay: e^(-6.91t/RT60) where RT60 = 1.0 second
        let expectedRT60 = 1.0
        let sampleRate = 44100.0
        let length = Int(sampleRate * 3) // 3 seconds of samples
        
        let impulse = (0..<length).map { i in
            let t = Double(i) / sampleRate
            return Float(exp(-6.91 * t / expectedRT60))
        }
        
        let calculatedRT60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: sampleRate)
        
        XCTAssertNotNil(calculatedRT60)
        if let rt60Value = calculatedRT60 {
            // Allow 10% tolerance for numerical approximation
            let tolerance = expectedRT60 * 0.1
            XCTAssertEqual(rt60Value, expectedRT60, accuracy: tolerance)
        }
    }
    
    func testRT60QualityWithCorrelation() throws {
        // Create impulse response with good linear decay characteristics
        let sampleRate = 44100.0
        let length = Int(sampleRate * 2)
        let targetRT60 = 0.8
        
        let impulse = (0..<length).map { i in
            let t = Double(i) / sampleRate
            return Float(exp(-6.91 * t / targetRT60))
        }
        
        // Calculate energy decay curve and convert to dB
        let energyCurve = try ImpulseResponseAnalyzer.energyDecayCurve(ir: impulse)
        let dbCurve = ImpulseResponseAnalyzer.decayCurveInDecibels(etc: energyCurve)
        
        // Find indices for correlation check
        guard let startIndex = ImpulseResponseAnalyzer.index(ofLevel: -5.0, in: dbCurve),
              let endIndex = ImpulseResponseAnalyzer.index(ofLevel: -25.0, in: dbCurve) else {
            XCTFail("Failed to find required decay levels")
            return
        }
        
        let correlation = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: startIndex,
            endIndex: endIndex
        )
        
        // According to ISO 3382-1, correlation should be >= 0.95
copilot/fix-acoustics-tests-import-error
        XCTAssertGreaterThanOrEqual(correlation, 0.95, "Correlation \(correlation) is below ISO 3382-1 threshold of 0.95")

        XCTAssertTrue(correlation >= 0.95, "Correlation \(correlation) is below ISO 3382-1 threshold of 0.95")
main
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testExtremeDecayValues() throws {
        // Test with very rapid decay
        let rapidDecay: [Float] = [1.0, 0.1, 0.01, 0.001, 0.0001]
        let rt60Rapid = try ImpulseResponseAnalyzer.rt60(ir: rapidDecay, sampleRate: 44100.0)
        XCTAssertNotNil(rt60Rapid) // Should handle rapid decay
        
        // Test with very slow decay (constant values) - make it shorter so no decay is possible
        let slowDecay: [Float] = Array(repeating: 1.0, count: 50) // Very short constant signal
        let rt60Slow = try ImpulseResponseAnalyzer.rt60(ir: slowDecay, sampleRate: 44100.0)
        XCTAssertNil(rt60Slow) // Should return nil for insufficient decay
    }
}