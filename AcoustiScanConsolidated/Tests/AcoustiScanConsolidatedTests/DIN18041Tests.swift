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
        guard let lowFreq = targets.first(where: { $0.frequency == 125 }) else {
            XCTFail("Expected to find 125 Hz target")
            return
        }
        guard let midFreq = targets.first(where: { $0.frequency == 1000 }) else {
            XCTFail("Expected to find 1000 Hz target")
            return
        }
        guard let highFreq = targets.first(where: { $0.frequency == 4000 }) else {
            XCTFail("Expected to find 4000 Hz target")
            return
        }

        XCTAssertTrue(lowFreq.targetRT60 > midFreq.targetRT60) // Low frequencies should have higher RT60
        XCTAssertTrue(highFreq.targetRT60 < midFreq.targetRT60) // High frequencies should have lower RT60
    }
    
    func testOfficeSpaceTargets() {
        let volume = 120.0
        let targets = DIN18041Database.targets(for: .officeSpace, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Office spaces should have low RT60 values around 0.5s (volume-adjusted)
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0 })
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 < 0.7 }) // Should be relatively low
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.1 })
        
        // Speech frequencies (500-2000 Hz) should have slightly lower RT60
        let speechFreqTargets = targets.filter { $0.frequency >= 500 && $0.frequency <= 2000 }
        let otherFreqTargets = targets.filter { $0.frequency < 500 || $0.frequency > 2000 }
        XCTAssertTrue(speechFreqTargets.allSatisfy { speech in
            otherFreqTargets.allSatisfy { other in speech.targetRT60 <= other.targetRT60 }
        })
    }
    
    func testConferenceRoomTargets() {
        let volume = 300.0
        let targets = DIN18041Database.targets(for: .conference, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Conference rooms have volume-adjusted RT60 around 0.7-0.8 range
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0.65 && $0.targetRT60 < 0.85 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.15 })
        
        // Speech frequencies (500-4000 Hz) should have optimized (lower) RT60
        let speechFreqTargets = targets.filter { $0.frequency >= 500 && $0.frequency <= 4000 }
        let lowFreqTargets = targets.filter { $0.frequency < 500 }
        XCTAssertTrue(speechFreqTargets.allSatisfy { speech in
            lowFreqTargets.allSatisfy { low in speech.targetRT60 < low.targetRT60 }
        })
    }
    
    func testLectureHallTargets() {
        let volume = 500.0
        let targets = DIN18041Database.targets(for: .lecture, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Lecture halls have volume-adjusted RT60 with higher volume scaling
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 0.7 && $0.targetRT60 < 1.2 })
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.15 })
        
        // Low frequencies (≤250 Hz) should have higher RT60 for warmth
        let lowFreqTargets = targets.filter { $0.frequency <= 250 }
        let midFreqTargets = targets.filter { $0.frequency > 250 && $0.frequency < 4000 }
        XCTAssertTrue(lowFreqTargets.allSatisfy { low in
            midFreqTargets.allSatisfy { mid in low.targetRT60 > mid.targetRT60 }
        })
        
        // High frequencies (≥4000 Hz) should have lower RT60 for clarity
        let highFreqTargets = targets.filter { $0.frequency >= 4000 }
        XCTAssertTrue(highFreqTargets.allSatisfy { high in
            midFreqTargets.allSatisfy { mid in high.targetRT60 < mid.targetRT60 }
        })
    }
    
    func testMusicRoomTargets() {
        let volume = 400.0
        let targets = DIN18041Database.targets(for: .music, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Music rooms need longer reverberation around 1.5s (volume-adjusted with frequency variation)
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 1.0 })
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 < 2.5 }) // Should be higher for music
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.2 })
        
        // Low frequencies (125 Hz) should have fuller bass response
        guard let lowFreqTarget = targets.first(where: { $0.frequency == 125 }) else {
            XCTFail("Expected to find 125 Hz target")
            return
        }
        let midFreqTargets = targets.filter { $0.frequency > 125 && $0.frequency < 4000 }
        XCTAssertTrue(midFreqTargets.allSatisfy { mid in lowFreqTarget.targetRT60 > mid.targetRT60 })
        
        // High frequencies (≥4000 Hz) should have controlled brilliance
        let highFreqTargets = targets.filter { $0.frequency >= 4000 }
        XCTAssertTrue(highFreqTargets.allSatisfy { high in
            midFreqTargets.allSatisfy { mid in high.targetRT60 < mid.targetRT60 }
        })
    }
    
    func testSportsHallTargets() {
        let volume = 2000.0
        let targets = DIN18041Database.targets(for: .sports, volume: volume)
        
        XCTAssertEqual(targets.count, 7)
        // Sports halls can have highest RT60 around 2.0s (volume-adjusted with frequency variation)
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 > 1.5 })
        XCTAssertTrue(targets.allSatisfy { $0.targetRT60 < 3.0 }) // Should be highest
        XCTAssertTrue(targets.allSatisfy { $0.tolerance == 0.3 })
        
        // Speech/PA frequencies (500-2000 Hz) should have better clarity
        let paFreqTargets = targets.filter { $0.frequency >= 500 && $0.frequency <= 2000 }
        let otherFreqTargets = targets.filter { $0.frequency < 500 || $0.frequency > 2000 }
        XCTAssertTrue(paFreqTargets.allSatisfy { pa in
            otherFreqTargets.allSatisfy { other in pa.targetRT60 <= other.targetRT60 }
        })
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