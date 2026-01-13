//
//  AudioManager.swift
//  AcoustiScanApp
//
//  USB Class-1 Microphone and RT60 Audio Measurement Manager
//  Supports professional measurement microphones via USB3/Lightning
//

import Foundation
import AVFoundation
import Accelerate
import Combine

// MARK: - Audio Input Device

/// Represents an available audio input device
public struct AudioInputDevice: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let portType: AVAudioSession.Port
    public let isUSB: Bool
    public let isBuiltIn: Bool

    /// Device quality classification
    public var qualityClass: MicrophoneClass {
        if isUSB && (name.lowercased().contains("class") || name.lowercased().contains("measurement")) {
            return .class1
        } else if isUSB {
            return .class2
        } else if isBuiltIn {
            return .builtin
        }
        return .unknown
    }
}

/// Microphone quality classification per IEC 61672
public enum MicrophoneClass: String, CaseIterable {
    case class1 = "Class 1"     // Professional measurement (±0.7 dB)
    case class2 = "Class 2"     // General purpose (±1.0 dB)
    case builtin = "Built-in"   // iPad internal microphone
    case unknown = "Unknown"

    public var toleranceDB: Double {
        switch self {
        case .class1: return 0.7
        case .class2: return 1.0
        case .builtin: return 3.0
        case .unknown: return 5.0
        }
    }

    public var isCalibrated: Bool {
        switch self {
        case .class1, .class2: return true
        default: return false
        }
    }
}

// MARK: - Measurement State

/// Current state of audio measurement
public enum MeasurementState: Equatable {
    case idle
    case preparing
    case recording
    case analyzing
    case completed
    case error(String)
}

// MARK: - RT60 Measurement Result

/// Result of a single RT60 measurement
public struct RT60MeasurementResult: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let frequency: Int
    public let t20: Double?         // T20 value in seconds
    public let t30: Double?         // T30 value in seconds
    public let edt: Double?         // Early Decay Time
    public let correlation: Double  // Correlation coefficient (0-100%)
    public let noiseFloor: Double   // Background noise in dB
    public let peakLevel: Double    // Peak signal level in dB

    /// Calculated RT60 (prefers T30, falls back to T20)
    public var rt60: Double? {
        return t30 ?? t20
    }

    /// Measurement quality assessment
    public var quality: MeasurementQuality {
        guard let rt60 = rt60 else { return .invalid }

        if correlation >= 99 && noiseFloor < -60 {
            return .excellent
        } else if correlation >= 95 && noiseFloor < -50 {
            return .good
        } else if correlation >= 90 && noiseFloor < -40 {
            return .acceptable
        } else if correlation >= 80 {
            return .marginal
        }
        return .invalid
    }
}

/// Measurement quality levels
public enum MeasurementQuality: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case acceptable = "Acceptable"
    case marginal = "Marginal"
    case invalid = "Invalid"

    public var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .marginal: return "orange"
        case .invalid: return "red"
        }
    }
}

// MARK: - Audio Manager

/// Manages audio input, recording, and RT60 analysis
@MainActor
public class AudioManager: ObservableObject {

    // MARK: - Published Properties

    @Published public var availableInputs: [AudioInputDevice] = []
    @Published public var selectedInput: AudioInputDevice?
    @Published public var measurementState: MeasurementState = .idle
    @Published public var currentLevel: Float = -100.0  // dB
    @Published public var peakLevel: Float = -100.0     // dB
    @Published public var isMonitoring: Bool = false
    @Published public var measurements: [RT60MeasurementResult] = []
    @Published public var frequencySpectrum: [Float] = []

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var recordingBuffer: AVAudioPCMBuffer?
    private var recordedSamples: [Float] = []

    // MARK: - FFT Setup

    private var fftSetup: vDSP_DFT_Setup?
    private let fftSize: Int = 4096
    private var hannWindow: [Float] = []

    // MARK: - Configuration

    public let sampleRate: Double = 48000.0
    public let recordingDuration: TimeInterval = 5.0
    public let standardFrequencies = [125, 250, 500, 1000, 2000, 4000, 8000]

    // MARK: - Initialization

    public init() {
        setupFFT()
        setupHannWindow()
        refreshAvailableInputs()
        setupNotifications()
    }

    deinit {
        stopMonitoring()
        if let setup = fftSetup {
            vDSP_DFT_Destroy(setup)
        }
    }

    // MARK: - Setup

    private func setupFFT() {
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            .FORWARD
        )
    }

    private func setupHannWindow() {
        hannWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hannWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAvailableInputs()
            }
        }
    }

    // MARK: - Input Device Management

    /// Refresh list of available audio inputs
    public func refreshAvailableInputs() {
        let session = AVAudioSession.sharedInstance()
        guard let inputs = session.availableInputs else {
            availableInputs = []
            return
        }

        availableInputs = inputs.map { port in
            let isUSB = port.portType == .usbAudio
            let isBuiltIn = port.portType == .builtInMic

            return AudioInputDevice(
                id: port.uid,
                name: port.portName,
                portType: port.portType,
                isUSB: isUSB,
                isBuiltIn: isBuiltIn
            )
        }

        // Auto-select USB Class-1 if available
        if selectedInput == nil {
            selectedInput = availableInputs.first { $0.qualityClass == .class1 }
                ?? availableInputs.first { $0.isUSB }
                ?? availableInputs.first
        }
    }

    /// Select a specific audio input device
    public func selectInput(_ device: AudioInputDevice) {
        let session = AVAudioSession.sharedInstance()
        guard let inputs = session.availableInputs,
              let port = inputs.first(where: { $0.uid == device.id }) else {
            return
        }

        do {
            try session.setPreferredInput(port)
            selectedInput = device
        } catch {
            ErrorLogger.log(
                error,
                context: "AudioManager.selectInput",
                level: .error
            )
        }
    }

    // MARK: - Level Monitoring

    /// Start real-time level monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }

        do {
            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else { return }

            inputNode = engine.inputNode
            let format = inputNode?.outputFormat(forBus: 0)

            inputNode?.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                Task { @MainActor in
                    self?.processMonitoringBuffer(buffer)
                }
            }

            try engine.start()
            isMonitoring = true

        } catch {
            ErrorLogger.log(
                error,
                context: "AudioManager.startMonitoring",
                level: .error
            )
        }
    }

    /// Stop level monitoring
    public func stopMonitoring() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isMonitoring = false
        currentLevel = -100.0
        peakLevel = -100.0
    }

    private func processMonitoringBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS level
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameLength))
        rms = sqrt(rms)

        // Convert to dB
        let dbLevel = 20 * log10(max(rms, 1e-10))
        currentLevel = dbLevel

        // Update peak with decay
        if dbLevel > peakLevel {
            peakLevel = dbLevel
        } else {
            peakLevel = max(peakLevel - 0.5, dbLevel)
        }

        // Calculate frequency spectrum
        if frameLength >= fftSize {
            calculateSpectrum(from: channelData, frameCount: frameLength)
        }
    }

    private func calculateSpectrum(from samples: UnsafePointer<Float>, frameCount: Int) {
        guard let setup = fftSetup else { return }

        var input = [Float](repeating: 0, count: fftSize)
        var inputImag = [Float](repeating: 0, count: fftSize)
        var output = [Float](repeating: 0, count: fftSize)
        var outputImag = [Float](repeating: 0, count: fftSize)

        // Copy samples and apply Hann window
        for i in 0..<min(frameCount, fftSize) {
            input[i] = samples[i] * hannWindow[i]
        }

        // Perform FFT
        vDSP_DFT_Execute(setup, &input, &inputImag, &output, &outputImag)

        // Calculate magnitude spectrum
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        for i in 0..<fftSize / 2 {
            magnitudes[i] = sqrt(output[i] * output[i] + outputImag[i] * outputImag[i])
        }

        // Convert to dB and update
        var dbSpectrum = [Float](repeating: 0, count: fftSize / 2)
        for i in 0..<fftSize / 2 {
            dbSpectrum[i] = 20 * log10(max(magnitudes[i], 1e-10))
        }

        frequencySpectrum = dbSpectrum
    }

    // MARK: - RT60 Measurement

    /// Start RT60 measurement for all standard frequencies
    public func startMeasurement() async {
        measurementState = .preparing
        recordedSamples = []
        measurements = []

        do {
            // Configure audio engine for recording
            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else {
                measurementState = .error("Failed to initialize audio engine")
                return
            }

            inputNode = engine.inputNode
            let format = inputNode?.outputFormat(forBus: 0)
            let expectedSamples = Int(sampleRate * recordingDuration)

            measurementState = .recording

            // Install recording tap
            inputNode?.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                guard let self = self else { return }
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)

                let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                Task { @MainActor in
                    self.recordedSamples.append(contentsOf: samples)
                }
            }

            try engine.start()

            // Wait for recording duration
            try await Task.sleep(nanoseconds: UInt64(recordingDuration * 1_000_000_000))

            // Stop recording
            inputNode?.removeTap(onBus: 0)
            engine.stop()

            // Analyze recorded audio
            measurementState = .analyzing
            await analyzeRecording()

            measurementState = .completed

        } catch {
            measurementState = .error(error.localizedDescription)
            ErrorLogger.log(
                error,
                context: "AudioManager.startMeasurement",
                level: .error
            )
        }
    }

    /// Analyze recorded audio and extract RT60 for each frequency band
    private func analyzeRecording() async {
        guard !recordedSamples.isEmpty else { return }

        for frequency in standardFrequencies {
            if let result = analyzeFrequencyBand(frequency: frequency) {
                measurements.append(result)
            }
        }
    }

    /// Analyze a single frequency band using Schroeder integration
    private func analyzeFrequencyBand(frequency: Int) -> RT60MeasurementResult? {
        // Apply bandpass filter around the target frequency
        let filteredSamples = applyBandpassFilter(
            samples: recordedSamples,
            centerFrequency: Double(frequency),
            bandwidth: Double(frequency) * 0.23  // 1/3 octave bandwidth
        )

        guard !filteredSamples.isEmpty else { return nil }

        // Calculate energy decay curve using Schroeder integration
        let energyCurve = calculateSchroederIntegral(samples: filteredSamples)

        // Find decay parameters
        let (t20, t30, correlation) = extractDecayParameters(from: energyCurve)

        // Calculate noise floor and peak
        let noiseFloor = calculateNoiseFloor(samples: filteredSamples)
        let peakLevel = calculatePeakLevel(samples: filteredSamples)

        return RT60MeasurementResult(
            timestamp: Date(),
            frequency: frequency,
            t20: t20,
            t30: t30,
            edt: nil,  // Could be calculated similarly
            correlation: correlation,
            noiseFloor: noiseFloor,
            peakLevel: peakLevel
        )
    }

    // MARK: - Signal Processing

    /// Apply bandpass filter using Butterworth design
    private func applyBandpassFilter(
        samples: [Float],
        centerFrequency: Double,
        bandwidth: Double
    ) -> [Float] {
        // Simple IIR bandpass filter implementation
        let lowCutoff = centerFrequency - bandwidth / 2
        let highCutoff = centerFrequency + bandwidth / 2

        let nyquist = sampleRate / 2
        let lowNorm = lowCutoff / nyquist
        let highNorm = highCutoff / nyquist

        // Butterworth coefficients (2nd order)
        let w0 = tan(.pi * (highNorm - lowNorm) / 2)
        let q = 0.707107  // 1/sqrt(2)

        let alpha = w0 / (2 * q)
        let cosW0 = cos(.pi * (highNorm + lowNorm) / 2)

        let b0 = Float(alpha)
        let b1: Float = 0
        let b2 = Float(-alpha)
        let a0 = Float(1 + alpha)
        let a1 = Float(-2 * cosW0)
        let a2 = Float(1 - alpha)

        // Normalize coefficients
        let b0n = b0 / a0
        let b1n = b1 / a0
        let b2n = b2 / a0
        let a1n = a1 / a0
        let a2n = a2 / a0

        // Apply filter
        var output = [Float](repeating: 0, count: samples.count)
        var x1: Float = 0, x2: Float = 0
        var y1: Float = 0, y2: Float = 0

        for i in 0..<samples.count {
            let x0 = samples[i]
            output[i] = b0n * x0 + b1n * x1 + b2n * x2 - a1n * y1 - a2n * y2

            x2 = x1
            x1 = x0
            y2 = y1
            y1 = output[i]
        }

        return output
    }

    /// Calculate Schroeder backward integration for energy decay
    private func calculateSchroederIntegral(samples: [Float]) -> [Float] {
        // Square the samples to get energy
        var energy = samples.map { $0 * $0 }

        // Backward integration (Schroeder method)
        var integral = [Float](repeating: 0, count: energy.count)
        var sum: Float = 0

        for i in stride(from: energy.count - 1, through: 0, by: -1) {
            sum += energy[i]
            integral[i] = sum
        }

        // Convert to dB
        let maxVal = integral.max() ?? 1
        return integral.map { 10 * log10(max($0 / maxVal, 1e-10)) }
    }

    /// Extract T20 and T30 from energy decay curve using linear regression
    private func extractDecayParameters(from curve: [Float]) -> (t20: Double?, t30: Double?, correlation: Double) {
        // Find -5dB and -35dB points for T30, -5dB and -25dB for T20
        let startIdx = curve.firstIndex { $0 <= -5 } ?? 0
        let t20EndIdx = curve.firstIndex { $0 <= -25 }
        let t30EndIdx = curve.firstIndex { $0 <= -35 }

        var t20: Double?
        var t30: Double?
        var correlation: Double = 0

        // Calculate T20
        if let endIdx = t20EndIdx, endIdx > startIdx {
            let (slope, r2) = linearRegression(
                x: Array(startIdx..<endIdx).map { Double($0) / sampleRate },
                y: Array(curve[startIdx..<endIdx]).map { Double($0) }
            )
            if slope < 0 {
                t20 = -60.0 / slope  // Extrapolate to -60dB
                correlation = r2 * 100
            }
        }

        // Calculate T30
        if let endIdx = t30EndIdx, endIdx > startIdx {
            let (slope, r2) = linearRegression(
                x: Array(startIdx..<endIdx).map { Double($0) / sampleRate },
                y: Array(curve[startIdx..<endIdx]).map { Double($0) }
            )
            if slope < 0 {
                t30 = -60.0 / slope  // Extrapolate to -60dB
                correlation = max(correlation, r2 * 100)
            }
        }

        return (t20, t30, correlation)
    }

    /// Linear regression for decay slope calculation
    private func linearRegression(x: [Double], y: [Double]) -> (slope: Double, r2: Double) {
        guard x.count == y.count, x.count > 1 else { return (0, 0) }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)

        // Calculate R²
        let meanY = sumY / n
        let ssTotal = y.map { ($0 - meanY) * ($0 - meanY) }.reduce(0, +)
        let intercept = (sumY - slope * sumX) / n
        let ssResidual = zip(x, y).map { (slope * $0 + intercept - $1) * (slope * $0 + intercept - $1) }.reduce(0, +)
        let r2 = 1 - ssResidual / max(ssTotal, 1e-10)

        return (slope, max(0, r2))
    }

    /// Calculate noise floor from quiet portion of signal
    private func calculateNoiseFloor(samples: [Float]) -> Double {
        // Use last 10% of samples as noise estimate
        let noiseStart = Int(Double(samples.count) * 0.9)
        let noiseSamples = Array(samples[noiseStart...])

        var rms: Float = 0
        vDSP_measqv(noiseSamples, 1, &rms, vDSP_Length(noiseSamples.count))
        rms = sqrt(rms)

        return Double(20 * log10(max(rms, 1e-10)))
    }

    /// Calculate peak level
    private func calculatePeakLevel(samples: [Float]) -> Double {
        var peak: Float = 0
        vDSP_maxmgv(samples, 1, &peak, vDSP_Length(samples.count))
        return Double(20 * log10(max(peak, 1e-10)))
    }

    // MARK: - Results

    /// Get RT60 values as dictionary for integration with SurfaceStore
    public func getRT60Dictionary() -> [Int: Double] {
        var result: [Int: Double] = [:]
        for measurement in measurements {
            if let rt60 = measurement.rt60 {
                result[measurement.frequency] = rt60
            }
        }
        return result
    }

    /// Average measurement quality across all frequencies
    public var overallQuality: MeasurementQuality {
        guard !measurements.isEmpty else { return .invalid }

        let avgCorrelation = measurements.map { $0.correlation }.reduce(0, +) / Double(measurements.count)

        if avgCorrelation >= 99 {
            return .excellent
        } else if avgCorrelation >= 95 {
            return .good
        } else if avgCorrelation >= 90 {
            return .acceptable
        } else if avgCorrelation >= 80 {
            return .marginal
        }
        return .invalid
    }
}
