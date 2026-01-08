# XLSX Import/Export Feature

## Overview

The AcoustiScan app now supports importing and exporting acoustic material data in XLSX (Microsoft Excel) format. This feature is implemented using **pure Swift** without any external dependencies, creating standard-compliant XLSX files that can be opened in Excel, Numbers, Google Sheets, and other spreadsheet applications.

## Architecture

### Components

1. **XLSXExporter.swift** - Exports materials to XLSX format
   - Creates valid .xlsx files (ZIP archives containing XML)
   - Handles text and numeric data with proper XML escaping
   - Uses Foundation's compression capabilities
   - Implements ZIP file structure from scratch

2. **XLSXImporter.swift** - Imports materials from XLSX files
   - Extracts ZIP archives
   - Parses XML worksheets
   - Handles both stored and deflate-compressed files
   - Robust error handling and validation

3. **MaterialManager.swift** - Integration layer
   - Provides high-level export/import methods
   - Error logging and handling
   - Persistence integration

## File Format

The XLSX files contain a simple table structure:

| Name | 125 Hz | 250 Hz | 500 Hz | 1000 Hz | 2000 Hz | 4000 Hz |
|------|--------|--------|--------|---------|---------|---------|
| Material 1 | 0.10 | 0.20 | 0.30 | 0.40 | 0.50 | 0.60 |
| Material 2 | 0.15 | 0.25 | 0.35 | 0.45 | 0.55 | 0.65 |

- **Column 1**: Material name (text)
- **Columns 2-7**: Absorption coefficients for standard octave band frequencies (numeric, 0.0-1.0)

## Usage Examples

### Exporting Materials to XLSX

```swift
import Foundation

// Create material manager
let materialManager = MaterialManager()

// Example 1: Export all custom materials
if let xlsxData = materialManager.exportToXLSX() {
    // Save to file
    let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("materials.xlsx")

    try? xlsxData.write(to: fileURL)
    print("Materials exported to: \(fileURL.path)")
}

// Example 2: Export specific materials
let selectedMaterials = [
    AcousticMaterial(
        name: "Custom Foam",
        absorption: AbsorptionData(values: [
            125: 0.15, 250: 0.40, 500: 0.80,
            1000: 0.95, 2000: 0.90, 4000: 0.85
        ])
    )
]

if let xlsxData = materialManager.exportToXLSX(materials: selectedMaterials) {
    // Use the data (e.g., share via ActivityViewController)
    shareXLSXData(xlsxData, filename: "custom_materials.xlsx")
}

// Example 3: Export predefined materials
if let xlsxData = materialManager.exportToXLSX(materials: materialManager.predefinedMaterials) {
    // Save for backup or sharing
    saveToCloud(xlsxData)
}
```

### Importing Materials from XLSX

```swift
import Foundation

let materialManager = MaterialManager()

// Example 1: Import from file
func importMaterialsFromFile(url: URL) {
    do {
        // Read file data
        let xlsxData = try Data(contentsOf: url)

        // Import materials
        let materials = try materialManager.importFromXLSX(xlsxData)

        print("Imported \(materials.count) materials:")
        for material in materials {
            print("- \(material.name)")
        }
    } catch {
        print("Import failed: \(error.localizedDescription)")
    }
}

// Example 2: Import and add to custom materials
func importAndAddMaterials(from data: Data) {
    do {
        try materialManager.importAndAdd(fromXLSX: data)
        print("Materials imported and added successfully")
    } catch {
        print("Import failed: \(error.localizedDescription)")
    }
}

// Example 3: Import with validation
func importWithValidation(from url: URL) throws {
    let xlsxData = try Data(contentsOf: url)
    let materials = try materialManager.importFromXLSX(xlsxData)

    // Validate imported materials
    let validMaterials = materials.filter { material in
        material.hasCompleteData && !material.name.isEmpty
    }

    guard !validMaterials.isEmpty else {
        throw NSError(domain: "Import", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "No valid materials found"])
    }

    // Add only valid materials
    for material in validMaterials {
        materialManager.add(material)
    }

    print("Added \(validMaterials.count) valid materials")
}
```

### SwiftUI Integration

```swift
import SwiftUI
import UniformTypeIdentifiers

struct MaterialExportView: View {
    @StateObject private var materialManager = MaterialManager()
    @State private var showingExporter = false
    @State private var exportData: Data?

    var body: some View {
        VStack {
            Button("Export Materials") {
                if let data = materialManager.exportToXLSX() {
                    exportData = data
                    showingExporter = true
                }
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: XLSXDocument(data: exportData ?? Data()),
            contentType: .xlsx,
            defaultFilename: "acoustic_materials.xlsx"
        ) { result in
            switch result {
            case .success(let url):
                print("Exported to: \(url)")
            case .failure(let error):
                print("Export failed: \(error)")
            }
        }
    }
}

struct MaterialImportView: View {
    @StateObject private var materialManager = MaterialManager()
    @State private var showingImporter = false
    @State private var importStatus = ""

    var body: some View {
        VStack {
            Button("Import Materials") {
                showingImporter = true
            }

            Text(importStatus)
                .foregroundColor(.secondary)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.xlsx],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }

                do {
                    let data = try Data(contentsOf: url)
                    let materials = try materialManager.importFromXLSX(data)
                    importStatus = "Imported \(materials.count) materials"
                } catch {
                    importStatus = "Import failed: \(error.localizedDescription)"
                }

            case .failure(let error):
                importStatus = "Error: \(error.localizedDescription)"
            }
        }
    }
}

// Helper document type for file exporter
struct XLSXDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.xlsx] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// Add XLSX UTType if not already defined
extension UTType {
    static var xlsx: UTType {
        UTType(importedAs: "org.openxmlformats.spreadsheetml.sheet")
    }
}
```

## Error Handling

### Export Errors

```swift
func exportWithErrorHandling() {
    guard let xlsxData = materialManager.exportToXLSX() else {
        // Export failed - check ErrorLogger for details
        print("Export failed. Possible reasons:")
        print("- Invalid material data")
        print("- Compression failure")
        print("- ZIP creation error")
        return
    }

    // Export succeeded
    saveXLSXFile(xlsxData)
}
```

### Import Errors

```swift
func importWithErrorHandling(data: Data) {
    do {
        let materials = try materialManager.importFromXLSX(data)
        print("Successfully imported \(materials.count) materials")
    } catch XLSXImportError.invalidFormat {
        print("The file is not a valid XLSX file")
    } catch XLSXImportError.decompressionFailed {
        print("Failed to decompress the XLSX file")
    } catch XLSXImportError.xmlParsingFailed {
        print("Failed to parse the XLSX content")
    } catch XLSXImportError.missingWorksheet {
        print("The XLSX file is missing the worksheet")
    } catch XLSXImportError.invalidData(let detail) {
        print("Invalid data in XLSX: \(detail)")
    } catch {
        print("Unknown error: \(error)")
    }
}
```

## Technical Details

### XLSX File Structure

The generated XLSX files contain the following structure:

```
materials.xlsx (ZIP archive)
├── [Content_Types].xml       - MIME types for all files
├── _rels/
│   └── .rels                  - Relationships
├── xl/
│   ├── workbook.xml          - Workbook definition
│   ├── styles.xml            - Minimal styling
│   ├── worksheets/
│   │   └── sheet1.xml        - Material data
│   └── _rels/
│       └── workbook.xml.rels - Workbook relationships
```

### Key Features

1. **Standard Compliance**: Files are fully compliant with Office Open XML standards
2. **No Dependencies**: Pure Swift implementation using only Foundation framework
3. **Robust**: Handles edge cases like special characters, long names, and extreme values
4. **Performance**: Efficient for typical datasets (tested with 100+ materials)
5. **Compatibility**: Works with Excel, Numbers, Google Sheets, LibreOffice

### Compression

- Files use the ZIP "stored" method (no compression) for maximum compatibility
- This ensures the files can be read by all XLSX parsers
- File sizes are small enough for this use case (materials database)

### Data Validation

Import process:
1. Validates ZIP structure and signature
2. Extracts and parses XML worksheet
3. Validates row structure (name + 6 frequency values)
4. Converts to AcousticMaterial objects
5. Applies AbsorptionData clamping (0.0-1.0 range)

Export process:
1. Generates XML with proper escaping
2. Creates ZIP structure with correct headers
3. Calculates CRC-32 checksums
4. Ensures valid XLSX format

## Testing

The implementation includes comprehensive tests in `MaterialManagerXLSXTests.swift`:

- ✅ Export/Import round-trip preservation
- ✅ Special character handling
- ✅ Empty data handling
- ✅ Invalid data error handling
- ✅ Performance tests with large datasets
- ✅ Edge cases (zero values, max values, long names)

Run tests:
```bash
xcodebuild test -scheme AcoustiScanApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Migration from CSV

The XLSX format coexists with the existing CSV format. Both are supported:

```swift
// CSV Export (existing)
let csvString = materialManager.exportToCSV()

// XLSX Export (new)
let xlsxData = materialManager.exportToXLSX()

// Users can choose their preferred format
```

Benefits of XLSX over CSV:
- ✅ Better Excel integration
- ✅ Preserves numeric types
- ✅ Handles special characters without escaping issues
- ✅ Standard format for data exchange
- ✅ More professional appearance

## Future Enhancements

Possible improvements for future versions:

1. **Styling**: Add header row formatting, colors, borders
2. **Multiple Sheets**: Support multiple material categories
3. **Charts**: Include absorption coefficient graphs
4. **Metadata**: Add export date, app version, user notes
5. **Compression**: Implement deflate compression for smaller files
6. **Validation**: Add data validation rules in Excel
7. **Templates**: Support importing from Excel templates

## Support

For issues or questions about XLSX import/export:

1. Check the ErrorLogger for detailed error messages
2. Verify XLSX file compatibility (standard Office Open XML format)
3. Ensure material data follows the expected format
4. Review test cases for usage examples

## License

This implementation is part of the AcoustiScan application.
Pure Swift XLSX implementation without external dependencies.
