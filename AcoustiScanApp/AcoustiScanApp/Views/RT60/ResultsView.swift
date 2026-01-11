//
//  ResultsView.swift
//  AcoustiScanApp
//
//  View for displaying RT60 classification results and DIN 18041 compliance
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: SurfaceStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Room Information Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizationKeys.room.localized(comment: "Room"))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("roomInfoHeader")
                    
                    HStack {
                        Text(store.roomName)
                            .font(.body)
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Room name: \(store.roomName)")
                    .accessibilityIdentifier("roomNameText")
                    
                    if store.roomVolume > 0 {
                        HStack {
                            Text(LocalizationKeys.roomVolume.localized(comment: "Room Volume"))
                            Spacer()
                            Text(String(format: "%.2f m³", store.roomVolume))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Room volume: \(String(format: "%.2f cubic meters", store.roomVolume))")
                        .accessibilityIdentifier("roomVolumeText")
                    }
                    
                    HStack {
                        Text(LocalizationKeys.surfaces.localized(comment: "Surfaces"))
                        Spacer()
                        Text("\(store.surfaces.count)")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Surfaces: \(store.surfaces.count)")
                    .accessibilityIdentifier("surfaceCountText")
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // RT60 Chart Preview
                if !store.surfaces.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizationKeys.rt60Measurements.localized(comment: "RT60 Measurements"))
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("rt60MeasurementsHeader")
                        
                        RT60ChartView(store: store)
                            .frame(height: 200)
                            .accessibilityLabel("RT60 frequency response chart")
                            .accessibilityIdentifier("rt60Chart")
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // DIN 18041 Classification
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizationKeys.dinClassification.localized(comment: "DIN 18041 Classification"))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("dinClassificationHeader")
                    
                    if store.surfaces.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                                .accessibilityLabel("Warning icon")
                                .accessibilityIdentifier("noDataIcon")
                            
                            Text(LocalizationKeys.noDataAvailable.localized(comment: "No data available"))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel(LocalizationKeys.noDataAvailable.localized(comment: "No data available"))
                                .accessibilityIdentifier("noDataText")
                            
                            Text(LocalizationKeys.scanRoomToSeeResults.localized(comment: "Scan room to see results"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .accessibilityHint("Go to Scanner tab to scan a room")
                                .accessibilityIdentifier("noDataHint")
                        }
                        .padding()
                    } else {
                        Text(LocalizationKeys.classificationResultsPlaceholder.localized(comment: "Classification results placeholder"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Classification results placeholder")
                            .accessibilityIdentifier("classificationPlaceholder")
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizationKeys.results.localized(comment: "Results"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("resultsView")
    }
}

#Preview {
    NavigationView {
        ResultsView(store: SurfaceStore())
    }
}
