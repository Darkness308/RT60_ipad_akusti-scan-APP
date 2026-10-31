// SabineConstantTests.swift
// Tests for the parameterized Sabine constant

import XCTest
@testable import AcoustiScanConsolidated

final class SabineConstantTests: XCTestCase {

    // MARK: - Standard Value Tests

    func testStandardValueAt20Celsius() {
        let standard = SabineConstant.standard
        XCTAssertEqual(standard.temperatureCelsius, 20.0)
        XCTAssertEqual(standard.value, 0.161, accuracy: 0.001)
    }

    func testDefaultAliasEqualsStandard() {
        XCTAssertEqual(SabineConstant.default, SabineConstant.standard)
    }

    // MARK: - Temperature Dependence Tests

    func testColdRoomConstant() {
        let cold = SabineConstant(temperatureCelsius: 10.0)
        // At 10°C, k should be higher (~0.163) because sound is slower
        XCTAssertGreaterThan(cold.value, SabineConstant.standard.value)
        XCTAssertEqual(cold.value, 0.163, accuracy: 0.001)
    }

    func testWarmRoomConstant() {
        let warm = SabineConstant(temperatureCelsius: 30.0)
        // At 30°C, k should be lower (~0.159) because sound is faster
        XCTAssertLessThan(warm.value, SabineConstant.standard.value)
        XCTAssertEqual(warm.value, 0.159, accuracy: 0.001)
    }

    func testReferenceTemperatures() {
        XCTAssertEqual(
            SabineConstant.ReferenceTemperatures.cold.temperatureCelsius,
            10.0
        )
        XCTAssertEqual(
            SabineConstant.ReferenceTemperatures.standard.temperatureCelsius,
            20.0
        )
        XCTAssertEqual(
            SabineConstant.ReferenceTemperatures.warm.temperatureCelsius,
            30.0
        )
    }

    // MARK: - Speed of Sound Tests

    func testSpeedOfSoundAt20Celsius() {
        let standard = SabineConstant.standard
        // c = 331.3 × √(1 + 20/273.15) ≈ 343.2 m/s
        XCTAssertEqual(standard.speedOfSound, 343.2, accuracy: 0.5)
    }

    func testSpeedOfSoundAt0Celsius() {
        let freezing = SabineConstant(temperatureCelsius: 0.0)
        // c = 331.3 × √(1 + 0/273.15) = 331.3 m/s
        XCTAssertEqual(freezing.speedOfSound, 331.3, accuracy: 0.1)
    }

    // MARK: - Formula Verification

    func testSabineConstantFormula() {
        // k = 24 × ln(10) / c
        // At 20°C: k = 55.26 / 343.2 ≈ 0.161
        let k = SabineConstant.calculate(temperatureCelsius: 20.0)
        let expectedNumerator = 24.0 * log(10.0)
        let expectedSpeed = 331.3 * sqrt(1.0 + 20.0 / 273.15)
        let expected = expectedNumerator / expectedSpeed

        XCTAssertEqual(k, expected, accuracy: 0.0001)
        XCTAssertEqual(k, 0.161, accuracy: 0.001)
    }

    // MARK: - Explicit Value Constructor

    func testExplicitValueConstructor() {
        let custom = SabineConstant(value: 0.165, temperatureCelsius: 15.0)
        XCTAssertEqual(custom.value, 0.165)
        XCTAssertEqual(custom.temperatureCelsius, 15.0)
    }

    // MARK: - Codable Tests

    func testCodable() throws {
        let original = SabineConstant(temperatureCelsius: 25.0)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SabineConstant.self, from: encoded)

        XCTAssertEqual(decoded.value, original.value)
        XCTAssertEqual(decoded.temperatureCelsius, original.temperatureCelsius)
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let a = SabineConstant(temperatureCelsius: 20.0)
        let b = SabineConstant(temperatureCelsius: 20.0)
        let c = SabineConstant(temperatureCelsius: 25.0)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - Canary Tests

    /// CANARY: The standard Sabine constant at 20°C MUST be approximately 0.161.
    /// This guards against accidental changes to the calculation formula.
    func testSabineConstantCanary() {
        let CANARY_VALUE = 0.161
        let standard = SabineConstant.standard

        XCTAssertEqual(
            standard.value,
            CANARY_VALUE,
            accuracy: 0.001,
            "CANARY BREACH: Standard Sabine constant changed! Expected ~\(CANARY_VALUE), got \(standard.value)"
        )
    }

    /// CANARY: The speed of sound formula must match ISO standard.
    /// c = 331.3 × √(1 + T/273.15) m/s at temperature T (°C)
    func testSpeedOfSoundFormulaCanary() {
        let temperatures = [0.0, 10.0, 20.0, 30.0]
        let expectedSpeeds = [331.3, 337.3, 343.2, 349.0]

        for (temp, expectedSpeed) in zip(temperatures, expectedSpeeds) {
            let constant = SabineConstant(temperatureCelsius: temp)
            XCTAssertEqual(
                constant.speedOfSound,
                expectedSpeed,
                accuracy: 0.5,
                "CANARY BREACH: Speed of sound at \(temp)°C changed!"
            )
        }
    }

    /// CANARY: RT60Calculator must use SabineConstant.standard by default.
    func testRT60CalculatorUsesSabineConstant() {
        let volume = 100.0
        let absorptionArea = 10.0

        let rt60Default = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea
        )
        let rt60Explicit = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea,
            sabineConstant: .standard
        )

        XCTAssertEqual(
            rt60Default,
            rt60Explicit,
            accuracy: 0.0001,
            "CANARY BREACH: RT60Calculator default must use SabineConstant.standard"
        )

        let expectedRT60 = SabineConstant.standard.value * volume / absorptionArea
        XCTAssertEqual(
            rt60Default,
            expectedRT60,
            accuracy: 0.0001,
            "CANARY BREACH: RT60 calculation formula changed!"
        )
    }

    /// CANARY: Temperature-adjusted calculation must differ from standard.
    func testTemperatureAdjustmentWorks() {
        let volume = 100.0
        let absorptionArea = 10.0

        let rt60Standard = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea
        )
        let rt60Cold = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea,
            temperatureCelsius: 10.0
        )
        let rt60Warm = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea,
            temperatureCelsius: 30.0
        )

        // Cold room: higher k → longer RT60
        XCTAssertGreaterThan(
            rt60Cold,
            rt60Standard,
            "CANARY BREACH: Cold room should have longer RT60"
        )

        // Warm room: lower k → shorter RT60
        XCTAssertLessThan(
            rt60Warm,
            rt60Standard,
            "CANARY BREACH: Warm room should have shorter RT60"
        )
    }

    // MARK: - Input Validation Tests

    func testTemperatureClampingPreventsNaN() {
        // Out-of-range temperatures must be clamped, not produce NaN
        let extremeCold = SabineConstant(temperatureCelsius: -300.0)
        let extremeHot = SabineConstant(temperatureCelsius: 1000.0)
        let nonFinite = SabineConstant(temperatureCelsius: .infinity)

        XCTAssertFalse(extremeCold.value.isNaN, "Extreme cold should not produce NaN")
        XCTAssertFalse(extremeHot.value.isNaN, "Extreme hot should not produce NaN")
        XCTAssertFalse(nonFinite.value.isNaN, "Non-finite input should not produce NaN")

        // Clamped to valid range
        XCTAssertEqual(extremeCold.temperatureCelsius, -40.0)
        XCTAssertEqual(extremeHot.temperatureCelsius, 60.0)
        XCTAssertEqual(nonFinite.temperatureCelsius, 60.0)
    }

    func testCalculateClampingPreventsNaN() {
        let extremeValue = SabineConstant.calculate(temperatureCelsius: -300.0)
        XCTAssertFalse(extremeValue.isNaN, "Calculate should clamp out-of-range values")
    }

    func testValidTemperatureRange() {
        XCTAssertEqual(SabineConstant.validTemperatureRange.lowerBound, -40.0)
        XCTAssertEqual(SabineConstant.validTemperatureRange.upperBound, 60.0)
    }
}
