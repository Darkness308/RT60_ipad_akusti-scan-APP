// DIN18041Tests.swift
// Test suite for the DIN 18041:2016-03 compliance module (Gruppe A).

import XCTest
import Foundation
@testable import AcoustiScanConsolidated

/// Tests for the normative DIN 18041:2016-03 target and tolerance logic.
final class DIN18041ModuleTests: XCTestCase {

    // MARK: - Target reverberation time T_soll = a·lg(V) + b

    func testTargetReverberationTimeFormulasPerGroup() {
        // A1 Musik: 0.45·lg(V) + 0.07
        XCTAssertEqual(RoomType.a1Music.targetReverberationTime(volume: 500), 1.285, accuracy: 0.005)
        // A2 Sprache/Vortrag: 0.37·lg(V) − 0.14
        XCTAssertEqual(RoomType.a2Speech.targetReverberationTime(volume: 1000), 0.97, accuracy: 0.005)
        // A3 Unterricht/Kommunikation: 0.32·lg(V) − 0.17
        XCTAssertEqual(RoomType.a3Education.targetReverberationTime(volume: 200), 0.566, accuracy: 0.005)
        // A4 Unterricht inklusiv: 0.26·lg(V) − 0.14
        XCTAssertEqual(RoomType.a4EducationInclusive.targetReverberationTime(volume: 100), 0.38, accuracy: 0.005)
        // A5 Sport: 0.75·lg(V) − 1.00
        XCTAssertEqual(RoomType.a5Sports.targetReverberationTime(volume: 2000), 1.476, accuracy: 0.005)
    }

    func testA5IsCappedAtTwoSecondsFromTenThousandCubicMetres() {
        // The equation already yields 2.0 s at 10 000 m³ and is capped beyond.
        XCTAssertEqual(RoomType.a5Sports.targetReverberationTime(volume: 10_000), 2.0, accuracy: 0.005)
        XCTAssertEqual(RoomType.a5Sports.targetReverberationTime(volume: 20_000), 2.0, accuracy: 0.005)
    }

    func testValidVolumeRanges() {
        XCTAssertEqual(RoomType.a1Music.validVolumeRange, 30...1000)
        XCTAssertEqual(RoomType.a2Speech.validVolumeRange, 50...5000)
        XCTAssertEqual(RoomType.a3Education.validVolumeRange, 30...5000)
        XCTAssertEqual(RoomType.a4EducationInclusive.validVolumeRange, 30...500)
        XCTAssertEqual(RoomType.a5Sports.validVolumeRange, 200...10000)
        XCTAssertFalse(RoomType.a4EducationInclusive.isVolumeWithinValidRange(600))
        XCTAssertTrue(RoomType.a4EducationInclusive.isVolumeWithinValidRange(300))
    }

    // MARK: - Evaluated octave bands

    func testA1ToA4AreEvaluatedAcross125To4000Hz() {
        for group in [RoomType.a1Music, .a2Speech, .a3Education, .a4EducationInclusive] {
            let targets = DIN18041Database.targets(for: group, volume: 200.0)
            XCTAssertEqual(targets.map { $0.frequency }.sorted(), [125, 250, 500, 1000, 2000, 4000])
        }
    }

    func testA5IsOnlyEvaluatedAcross250To2000Hz() {
        let targets = DIN18041Database.targets(for: .a5Sports, volume: 2000.0)
        XCTAssertEqual(targets.map { $0.frequency }.sorted(), [250, 500, 1000, 2000])
    }

    // MARK: - Bild 2 tolerance band

    func testToleranceBandMidVersusEdgesForA1ToA4() {
        let volume = 200.0
        let tSoll = RoomType.a3Education.targetReverberationTime(volume: volume)
        let targets = DIN18041Database.targets(for: .a3Education, volume: volume)

        guard let mid = targets.first(where: { $0.frequency == 500 }),
              let edge = targets.first(where: { $0.frequency == 125 }) else {
            return XCTFail("Expected 500 Hz and 125 Hz targets")
        }

        // Mid band: 0.80–1.20 · T_soll
        XCTAssertEqual(mid.lowerBound, tSoll * 0.80, accuracy: 0.001)
        XCTAssertEqual(mid.upperBound, tSoll * 1.20, accuracy: 0.001)
        // Edge band (125 Hz): 0.65–1.45 · T_soll
        XCTAssertEqual(edge.lowerBound, tSoll * 0.65, accuracy: 0.001)
        XCTAssertEqual(edge.upperBound, tSoll * 1.45, accuracy: 0.001)
    }

    func testToleranceBandForA5IsPlusMinusTwentyPercent() {
        let volume = 2000.0
        let tSoll = RoomType.a5Sports.targetReverberationTime(volume: volume)
        let targets = DIN18041Database.targets(for: .a5Sports, volume: volume)

        for target in targets {
            XCTAssertEqual(target.lowerBound, tSoll * 0.80, accuracy: 0.001)
            XCTAssertEqual(target.upperBound, tSoll * 1.20, accuracy: 0.001)
        }
    }

    // MARK: - Compliance evaluation

    func testMeasurementsAtTargetAreWithinTolerance() {
        let targets = DIN18041Database.targets(for: .a3Education, volume: 150.0)
        let measurements = targets.map { RT60Measurement(frequency: $0.frequency, rt60: $0.targetRT60) }

        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .a3Education,
            volume: 150.0
        )

        XCTAssertEqual(deviations.count, targets.count)
        XCTAssertTrue(deviations.allSatisfy { $0.status == .withinTolerance })
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: deviations), .withinTolerance)
    }

    func testTooHighAndTooLowAtMidBand() {
        // A3 at 150 m³: T_soll ≈ 0.526 s; mid band 500 Hz tolerance ≈ [0.421, 0.632].
        let tooHigh = RT60Evaluator.evaluateDINCompliance(
            measurements: [RT60Measurement(frequency: 500, rt60: 0.80)],
            roomType: .a3Education,
            volume: 150.0
        )
        XCTAssertEqual(tooHigh.first?.status, .tooHigh)

        let tooLow = RT60Evaluator.evaluateDINCompliance(
            measurements: [RT60Measurement(frequency: 500, rt60: 0.30)],
            roomType: .a3Education,
            volume: 150.0
        )
        XCTAssertEqual(tooLow.first?.status, .tooLow)
    }

    func testEdgeBandToleratesMoreThanMidBand() {
        // The same low RT60 that is "too low" at 500 Hz can still be within the
        // wider 125 Hz edge band, demonstrating the frequency-dependent tolerance.
        let measurements = [
            RT60Measurement(frequency: 125, rt60: 0.40),
            RT60Measurement(frequency: 500, rt60: 0.40)
        ]
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .a3Education,
            volume: 150.0
        )
        let edge = deviations.first { $0.frequency == 125 }
        let mid = deviations.first { $0.frequency == 500 }
        XCTAssertEqual(edge?.status, .withinTolerance)
        XCTAssertEqual(mid?.status, .tooLow)
    }

    func testEmptyMeasurements() {
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [],
            roomType: .a3Education,
            volume: 150.0
        )
        XCTAssertTrue(deviations.isEmpty)
        XCTAssertEqual(RT60Evaluator.overallCompliance(deviations: []), .withinTolerance)
    }

    func testMismatchedFrequenciesAreIgnored() {
        let measurements = [
            RT60Measurement(frequency: 100, rt60: 0.60), // not an evaluated octave
            RT60Measurement(frequency: 500, rt60: 0.60)
        ]
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: .a3Education,
            volume: 150.0
        )
        XCTAssertEqual(deviations.count, 1)
        XCTAssertEqual(deviations.first?.frequency, 500)
    }

    func testCompleteWorkflowForEveryGroup() {
        for group in RoomType.allCases {
            let range = group.validVolumeRange
            let volume = (range.lowerBound + range.upperBound) / 2.0
            let targets = DIN18041Database.targets(for: group, volume: volume)
            let measurements = targets.map { RT60Measurement(frequency: $0.frequency, rt60: $0.targetRT60) }

            let deviations = RT60Evaluator.evaluateDINCompliance(
                measurements: measurements,
                roomType: group,
                volume: volume
            )

            XCTAssertEqual(deviations.count, targets.count, "\(group) band count")
            XCTAssertTrue(deviations.allSatisfy { $0.status == .withinTolerance }, "\(group) all within tolerance")
        }
    }
}
