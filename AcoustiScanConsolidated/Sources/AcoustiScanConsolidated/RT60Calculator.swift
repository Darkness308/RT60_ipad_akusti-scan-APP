// RT60Calculator.swift
// Consolidated RT60 calculation engine

import Foundation

/// Advanced RT60 calculation engine with DIN 18041 compliance
public class RT60Calculator {

    /// Calculate RT60 using Sabine formula
    /// - Parameters:
    ///   - volume: Room volume in cubic meters
    ///   - absorptionArea: Total absorption area in m² Sabine
    ///   - sabineConstant: Sabine constant (default: standard conditions at 20°C)
    /// - Returns: RT60 reverberation time in seconds
    public static func calculateRT60(
        volume: Double,
        absorptionArea: Double,
        sabineConstant: SabineConstant = .standard
    ) -> Double {
        guard absorptionArea > 0 else { return 0.0 }
        return sabineConstant.value * volume / absorptionArea
    }

    /// Calculate RT60 using Sabine formula with temperature adjustment
    /// - Parameters:
    ///   - volume: Room volume in cubic meters
    ///   - absorptionArea: Total absorption area in m² Sabine
    ///   - temperatureCelsius: Air temperature in degrees Celsius
    /// - Returns: RT60 reverberation time in seconds
    public static func calculateRT60(
        volume: Double,
        absorptionArea: Double,
        temperatureCelsius: Double
    ) -> Double {
        let sabineConstant = SabineConstant(temperatureCelsius: temperatureCelsius)
        return calculateRT60(volume: volume, absorptionArea: absorptionArea, sabineConstant: sabineConstant)
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
    /// - Note: This method delegates to RT60Evaluator for consistency
    public static func evaluateDINCompliance(
        measurements: [RT60Measurement],
        roomType: RoomType,
        volume: Double
    ) -> [RT60Deviation] {
        // Delegate to the canonical implementation in RT60Evaluator
        return RT60Evaluator.evaluateDINCompliance(
            measurements: measurements,
            roomType: roomType,
            volume: volume
        )
    }
}

// Note: AcousticSurface and AcousticMaterial models have been moved to
// dedicated files in the Models/ directory to avoid duplication.
