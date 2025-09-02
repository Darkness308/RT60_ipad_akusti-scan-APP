import XCTest
@testable import DIN18041

final class RT60EvaluatorTests: XCTestCase {
    func testRT60EvaluationWithinTolerance() {
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.6)
        let roomType = RoomType.classroom
        let volume = 150.0
        
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [measurement],
            roomType: roomType,
            volume: volume
        )
        
        XCTAssertEqual(deviations.count, 1)
        XCTAssertEqual(deviations.first?.status, .withinTolerance)
    }

    func testRoomTypeDescription() {
        let classroom = RoomType.classroom
        XCTAssertEqual(classroom.germanName, "Unterrichtsraum")
        XCTAssertFalse(classroom.description.isEmpty)
    }

    func testRT60MeasurementComparable() {
        let measurement1 = RT60Measurement(frequency: 500, rt60: 0.6)
        let measurement2 = RT60Measurement(frequency: 1000, rt60: 0.7)
        
        XCTAssertTrue(measurement1 < measurement2)
    }
}