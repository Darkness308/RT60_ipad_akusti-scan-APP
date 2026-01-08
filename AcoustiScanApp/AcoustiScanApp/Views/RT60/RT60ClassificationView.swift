import SwiftUI
import AcoustiScanConsolidated

struct RT60ClassificationView: View {
    let deviations: [RT60Deviation]

    var body: some View {
        VStack(alignment: .leading) {
            Text("RT60-Auswertung nach DIN 18041")
                .font(.title2)
                .padding(.bottom)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("classificationTitle")

            ForEach(deviations, id: \.frequency) { result in
                HStack {
                    Text("Frequenz \(result.frequency) Hz:")
                        .accessibilityHidden(true)
                    Spacer()
                    Text(String(format: "%.2f s → %@", result.measuredRT60, result.status.rawValue))
                        .foregroundColor(result.status == .withinTolerance ? .green : .red)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Frequency \(result.frequency) Hertz")
                .accessibilityValue(String(format: "%.2f seconds, status: %@", result.measuredRT60, result.status.rawValue))
                .accessibilityHint(result.status == .withinTolerance ? "Within tolerance" : "Outside tolerance")
                .accessibilityIdentifier("classificationRow\(result.frequency)")
            }
        }
        .padding()
    }
}
