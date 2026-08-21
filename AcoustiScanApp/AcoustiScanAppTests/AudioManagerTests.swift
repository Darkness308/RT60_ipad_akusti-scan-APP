//
//  AudioManagerTests.swift
//  AcoustiScanAppTests
//
//  Unit tests for AudioManager USB microphone and RT60 measurement functionality
//

import XCTest
@testable import AcoustiScanApp

@MainActor
final class AudioManagerTests: XCTestCase {

    var audioManager: AudioManager!

    override func setUp() async throws {
        audioManager = AudioManager()
    }

    override func tearDown() async throws {
        audioManager?.stopMonitoring()
        audioManager = nil
    }

    // MARK: - Initialization Tests

    func testAudioManagerInitialization() {
        XCTAssertNotNil(audioManager)
        XCTAssertEqual(audioManager.measurementState, .idle)
        XCTAssertFalse(audioManager.isMonitoring)
        XCTAssertTrue(audioManager.measurements.isEmpty)
    }

    func testStandardFrequenciesCount() {
        XCTAssertEqual(audioManager.standardFrequencies.count, 7)
        XCTAssertTrue(audioManager.standardFrequencies.contains(125))
        XCTAssertTrue(audioManager.standardFrequencies.contains(8000))
    }

    func testSampleRateConfiguration() {
        XCTAssertEqual(audioManager.sampleRate, 48000.0)
    }

    func testRecordingDuration() {
        XCTAssertEqual(audioManager.recordingDuration, 5.0)
    }

    // MARK: - Audio Input Device Tests

    func testMicrophoneClassRawValues() {
        XCTAssertEqual(MicrophoneClass.class1.rawValue, "Class 1")
        XCTAssertEqual(MicrophoneClass.class2.rawValue, "Class 2")
        XCTAssertEqual(MicrophoneClass.builtin.rawValue, "Built-in")
    }

    func testMicrophoneClassTolerance() {
        XCTAssertEqual(MicrophoneClass.class1.toleranceDB, 0.7)
        XCTAssertEqual(MicrophoneClass.class2.toleranceDB, 1.0)
        XCTAssertEqual(MicrophoneClass.builtin.toleranceDB, 3.0)
    }

    func testMicrophoneClassIsCalibrated() {
        XCTAssertTrue(MicrophoneClass.class1.isCalibrated)
        XCTAssertTrue(MicrophoneClass.class2.isCalibrated)
        XCTAssertFalse(MicrophoneClass.builtin.isCalibrated)
        XCTAssertFalse(MicrophoneClass.unknown.isCalibrated)
    }

    // MARK: - Measurement State Tests

    func testMeasurementStateEquality() {
        XCTAssertEqual(MeasurementState.idle, MeasurementState.idle)
        XCTAssertEqual(MeasurementState.recording, MeasurementState.recording)
        XCTAssertNotEqual(MeasurementState.idle, MeasurementState.recording)
    }

    func testMeasurementStateError() {
        let error1 = MeasurementState.error("Test error")
        let error2 = MeasurementState.error("Test error")
        XCTAssertEqual(error1, error2)
    }

    // MARK: - Measurement Quality Tests

    func testMeasurementQualityColors() {
        XCTAssertEqual(MeasurementQuality.excellent.color, "green")
        XCTAssertEqual(MeasurementQuality.good.color, "blue")
        XCTAssertEqual(MeasurementQuality.acceptable.color, "yellow")
        XCTAssertEqual(MeasurementQuality.marginal.color, "orange")
        XCTAssertEqual(MeasurementQuality.invalid.color, "red")
    }

    func testMeasurementQualityCaseIterable() {
        XCTAssertEqual(MeasurementQuality.allCases.count, 5)
    }

    // MARK: - RT60 Measurement Result Tests

    func testRT60MeasurementResultQuality() {
        // Excellent quality
        let excellentResult = RT60MeasurementResult(
            timestamp: Date(),
            frequency: 1000,
            t20: 0.5,
            t30: 0.6,
            edt: nil,
            correlation: 99.5,
            noiseFloor: -65,
            peakLevel: -10
        )
        XCTAssertEqual(excellentResult.quality, .excellent)

        // Good quality
        let goodResult = RT60MeasurementResult(
            timestamp: Date(),
            frequency: 1000,
            t20: 0.5,
            t30: 0.6,
            edt: nil,
            correlation: 96.0,
            noiseFloor: -55,
            peakLevel: -10
        )
        XCTAssertEqual(goodResult.quality, .good)

        // Invalid quality (low correlation)
        let invalidResult = RT60MeasurementResult(
            timestamp: Date(),
            frequency: 1000,
            t20: nil,
            t30: nil,
            edt: nil,
            correlation: 50.0,
            noiseFloor: -30,
            peakLevel: -10
        )
        XCTAssertEqual(invalidResult.quality, .invalid)
    }

    func testRT60MeasurementResultRT60Preference() {
        // T30 preferred over T20
        let resultWithBoth = RT60MeasurementResult(
            timestamp: Date(),
            frequency: 1000,
            t20: 0.5,
            t30: 0.6,
            edt: nil,
            correlation: 95.0,
            noiseFloor: -50,
            peakLevel: -10
        )
        XCTAssertEqual(resultWithBoth.rt60, 0.6)

        // Falls back to T20 when T30 is nil
        let resultOnlyT20 = RT60MeasurementResult(
            timestamp: Date(),
            frequency: 1000,
            t20: 0.5,
            t30: nil,
            edt: nil,
            correlation: 95.0,
            noiseFloor: -50,
            peakLevel: -10
        )
        XCTAssertEqual(resultOnlyT20.rt60, 0.5)
    }

    // MARK: - RT60 Dictionary Tests

    func testGetRT60DictionaryEmpty() {
        XCTAssertTrue(audioManager.getRT60Dictionary().isEmpty)
    }

    // MARK: - Overall Quality Tests

    func testOverallQualityEmpty() {
        XCTAssertEqual(audioManager.overallQuality, .invalid)
    }

    // MARK: - Level Monitoring Tests

    func testInitialLevels() {
        XCTAssertEqual(audioManager.currentLevel, -100.0)
        XCTAssertEqual(audioManager.peakLevel, -100.0)
    }

    // MARK: - Input Device Tests

    func testRefreshAvailableInputsDoesNotCrash() {
        // Should not crash even without audio hardware
        audioManager.refreshAvailableInputs()
        // availableInputs may be empty in test environment
        XCTAssertNotNil(audioManager.availableInputs)
    }
}

// MARK: - Audio Input Device Tests

final class AudioInputDeviceTests: XCTestCase {

    func testAudioInputDeviceIdentifiable() {
        let device = AudioInputDevice(
            id: "test-uid",
            name: "Test Microphone",
            portType: .builtInMic,
            isUSB: false,
            isBuiltIn: true
        )

        XCTAssertEqual(device.id, "test-uid")
        XCTAssertEqual(device.name, "Test Microphone")
        XCTAssertFalse(device.isUSB)
        XCTAssertTrue(device.isBuiltIn)
    }

    func testAudioInputDeviceQualityClassBuiltIn() {
        let builtIn = AudioInputDevice(
            id: "builtin",
            name: "iPad Microphone",
            portType: .builtInMic,
            isUSB: false,
            isBuiltIn: true
        )

        XCTAssertEqual(builtIn.qualityClass, .builtin)
    }

    func testAudioInputDeviceQualityClassUSB() {
        let usb = AudioInputDevice(
            id: "usb",
            name: "USB Audio Device",
            portType: .usbAudio,
            isUSB: true,
            isBuiltIn: false
        )

        XCTAssertEqual(usb.qualityClass, .class2)
    }

    func testAudioInputDeviceQualityClassMeasurement() {
        let measurement = AudioInputDevice(
            id: "measurement",
            name: "Measurement Class 1 Microphone",
            portType: .usbAudio,
            isUSB: true,
            isBuiltIn: false
        )

        XCTAssertEqual(measurement.qualityClass, .class1)
    }

    func testAudioInputDeviceEquatable() {
        let device1 = AudioInputDevice(
            id: "test",
            name: "Test",
            portType: .builtInMic,
            isUSB: false,
            isBuiltIn: true
        )

        let device2 = AudioInputDevice(
            id: "test",
            name: "Test",
            portType: .builtInMic,
            isUSB: false,
            isBuiltIn: true
        )

        XCTAssertEqual(device1, device2)
    }
}
