//
//  MaterialManager.swift
//  AcoustiScanApp
//
//  Manager for acoustic materials with import/export functionality
//

import Foundation
import Combine

/// Manager for acoustic materials with CSV and XLSX support
public class MaterialManager: ObservableObject {
    
    /// Published array of custom materials
    @Published public var customMaterials: [AcousticMaterial] = []
    
    /// Predefined materials database
    public let predefinedMaterials: [AcousticMaterial]
    
    /// Initialize with default materials
    public init() {
        // Load some common predefined materials
        self.predefinedMaterials = Self.loadPredefinedMaterials()
        self.loadCustomMaterials()
    }
    
    /// Add a new material
    /// - Parameter material: Material to add
    public func add(_ material: AcousticMaterial) {
        customMaterials.append(material)
        saveCustomMaterials()
    }
    
    /// Remove materials at indices
    /// - Parameter offsets: Index set of materials to remove
    public func remove(at offsets: IndexSet) {
        customMaterials.remove(atOffsets: offsets)
        saveCustomMaterials()
    }
    
    /// Get all materials (predefined + custom)
    public var allMaterials: [AcousticMaterial] {
        return predefinedMaterials + customMaterials
    }
    
    // MARK: - CSV Import/Export
    
    /// Export materials to CSV format
    /// - Parameter materials: Materials to export (defaults to custom materials)
    /// - Returns: CSV string
    public func exportToCSV(materials: [AcousticMaterial]? = nil) -> String {
        let materialsToExport = materials ?? customMaterials
        var csv = "Name,125Hz,250Hz,500Hz,1kHz,2kHz,4kHz\n"
        
        for material in materialsToExport {
            let name = material.name.replacingOccurrences(of: ",", with: ";")
            let values = AbsorptionData.standardFrequencies.map {
                String(format: "%.2f", material.absorption.coefficient(at: $0))
            }
            csv += "\(name),\(values.joined(separator: ","))\n"
        }
        
        return csv
    }
    
    /// Import materials from CSV format
    /// - Parameter csvString: CSV string to parse
    /// - Returns: Array of imported materials
    /// - Throws: Error if CSV parsing fails
    public func importFromCSV(_ csvString: String) throws -> [AcousticMaterial] {
        var importedMaterials: [AcousticMaterial] = []
        let lines = csvString.components(separatedBy: .newlines)
        
        // Skip header line
        for line in lines.dropFirst() {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 7 else { continue }
            
            let name = components[0].trimmingCharacters(in: .whitespaces)
            var values: [Int: Float] = [:]
            
            for (index, freq) in AbsorptionData.standardFrequencies.enumerated() {
                if let value = Float(components[index + 1].trimmingCharacters(in: .whitespaces)) {
                    values[freq] = value
                }
            }
            
            let material = AcousticMaterial(
                name: name,
                absorption: AbsorptionData(values: values)
            )
            importedMaterials.append(material)
        }
        
        return importedMaterials
    }
    
    /// Add imported materials to custom materials
    /// - Parameter csvString: CSV string to import
    public func importAndAdd(fromCSV csvString: String) {
        do {
            let materials = try importFromCSV(csvString)
            customMaterials.append(contentsOf: materials)
            saveCustomMaterials()
        } catch {
            print("Error importing CSV: \(error)")
        }
    }
    
    // MARK: - XLSX Import/Export (Placeholder for US-6)
    
    /// Export materials to XLSX format
    /// - Parameter materials: Materials to export
    /// - Returns: XLSX data
    /// - Note: This is a placeholder. Full XLSX support requires additional library
    public func exportToXLSX(materials: [AcousticMaterial]? = nil) -> Data? {
        // TODO: Implement XLSX export using a library like CoreXLSX or similar
        // For now, return nil to indicate not yet implemented
        print("XLSX export not yet implemented (US-6)")
        return nil
    }
    
    /// Import materials from XLSX data
    /// - Parameter xlsxData: XLSX file data
    /// - Returns: Array of imported materials
    /// - Note: This is a placeholder. Full XLSX support requires additional library
    public func importFromXLSX(_ xlsxData: Data) throws -> [AcousticMaterial] {
        // TODO: Implement XLSX import using a library like CoreXLSX or similar
        print("XLSX import not yet implemented (US-6)")
        throw NSError(domain: "MaterialManager", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "XLSX import not yet implemented"
        ])
    }
    
    // MARK: - Persistence
    
    private func saveCustomMaterials() {
        if let encoded = try? JSONEncoder().encode(customMaterials) {
            UserDefaults.standard.set(encoded, forKey: "customMaterials")
        }
    }
    
    private func loadCustomMaterials() {
        if let data = UserDefaults.standard.data(forKey: "customMaterials"),
           let decoded = try? JSONDecoder().decode([AcousticMaterial].self, from: data) {
            customMaterials = decoded
        }
    }
    
    // MARK: - Predefined Materials
    
    private static func loadPredefinedMaterials() -> [AcousticMaterial] {
        return [
            AcousticMaterial(name: "Beton (glatt)", absorption: AbsorptionData(values: [
                125: 0.01, 250: 0.01, 500: 0.02, 1000: 0.02, 2000: 0.02, 4000: 0.03
            ])),
            AcousticMaterial(name: "Gipskarton", absorption: AbsorptionData(values: [
                125: 0.29, 250: 0.10, 500: 0.05, 1000: 0.04, 2000: 0.07, 4000: 0.09
            ])),
            AcousticMaterial(name: "Holz (massiv)", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.11, 500: 0.10, 1000: 0.07, 2000: 0.06, 4000: 0.07
            ])),
            AcousticMaterial(name: "Teppichboden", absorption: AbsorptionData(values: [
                125: 0.08, 250: 0.24, 500: 0.57, 1000: 0.69, 2000: 0.71, 4000: 0.73
            ])),
            AcousticMaterial(name: "Akustikplatten", absorption: AbsorptionData(values: [
                125: 0.15, 250: 0.40, 500: 0.80, 1000: 0.95, 2000: 0.90, 4000: 0.85
            ])),
            AcousticMaterial(name: "Glasfenster", absorption: AbsorptionData(values: [
                125: 0.35, 250: 0.25, 500: 0.18, 1000: 0.12, 2000: 0.07, 4000: 0.04
            ])),
            AcousticMaterial(name: "Vorhang (schwer)", absorption: AbsorptionData(values: [
                125: 0.14, 250: 0.35, 500: 0.55, 1000: 0.72, 2000: 0.70, 4000: 0.65
            ]))
        ]
    }
}
