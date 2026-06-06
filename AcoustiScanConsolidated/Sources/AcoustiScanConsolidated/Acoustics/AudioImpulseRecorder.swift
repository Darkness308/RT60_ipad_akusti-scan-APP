// AudioImpulseRecorder.swift
// AcoustiScan
//
// Microphone capture for an impulsive excitation (hand clap / balloon pop),
// feeding the recorded signal into `ImpulseCaptureProcessing` for octave-band
// RT60. This is the audio INPUT that was previously missing entirely.
//
// VERIFICATION STATUS: iOS-only; compile-checked by the iOS app build (the app
// links AcoustiScanConsolidated, so this whole library is compiled for the
// simulator). It is NOT unit-tested — there is no headless microphone in CI.
// The testable signal processing lives in `ImpulseCaptureProcessing`.
//
// Runtime requirements (device): `NSMicrophoneUsageDescription` in the app's
// Info.plist and a granted record permission. Requesting permission is the
// responsibility of the app layer (kept out here to avoid OS-version-specific
// permission APIs leaking into the cross-platform package).

#if os(iOS)
import Foundation
import AVFoundation
/// Records a short mono signal from the microphone and computes octave-band
/// RT60 via `ImpulseCaptureProcessing` + `ImpulseResponseAnalyzer`.
public final class AudioImpulseRecorder {

    public enum RecorderError: Error {
        case engineFailure(String)
        case sessionFailure(String)
    }

    private let engine = AVAudioEngine()

    public init() {}

    /// Capture `duration` seconds of mono audio.
    /// - Returns: raw samples and the hardware sample rate (Hz).
    public func record(duration: TimeInterval = 3.0) async throws -> (samples: [Float], sampleRate: Double) {
        try configureSession()

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate

        var collected: [Float] = []
        // Pre-reserve to limit reallocations while the audio tap appends on its
        // real-time thread. A lock-free ring buffer is the fully robust solution
        // (see #289 review) and is deferred until on-device dropouts are observed.
        if sampleRate > 0 {
            collected.reserveCapacity(Int(sampleRate * max(0, duration)) + 4096)
        }
        let lock = NSLock()

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            lock.lock()
            collected.append(contentsOf: UnsafeBufferPointer(start: channel, count: frameCount))
            lock.unlock()
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw RecorderError.engineFailure(error.localizedDescription)
        }

        defer {
            input.removeTap(onBus: 0)
            engine.stop()
        }

        let nanoseconds = UInt64(max(0, duration) * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)

        lock.lock()
        let samples = collected
        lock.unlock()
        return (samples, sampleRate)
    }

    /// Convenience: record, then compute octave-band RT60 from the recording.
    public func measureRT60(duration: TimeInterval = 3.0,
                            minimumSNRdB: Double = 0.0) async throws -> [RT60Measurement] {
        let (samples, sampleRate) = try await record(duration: duration)
        return try ImpulseCaptureProcessing.measureRT60(
            fromRecording: samples,
            sampleRate: sampleRate,
            minimumSNRdB: minimumSNRdB
        )
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
        } catch {
            throw RecorderError.sessionFailure(error.localizedDescription)
        }
    }
}
#endif
