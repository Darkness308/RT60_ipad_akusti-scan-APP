// RT60Calculator.swift
// Consolidated RT60 calculation engine

import Foundation

/// Advanced RT60 calculation engine with DIN 18041 compliance
public class RT60Calculator {

    /// Calculate RT60 using Sabine formula
    public static func calculateRT60(volume: Double, absorptionArea: Double) -> Double {
        guard absorptionArea > 0 else { return 0.0 }
        let sabineConstant = 0.161 // For air at 20°C, 50% humidity
        return sabineConstant * volume / absorptionArea
    }

    /// Calculate total absorption area from surfaces and materials
    public static func totalAbsorptionArea(
        surfaceAreas: [Double],
        absorptionCoefficients: [Double]
    ) -> Double {
        guard surfaceAreas.count == absorptionCoefficients.count else { return 0.0 }
        return zip(surfaceAreas, absorptionCoefficients)
            .map { $0 * $1 }
            .reduce(0, +)
    }

    /// Calculate RT60 for all standard frequencies
    public static func calculateFrequencySpectrum(
        volume: Double,
        surfaces: [AcousticSurface]
    ) -> [RT60Measurement] {
        let frequencies = [125, 250, 500, 1000, 2000, 4000, 8000]

        return frequencies.map { frequency in
            let totalAbsorption = surfaces.reduce(0.0) { total, surface in
                let coefficient = surface.material.absorptionCoefficient(at: frequency)
                return total + (surface.area * coefficient)
            }

            let rt60 = calculateRT60(volume: volume, absorptionArea: totalAbsorption)
            return RT60Measurement(frequency: frequency, rt60: rt60)
        }
    }

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
}

// Note: AcousticSurface and AcousticMaterial models have been moved to
// dedicated files in the Models/ directory to avoid duplication.
