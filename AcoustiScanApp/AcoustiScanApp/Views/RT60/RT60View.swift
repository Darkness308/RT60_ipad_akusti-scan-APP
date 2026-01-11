import SwiftUI

struct RT60View: View {
    @ObservedObject var store: SurfaceStore

    func calculateRT60(frequency: Int) -> Double {
        var a_f: Double = 0.0
        for surface in store.surfaces {
            if let material = surface.material {
                let alpha = material.absorptionCoefficient(at: frequency)
                a_f += surface.area * Double(alpha)
            }
        }

        let v = store.roomVolume
        return a_f > 0 ? 0.161 * v / a_f : 0.0
    }

    var body: some View {
        List {
            Section(header: Text("RT60 je Frequenz")
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("rt60Header")) {
                ForEach([125, 250, 500, 1000, 2000, 4000, 8000], id: \.self) { freq in
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
        }
        .navigationTitle("Nachhallzeiten")
    }
}
