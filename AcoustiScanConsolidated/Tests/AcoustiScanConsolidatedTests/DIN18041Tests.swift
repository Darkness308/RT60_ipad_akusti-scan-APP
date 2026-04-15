// DIN18041Tests.swift
// Comprehensive test suite for DIN 18041 module

import XCTest
import Foundation
@testable import AcoustiScanConsolidated

/// Comprehensive test suite for DIN 18041 compliance evaluation
final class DIN18041ModuleTests: XCTestCase {
    
    // MARK: - DIN18041Database Tests
    
    func testClassroomTargets() {
        let volume = 200.0
        let targets = DIN18041Database.targets(for: .classroom, volume: volume)
        
        XCTAssertEqual(targets.count, 7) // 7 frequency bands
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance > 0 })
        
        // Check that 500-1000 Hz has reasonable values for classroom
        let midFreqTargets = targets.filter { $0.frequency == 500 || $0.frequency == 1000 }
        XCTAssertTrue(midFreqTargets.allSatisfy { $0.targetRT60 <= 0.8 }) // Should be relatively low for speech
        
        // Verify frequency-dependent adjustments
        let lowFreq = targets.first { $0.frequency == 125 }!
        let midFreq = targets.first { $0.frequency == 1000 }!
        let highFreq = targets.first { $0.frequency == 4000 }!
        
        XCTAssertTrue(lowFreq.targetRT60 > midFreq.targetRT60) // Low frequencies should have higher RT60
        XCTAssertTrue(highFreq.targetRT60 < midFreq.targetRT60) // High frequencies should have lower RT60
    }
    
    func testOfficeSpaceTargets() {
        let volume = 120.0
        let targets = DIN18041Database.targets(for: .officeSpace, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Volume-adjusted targets are near 0.5s; speech frequencies (500-2000 Hz) use a 0.95 factor
        let nonSpeechLow = targets.first { $0.frequency == 125 }!
        let speech500 = targets.first { $0.frequency == 500 }!
        let speech1000 = targets.first { $0.frequency == 1000 }!
        let speech2000 = targets.first { $0.frequency == 2000 }!
        let nonSpeechHigh = targets.first { $0.frequency == 4000 }!
        
        XCTAssertEqual(nonSpeechLow.targetRT60, 0.5, accuracy: 0.001)
        XCTAssertEqual(nonSpeechHigh.targetRT60, 0.5, accuracy: 0.001)
        XCTAssertEqual(speech500.targetRT60, 0.5 * 0.95, accuracy: 0.001)
        XCTAssertEqual(speech1000.targetRT60, 0.5 * 0.95, accuracy: 0.001)
        XCTAssertEqual(speech2000.targetRT60, 0.5 * 0.95, accuracy: 0.001)
        
        XCTAssertTrue(speech500.targetRT60 < nonSpeechLow.targetRT60)
        XCTAssertTrue(speech1000.targetRT60 < nonSpeechLow.targetRT60)
        XCTAssertTrue(speech2000.targetRT60 < nonSpeechHigh.targetRT60)
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.1 })
    }
    
    func testConferenceRoomTargets() {
        let volume = 300.0
        let targets = DIN18041Database.targets(for: .conference, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Volume-adjusted targets (300m³) are near 0.7s; speech frequencies (500-4000 Hz) use a 0.9 factor
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0.6 && $0.targetRT60 < 0.9 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.15 })
    }
    
    func testLectureHallTargets() {
        let volume = 500.0
        let targets = DIN18041Database.targets(for: .lecture, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Volume-adjusted targets (500m³) are near 0.8s; frequency-dependent adjustments apply
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0.75 && $0.targetRT60 < 1.15 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.15 })
        
        // Verify the expected DIN 18041 frequency shaping:
        // low frequencies (<=250 Hz) should be higher than mid-band,
        // while high frequencies (>=4000 Hz) should be lower than mid-band.
        let midBandTarget = targets[3].targetRT60 // 1000 Hz in the 7-band sequence
        XCTAssertGreaterThan(targets[0].targetRT60, midBandTarget) // 125 Hz > 1000 Hz
        XCTAssertGreaterThan(targets[1].targetRT60, midBandTarget) // 250 Hz > 1000 Hz
        XCTAssertLessThan(targets[5].targetRT60, midBandTarget)    // 4000 Hz < 1000 Hz
        XCTAssertLessThan(targets[6].targetRT60, midBandTarget)    // 8000 Hz < 1000 Hz
    }
    
    func testMusicRoomTargets() {
        let volume = 400.0
        let targets = DIN18041Database.targets(for: .music, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.2 })
        
        let targetsByFrequency = Dictionary(uniqueKeysWithValues: targets.map { ($0.frequency, $0) })
        
        guard
            let rt125 = targetsByFrequency[125]?.targetRT60,
            let rt1000 = targetsByFrequency[1000]?.targetRT60,
            let rt4000 = targetsByFrequency[4000]?.targetRT60
        else {
            XCTFail("Music room targets missing representative frequencies")
            return
        }
        
        // Volume-adjusted targets (400m³) are around 1.95s at 1000 Hz with
        // low-frequency boost and high-frequency reduction applied.
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 >= 1.5 && $0.targetRT60 < 2.5 }) // Music rooms need longer reverberation
        XCTAssertGreaterThan(rt125, rt1000, "125 Hz should be boosted relative to 1000 Hz")
        XCTAssertLessThan(rt4000, rt1000, "4000 Hz should be reduced relative to 1000 Hz")
        
        XCTAssertEqual(rt1000, 1.95, accuracy: 0.1)
        XCTAssertEqual(rt125, 2.15, accuracy: 0.1)
        XCTAssertEqual(rt4000, 1.75, accuracy: 0.1)
    }
    
    func testSportsHallTargets() {
        let volume = 2000.0
        let targets = DIN18041Database.targets(for: .sports, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Volume-adjusted targets (2000m³) are significantly above base 2.0s due to volume scaling
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 2.3 && $0.targetRT60 < 3.2 }) // Sports halls can have highest RT60
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.3 })
    }
    
    func testFrequencyCoverage() {
        let expectedFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
        
        for roomType in RoomType.allCases {
            let targets = DIN18041Database.targets(for: roomType, volume: 300.0)
            let frequencies = targets.map { $0.frequency }.sorted()
            XCTAssertEqual(frequencies, expectedFrequencies, "Room type \(roomType) missing frequencies")
        }
    }
    
    // MARK: - RT60Evaluator Tests
    
    func testCompliantEvaluation() {
        let measurements = [
            RT60Measurement(frequency: 500, rt60: 0.60),
            RT60Measurement(frequency: 1000, rt60: 0.55),
            RT60Measurement(frequency: 2000, rt60: 0.52)
        ]
        
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )
        
        XCTAssertEqual(deviations.count, 3)
        XCTAssertTrue(deviations.allSatisfy { $0.status == .withinTolerance })
        XCTAssertTrue(deviations.allSatisfy { abs($0.deviation) <= 0.1 })
    }
    
    func testTooHighEvaluation() {
        let measurements = [
            RT60Measurement(frequency: 500, rt60: 0.80), // Target ~0.6, tolerance 0.1
            RT60Measurement(frequency: 1000, rt60: 0.75),
            RT60Measurement(frequency: 2000, rt60: 0.70)
        ]
        
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )
        
        XCTAssertEqual(deviations.count, 3)
        XCTAssertTrue(deviations.allSatisfy { $0.status == .tooHigh })
        XCTAssertTrue(deviations.allSatisfy { $0.deviation > 0.1 })
    }
    
    func testTooLowEvaluation() {
        let measurements = [
            RT60Measurement(frequency: 500, rt60: 0.40), // Target ~0.6, tolerance 0.1
            RT60Measurement(frequency: 1000, rt60: 0.35),
            RT60Measurement(frequency: 2000, rt60: 0.30)
        ]
        
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )
        
        XCTAssertEqual(deviations.count, 3)
        XCTAssertTrue(deviations.allSatisfy { $0.status == .tooLow })
        XCTAssertTrue(deviations.allSatisfy { $0.deviation < -0.1 })
    }
    
    func testRT60Classification() {
        let target = 0.6
        let tolerance = 0.1
        
        // Within tolerance
        XCTAssertEqual(RT60Evaluator.classifyRT60(measured: 0.60, target: target, tolerance: tolerance), .withinTolerance)
        XCTAssertEqual(RT60Evaluator.classifyRT60(measured: 0.65, target: target, tolerance: tolerance), .withinTolerance)
        XCTAssertEqual(RT60Evaluator.classifyRT60(measured: 0.55, target: target, tolerance: tolerance), .withinTolerance)
        
        // Too high
        XCTAssertEqual(RT60Evaluator.classifyRT60(measured: 0.75, target: target, tolerance: tolerance), .tooHigh)
        
        // Too low
        XCTAssertEqual(RT60Evaluator.classifyRT60(measured: 0.45, target: target, tolerance: tolerance), .tooLow)
    }
    
    func testOverallCompliance() {
        // All compliant
        let allCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.60, targetRT60: 0.60, status: .withinTolerance),
            RT60Deviation(frequency: 1000, measuredRT60: 0.55, targetRT60: 0.60, status: .withinTolerance)
        ]
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: allCompliant), .withinTolerance)
        
        // Partially compliant (less than half non-compliant)
        let partiallyCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.60, targetRT60: 0.60, status: .withinTolerance),
            RT60Deviation(frequency: 1000, measuredRT60: 0.80, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 2000, measuredRT60: 0.55, targetRT60: 0.48, status: .withinTolerance)
        ]
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: partiallyCompliant), .partiallyCompliant)
        
        // Non-compliant (more than half non-compliant)
        let nonCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.80, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 1000, measuredRT60: 0.85, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 2000, measuredRT60: 0.55, targetRT60: 0.48, status: .withinTolerance)
        ]
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: nonCompliant), .tooHigh)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() {
        let volumes = [150.0, 300.0, 500.0]
        let roomTypes: [RoomType] = [.classroom, .officeSpace, .conference, .lecture, .music, .sports]
        
        for roomType in roomTypes {
            for volume in volumes {
                let targets = DIN18041Database.targets(for: roomType, volume: volume)
                
                // Create test measurements that should be within tolerance
                let measurements = targets.map { target in
                    RT60Measurement(frequency: target.frequency, rt60: target.targetRT60)
                }
                
                let deviations = RT60Evaluator.evaluateDINCompliance(
                    measurements: measurements,
                    roomType: roomType,
                    volume: volume
                )
                
                XCTAssertEqual(deviations.count, targets.count)
                XCTAssertTrue(deviations.allSatisfy { $0.status == .withinTolerance })
                XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: deviations), .withinTolerance)
            }
        }
    }
    
    func testEmptyMeasurements() {
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [],
            roomType: .classroom,
            volume: 150.0
        )
        
        XCTAssertTrue(deviations.isEmpty)
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: []), .withinTolerance)
    }
    
    func testMismatchedFrequencies() {
        let measurements = [
            RT60Measurement(frequency: 100, rt60: 0.60), // Non-standard frequency
            RT60Measurement(frequency: 500, rt60: 0.60),  // Standard frequency
        ]
        
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .classroom,
            volume: 150.0
        )
        
        XCTAssertEqual(deviations.count, 1) // Only the 500 Hz measurement should be evaluated
        XCTAssertEqual(deviations.first?.frequency, 500)
    }
}