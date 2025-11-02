
import XCTest
@testable import iPadScannerApp

final class RT60EvaluatorTests: XCTestCase {

    func testEvaluationWithinTolerance() {
        let measurement = RT60Measurement(frequency: 1000, simulated: 0.49, measured: nil)
        let deviations = RT60Evaluator.evaluate(
            measurements: [measurement],
            roomType: RoomType.classroom,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .withinTolerance)
    }

    func testEvaluationTooHigh() {
        let measurement = RT60Measurement(frequency: 1000, simulated: 0.65, measured: nil)
        let deviations = RT60Evaluator.evaluate(
            measurements: [measurement],
            roomType: RoomType.classroom,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .tooHigh)
    }
}
