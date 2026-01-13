//
//  ContentView.swift
//  AcoustiScanApp
//
//  Created by Marc Schneider-Handrup on 26.05.25.
//  Enhanced with full navigation and acoustic dashboard
//

import SwiftUI

struct ContentView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var surfaceStore: SurfaceStore
    @EnvironmentObject var materialManager: MaterialManager
    @EnvironmentObject var audioManager: AudioManager

    // MARK: - State

    @State private var selectedTab: Tab = .dashboard

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case scanner = "Scanner"
        case rt60 = "RT60"
        case materials = "Materialien"
        case export = "Export"

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.xaxis"
            case .scanner: return "camera.metering.matrix"
            case .rt60: return "waveform"
            case .materials: return "square.3.layers.3d"
            case .export: return "square.and.arrow.up"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
            }
            .tag(Tab.dashboard)

            // Tab 2: LiDAR Scanner
            NavigationStack {
                LiDARScannerTab()
            }
            .tabItem {
                Label(Tab.scanner.rawValue, systemImage: Tab.scanner.icon)
            }
            .tag(Tab.scanner)

            // Tab 3: RT60 Measurement
            NavigationStack {
                RT60MeasurementTab()
            }
            .tabItem {
                Label(Tab.rt60.rawValue, systemImage: Tab.rt60.icon)
            }
            .tag(Tab.rt60)

            // Tab 4: Materials
            NavigationStack {
                MaterialEditorView(manager: materialManager)
                    .navigationTitle("Materialdatenbank")
            }
            .tabItem {
                Label(Tab.materials.rawValue, systemImage: Tab.materials.icon)
            }
            .tag(Tab.materials)

            // Tab 5: Export
            NavigationStack {
                ExportView(store: surfaceStore)
                    .navigationTitle("Export & Berichte")
            }
            .tabItem {
                Label(Tab.export.rawValue, systemImage: Tab.export.icon)
            }
            .tag(Tab.export)
        }
        .accessibilityIdentifier("mainTabView")
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var surfaceStore: SurfaceStore
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                HeaderCard()

                // Quick Stats
                QuickStatsGrid()

                // RT60 Overview Chart
                RT60OverviewCard()

                // Room Info Card
                RoomInfoCard()

                // Audio Input Card
                AudioInputCard()

                // Recent Measurements
                RecentMeasurementsCard()
            }
            .padding()
        }
        .navigationTitle("AcoustiScan RT60")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { surfaceStore.clearAll() }) {
                        Label("Neues Projekt", systemImage: "doc.badge.plus")
                    }
                    Button(action: {}) {
                        Label("Projekt laden", systemImage: "folder")
                    }
                    Divider()
                    Button(action: {}) {
                        Label("Einstellungen", systemImage: "gear")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Dashboard Components

struct HeaderCard: View {
    @EnvironmentObject var surfaceStore: SurfaceStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(surfaceStore.roomName)
                    .font(.title2.bold())
                Text("Raumakustische Analyse nach DIN 18041")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status Badge
            StatusBadge(
                status: surfaceStore.surfaces.isEmpty ? .needsScan : .ready,
                text: surfaceStore.surfaces.isEmpty ? "Scan erforderlich" : "Bereit"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatusBadge: View {
    enum Status {
        case ready, needsScan, measuring, error

        var color: Color {
            switch self {
            case .ready: return .green
            case .needsScan: return .orange
            case .measuring: return .blue
            case .error: return .red
            }
        }
    }

    let status: Status
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .cornerRadius(20)
    }
}

struct QuickStatsGrid: View {
    @EnvironmentObject var surfaceStore: SurfaceStore
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Volumen",
                value: String(format: "%.1f", surfaceStore.roomVolume),
                unit: "m³",
                icon: "cube",
                color: .blue
            )

            StatCard(
                title: "Oberflächen",
                value: "\(surfaceStore.surfaces.count)",
                unit: "",
                icon: "square.stack.3d.up",
                color: .purple
            )

            StatCard(
                title: "Fläche",
                value: String(format: "%.1f", surfaceStore.totalArea),
                unit: "m²",
                icon: "square.dashed",
                color: .green
            )

            StatCard(
                title: "Mikrofon",
                value: audioManager.selectedInput?.qualityClass.rawValue ?? "–",
                unit: "",
                icon: "mic.fill",
                color: audioManager.selectedInput?.qualityClass == .class1 ? .green : .orange
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title3.bold())
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct RT60OverviewCard: View {
    @EnvironmentObject var surfaceStore: SurfaceStore

    private let frequencies = AbsorptionData.standardFrequencies

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RT60 Übersicht")
                    .font(.headline)
                Spacer()
                Text("Sabine-Formel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if surfaceStore.surfaces.isEmpty {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "waveform.slash",
                    description: Text("Scannen Sie einen Raum, um RT60 Werte zu berechnen")
                )
                .frame(height: 150)
            } else {
                // RT60 Bar Chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(frequencies, id: \.self) { freq in
                        VStack(spacing: 4) {
                            let rt60 = surfaceStore.calculateRT60(at: freq) ?? 0

                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForRT60(rt60))
                                .frame(width: 40, height: max(20, CGFloat(rt60 * 60)))

                            // Value
                            Text(String(format: "%.2f", rt60))
                                .font(.caption2.bold())

                            // Frequency label
                            Text(formatFrequency(freq))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            return "\(freq / 1000)k"
        }
        return "\(freq)"
    }

    private func colorForRT60(_ value: Double) -> Color {
        if value < 0.4 { return .blue }
        if value < 0.8 { return .green }
        if value < 1.2 { return .yellow }
        if value < 1.6 { return .orange }
        return .red
    }
}

struct RoomInfoCard: View {
    @EnvironmentObject var surfaceStore: SurfaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raumdaten")
                .font(.headline)

            if let dims = surfaceStore.roomDimensions {
                HStack(spacing: 20) {
                    InfoItem(label: "Breite", value: String(format: "%.2f m", dims.width))
                    InfoItem(label: "Höhe", value: String(format: "%.2f m", dims.height))
                    InfoItem(label: "Tiefe", value: String(format: "%.2f m", dims.depth))
                }
            }

            Divider()

            // Surface List Preview
            if !surfaceStore.surfaces.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Oberflächen (\(surfaceStore.surfaces.count))")
                        .font(.subheadline.bold())

                    ForEach(surfaceStore.surfaces.prefix(3)) { surface in
                        HStack {
                            Text(surface.name)
                            Spacer()
                            Text(String(format: "%.2f m²", surface.area))
                                .foregroundStyle(.secondary)
                            if surface.material != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .font(.caption)
                    }

                    if surfaceStore.surfaces.count > 3 {
                        Text("+ \(surfaceStore.surfaces.count - 3) weitere...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.bold())
        }
    }
}

struct AudioInputCard: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Audio-Eingang")
                    .font(.headline)
                Spacer()
                Button(action: { audioManager.refreshAvailableInputs() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }

            if let input = audioManager.selectedInput {
                HStack {
                    Image(systemName: input.isUSB ? "cable.connector" : "mic.fill")
                        .font(.title2)
                        .foregroundStyle(input.qualityClass == .class1 ? .green : .orange)

                    VStack(alignment: .leading) {
                        Text(input.name)
                            .font(.subheadline.bold())
                        Text(input.qualityClass.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if audioManager.isMonitoring {
                        LevelMeter(level: audioManager.currentLevel)
                    }
                }

                // Device picker
                if audioManager.availableInputs.count > 1 {
                    Picker("Eingang", selection: Binding(
                        get: { audioManager.selectedInput },
                        set: { if let device = $0 { audioManager.selectInput(device) } }
                    )) {
                        ForEach(audioManager.availableInputs) { device in
                            Text(device.name).tag(device as AudioInputDevice?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } else {
                Text("Kein Audio-Eingang verfügbar")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct LevelMeter: View {
    let level: Float

    private var normalizedLevel: CGFloat {
        // Normalize -60dB to 0dB to 0-1 range
        CGFloat(max(0, min(1, (level + 60) / 60)))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 2)
                    .fill(levelColor)
                    .frame(width: geometry.size.width * normalizedLevel)
            }
        }
        .frame(width: 80, height: 8)
    }

    private var levelColor: Color {
        if level > -6 { return .red }
        if level > -12 { return .orange }
        if level > -20 { return .yellow }
        return .green
    }
}

struct RecentMeasurementsCard: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte Messungen")
                .font(.headline)

            if audioManager.measurements.isEmpty {
                ContentUnavailableView(
                    "Keine Messungen",
                    systemImage: "waveform.badge.exclamationmark",
                    description: Text("Führen Sie eine RT60-Messung durch")
                )
                .frame(height: 100)
            } else {
                ForEach(audioManager.measurements.prefix(5)) { measurement in
                    HStack {
                        Text("\(measurement.frequency) Hz")
                            .font(.caption.bold())

                        Spacer()

                        if let rt60 = measurement.rt60 {
                            Text(String(format: "%.2f s", rt60))
                                .font(.caption)
                        }

                        Text(measurement.quality.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(qualityColor(measurement.quality).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func qualityColor(_ quality: MeasurementQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .acceptable: return .yellow
        case .marginal: return .orange
        case .invalid: return .red
        }
    }
}

// MARK: - LiDAR Scanner Tab

struct LiDARScannerTab: View {
    @EnvironmentObject var surfaceStore: SurfaceStore
    @State private var showingScanView = false
    @State private var showingManualEntry = false

    var body: some View {
        VStack(spacing: 20) {
            if surfaceStore.surfaces.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("Kein Raum gescannt", systemImage: "camera.metering.matrix")
                } description: {
                    Text("Scannen Sie einen Raum mit LiDAR oder geben Sie die Maße manuell ein")
                } actions: {
                    Button(action: { showingScanView = true }) {
                        Label("LiDAR Scan starten", systemImage: "camera.metering.matrix")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { showingManualEntry = true }) {
                        Label("Manuell eingeben", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Show scan results
                List {
                    Section("Raumdaten") {
                        LabeledContent("Name", value: surfaceStore.roomName)
                        LabeledContent("Volumen", value: String(format: "%.2f m³", surfaceStore.roomVolume))
                        LabeledContent("Gesamtfläche", value: String(format: "%.2f m²", surfaceStore.totalArea))
                    }

                    Section("Oberflächen (\(surfaceStore.surfaces.count))") {
                        ForEach(surfaceStore.surfaces) { surface in
                            SurfaceRow(surface: surface)
                        }
                        .onDelete { surfaceStore.remove(at: $0) }
                    }
                }

                HStack {
                    Button(action: { showingScanView = true }) {
                        Label("Erneut scannen", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { showingManualEntry = true }) {
                        Label("Fläche hinzufügen", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Raumscanner")
        .sheet(isPresented: $showingScanView) {
            LiDARScanView(store: surfaceStore)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingManualEntry) {
            RoomDimensionView(store: surfaceStore)
        }
    }
}

struct SurfaceRow: View {
    let surface: Surface
    @EnvironmentObject var materialManager: MaterialManager
    @EnvironmentObject var surfaceStore: SurfaceStore
    @State private var showingMaterialPicker = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(surface.name)
                    .font(.headline)
                Text(String(format: "%.2f m²", surface.area))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let material = surface.material {
                Text(material.name)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Button("Material wählen") {
                    showingMaterialPicker = true
                }
                .font(.caption)
            }
        }
        .sheet(isPresented: $showingMaterialPicker) {
            MaterialPickerSheet(
                surface: surface,
                materials: materialManager.allMaterials
            ) { material in
                surfaceStore.updateMaterial(for: surface.id, material: material)
            }
        }
    }
}

struct MaterialPickerSheet: View {
    let surface: Surface
    let materials: [AcousticMaterial]
    let onSelect: (AcousticMaterial) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(materials) { material in
                Button(action: {
                    onSelect(material)
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(material.name)
                            .font(.headline)
                        HStack {
                            ForEach([500, 1000, 2000], id: \.self) { freq in
                                Text("\(freq)Hz: \(String(format: "%.2f", material.absorptionCoefficient(at: freq)))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Material für \(surface.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - RT60 Measurement Tab

struct RT60MeasurementTab: View {
    @EnvironmentObject var surfaceStore: SurfaceStore
    @EnvironmentObject var audioManager: AudioManager
    @State private var showingMeasurement = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Calculated RT60 Section
                CalculatedRT60Section()

                // Measured RT60 Section
                MeasuredRT60Section()

                // Comparison Section
                if !audioManager.measurements.isEmpty {
                    ComparisonSection()
                }

                // Measurement Controls
                MeasurementControlsSection()
            }
            .padding()
        }
        .navigationTitle("RT60 Nachhallzeit")
    }
}

struct CalculatedRT60Section: View {
    @EnvironmentObject var surfaceStore: SurfaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Berechnete RT60 (Sabine)")
                    .font(.headline)
                Spacer()
                Image(systemName: "function")
                    .foregroundStyle(.secondary)
            }

            if surfaceStore.surfaces.isEmpty || !surfaceStore.allSurfacesHaveMaterials {
                ContentUnavailableView(
                    "Daten unvollständig",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Scannen Sie einen Raum und weisen Sie allen Oberflächen Materialien zu")
                )
                .frame(height: 150)
            } else {
                RT60Table(
                    title: "Frequenz",
                    valueTitle: "RT60",
                    values: surfaceStore.calculateRT60Spectrum()
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MeasuredRT60Section: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gemessene RT60 (Impulsantwort)")
                    .font(.headline)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.secondary)
            }

            if audioManager.measurements.isEmpty {
                ContentUnavailableView(
                    "Keine Messung",
                    systemImage: "mic.slash",
                    description: Text("Führen Sie eine RT60-Messung mit dem Mikrofon durch")
                )
                .frame(height: 150)
            } else {
                RT60Table(
                    title: "Frequenz",
                    valueTitle: "RT60",
                    values: audioManager.getRT60Dictionary()
                )

                // Quality indicator
                HStack {
                    Text("Messqualität:")
                        .font(.caption)
                    Text(audioManager.overallQuality.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(qualityColor(audioManager.overallQuality))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func qualityColor(_ quality: MeasurementQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .acceptable: return .yellow
        case .marginal: return .orange
        case .invalid: return .red
        }
    }
}

struct RT60Table: View {
    let title: String
    let valueTitle: String
    let values: [Int: Double]

    private let frequencies = AbsorptionData.standardFrequencies

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(title)
                    .font(.caption.bold())
                    .frame(width: 80, alignment: .leading)
                Spacer()
                Text(valueTitle)
                    .font(.caption.bold())
                    .frame(width: 60, alignment: .trailing)
                Text("Status")
                    .font(.caption.bold())
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 8)

            Divider()

            // Rows
            ForEach(frequencies, id: \.self) { freq in
                HStack {
                    Text(formatFrequency(freq))
                        .font(.callout)
                        .frame(width: 80, alignment: .leading)
                    Spacer()

                    if let value = values[freq] {
                        Text(String(format: "%.2f s", value))
                            .font(.callout.monospacedDigit())
                            .frame(width: 60, alignment: .trailing)

                        StatusIndicator(rt60: value)
                            .frame(width: 80, alignment: .trailing)
                    } else {
                        Text("–")
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Text("–")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            return "\(freq / 1000) kHz"
        }
        return "\(freq) Hz"
    }
}

struct StatusIndicator: View {
    let rt60: Double

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
    }

    private var statusColor: Color {
        if rt60 < 0.4 { return .blue }    // Sehr kurz (gedämpft)
        if rt60 < 0.8 { return .green }   // Optimal für Sprache
        if rt60 < 1.2 { return .yellow }  // Akzeptabel
        if rt60 < 1.8 { return .orange }  // Lang
        return .red                        // Sehr lang (hallig)
    }

    private var statusText: String {
        if rt60 < 0.4 { return "Gedämpft" }
        if rt60 < 0.8 { return "Optimal" }
        if rt60 < 1.2 { return "OK" }
        if rt60 < 1.8 { return "Lang" }
        return "Hallig"
    }
}

struct ComparisonSection: View {
    @EnvironmentObject var surfaceStore: SurfaceStore
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vergleich: Berechnung vs. Messung")
                .font(.headline)

            let calculated = surfaceStore.calculateRT60Spectrum()
            let measured = audioManager.getRT60Dictionary()

            ForEach(AbsorptionData.standardFrequencies, id: \.self) { freq in
                if let calc = calculated[freq], let meas = measured[freq] {
                    let diff = abs(calc - meas)
                    let diffPercent = diff / calc * 100

                    HStack {
                        Text(formatFrequency(freq))
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)

                        ProgressView(value: min(calc, 3), total: 3)
                            .tint(.blue)

                        ProgressView(value: min(meas, 3), total: 3)
                            .tint(.green)

                        Text(String(format: "Δ%.0f%%", diffPercent))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(diffPercent < 15 ? .green : .orange)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }

            HStack {
                Circle().fill(.blue).frame(width: 8, height: 8)
                Text("Berechnet")
                    .font(.caption)
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Gemessen")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatFrequency(_ freq: Int) -> String {
        if freq >= 1000 {
            return "\(freq / 1000)k"
        }
        return "\(freq)"
    }
}

struct MeasurementControlsSection: View {
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(spacing: 16) {
            // Level meter
            if audioManager.isMonitoring {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Eingangspegel")
                        .font(.caption)
                    LargeLevelMeter(level: audioManager.currentLevel, peak: audioManager.peakLevel)
                }
            }

            // Control buttons
            HStack(spacing: 16) {
                Button(action: {
                    if audioManager.isMonitoring {
                        audioManager.stopMonitoring()
                    } else {
                        audioManager.startMonitoring()
                    }
                }) {
                    Label(
                        audioManager.isMonitoring ? "Monitoring stoppen" : "Monitoring starten",
                        systemImage: audioManager.isMonitoring ? "stop.fill" : "waveform"
                    )
                }
                .buttonStyle(.bordered)

                Button(action: {
                    Task {
                        await audioManager.startMeasurement()
                    }
                }) {
                    Label("RT60 messen", systemImage: "record.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(audioManager.measurementState == .recording || audioManager.measurementState == .analyzing)
            }

            // Measurement state
            if audioManager.measurementState != .idle {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(measurementStateText)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var measurementStateText: String {
        switch audioManager.measurementState {
        case .idle: return ""
        case .preparing: return "Vorbereitung..."
        case .recording: return "Aufnahme läuft..."
        case .analyzing: return "Analyse..."
        case .completed: return "Abgeschlossen"
        case .error(let msg): return "Fehler: \(msg)"
        }
    }
}

struct LargeLevelMeter: View {
    let level: Float
    let peak: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))

                // Level bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(levelGradient)
                    .frame(width: geometry.size.width * normalizedLevel)

                // Peak indicator
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2)
                    .offset(x: geometry.size.width * normalizedPeak - 1)

                // dB markers
                HStack {
                    ForEach([-48, -36, -24, -12, -6, 0], id: \.self) { db in
                        Text("\(db)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        if db != 0 { Spacer() }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 24)
    }

    private var normalizedLevel: CGFloat {
        CGFloat(max(0, min(1, (level + 60) / 60)))
    }

    private var normalizedPeak: CGFloat {
        CGFloat(max(0, min(1, (peak + 60) / 60)))
    }

    private var levelGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(SurfaceStore())
        .environmentObject(MaterialManager())
        .environmentObject(AudioManager())
}
