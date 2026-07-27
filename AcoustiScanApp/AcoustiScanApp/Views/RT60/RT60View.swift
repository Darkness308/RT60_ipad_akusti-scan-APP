import SwiftUI

struct RT60View: View {
    @ObservedObject var store: SurfaceStore

    /// RT60 for a given frequency, delegating to the SurfaceStore Sabine
    /// implementation which correctly accounts for per-surface area and the
    /// material absorption coefficient at that frequency. Returns 0 when the
    /// room volume or total absorption is not yet known.
    func calculateRT60(frequency: Int) -> Double {
        return store.calculateRT60(at: frequency) ?? 0.0
    }

    var body: some View {
        List {
            Section(
                header: Text("RT60 je Frequenz")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("rt60Header"),
                footer: Text("Berechnet nach Sabine aus Raumvolumen und Materialabsorption – keine akustische Messung.")
                    .accessibilityIdentifier("rt60MethodNote")
            ) {
                ForEach(AbsorptionData.standardFrequencies, id: \.self) { freq in
                    let value = calculateRT60(frequency: freq)
                    HStack {
                        Text("\(freq) Hz")
                            .accessibilityHidden(true)
                        Spacer()
                        Text(String(format: "%.2f s", value))
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(freq) Hertz")
                    .accessibilityValue(String(format: "%.2f seconds", value))
                    .accessibilityHint("Reverberation time for this frequency")
                    .accessibilityIdentifier("rt60Row\(freq)")
                }
            }

            Section {
                NavigationLink {
                    RT60MeasurementView(store: store)
                } label: {
                    Label("Impulsmessung (Mikrofon)", systemImage: "waveform")
                }
                .accessibilityIdentifier("openMeasurementLink")

                NavigationLink {
                    RT60DINView(store: store)
                } label: {
                    Label("DIN 18041-Auswertung", systemImage: "checkmark.seal")
                }
                .accessibilityIdentifier("openDINLink")
            }
        }
        .navigationTitle("Nachhallzeiten")
    }
}
