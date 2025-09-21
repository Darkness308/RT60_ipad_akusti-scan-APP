// DIN18041Tests.swift
// Comprehensive test suite for DIN 18041 module

import Testing
import Foundation
@testable import AcoustiScanConsolidated

/// Comprehensive test suite for DIN 18041 compliance evaluation
struct DIN18041ModuleTests {
    
    // MARK: - DIN18041Database Tests
    
    @Test("DIN 18041 targets for classroom rooms")
    func testClassroomTargets() {
        let volume = 200.0
        let targets = DIN18041Database.targets(for: .classroom, volume: volume)
        
        #expect(targets.count == 7) // 7 frequency bands
        #expect(targets.allSatisfy { $0.targetRT60 > 0 })
        #expect(targets.allSatisfy { $0.tolerance > 0 })
        
        // Check that 500-1000 Hz has reasonable values for classroom
        let midFreqTargets = targets.filter { $0.frequency == 500 || $0.frequency == 1000 }
        #expect(midFreqTargets.allSatisfy { $0.targetRT60 <= 0.8 }) // Should be relatively low for speech
        
        // Verify frequency-dependent adjustments
        let lowFreq = targets.first { $0.frequency == 125 }!
        let midFreq = targets.first { $0.frequency == 1000 }!
        let highFreq = targets.first { $0.frequency == 4000 }!
        
        #expect(lowFreq.targetRT60 > midFreq.targetRT60) // Low frequencies should have higher RT60
        #expect(highFreq.targetRT60 < midFreq.targetRT60) // High frequencies should have lower RT60
    }
    
    @Test("DIN 18041 targets for office spaces")
    func testOfficeSpaceTargets() {
        let volume = 120.0
        let targets = DIN18041Database.targets(for: .officeSpace, volume: volume)
        
        #expect(targets.count == 7)
        #expect(targets.allSatisfy { $0.targetRT60 == 0.5 }) // Office spaces should have uniform low RT60
        #expect(targets.allSatisfy { $0.tolerance == 0.1 })
    }
    
    @Test("DIN 18041 targets for conference rooms")
    func testConferenceRoomTargets() {
        let volume = 300.0
        let targets = DIN18041Database.targets(for: .conference, volume: volume)
        
        #expect(targets.count == 7)
        #expect(targets.allSatisfy { $0.targetRT60 == 0.7 })
        #expect(targets.allSatisfy { $0.tolerance == 0.15 })
    }
    
    @Test("DIN 18041 targets for lecture halls")
    func testLectureHallTargets() {
        let volume = 500.0
        let targets = DIN18041Database.targets(for: .lecture, volume: volume)
        
        #expect(targets.count == 7)
        #expect(targets.allSatisfy { $0.targetRT60 == 0.8 })
        #expect(targets.allSatisfy { $0.tolerance == 0.15 })
    }
    
    @Test("DIN 18041 targets for music rooms")
    func testMusicRoomTargets() {
        let volume = 400.0
        let targets = DIN18041Database.targets(for: .music, volume: volume)
        
        #expect(targets.count == 7)
        #expect(targets.allSatisfy { $0.targetRT60 == 1.5 }) // Music rooms need longer reverberation
        #expect(targets.allSatisfy { $0.tolerance == 0.2 })
    }
    
    @Test("DIN 18041 targets for sports halls")
    func testSportsHallTargets() {
        let volume = 2000.0
        let targets = DIN18041Database.targets(for: .sports, volume: volume)
        
        #expect(targets.count == 7)
        #expect(targets.allSatisfy { $0.targetRT60 == 2.0 }) // Sports halls can have highest RT60
        #expect(targets.allSatisfy { $0.tolerance == 0.3 })
    }
    
    @Test("All room types have complete frequency coverage")
    func testFrequencyCoverage() {
        let expectedFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
        
        for roomType in RoomType.allCases {
            let targets = DIN18041Database.targets(for: roomType, volume: 300.0)
            let frequencies = targets.map { $0.frequency }.sorted()
            #expect(frequencies == expectedFrequencies, "Room type \(roomType) missing frequencies")
        }
    }
    
    // MARK: - RT60Evaluator Tests
    
    @Test("RT60 compliance evaluation - within tolerance")
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
        
        #expect(deviations.count == 3)
        #expect(deviations.allSatisfy { $0.status == .withinTolerance })
        #expect(deviations.allSatisfy { abs($0.deviation) <= 0.1 })
    }
    
    @Test("RT60 compliance evaluation - too high")
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
        
        #expect(deviations.count == 3)
        #expect(deviations.allSatisfy { $0.status == .tooHigh })
        #expect(deviations.allSatisfy { $0.deviation > 0.1 })
    }
    
    @Test("RT60 compliance evaluation - too low")
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
        
        #expect(deviations.count == 3)
        #expect(deviations.allSatisfy { $0.status == .tooLow })
        #expect(deviations.allSatisfy { $0.deviation < -0.1 })
    }
    
    @Test("RT60 classification for individual values")
    func testRT60Classification() {
        let target = 0.6
        let tolerance = 0.1
        
        // Within tolerance
        #expect(RT60Evaluator.classifyRT60(measured: 0.60, target: target, tolerance: tolerance) == .withinTolerance)
        #expect(RT60Evaluator.classifyRT60(measured: 0.65, target: target, tolerance: tolerance) == .withinTolerance)
        #expect(RT60Evaluator.classifyRT60(measured: 0.55, target: target, tolerance: tolerance) == .withinTolerance)
        
        // Too high
        #expect(RT60Evaluator.classifyRT60(measured: 0.75, target: target, tolerance: tolerance) == .tooHigh)
        
        // Too low
        #expect(RT60Evaluator.classifyRT60(measured: 0.45, target: target, tolerance: tolerance) == .tooLow)
    }
    
    @Test("Overall compliance assessment")
    func testOverallCompliance() {
        // All compliant
        let allCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.60, targetRT60: 0.60, status: .withinTolerance),
            RT60Deviation(frequency: 1000, measuredRT60: 0.55, targetRT60: 0.60, status: .withinTolerance)
        ]
        #expect(RT60Evaluator.overallCompliance(deviations: allCompliant) == .withinTolerance)
        
        // Partially compliant (less than half non-compliant)
        let partiallyCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.60, targetRT60: 0.60, status: .withinTolerance),
            RT60Deviation(frequency: 1000, measuredRT60: 0.80, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 2000, measuredRT60: 0.55, targetRT60: 0.48, status: .withinTolerance)
        ]
        #expect(RT60Evaluator.overallCompliance(deviations: partiallyCompliant) == .tooLow)
        
        // Non-compliant (more than half non-compliant)
        let nonCompliant = [
            RT60Deviation(frequency: 500, measuredRT60: 0.80, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 1000, measuredRT60: 0.85, targetRT60: 0.60, status: .tooHigh),
            RT60Deviation(frequency: 2000, measuredRT60: 0.55, targetRT60: 0.48, status: .withinTolerance)
        ]
        #expect(RT60Evaluator.overallCompliance(deviations: nonCompliant) == .tooHigh)
    }
    
    // MARK: - Integration Tests
    
    @Test("Complete DIN 18041 workflow for different room types")
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
                
                #expect(deviations.count == targets.count)
                #expect(deviations.allSatisfy { $0.status == .withinTolerance })
                #expect(RT60Evaluator.overallCompliance(deviations: deviations) == .withinTolerance)
            }
        }
    }
    
    @Test("Edge cases - empty measurements")
    func testEmptyMeasurements() {
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [],
            roomType: .classroom,
            volume: 150.0
        )
        
        #expect(deviations.isEmpty)
        #expect(RT60Evaluator.overallCompliance(deviations: []) == .withinTolerance)
    }
    
    @Test("Edge cases - mismatched frequencies")
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
        
        #expect(deviations.count == 1) // Only the 500 Hz measurement should be evaluated
        #expect(deviations.first?.frequency == 500)
    }
}