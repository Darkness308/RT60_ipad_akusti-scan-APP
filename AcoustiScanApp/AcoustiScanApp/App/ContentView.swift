//
//  ContentView.swift
//  iPadScannerApp
//
//  Created by Marc Schneider-Handrup on 26.05.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var surfaceStore = SurfaceStore()
    @StateObject private var materialManager = MaterialManager()
    
    #if canImport(RoomPlan)
    @StateObject private var roomScanCoordinator = RoomScanCoordinator()
    #endif
    
    var body: some View {
        TabView {
            // Scanner Tab
            NavigationView {
                #if canImport(RoomPlan)
                RoomScanView(coordinator: roomScanCoordinator)
                    .navigationTitle(LocalizationKeys.lidarScan.localized(comment: "LiDAR Scan"))
                #else
                RoomScanView(store: surfaceStore)
                    .navigationTitle(LocalizationKeys.lidarScan.localized(comment: "LiDAR Scan"))
                #endif
            }
            .tabItem {
                Label("Scanner", systemImage: "camera.fill")
            }
            .accessibilityIdentifier("scannerTab")
            
            // RT60 Tab
            NavigationView {
                RT60View(store: surfaceStore)
            }
            .tabItem {
                Label("RT60", systemImage: "waveform")
            }
            .accessibilityIdentifier("rt60Tab")
            
            // Results Tab
            NavigationView {
                ResultsView(store: surfaceStore)
            }
            .tabItem {
                Label("Results", systemImage: "chart.bar.fill")
            }
            .accessibilityIdentifier("resultsTab")
            
            // Export Tab
            NavigationView {
                ExportView(store: surfaceStore)
            }
            .tabItem {
                Label(LocalizationKeys.export.localized(comment: "Export"), systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("exportTab")
            
            // Materials Tab
            NavigationView {
                MaterialEditorView(materialManager: materialManager)
                    .navigationTitle(LocalizationKeys.materialOverview.localized(comment: "Materials"))
            }
            .tabItem {
                Label("Materials", systemImage: "list.bullet.rectangle")
            }
            .accessibilityIdentifier("materialsTab")
        }
        .onAppear {
            #if canImport(RoomPlan)
            // Connect coordinator to store
            roomScanCoordinator.store = surfaceStore
            #endif
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mainTabView")
    }
}

#Preview {
    ContentView()
}
