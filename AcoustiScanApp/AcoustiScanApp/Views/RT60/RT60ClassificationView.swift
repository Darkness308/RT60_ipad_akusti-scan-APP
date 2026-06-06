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
                    Text(String(format: "%.2f s -> %@", result.measuredRT60, result.status.displayName))
                        .foregroundColor(color(for: result.status))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Frequency \(result.frequency) Hertz")
                .accessibilityValue(
                    String(format: "%.2f seconds, status: %@", result.measuredRT60, result.status.displayName)
                )
                .accessibilityHint(
                    result.status == .withinTolerance ? "Within tolerance" : "Outside tolerance"
                )
                .accessibilityIdentifier("classificationRow\(result.frequency)")
            }
        }
        .padding()
    }

    /// Map the package's per-status colour intent to a SwiftUI colour
    /// (non-binary: too-low is orange, not red).
    private func color(for status: EvaluationStatus) -> Color {
        switch status.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .secondary
        }
    }
}
