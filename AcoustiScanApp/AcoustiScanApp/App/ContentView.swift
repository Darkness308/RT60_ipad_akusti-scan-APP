//
//  ContentView.swift
//  AcoustiScanApp
//
//  Root navigation: tab-based access to RT60 analysis, room scanning,
//  manual room dimensions, material editing and export.
//

import SwiftUI

struct ContentView: View {
    /// Shared model holding scanned/edited surfaces and the room volume.
    @StateObject private var store = SurfaceStore()

    /// Library of acoustic materials used by the material editor.
    @StateObject private var materialManager = MaterialManager()

    // Manual room-dimension entry (used when no LiDAR scan is available).
    @State private var roomLength: Double = 5.0
    @State private var roomWidth: Double = 4.0
    @State private var roomHeight: Double = 2.7

    #if canImport(RoomPlan)
    /// Coordinator driving the RoomPlan LiDAR capture session.
    @StateObject private var scanCoordinator = RoomScanCoordinator()
    #endif

    var body: some View {
        TabView {
            NavigationStack {
                RT60View(store: store)
                    .navigationTitle("RT60")
            }
            .tabItem {
                Label("RT60", systemImage: "waveform")
            }
            .accessibilityIdentifier("tabRT60")

            NavigationStack {
                scannerTab
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
            .accessibilityIdentifier("tabScan")

            NavigationStack {
                RoomDimensionView(length: $roomLength, width: $roomWidth, height: $roomHeight)
                    .navigationTitle("Maße")
            }
            .tabItem {
                Label("Maße", systemImage: "ruler")
            }
            .accessibilityIdentifier("tabDimensions")

            NavigationStack {
                MaterialEditorView(materialManager: materialManager)
                    .navigationTitle("Material")
            }
            .tabItem {
                Label("Material", systemImage: "square.stack.3d.up")
            }
            .accessibilityIdentifier("tabMaterials")

            NavigationStack {
                ExportView(store: store)
                    .navigationTitle("Export")
            }
            .tabItem {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("tabExport")
        }
        .accessibilityIdentifier("contentView")
        .onAppear(perform: syncRoomVolume)
        .onChange(of: roomLength) { _, _ in syncRoomVolume() }
        .onChange(of: roomWidth) { _, _ in syncRoomVolume() }
        .onChange(of: roomHeight) { _, _ in syncRoomVolume() }
    }

    /// Scanner tab: real RoomPlan capture where available, otherwise a fallback
    /// that explains the requirement and relies on manual dimension entry.
    @ViewBuilder
    private var scannerTab: some View {
        #if canImport(RoomPlan)
        RoomScanView(coordinator: scanCoordinator)
            .navigationTitle("Scan")
            .onAppear { scanCoordinator.store = store }
        #else
        RoomScanView(store: store)
            .navigationTitle("Scan")
        #endif
    }

    /// Keep the shared room volume in sync with the manual dimension entry so
    /// the RT60 calculation has a volume even without a LiDAR scan.
    private func syncRoomVolume() {
        store.roomVolume = roomLength * roomWidth * roomHeight
        store.roomDimensions = (width: roomWidth, height: roomHeight, depth: roomLength)
    }
}

#Preview {
    ContentView()
}
