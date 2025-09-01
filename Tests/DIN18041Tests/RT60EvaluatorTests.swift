import XCTest
@testable import iPadScannerApp

final class RT60EvaluatorTests: XCTestCase {
    func testRT60ClassificationWithinRange() {
        let result = RT60Evaluator.classifyRT60(measured: 1.1, target: 1.0)
        XCTAssertEqual(result, .withinRange)
    }

    func testRT60ClassificationTooHigh() {
        let result = RT60Evaluator.classifyRT60(measured: 1.3, target: 1.0)
        XCTAssertEqual(result, .tooHigh)
    }

    func testRT60ClassificationTooLow() {
        let result = RT60Evaluator.classifyRT60(measured: 0.7, target: 1.0)
        XCTAssertEqual(result, .tooLow)
    }
}