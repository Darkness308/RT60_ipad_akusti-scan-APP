
import XCTest
@testable import AcoustiScanConsolidated

final class RT60EvaluatorTests: XCTestCase {

    func testEvaluationWithinTolerance() {
        // RT60Measurement uses (frequency, rt60) constructor
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.49)
        let deviations = RT60Evaluator.evaluate(
            measurements: [measurement],
            roomType: RoomType.classroom,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .withinTolerance)
    }

    func testEvaluationTooHigh() {
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.75)
        let deviations = RT60Evaluator.evaluate(
            measurements: [measurement],
            roomType: RoomType.classroom,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .tooHigh)
    }
}
