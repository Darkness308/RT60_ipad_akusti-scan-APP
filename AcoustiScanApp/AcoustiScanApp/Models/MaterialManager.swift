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
    /// - Note: Handles quoted fields and commas in names properly
    public func importFromCSV(_ csvString: String) throws -> [AcousticMaterial] {
        var importedMaterials: [AcousticMaterial] = []
        let lines = csvString.components(separatedBy: .newlines)

        // Skip header line
        for line in lines.dropFirst() {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            // Simple CSV parser that handles quoted fields
            let components = parseCSVLine(line)
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

    /// Simple CSV line parser that handles quoted fields
    /// - Parameter line: CSV line to parse
    /// - Returns: Array of field values
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false

        let characters = Array(line)
        var index = 0

        while index < characters.count {
            let char = characters[index]

            if char == "\"" {
                if inQuotes {
                    // Handle escaped quote ("") inside a quoted field
                    if index + 1 < characters.count && characters[index + 1] == "\"" {
                        currentField.append("\"")
                        index += 2
                        continue
                    } else {
                        // Closing quote for the current quoted field
                        inQuotes = false
                    }
                } else {
                    // Opening quote for a quoted field
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }

            index += 1
        }
        fields.append(currentField)

        return fields
    }

    /// Add imported materials to custom materials
    /// - Parameter csvString: CSV string to import
    /// - Throws: Re-throws CSV parsing errors for proper error handling
    public func importAndAdd(fromCSV csvString: String) throws {
        let materials = try importFromCSV(csvString)
        customMaterials.append(contentsOf: materials)
        saveCustomMaterials()
    }

    // MARK: - XLSX Import/Export

    /// Export materials to XLSX format
    /// - Parameter materials: Materials to export (defaults to custom materials)
    /// - Returns: XLSX data, or nil if export fails
    public func exportToXLSX(materials: [AcousticMaterial]? = nil) -> Data? {
        let materialsToExport = materials ?? customMaterials

        do {
            return try XLSXExporter.export(materials: materialsToExport)
        } catch {
            ErrorLogger.log(
                error,
                context: "MaterialManager.exportToXLSX",
                level: .error
            )
            return nil
        }
    }

    /// Import materials from XLSX data
    /// - Parameter xlsxData: XLSX file data
    /// - Returns: Array of imported materials
    /// - Throws: XLSXImportError if parsing fails
    public func importFromXLSX(_ xlsxData: Data) throws -> [AcousticMaterial] {
        do {
            return try XLSXImporter.import(data: xlsxData)
        } catch {
            ErrorLogger.log(
                error,
                context: "MaterialManager.importFromXLSX",
                level: .error
            )
            throw error
        }
    }

    /// Add imported materials from XLSX to custom materials
    /// - Parameter xlsxData: XLSX data to import
    /// - Throws: Re-throws XLSX parsing errors for proper error handling
    public func importAndAdd(fromXLSX xlsxData: Data) throws {
        let materials = try importFromXLSX(xlsxData)
        customMaterials.append(contentsOf: materials)
        saveCustomMaterials()
    }

    // MARK: - Persistence

    private func saveCustomMaterials() {
        do {
            let encoded = try JSONEncoder().encode(customMaterials)
            UserDefaults.standard.set(encoded, forKey: "customMaterials")
        } catch {
            ErrorLogger.log(
                error,
                context: "MaterialManager.saveCustomMaterials",
                level: .error
            )
        }
    }

    private func loadCustomMaterials() {
        guard let data = UserDefaults.standard.data(forKey: "customMaterials") else {
            return
        }

        do {
            let decoded = try JSONDecoder().decode([AcousticMaterial].self, from: data)
            customMaterials = decoded
        } catch {
            ErrorLogger.log(
                error,
                context: "MaterialManager.loadCustomMaterials",
                level: .error
            )
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
