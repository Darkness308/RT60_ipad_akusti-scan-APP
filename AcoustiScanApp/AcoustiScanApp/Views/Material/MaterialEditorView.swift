import SwiftUI

struct MaterialEditorView: View {
    @ObservedObject var materialManager: MaterialManager
    @State private var name: String = ""
    @State private var values: [Int: Float] = [125: 0, 250: 0, 500: 0, 1000: 0, 2000: 0, 4000: 0]

    var body: some View {
        Form {
            Section(header: Text(LocalizationKeys.newMaterial.localized(comment: "Header for new material section"))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("newMaterialHeader")) {
                TextField("Name", text: $name)
                    .accessibilityLabel("Material name")
                    .accessibilityHint("Enter the name for the new acoustic material")
                    .accessibilityValue(name.isEmpty ? "Empty" : name)
                    .accessibilityIdentifier("materialNameTextField")

                ForEach(values.keys.sorted(), id: \.self) { freq in
                    HStack {
                        Text("\(freq) Hz")
                            .accessibilityHidden(true)
                        Spacer()
                        TextField("alpha", value: Binding(
                            get: { values[freq] ?? 0 },
                            set: { values[freq] = $0 }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .accessibilityLabel("Absorption coefficient for \(freq) Hertz")
                        .accessibilityHint("Enter alpha value between 0 and 1")
                        .accessibilityValue(String(format: "%.2f", values[freq] ?? 0))
                        .accessibilityIdentifier("alphaTextField\(freq)")
                    }
                    .accessibilityElement(children: .combine)
                }

                Button(LocalizationKeys.addButton.localized(comment: "Button to add new material")) {
                    let material = AcousticMaterial(name: name, absorption: AbsorptionData(values: values))
                    materialManager.add(material)
                    name = ""
                    values = [125: 0, 250: 0, 500: 0, 1000: 0, 2000: 0, 4000: 0]
                }
                .accessibilityLabel("Add material")
                .accessibilityHint("Adds the new material to your saved materials")
                .accessibilityIdentifier("addMaterialButton")
                .accessibilityAddTraits(.isButton)
            }

            Section(
                header: Text(
                    LocalizationKeys.savedMaterials.localized(
                        comment: "Header for saved materials section"
                    )
                )
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("savedMaterialsHeader")
            ) {
                ForEach(materialManager.customMaterials, id: \.name) { material in
                    VStack(alignment: .leading) {
                        Text(material.name)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("materialName\(material.name)")
                        ForEach(material.absorption.values.sorted(by: { $0.key < $1.key }), id: \.key) { freq, alpha in
                            Text("\(freq) Hz: alpha = \(String(format: "%.2f", alpha))")
                                .font(.caption)
                                .accessibilityLabel("\(freq) Hertz")
                                .accessibilityValue("Alpha equals \(String(format: "%.2f", alpha))")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Material: \(material.name)")
                    .accessibilityIdentifier("savedMaterial\(material.name)")
                }
                .onDelete(perform: materialManager.remove)
            }
        }
    }
}
