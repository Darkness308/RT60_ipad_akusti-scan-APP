import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Material manager for acoustic materials database
public class MaterialManager {
    public var customMaterials: [AcousticMaterial] = []

    public init() {}
    
    public func add(_ material: AcousticMaterial) {
        customMaterials.append(material)
    }

    func remove(at offsets: IndexSet) {
        let indices = Array(offsets).sorted(by: >)
        for index in indices {
            if index < customMaterials.count {
                customMaterials.remove(at: index)
            }
        }
    }

    /// Importiert Materialien aus einem CSV‑String.  Ersetzte vorhandene
    /// `customMaterials` vollständig durch die importierten Daten.
    /// - Parameter csv: Die CSV‑Zeichenkette.
    func importFromCSV(_ csv: String) {
        let imported = parseCSV(csv)
        customMaterials = imported
    }

    /// Importiert Materialien aus einer Datei.
    /// - Parameter url: Die Datei‑URL.
    func importFromFile(url: URL) {
        do {
            let csv = try String(contentsOf: url)
            importFromCSV(csv)
        } catch {
            // Fehlerbehandlung: In einer realen App sollte ein Alert angezeigt werden.
            print("CSV‑Import fehlgeschlagen: \(error)")
        }
    }

    /// Exportiert die aktuell gespeicherten Materialien als CSV‑String.
    func exportToCSV() -> String {
        return exportCSV(materials: customMaterials)
    }
    
    // MARK: - Private Helpers
    
    private func parseCSV(_ csv: String) -> [AcousticMaterial] {
        let lines = csv.components(separatedBy: .newlines)
        var materials: [AcousticMaterial] = []
        
        for line in lines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ",")
            if components.count >= 8 {
                let name = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let coefficients: [Int: Double] = [
                    125: Double(components[1]) ?? 0.1,
                    250: Double(components[2]) ?? 0.1,
                    500: Double(components[3]) ?? 0.1,
                    1000: Double(components[4]) ?? 0.1,
                    2000: Double(components[5]) ?? 0.1,
                    4000: Double(components[6]) ?? 0.1,
                    8000: Double(components[7]) ?? 0.1
                ]
                
                let absorption = AbsorptionData(
                    f125: coefficients[125] ?? 0.1,
                    f250: coefficients[250] ?? 0.1,
                    f500: coefficients[500] ?? 0.1,
                    f1000: coefficients[1000] ?? 0.1,
                    f2000: coefficients[2000] ?? 0.1,
                    f4000: coefficients[4000] ?? 0.1,
                    f8000: coefficients[8000] ?? 0.1
                )
                
                materials.append(AcousticMaterial(
                    id: UUID(),
                    name: name,
                    coefficients: coefficients,
                    absorption: absorption
                ))
            }
        }
        
        return materials
    }
    
    private func exportCSV(materials: [AcousticMaterial]) -> String {
        var csv = "Name,125Hz,250Hz,500Hz,1000Hz,2000Hz,4000Hz,8000Hz\n"
        
        for material in materials {
            let line = [
                material.name,
                String(material.coefficients[125] ?? 0.1),
                String(material.coefficients[250] ?? 0.1),
                String(material.coefficients[500] ?? 0.1),
                String(material.coefficients[1000] ?? 0.1),
                String(material.coefficients[2000] ?? 0.1),
                String(material.coefficients[4000] ?? 0.1),
                String(material.coefficients[8000] ?? 0.1)
            ].joined(separator: ",")
            
            csv += line + "\n"
        }
        
        return csv
    }
}