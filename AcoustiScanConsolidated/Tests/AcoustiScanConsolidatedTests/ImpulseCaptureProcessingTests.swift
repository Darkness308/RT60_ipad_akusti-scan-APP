// ImpulseCaptureProcessingTests.swift
// Verifies the recording -> impulse response -> RT60 -> vs-Sabine pipeline.
// (The AVFoundation capture itself is iOS-only and compile-checked by the app
//  build; here we test the pure processing with synthetic signals.)

import XCTest
import Foundation
@testable import AcoustiScanConsolidated

final class ImpulseCaptureProcessingTests: XCTestCase {

    /// Build a synthetic recording: `leadingSilence` zero samples, then an
    /// exponentially decaying impulse with the given RT60.
    private func syntheticRecording(
        rt60: Double,
        sampleRate: Double,
        decaySeconds: Double,
        leadingSilence: Int,
        noiseAmplitude: Float = 0.0
    ) -> [Float] {
        var samples = [Float](repeating: 0.0, count: leadingSilence)
        if noiseAmplitude > 0 {
            for i in 0..<leadingSilence {
                samples[i] = (i % 2 == 0 ? noiseAmplitude : -noiseAmplitude)
            }
        }
        let n = Int(sampleRate * decaySeconds)
        let decay = (0..<n).map { i -> Float in
            let t = Double(i) / sampleRate
            return Float(exp(-6.91 * t / rt60))
        }
        return samples + decay
    }

    // MARK: - Onset detection

    func testOnsetIndexFindsImpulseAfterSilence() {
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: 48000, decaySeconds: 0.5, leadingSilence: 100
        )
        XCTAssertEqual(ImpulseCaptureProcessing.onsetIndex(in: recording), 100)
    }

    func testOnsetIndexNilForAllZero() {
        XCTAssertNil(ImpulseCaptureProcessing.onsetIndex(in: [Float](repeating: 0, count: 50)))
        XCTAssertNil(ImpulseCaptureProcessing.onsetIndex(in: []))
    }

    // MARK: - Extraction

    func testExtractTrimsLeadingSilenceToPreRoll() throws {
        let sampleRate = 48000.0
        let leadingSilence = 2000 // > pre-roll
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: sampleRate, decaySeconds: 1.0, leadingSilence: leadingSilence
        )
        let ir = try ImpulseCaptureProcessing.extractImpulseResponse(
            from: recording, sampleRate: sampleRate, preRollSeconds: 0.005
        )
        let preRoll = Int(0.005 * sampleRate) // 240 samples
        XCTAssertEqual(ir.count, recording.count - (leadingSilence - preRoll))
    }

    func testExtractEmptyThrows() {
        XCTAssertThrowsError(
            try ImpulseCaptureProcessing.extractImpulseResponse(from: [], sampleRate: 48000)
        )
    }

    func testExtractInvalidSampleRateThrows() {
        XCTAssertThrowsError(
            try ImpulseCaptureProcessing.extractImpulseResponse(from: [1, 0.5, 0.25], sampleRate: 0)
        )
    }

    // MARK: - End-to-end RT60 (full band, tight tolerance)

    func testEndToEndRecoversKnownRT60FullBand() throws {
        let sampleRate = 48000.0
        let targetRT60 = 0.8
        let recording = syntheticRecording(
            rt60: targetRT60, sampleRate: sampleRate, decaySeconds: 2.0, leadingSilence: 1500
        )
        let ir = try ImpulseCaptureProcessing.extractImpulseResponse(
            from: recording, sampleRate: sampleRate
        )
        let rt60 = try ImpulseResponseAnalyzer.rt60(ir: ir, sampleRate: sampleRate)
        XCTAssertNotNil(rt60)
        XCTAssertEqual(rt60 ?? -1, targetRT60, accuracy: targetRT60 * 0.1)
    }

    // MARK: - Full octave-band pipeline

    func testMeasureRT60ReturnsPlausibleBands() throws {
        let sampleRate = 48000.0
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: sampleRate, decaySeconds: 2.0, leadingSilence: 500
        )
        let measured = try ImpulseCaptureProcessing.measureRT60(
            fromRecording: recording, sampleRate: sampleRate
        )
        XCTAssertFalse(measured.isEmpty)
        let standard: Set<Int> = [125, 250, 500, 1000, 2000, 4000, 8000]
        for m in measured {
            XCTAssertTrue(standard.contains(m.frequency))
            XCTAssertGreaterThan(m.rt60, 0.0)
            XCTAssertLessThan(m.rt60, 10.0)
        }
        // Results are sorted ascending by frequency.
        XCTAssertEqual(measured.map(\.frequency), measured.map(\.frequency).sorted())
    }

    func testMeasureRT60EmptyRecordingThrows() {
        XCTAssertThrowsError(
            try ImpulseCaptureProcessing.measureRT60(fromRecording: [], sampleRate: 48000)
        )
    }

    // MARK: - SNR

    func testSNREstimateHighForCleanImpulse() {
        let sampleRate = 48000.0
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: sampleRate, decaySeconds: 0.5,
            leadingSilence: 1000, noiseAmplitude: 0.001
        )
        let snr = ImpulseCaptureProcessing.estimateSNRdB(samples: recording, sampleRate: sampleRate)
        XCTAssertNotNil(snr)
        XCTAssertGreaterThan(snr ?? 0, 40.0) // peak 1.0 vs noise ~0.001 -> ~60 dB
    }

    func testSNRNilWhenNoNoiseSegment() {
        // Pure silence then impulse -> noise RMS is zero -> nil.
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: 48000, decaySeconds: 0.5, leadingSilence: 500
        )
        XCTAssertNil(ImpulseCaptureProcessing.estimateSNRdB(samples: recording, sampleRate: 48000))
    }

    // MARK: - SNR gate (minimumSNRdB)

    func testMeasureRT60ThrowsSnrUnavailableWhenGateRequestedButNoNoise() {
        // No leading silence -> onset at index 0 -> SNR cannot be estimated.
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: 48000, decaySeconds: 0.5, leadingSilence: 0
        )
        XCTAssertThrowsError(
            try ImpulseCaptureProcessing.measureRT60(
                fromRecording: recording, sampleRate: 48000, minimumSNRdB: 6.0
            )
        ) { error in
            XCTAssertEqual(error as? ImpulseCaptureProcessing.ProcessingError, .snrUnavailable)
        }
    }

    func testMeasureRT60ThrowsInsufficientSNRWhenBelowGate() {
        // Loud background noise close to the peak -> SNR well below the gate.
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: 48000, decaySeconds: 0.5,
            leadingSilence: 1000, noiseAmplitude: 0.9
        )
        XCTAssertThrowsError(
            try ImpulseCaptureProcessing.measureRT60(
                fromRecording: recording, sampleRate: 48000, minimumSNRdB: 6.0
            )
        ) { error in
            guard case ImpulseCaptureProcessing.ProcessingError.insufficientSNR = error else {
                return XCTFail("expected insufficientSNR, got \(error)")
            }
        }
    }

    func testMeasureRT60PassesGateForCleanSignal() throws {
        let sampleRate = 48000.0
        let recording = syntheticRecording(
            rt60: 0.8, sampleRate: sampleRate, decaySeconds: 2.0,
            leadingSilence: 1000, noiseAmplitude: 0.001
        )
        let measured = try ImpulseCaptureProcessing.measureRT60(
            fromRecording: recording, sampleRate: sampleRate, minimumSNRdB: 6.0
        )
        XCTAssertFalse(measured.isEmpty)
    }

    // MARK: - Measured vs. predicted (Sabine as verification)

    func testCompareMatchesByFrequency() {
        let measured = [
            RT60Measurement(frequency: 500, rt60: 0.90),
            RT60Measurement(frequency: 1000, rt60: 0.80),
            RT60Measurement(frequency: 2000, rt60: 0.70)
        ]
        let predicted = [
            RT60Measurement(frequency: 500, rt60: 1.00),
            RT60Measurement(frequency: 1000, rt60: 0.80)
            // 2000 Hz intentionally missing -> dropped
        ]
        let comparison = ImpulseCaptureProcessing.compare(measured: measured, predicted: predicted)
        XCTAssertEqual(comparison.count, 2)
        XCTAssertEqual(comparison[0].frequency, 500)
        XCTAssertEqual(comparison[0].deltaSeconds, -0.10, accuracy: 1e-9)
        XCTAssertEqual(comparison[0].relativeError, -0.10, accuracy: 1e-9)
        XCTAssertEqual(comparison[1].frequency, 1000)
        XCTAssertEqual(comparison[1].deltaSeconds, 0.0, accuracy: 1e-9)
    }
}
