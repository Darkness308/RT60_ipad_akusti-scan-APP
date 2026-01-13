//
//  AcoustiScanApp.swift
//  AcoustiScanApp
//
//  Created by Marc Schneider-Handrup on 26.05.25.
//  Enhanced with State Injection and Audio Manager
//

import SwiftUI
import AVFoundation

@main
struct AcoustiScanApp: App {
    // MARK: - State Objects

    /// Central surface store for room data
    @StateObject private var surfaceStore = SurfaceStore()

    /// Material database manager
    @StateObject private var materialManager = MaterialManager()

    /// Audio manager for USB microphone input
    @StateObject private var audioManager = AudioManager()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(surfaceStore)
                .environmentObject(materialManager)
                .environmentObject(audioManager)
                .onAppear {
                    configureAudioSession()
                }
        }
    }

    // MARK: - Audio Configuration

    /// Configure audio session for USB Class-1 microphone support
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Configure for measurement mode with USB input support
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )

            // Set preferred sample rate for professional audio (48kHz)
            try audioSession.setPreferredSampleRate(48000.0)

            // Set preferred buffer duration for low latency
            try audioSession.setPreferredIOBufferDuration(0.005)

            // Activate the session
            try audioSession.setActive(true)

            // Log available inputs for debugging
            if let inputs = audioSession.availableInputs {
                for input in inputs {
                    print("Available audio input: \(input.portName) - \(input.portType.rawValue)")
                }
            }

        } catch {
            ErrorLogger.log(
                error,
                context: "AcoustiScanApp.configureAudioSession",
                level: .error
            )
        }
    }
}
