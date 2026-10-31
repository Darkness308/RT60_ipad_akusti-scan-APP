// SabineConstant.swift
// Parameterized Sabine constant for RT60 calculations

import Foundation

/// The Sabine constant used in reverberation time calculations.
///
/// The Sabine formula is: RT60 = k × V / A
/// where k is this constant, V is volume (m³), and A is absorption area (m² Sabine).
///
/// The constant k = 24 × ln(10) / c ≈ 55.26 / c
/// where c is the speed of sound in air (m/s).
///
/// Speed of sound depends on temperature: c = 331.3 × √(1 + T/273.15)
/// At 20°C: c ≈ 343.2 m/s → k ≈ 0.161
///
/// Reference: ISO 3382-1:2009, Sabine equation derivation
public struct SabineConstant: Equatable, Hashable, Codable {

    /// The Sabine constant value (dimensionless, typically ~0.161)
    public let value: Double

    /// Temperature in Celsius used to calculate this constant
    public let temperatureCelsius: Double

    /// Standard conditions: 20°C, 50% relative humidity
    /// This is the commonly cited value of 0.161
    public static let standard = SabineConstant(temperatureCelsius: 20.0)

    /// Alias for standard conditions (backward compatibility)
    public static let `default` = standard

    /// Valid temperature range for acoustic calculations
    public static let validTemperatureRange: ClosedRange<Double> = -40.0...60.0

    /// Create a Sabine constant for a specific temperature.
    /// - Parameter temperatureCelsius: Air temperature in degrees Celsius.
    ///   Valid range: -40°C to +60°C (physically reasonable for indoor acoustics).
    ///   Values outside this range are clamped to prevent NaN propagation.
    public init(temperatureCelsius: Double) {
        let clampedTemp = min(max(temperatureCelsius, Self.validTemperatureRange.lowerBound),
                               Self.validTemperatureRange.upperBound)
        self.temperatureCelsius = clampedTemp
        self.value = SabineConstant.calculate(temperatureCelsius: clampedTemp)
    }

    /// Create with an explicit value (for testing or calibration)
    public init(value: Double, temperatureCelsius: Double = 20.0) {
        self.value = value
        self.temperatureCelsius = temperatureCelsius
    }

    /// Calculate the Sabine constant for a given temperature.
    ///
    /// Formula: k = 24 × ln(10) / c
    /// where c = 331.3 × √(1 + T/273.15) m/s
    ///
    /// - Parameter temperatureCelsius: Temperature in degrees Celsius.
    ///   Values outside -40°C to +60°C are clamped to prevent NaN.
    /// - Returns: Sabine constant (typically 0.159–0.163 for indoor temperatures)
    public static func calculate(temperatureCelsius: Double) -> Double {
        let clampedTemp = min(max(temperatureCelsius, validTemperatureRange.lowerBound),
                               validTemperatureRange.upperBound)
        let speedOfSound = 331.3 * sqrt(1.0 + clampedTemp / 273.15)
        let numerator = 24.0 * log(10.0) // ≈ 55.26
        return numerator / speedOfSound
    }

    /// Speed of sound at the temperature used for this constant
    public var speedOfSound: Double {
        331.3 * sqrt(1.0 + temperatureCelsius / 273.15)
    }
}

// MARK: - Convenience Extensions

extension SabineConstant {
    /// Typical indoor temperature range values for reference
    public enum ReferenceTemperatures {
        /// Cold room: 10°C → k ≈ 0.163
        public static let cold = SabineConstant(temperatureCelsius: 10.0)

        /// Standard room: 20°C → k ≈ 0.161
        public static let standard = SabineConstant.standard

        /// Warm room: 30°C → k ≈ 0.159
        public static let warm = SabineConstant(temperatureCelsius: 30.0)
    }
}

// MARK: - CustomStringConvertible

extension SabineConstant: CustomStringConvertible {
    public var description: String {
        String(format: "SabineConstant(%.4f @ %.1f°C)", value, temperatureCelsius)
    }
}
