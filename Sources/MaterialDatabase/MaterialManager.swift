import Foundation
import SwiftUI

class MaterialManager: ObservableObject {
    @Published var customMaterials: [AcousticMaterial] = []

    func add(_ material: AcousticMaterial) {
        customMaterials.append(material)
    }

    func remove(at offsets: IndexSet) {
        customMaterials.remove(atOffsets: offsets)
    }

    /// Importiert Materialien aus einem CSV‑String.  Ersetzte vorhandene
    /// `customMaterials` vollständig durch die importierten Daten.
    /// - Parameter csv: Die CSV‑Zeichenkette.
    func importFromCSV(_ csv: String) {
        let imported = MaterialCSVImporter.parseCSV(csv)
        DispatchQueue.main.async {
            self.customMaterials = imported
        }
    }

    /// Importiert Materialien aus einer Datei.
    /// - Parameter url: Die Datei‑URL.
    func importFromFile(url: URL) {
        do {
            let materials = try MaterialCSVImporter.importFromFile(url: url)
            DispatchQueue.main.async {
                self.customMaterials = materials
            }
        } catch {
            // Fehlerbehandlung: In einer realen App sollte ein Alert angezeigt werden.
            print("CSV‑Import fehlgeschlagen: \(error)")
        }
    }

    /// Exportiert die aktuell gespeicherten Materialien als CSV‑String.
    func exportToCSV() -> String {
        return MaterialCSVImporter.exportCSV(materials: customMaterials)
    }
}