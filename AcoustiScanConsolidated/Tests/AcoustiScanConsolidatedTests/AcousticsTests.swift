// AcousticsTests.swift
// Unit tests for the ImpulseResponseAnalyzer in the Acoustics module

import Testing
import Foundation
@testable import AcoustiScanConsolidated

/// Test suite for Impulse Response Analysis and RT60 calculations
struct AcousticsTests {
    
    // MARK: - Energy Decay Curve Tests
    
    @Test("Energy decay curve from simple impulse")
    func testEnergyDecayCurveSimpleImpulse() throws {
        // Create a simple exponentially decaying impulse response
        let length = 1000
        let decay = Float(0.999) // Decay factor per sample
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let energyCurve = try ImpulseResponseAnalyzer.energyDecayCurve(ir: impulse)
        
        #expect(energyCurve.count == length)
        #expect(energyCurve.first == 1.0) // Normalized to start at 1.0
        #expect(energyCurve.last ?? 0 > 0) // Should not be zero
        
        // Energy curve should be monotonically decreasing
        for i in 1..<energyCurve.count {
            #expect(energyCurve[i] <= energyCurve[i-1])
        }
    }
    
    @Test("Energy decay curve with empty input throws error")
    func testEnergyDecayCurveEmptyInput() {
        #expect(throws: (any Error).self) {
            try ImpulseResponseAnalyzer.energyDecayCurve(ir: [])
        }
    }
    
    @Test("Energy decay curve with insufficient data throws error")
    func testEnergyDecayCurveInsufficientData() {
        #expect(throws: (any Error).self) {
            try ImpulseResponseAnalyzer.energyDecayCurve(ir: [1.0])
        }
    }
    
    @Test("Energy decay curve from known values")
    func testEnergyDecayCurveKnownValues() throws {
        // Simple test case with known values
        let impulse: [Float] = [1.0, 0.8, 0.6, 0.4, 0.2]
        let energyCurve = try ImpulseResponseAnalyzer.energyDecayCurve(ir: impulse)
        
        #expect(energyCurve.count == 5)
        #expect(energyCurve.first == 1.0) // Normalized
        
        // Verify monotonic decrease
        #expect(energyCurve[1] < energyCurve[0])
        #expect(energyCurve[2] < energyCurve[1])
        #expect(energyCurve[3] < energyCurve[2])
        #expect(energyCurve[4] < energyCurve[3])
    }
    
    // MARK: - Decibel Conversion Tests
    
    @Test("Decay curve conversion to decibels")
    func testDecayCurveInDecibels() {
        let linearCurve: [Float] = [1.0, 0.5, 0.25, 0.125, 0.0625]
        let dbCurve = ImpulseResponseAnalyzer.decayCurveInDecibels(etc: linearCurve)
        
        #expect(dbCurve.count == 5)
        #expect(abs(dbCurve[0] - 0.0) < 0.001) // 1.0 -> 0 dB
        #expect(abs(dbCurve[1] - (-3.0)) < 0.1) // 0.5 -> ~-3 dB
        #expect(abs(dbCurve[2] - (-6.0)) < 0.1) // 0.25 -> ~-6 dB
        #expect(abs(dbCurve[3] - (-9.0)) < 0.1) // 0.125 -> ~-9 dB
        #expect(abs(dbCurve[4] - (-12.0)) < 0.1) // 0.0625 -> ~-12 dB
    }
    
    @Test("Decibel conversion with empty input")
    func testDecayCurveInDecibelsEmpty() {
        let dbCurve = ImpulseResponseAnalyzer.decayCurveInDecibels(etc: [])
        #expect(dbCurve.isEmpty)
    }
    
    // MARK: - Level Index Finding Tests
    
    @Test("Find level index in decay curve")
    func testIndexOfLevel() {
        let dbCurve: [Float] = [0.0, -3.0, -6.0, -9.0, -12.0, -15.0, -18.0, -21.0, -24.0, -27.0, -30.0]
        
        let index5dB = ImpulseResponseAnalyzer.index(ofLevel: -5.0, in: dbCurve)
        let index25dB = ImpulseResponseAnalyzer.index(ofLevel: -25.0, in: dbCurve)
        let index35dB = ImpulseResponseAnalyzer.index(ofLevel: -35.0, in: dbCurve)
        
        #expect(index5dB == 2) // -6 dB is the first to reach or exceed -5 dB
        #expect(index25dB == 9) // -27 dB is the first to reach or exceed -25 dB
        #expect(index35dB == nil) // -35 dB is not reached
    }
    
    @Test("Find level index with empty curve")
    func testIndexOfLevelEmpty() {
        let index = ImpulseResponseAnalyzer.index(ofLevel: -5.0, in: [])
        #expect(index == nil)
    }
    
    // MARK: - T20 Calculation Tests
    
    @Test("T20 calculation with sufficient decay")
    func testT20FromDecay() {
        // Create a decay curve that goes from 0 to -30 dB linearly
        let dbCurve = (0...300).map { Float($0) * -0.1 } // 0 to -30 dB in 301 samples
        let sampleRate = 44100.0
        
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: sampleRate)
        
        #expect(t20 != nil)
        if let t20Value = t20 {
            // Should be approximately (200 samples / 44100 Hz) * 3
            let expectedDuration = (200.0 / sampleRate) * 3.0
            #expect(abs(t20Value - expectedDuration) < 0.001)
        }
    }
    
    @Test("T20 calculation with insufficient decay")
    func testT20FromDecayInsufficient() {
        // Decay curve that only goes to -10 dB (insufficient for T20)
        let dbCurve = (0...100).map { Float($0) * -0.1 } // 0 to -10 dB
        let sampleRate = 44100.0
        
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: sampleRate)
        #expect(t20 == nil)
    }
    
    @Test("T20 calculation with invalid sample rate")
    func testT20FromDecayInvalidSampleRate() {
        let dbCurve: [Float] = [0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -30.0]
        let t20 = ImpulseResponseAnalyzer.t20FromDecay(dbCurve, sampleRate: 0.0)
        #expect(t20 == nil)
    }
    
    // MARK: - T30 Calculation Tests
    
    @Test("T30 calculation with sufficient decay")
    func testT30FromDecay() {
        // Create a decay curve that goes from 0 to -40 dB linearly
        let dbCurve = (0...400).map { Float($0) * -0.1 } // 0 to -40 dB in 401 samples
        let sampleRate = 44100.0
        
        let t30 = ImpulseResponseAnalyzer.t30FromDecay(dbCurve, sampleRate: sampleRate)
        
        #expect(t30 != nil)
        if let t30Value = t30 {
            // Should be approximately (300 samples / 44100 Hz) * 2
            let expectedDuration = (300.0 / sampleRate) * 2.0
            #expect(abs(t30Value - expectedDuration) < 0.001)
        }
    }
    
    @Test("T30 calculation with insufficient decay")
    func testT30FromDecayInsufficient() {
        // Decay curve that only goes to -20 dB (insufficient for T30)
        let dbCurve = (0...200).map { Float($0) * -0.1 } // 0 to -20 dB
        let sampleRate = 44100.0
        
        let t30 = ImpulseResponseAnalyzer.t30FromDecay(dbCurve, sampleRate: sampleRate)
        #expect(t30 == nil)
    }
    
    // MARK: - RT60 Calculation Tests
    
    @Test("RT60 calculation using T30 method")
    func testRT60UsingT30() throws {
        // Create impulse response that decays sufficiently for T30
        let length = 5000
        let decay = Float(0.9995) // Strong decay
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        
        #expect(rt60 != nil)
        if let rt60Value = rt60 {
            // RT60 should be positive and reasonable (0.1 to 10 seconds)
            #expect(rt60Value > 0.0)
            #expect(rt60Value < 10.0)
        }
    }
    
    @Test("RT60 calculation using T20 fallback")
    func testRT60UsingT20Fallback() throws {
        // Create impulse response that decays enough for T20 but not T30
        let length = 2000
        let decay = Float(0.999) // Moderate decay
        let impulse = (0..<length).map { i in
            pow(decay, Float(i))
        }
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        
        #expect(rt60 != nil)
        if let rt60Value = rt60 {
            #expect(rt60Value > 0.0)
            #expect(rt60Value < 10.0)
        }
    }
    
    @Test("RT60 calculation with insufficient decay")
    func testRT60InsufficientDecay() throws {
        // Create impulse response with minimal decay - constant values should not produce valid RT60
        let impulse: [Float] = Array(repeating: 1.0, count: 100) // Very short, no decay
        
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 44100.0)
        #expect(rt60 == nil)
    }
    
    @Test("RT60 calculation with invalid sample rate throws error")
    func testRT60InvalidSampleRate() {
        let impulse: [Float] = [1.0, 0.5, 0.25]
        
        #expect(throws: (any Error).self) {
            try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: 0.0)
        }
        
        #expect(throws: (any Error).self) {
            try ImpulseResponseAnalyzer.rt60(ir: impulse, sampleRate: -44100.0)
        }
    }
    
    // MARK: - Correlation Tests
    
    @Test("Correlation calculation for linear decay")
    func testCalculateCorrelationLinearDecay() {
        // Create perfectly linear decay
        let dbCurve = (0...100).map { Float($0) * -0.2 } // Linear decay
        
        let correlation = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 10,
            endIndex: 90
        )
        
        // Perfect linear correlation should be close to 1.0
        #expect(correlation > 0.99)
    }
    
    @Test("Correlation calculation with invalid indices")
    func testCalculateCorrelationInvalidIndices() {
        let dbCurve: [Float] = [0.0, -1.0, -2.0, -3.0, -4.0]
        
        // End index before start index
        let correlation1 = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 3,
            endIndex: 1
        )
        #expect(correlation1 == 0.0)
        
        // Index out of bounds
        let correlation2 = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: 1,
            endIndex: 10
        )
        #expect(correlation2 == 0.0)
    }
    
    // MARK: - Integration Tests with Known Values
    
    @Test("End-to-end test with known RT60 value")
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
        
        #expect(calculatedRT60 != nil)
        if let rt60Value = calculatedRT60 {
            // Allow 10% tolerance for numerical approximation
            let tolerance = expectedRT60 * 0.1
            #expect(abs(rt60Value - expectedRT60) < tolerance)
        }
    }
    
    @Test("RT60 quality check with correlation validation")
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
            #expect(Bool(false), "Failed to find required decay levels")
            return
        }
        
        let correlation = ImpulseResponseAnalyzer.calculateCorrelation(
            dbCurve: dbCurve,
            startIndex: startIndex,
            endIndex: endIndex
        )
        
        // According to ISO 3382-1, correlation should be >= 0.95
        #expect(correlation >= 0.95, "Correlation \(correlation) is below ISO 3382-1 threshold of 0.95")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Handle extreme decay values")
    func testExtremeDecayValues() throws {
        // Test with very rapid decay
        let rapidDecay: [Float] = [1.0, 0.1, 0.01, 0.001, 0.0001]
        let rt60Rapid = try ImpulseResponseAnalyzer.rt60(ir: rapidDecay, sampleRate: 44100.0)
        #expect(rt60Rapid != nil) // Should handle rapid decay
        
        // Test with very slow decay (constant values) - make it shorter so no decay is possible
        let slowDecay: [Float] = Array(repeating: 1.0, count: 50) // Very short constant signal
        let rt60Slow = try ImpulseResponseAnalyzer.rt60(ir: slowDecay, sampleRate: 44100.0)
        #expect(rt60Slow == nil) // Should return nil for insufficient decay
    }
}