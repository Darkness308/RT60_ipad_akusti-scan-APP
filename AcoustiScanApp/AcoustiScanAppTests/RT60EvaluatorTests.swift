
import XCTest
@testable import AcoustiScanConsolidated

final class RT60EvaluatorTests: XCTestCase {

    // A3 (Unterricht/Kommunikation) at V = 120 m³:
    // T_soll = 0.32·lg(120) − 0.17 ≈ 0.495 s; 1 kHz mid-band tolerance ≈ [0.396, 0.594].

    func testEvaluationWithinTolerance() {
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.49)
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [measurement],
            roomType: .a3Education,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .withinTolerance)
    }

    func testEvaluationTooHigh() {
        let measurement = RT60Measurement(frequency: 1000, rt60: 0.75)
        let deviations = RT60Evaluator.evaluateDINCompliance(
            measurements: [measurement],
            roomType: .a3Education,
            volume: 120.0
        )

        XCTAssertEqual(deviations.first?.status, .tooHigh)
    }
}
