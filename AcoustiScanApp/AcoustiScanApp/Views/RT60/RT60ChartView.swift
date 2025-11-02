import SwiftUI
import Charts

struct RT60ChartView: View {
    @ObservedObject var store: SurfaceStore

    func calculateRT60(frequency: Int) -> Float {
        var a_f: Float = 0.0
        for surface in store.surfaces {
            if let material = surface.materialType,
               let alpha = MaterialDatabase.absorption(for: material)?.values[frequency] {
                a_f += surface.area * alpha
            }
        }

        let v = store.estimatedVolume
        return a_f > 0 ? 0.161 * v / a_f : 0.0
    }

    var body: some View {
        VStack {
            Text("RT60 je Frequenz")
                .font(.headline)
                .padding(.top)

            Chart {
                ForEach([125, 250, 500, 1000, 2000, 4000, 8000], id: \.self) { freq in
                    let value = calculateRT60(frequency: freq)
                    BarMark(
                        x: .value("Frequenz", "\(freq) Hz"),
                        y: .value("RT60 (s)", value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 300)
            .padding()

            Spacer()
        }
        .navigationTitle("RT60 Chart")
    }
}
