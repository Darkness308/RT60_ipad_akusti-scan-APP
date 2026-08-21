//
//  RT60View.swift
//  AcoustiScanApp
//
//  RT60 calculation view with frequency-dependent absorption coefficients
//  Fixed: Now correctly uses frequency-specific absorption values
//

import SwiftUI

struct RT60View: View {
    @ObservedObject var store: SurfaceStore

    /// Standard octave band frequencies for RT60 calculation
    private let frequencies = AbsorptionData.standardFrequencies

    /// Calculate RT60 using Sabine formula for a specific frequency
    /// Formula: RT60 = 0.161 * V / A
    /// Where V = room volume (m³), A = total absorption area (m² Sabine)
    /// - Parameter frequency: Target frequency in Hz
    /// - Returns: RT60 value in seconds
    func calculateRT60(frequency: Int) -> Double {
        // Use SurfaceStore's built-in calculation which correctly handles frequency
        return store.calculateRT60(at: frequency) ?? 0.0
    }

    /// Calculate using Eyring formula (more accurate for high absorption)
    /// Formula: RT60 = 0.161 * V / (-S * ln(1 - α_avg))
    /// - Parameter frequency: Target frequency in Hz
    /// - Returns: RT60 value in seconds using Eyring formula
    func calculateRT60Eyring(frequency: Int) -> Double {
        guard store.roomVolume > 0, store.totalArea > 0 else { return 0.0 }

        let totalAbsorption = store.totalAbsorption(at: frequency)
        let avgAbsorption = totalAbsorption / store.totalArea

        // Eyring formula handles high absorption better
        guard avgAbsorption > 0, avgAbsorption < 1 else {
            return calculateRT60(frequency: frequency)
        }

        return 0.161 * store.roomVolume / (-store.totalArea * log(1 - avgAbsorption))
    }

    /// Determine which formula to use based on average absorption
    func recommendedRT60(frequency: Int) -> Double {
        let avgAbsorption = store.totalAbsorption(at: frequency) / max(store.totalArea, 1)

        // Use Eyring for high absorption (α > 0.2), Sabine for low
        if avgAbsorption > 0.2 {
            return calculateRT60Eyring(frequency: frequency)
        }
        return calculateRT60(frequency: frequency)
    }

    var body: some View {
        List {
            // Room Summary Section
            Section {
                LabeledContent("Raumname", value: store.roomName)
                LabeledContent("Volumen", value: String(format: "%.2f m³", store.roomVolume))
                LabeledContent("Gesamtfläche", value: String(format: "%.2f m²", store.totalArea))
                LabeledContent("Oberflächen", value: "\(store.surfaces.count)")

                // Material assignment progress
                ProgressView(
                    "Materialzuweisung",
                    value: store.materialAssignmentProgress
                )
                .tint(store.allSurfacesHaveMaterials ? .green : .orange)
            } header: {
                Text("Raumdaten")
                    .accessibilityAddTraits(.isHeader)
            }

            // RT60 Results Section
            Section {
                if store.surfaces.isEmpty {
                    ContentUnavailableView(
                        "Keine Oberflächen",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Scannen Sie zuerst einen Raum")
                    )
                } else if !store.allSurfacesHaveMaterials {
                    ContentUnavailableView(
                        "Materialien fehlen",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Weisen Sie allen Oberflächen Materialien zu")
                    )
                } else {
                    ForEach(frequencies, id: \.self) { freq in
                        RT60FrequencyRow(
                            frequency: freq,
                            sabineValue: calculateRT60(frequency: freq),
                            eyringValue: calculateRT60Eyring(frequency: freq),
                            recommendedValue: recommendedRT60(frequency: freq)
                        )
                    }
                }
            } header: {
                Text("RT60 je Frequenz")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("rt60Header")
            } footer: {
                if store.allSurfacesHaveMaterials {
                    Text("Sabine-Formel für α < 0.2, Eyring für α ≥ 0.2")
                        .font(.caption)
                }
            }

            // DIN 18041 Evaluation Section
            if store.allSurfacesHaveMaterials {
                Section {
                    DIN18041EvaluationRow(store: store)
                } header: {
                    Text("DIN 18041 Bewertung")
                }
            }

            // Absorption Details Section
            Section {
                ForEach(frequencies, id: \.self) { freq in
                    AbsorptionDetailRow(frequency: freq, store: store)
                }
            } header: {
                Text("Absorptionsfläche je Frequenz")
            }
        }
        .navigationTitle("Nachhallzeiten")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {}) {
                        Label("Als PDF exportieren", systemImage: "doc.fill")
                    }
                    Button(action: {}) {
                        Label("Messung starten", systemImage: "waveform")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct RT60FrequencyRow: View {
    let frequency: Int
    let sabineValue: Double
    let eyringValue: Double
    let recommendedValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatFrequency(frequency))
                    .font(.headline)
                    .frame(width: 80, alignment: .leading)

                Spacer()

                // Recommended value with status color
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(String(format: "%.2f s", recommendedValue))
                        .font(.title3.monospacedDigit().bold())
                }
            }

            // Detail values
            HStack {
                Text("Sabine: \(String(format: "%.2f s", sabineValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Eyring: \(String(format: "%.2f s", eyringValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(statusText)
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(frequency) Hertz")
        .accessibilityValue(String(format: "%.2f seconds, %@", recommendedValue, statusText))
        .accessibilityIdentifier("rt60Row\(frequency)")
    }

    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            return "\(freq / 1000) kHz"
        }
        return "\(freq) Hz"
    }

    private var statusColor: Color {
        if recommendedValue < 0.4 { return .blue }      // Sehr kurz
        if recommendedValue < 0.8 { return .green }     // Optimal für Sprache
        if recommendedValue < 1.2 { return .yellow }    // Akzeptabel
        if recommendedValue < 1.8 { return .orange }    // Lang
        return .red                                      // Zu lang
    }

    private var statusText: String {
        if recommendedValue < 0.4 { return "Sehr kurz" }
        if recommendedValue < 0.8 { return "Optimal" }
        if recommendedValue < 1.2 { return "Akzeptabel" }
        if recommendedValue < 1.8 { return "Lang" }
        return "Zu lang"
    }
}

struct AbsorptionDetailRow: View {
    let frequency: Int
    @ObservedObject var store: SurfaceStore

    var body: some View {
        HStack {
            Text(formatFrequency(frequency))
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text(String(format: "%.2f m² Sabine", store.totalAbsorption(at: frequency)))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            return "\(freq / 1000) kHz"
        }
        return "\(freq) Hz"
    }
}

struct DIN18041EvaluationRow: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: dinComplianceIcon)
                    .foregroundStyle(dinComplianceColor)
                Text(dinComplianceText)
                    .font(.headline)
            }

            Text("Basierend auf Mittelwert 500 Hz - 1 kHz")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var averageRT60: Double {
        let rt500 = store.calculateRT60(at: 500) ?? 0
        let rt1000 = store.calculateRT60(at: 1000) ?? 0
        return (rt500 + rt1000) / 2
    }

    private var dinComplianceIcon: String {
        if averageRT60 < 0.6 { return "checkmark.seal.fill" }
        if averageRT60 < 1.0 { return "checkmark.circle.fill" }
        if averageRT60 < 1.5 { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }

    private var dinComplianceColor: Color {
        if averageRT60 < 0.6 { return .green }
        if averageRT60 < 1.0 { return .blue }
        if averageRT60 < 1.5 { return .orange }
        return .red
    }

    private var dinComplianceText: String {
        if averageRT60 < 0.6 { return "Sehr gut (DIN 18041 A)" }
        if averageRT60 < 1.0 { return "Gut (DIN 18041 B)" }
        if averageRT60 < 1.5 { return "Ausreichend (DIN 18041 C)" }
        return "Verbesserung erforderlich"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RT60View(store: SurfaceStore())
    }
}
