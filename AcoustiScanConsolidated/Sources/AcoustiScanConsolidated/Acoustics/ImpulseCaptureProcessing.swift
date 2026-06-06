// ImpulseCaptureProcessing.swift
// AcoustiScan
//
// The missing link between a microphone RECORDING and the (already tested)
// Schroeder/RT60 DSP in `ImpulseResponseAnalyzer`:
//   raw recording  ->  impulse response  ->  octave-band RT60  ->  vs. Sabine
//
// Method: impulse excitation (hand clap / balloon pop). We locate the impulse
// onset (largest absolute amplitude), trim the pre-roll, and hand the decay to
// `ImpulseResponseAnalyzer.rt60PerOctaveBand`.
//
// Verification: every function here is pure ([Float] in, value out) and covered
// by unit tests (`ImpulseCaptureProcessingTests`). The audio I/O itself lives in
// `AudioImpulseRecorder` (iOS only) and is compile-checked by the iOS app build,
// but requires a real device + microphone to run.

import Foundation

/// Pure signal processing that turns a raw recording into a usable room impulse
/// response and an octave-band RT60 result, plus a comparison against a
/// (Sabine-)predicted RT60 so the prediction can VERIFY the measurement.
public enum ImpulseCaptureProcessing {

    public enum ProcessingError: Error, Equatable {
        case emptyRecording
        case noOnsetFound
        case snrUnavailable
        case insufficientSNR(Double)
    }

    /// Index of the impulse onset = the sample with the largest absolute amplitude.
    /// - Returns: onset index, or `nil` if the recording is empty / all zero.
    public static func onsetIndex(in samples: [Float]) -> Int? {
        guard !samples.isEmpty else { return nil }
        var bestIndex = 0
        var bestValue: Float = -1
        for (i, sample) in samples.enumerated() {
            let magnitude = abs(sample)
            if magnitude > bestValue {
                bestValue = magnitude
                bestIndex = i
            }
        }
        return bestValue > 0 ? bestIndex : nil
    }

    /// Extract the impulse response: keep a short pre-roll before the onset and
    /// everything after it (the decay tail).
    /// - Throws: `ProcessingError`/`AnalysisError` for empty input or bad sample rate.
    public static func extractImpulseResponse(
        from samples: [Float],
        sampleRate: Double,
        preRollSeconds: Double = 0.005
    ) throws -> [Float] {
        guard !samples.isEmpty else { throw ProcessingError.emptyRecording }
        guard sampleRate > 0 else {
            throw ImpulseResponseAnalyzer.AnalysisError.invalidSampleRate(sampleRate)
        }
        guard let onset = onsetIndex(in: samples) else { throw ProcessingError.noOnsetFound }

        let preRoll = max(0, Int(preRollSeconds * sampleRate))
        let start = max(0, onset - preRoll)
        return Array(samples[start...])
    }

    /// Estimate signal-to-noise ratio (dB): onset peak vs. RMS of the pre-onset
    /// segment (treated as background noise). Returns `nil` if no usable noise
    /// segment exists (e.g. onset at the very start or perfect silence).
    public static func estimateSNRdB(samples: [Float], sampleRate: Double) -> Double? {
        guard let onset = onsetIndex(in: samples), onset > 1 else { return nil }
        let noise = samples[0..<onset]
        let peak = abs(samples[onset])
        guard peak > 0 else { return nil }
        let meanSquare = noise.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(noise.count)
        let noiseRMS = meanSquare.squareRoot()
        guard noiseRMS > 0 else { return nil }
        return 20.0 * log10(Double(peak) / noiseRMS)
    }

    /// Full pipeline: recording -> impulse response -> per-octave-band RT60.
    /// - Parameter minimumSNRdB: if > 0 and the estimated SNR is below it, throws
    ///   `insufficientSNR` instead of returning an unreliable result.
    public static func measureRT60(
        fromRecording samples: [Float],
        sampleRate: Double,
        minimumSNRdB: Double = 0.0
    ) throws -> [RT60Measurement] {
        if minimumSNRdB > 0 {
            guard let snr = estimateSNRdB(samples: samples, sampleRate: sampleRate) else {
                throw ProcessingError.snrUnavailable
            }
            if snr < minimumSNRdB {
                throw ProcessingError.insufficientSNR(snr)
            }
        }
        let ir = try extractImpulseResponse(from: samples, sampleRate: sampleRate)
        let byBand = try ImpulseResponseAnalyzer.rt60PerOctaveBand(ir: ir, sampleRate: sampleRate)
        return byBand
            .sorted { $0.key < $1.key }
            .map { RT60Measurement(frequency: $0.key, rt60: $0.value) }
    }

    // MARK: - Measured vs. predicted (Sabine as verification)

    /// One frequency band: measured RT60 vs. predicted (Sabine) RT60.
    public struct RT60Comparison: Equatable {
        public let frequency: Int
        public let measured: Double
        public let predicted: Double

        public init(frequency: Int, measured: Double, predicted: Double) {
            self.frequency = frequency
            self.measured = measured
            self.predicted = predicted
        }

        /// Absolute deviation in seconds (measured − predicted).
        public var deltaSeconds: Double { measured - predicted }

        /// Relative deviation (measured − predicted) / predicted; 0 if predicted == 0.
        public var relativeError: Double {
            predicted != 0 ? (measured - predicted) / predicted : 0
        }
    }

    /// Compare a measured RT60 spectrum against a predicted (Sabine) one,
    /// matched by frequency. Bands without a prediction are dropped.
    public static func compare(
        measured: [RT60Measurement],
        predicted: [RT60Measurement]
    ) -> [RT60Comparison] {
        let predictedByFrequency = Dictionary(
            predicted.map { ($0.frequency, $0.rt60) },
            uniquingKeysWith: { first, _ in first }
        )
        return measured.compactMap { m in
            guard let p = predictedByFrequency[m.frequency] else { return nil }
            return RT60Comparison(frequency: m.frequency, measured: m.rt60, predicted: p)
        }
        .sorted { $0.frequency < $1.frequency }
    }
}
