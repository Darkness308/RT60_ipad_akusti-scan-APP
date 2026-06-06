//  RT60MeasurementView.swift
//  AcoustiScanApp
//
//  UI for impulse-based RT60 MEASUREMENT (microphone) — as opposed to the Sabine
//  CALCULATION shown in RT60View. Records an impulsive excitation (hand clap /
//  balloon pop), computes octave-band RT60 from the impulse response (ISO 3382 /
//  Schroeder, via AcoustiScanConsolidated) and shows it next to the Sabine
//  prediction so the prediction VERIFIES the measurement.
//
//  Runtime: needs a device with a microphone and granted record permission
//  (NSMicrophoneUsageDescription is already set in Info.plist).

import SwiftUI
import AVFoundation
import AcoustiScanConsolidated

@MainActor
final class RT60MeasurementViewModel: ObservableObject {

    enum Status: Equatable {
        case idle
        case recording
        case finished
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var measured: [RT60Measurement] = []

    private let predictedByFrequency: [Int: Double]

    init(predicted: [RT60Measurement]) {
        self.predictedByFrequency = Dictionary(
            predicted.map { ($0.frequency, $0.rt60) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var isRecording: Bool { status == .recording }

    /// Sabine-predicted RT60 for a band, if known.
    func predicted(at frequency: Int) -> Double? { predictedByFrequency[frequency] }

    func measure(durationSeconds: TimeInterval = 3.0) async {
        #if os(iOS)
        status = .recording
        measured = []

        guard await Self.ensureMicrophonePermission() else {
            status = .failed("Mikrofonzugriff wurde nicht erteilt. Bitte in den iOS-Einstellungen aktivieren.")
            return
        }

        do {
            let recorder = AudioImpulseRecorder()
            measured = try await recorder.measureRT60(duration: durationSeconds)
            status = .finished
        } catch {
            status = .failed(Self.describe(error))
        }
        #else
        status = .failed("Die Audio-Messung ist nur auf iOS verfügbar.")
        #endif
    }

    #if os(iOS)
    private static func ensureMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    #endif

    private static func describe(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

struct RT60MeasurementView: View {
    @StateObject private var viewModel: RT60MeasurementViewModel

    init(store: SurfaceStore) {
        let predicted = store.calculateRT60Spectrum()
            .sorted { $0.key < $1.key }
            .map { RT60Measurement(frequency: $0.key, rt60: $0.value) }
        _viewModel = StateObject(wrappedValue: RT60MeasurementViewModel(predicted: predicted))
    }

    var body: some View {
        List {
            Section(
                footer: Text("Impulsmessung: am Messpunkt ein kurzes, lautes Geräusch (Klatschen/Ballon) auslösen. RT60 wird aus der Impulsantwort bestimmt (ISO 3382, Schroeder) und mit der Sabine-Prognose verglichen.")
            ) {
                Button {
                    Task { await viewModel.measure() }
                } label: {
                    Label(viewModel.isRecording ? "Messung läuft …" : "Messung starten",
                          systemImage: "mic.fill")
                }
                .disabled(viewModel.isRecording)
                .accessibilityIdentifier("startMeasurementButton")
            }

            switch viewModel.status {
            case .failed(let message):
                Section {
                    Text(message).foregroundStyle(.red)
                }
            case .finished:
                if viewModel.measured.isEmpty {
                    Section {
                        Text("Keine auswertbaren Bänder – zu wenig Pegel oder Abklingen. Lauter / näher messen.")
                    }
                } else {
                    Section(header: Text("Gemessen (Δ = gemessen − Sabine)")) {
                        ForEach(viewModel.measured, id: \.frequency) { measurement in
                            HStack {
                                Text("\(measurement.frequency) Hz")
                                Spacer()
                                Text(String(format: "%.2f s", measurement.rt60))
                                if let predicted = viewModel.predicted(at: measurement.frequency) {
                                    Text(String(format: "Δ %+.2f s", measurement.rt60 - predicted))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("measuredRow\(measurement.frequency)")
                        }
                    }
                }
            case .idle, .recording:
                EmptyView()
            }
        }
        .navigationTitle("Impulsmessung")
    }
}
