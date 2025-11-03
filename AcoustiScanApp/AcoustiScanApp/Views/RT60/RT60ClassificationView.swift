
import SwiftUI

struct RT60ClassificationView: View {
    let deviations: [RT60Deviation]

    var body: some View {
        VStack(alignment: .leading) {
            Text("RT60-Auswertung nach DIN 18041")
                .font(.title2).padding(.bottom)

            ForEach(deviations, id: \.frequency) { result in
                HStack {
                    Text("Frequenz \(result.frequency) Hz:")
                    Spacer()
                    Text(String(format: "%.2f s → %@", result.simulated, result.status.rawValue))
                        .foregroundColor(result.status == .withinTolerance ? .green : .red)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
    }
}
