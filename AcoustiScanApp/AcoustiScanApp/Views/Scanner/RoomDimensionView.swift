
import SwiftUI

struct RoomDimensionView: View {
    @Binding var length: Double
    @Binding var width: Double
    @Binding var height: Double

    var volume: Double {
        return length * width * height
    }

    var body: some View {
        Form {
            Section(header: Text("Raummaße in Metern")) {
                HStack {
                    Text("Länge")
                    Spacer()
                    TextField("z. B. 7.5", value: $length, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Breite")
                    Spacer()
                    TextField("z. B. 5.0", value: $width, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Höhe")
                    Spacer()
                    TextField("z. B. 3.2", value: $height, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section(header: Text("Volumen")) {
                Text(String(format: "%.2f m³", volume))
            }
        }
        .navigationTitle("Raumdimensionen")
    }
}
