
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
            Section(header: Text(LocalizationKeys.roomDimensionsInMeters.localized(comment: "Header for room dimensions in meters"))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("dimensionsHeader")) {
                HStack {
                    Text(LocalizationKeys.length.localized(comment: "Length label"))
                        .accessibilityHidden(true)
                    Spacer()
                    TextField("z. B. 7.5", value: $length, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Room length in meters")
                        .accessibilityHint("Enter the length of the room")
                        .accessibilityValue(String(format: "%.2f meters", length))
                        .accessibilityIdentifier("lengthTextField")
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Text(LocalizationKeys.width.localized(comment: "Width label"))
                        .accessibilityHidden(true)
                    Spacer()
                    TextField("z. B. 5.0", value: $width, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Room width in meters")
                        .accessibilityHint("Enter the width of the room")
                        .accessibilityValue(String(format: "%.2f meters", width))
                        .accessibilityIdentifier("widthTextField")
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Text(LocalizationKeys.height.localized(comment: "Height label"))
                        .accessibilityHidden(true)
                    Spacer()
                    TextField("z. B. 3.2", value: $height, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Room height in meters")
                        .accessibilityHint("Enter the height of the room")
                        .accessibilityValue(String(format: "%.2f meters", height))
                        .accessibilityIdentifier("heightTextField")
                }
                .accessibilityElement(children: .combine)
            }

            Section(header: Text(LocalizationKeys.volume.localized(comment: "Volume header"))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("volumeHeader")) {
                Text(String(format: "%.2f m3", volume))
                    .accessibilityLabel("Room volume")
                    .accessibilityValue(String(format: "%.2f cubic meters", volume))
                    .accessibilityIdentifier("volumeText")
            }
        }
        .navigationTitle(LocalizationKeys.roomDimensions.localized(comment: "Room dimensions navigation title"))
    }
}
