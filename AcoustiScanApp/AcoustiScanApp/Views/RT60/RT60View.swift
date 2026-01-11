import SwiftUI

struct RT60View: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        List {
            Section(header: Text("RT60 je Frequenz")
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("rt60Header")) {
                ForEach([125, 250, 500, 1000, 2000, 4000, 8000], id: \.self) { freq in
                    let value = store.calculateRT60(at: freq) ?? 0.0
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
        }
        .navigationTitle("Nachhallzeiten")
    }
}
