import SwiftUI

struct RT60View: View {
    @ObservedObject var store: SurfaceStore

    func calculateRT60(frequency: Int) -> Double {
        var a_f: Double = 0.0
        for surface in store.surfaces {
            a_f += surface.absorptionCoefficient
        }
        let v = store.estimatedVolume
        return a_f > 0 ? 0.161 * v / a_f : 0.0
    }

    var body: some View {
        List {
            Section(header: Text("RT60 je Frequenz")) {
                ForEach([125, 250, 500, 1000, 2000, 4000, 8000], id: \.self) { freq in
                    let value = calculateRT60(frequency: freq)
                    HStack {
                        Text("\(freq) Hz")
                        Spacer()
                        Text(String(format: "%.2f s", value))
                    }
                }
            }
        }
        .navigationTitle("Nachhallzeiten")
    }
}
