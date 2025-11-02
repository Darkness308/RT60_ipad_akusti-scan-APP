import SwiftUI

struct MaterialEditorView: View {
    @ObservedObject var materialManager: MaterialManager
    @State private var name: String = ""
    @State private var values: [Int: Float] = [125: 0, 250: 0, 500: 0, 1000: 0, 2000: 0, 4000: 0]

    var body: some View {
        Form {
            Section(header: Text("Neues Material")) {
                TextField("Name", text: $name)
                ForEach(values.keys.sorted(), id: \.self) { freq in
                    HStack {
                        Text("\(freq) Hz")
                        Spacer()
                        TextField("α", value: Binding(
                            get: { values[freq]! },
                            set: { values[freq] = $0 }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    }
                }
                Button("Hinzufügen") {
                    let material = AcousticMaterial(name: name, absorption: AbsorptionData(values: values))
                    materialManager.add(material)
                    name = ""
                    values = [125: 0, 250: 0, 500: 0, 1000: 0, 2000: 0, 4000: 0]
                }
            }

            Section(header: Text("Gespeicherte Materialien")) {
                ForEach(materialManager.customMaterials, id: \.name) { material in
                    VStack(alignment: .leading) {
                        Text(material.name).font(.headline)
                        ForEach(material.absorption.values.sorted(by: { $0.key < $1.key }), id: \.key) { freq, alpha in
                            Text("\(freq) Hz: α = \(String(format: "%.2f", alpha))")
                                .font(.caption)
                        }
                    }
                }
                .onDelete(perform: materialManager.remove)
            }
        }
    }
}