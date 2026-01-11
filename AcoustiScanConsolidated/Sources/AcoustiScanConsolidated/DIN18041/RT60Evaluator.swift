// RT60Evaluator.swift
// RT60 evaluation logic for DIN 18041 compliance

import Foundation

/// RT60 evaluation logic for DIN 18041 compliance
public struct RT60Evaluator {

    /// Evaluate RT60 measurements against DIN 18041 targets
    public static func evaluateDINCompliance(
        measurements: [RT60Measurement],
        roomType: RoomType,
        volume: Double
    ) -> [RT60Deviation] {
        let targets = DIN18041Database.targets(for: roomType, volume: volume)

        return measurements.compactMap { measurement in
            guard let target = targets.first(where: { $0.frequency == measurement.frequency }) else {
                return nil
            }

            let diff = measurement.rt60 - target.targetRT60
            let status: EvaluationStatus

            if abs(diff) <= target.tolerance {
                status = .withinTolerance
            } else if diff > 0 {
                status = .tooHigh
            } else {
                status = .tooLow
            }

            return RT60Deviation(
                frequency: measurement.frequency,
                measuredRT60: measurement.rt60,
                targetRT60: target.targetRT60,
                status: status
            )
        }
    }

    /// Classify RT60 value against target for a specific frequency
    public static func classifyRT60(
        measured: Double,
        target: Double,
        tolerance: Double
    ) -> EvaluationStatus {
        let diff = measured - target

        if abs(diff) <= tolerance {
            return .withinTolerance
        } else if diff > 0 {
            return .tooHigh
        } else {
            return .tooLow
        }
    }

    /// Get overall compliance status for all measurements
    public static func overallCompliance(deviations: [RT60Deviation]) -> EvaluationStatus {
        let nonCompliantCount = deviations.filter { $0.status != .withinTolerance }.count

        if nonCompliantCount == 0 {
            return .withinTolerance
        } else if nonCompliantCount <= deviations.count / 2 {
            // If less than half are non-compliant, consider it "partially compliant"
            return .partiallyCompliant
        } else {
            // If more than half are non-compliant, consider it "non-compliant" -> tooHigh
            return .tooHigh
        }
    }
}
