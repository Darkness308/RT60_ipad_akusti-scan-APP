//  RT60DINView.swift
//  AcoustiScanApp
//
//  In-app DIN 18041 evaluation: pick the room usage group (A1–A5), evaluate the
//  calculated RT60 spectrum against the norm-faithful asymmetric tolerance band
//  (via AcoustiScanConsolidated) and show the per-band result. This wires up the
//  app's core DIN function, which previously had no UI path.

import SwiftUI
import AcoustiScanConsolidated

struct RT60DINView: View {
    @ObservedObject var store: SurfaceStore

    /// Persisted DIN room usage group (raw "A1"…"A5"); kept as String so this
    /// view owns the selection without modifying SurfaceStore.
    @AppStorage("din.roomType") private var roomTypeRaw: String = RoomType.a3Education.rawValue

    private var roomType: RoomType {
        RoomType(rawValue: roomTypeRaw) ?? .a3Education
    }

    private var deviations: [RT60Deviation] {
        DINEvaluation.deviations(
            spectrum: store.calculateRT60Spectrum(),
            roomType: roomType,
            volume: store.roomVolume
        )
    }

    var body: some View {
        List {
            Section(
                header: Text("Raumnutzungsgruppe (DIN 18041)"),
                footer: Text("Bewertung der berechneten RT60 gegen das asymmetrische Toleranzband (Bild 2) der gewählten Gruppe.")
            ) {
                Picker("Gruppe", selection: $roomTypeRaw) {
                    ForEach(RoomType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type.rawValue)
                    }
                }
                .accessibilityIdentifier("roomTypePicker")

                if store.roomVolume > 0 && !roomType.isVolumeWithinValidRange(store.roomVolume) {
                    Text("Hinweis: Volumen \(String(format: "%.0f m³", store.roomVolume)) liegt außerhalb des für \(roomType.groupLabel) gültigen Bereichs.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("volumeRangeWarning")
                }
            }

            if store.roomVolume <= 0 {
                Section {
                    Text("Kein Raumvolumen gesetzt – erst Maße eingeben oder scannen.")
                        .foregroundStyle(.secondary)
                }
            } else if deviations.isEmpty {
                Section {
                    Text("Keine bewertbaren Bänder – Materialien/Absorption fehlen.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    RT60ClassificationView(deviations: deviations)
                }
            }
        }
        .navigationTitle("DIN 18041")
    }
}
