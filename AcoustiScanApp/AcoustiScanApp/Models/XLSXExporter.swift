//
//  XLSXExporter.swift
//  AcoustiScanApp
//
//  Pure Swift XLSX exporter without external dependencies
//  Creates valid .xlsx files using ZIP compression and XML generation
//

import Foundation
import Compression

/// Error types for XLSX export operations
public enum XLSXExportError: Error, LocalizedError {
    case compressionFailed
    case invalidData
    case zipCreationFailed

    public var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress XLSX data"
        case .invalidData:
            return "Invalid data provided for export"
        case .zipCreationFailed:
            return "Failed to create ZIP archive"
        }
    }
}

/// XLSX file exporter using pure Swift
public class XLSXExporter {

    /// Export acoustic materials to XLSX format
    /// - Parameter materials: Array of materials to export
    /// - Returns: Data representing the XLSX file
    /// - Throws: XLSXExportError if export fails
    public static func export(materials: [AcousticMaterial]) throws -> Data {
        // Create the XLSX structure
        let xlsxBuilder = XLSXBuilder()

        // Add header row
        xlsxBuilder.addRow([
            "Name",
            "125 Hz",
            "250 Hz",
            "500 Hz",
            "1000 Hz",
            "2000 Hz",
            "4000 Hz"
        ])

        // Add data rows
        for material in materials {
            var row: [String] = [material.name]
            for frequency in AbsorptionData.standardFrequencies {
                let coefficient = material.absorption.coefficient(at: frequency)
                row.append(String(format: "%.2f", coefficient))
            }
            xlsxBuilder.addRow(row)
        }

        // Build the XLSX file
        return try xlsxBuilder.build()
    }
}

/// Internal class for building XLSX file structure
private class XLSXBuilder {
    private var rows: [[String]] = []

    func addRow(_ cells: [String]) {
        rows.append(cells)
    }

    func build() throws -> Data {
        // Create all required XML files
        let contentTypes = generateContentTypes()
        let rels = generateRels()
        let workbook = generateWorkbook()
        let worksheet = generateWorksheet()
        let styles = generateStyles()
        let workbookRels = generateWorkbookRels()

        // Create ZIP archive
        var archive = ZIPArchive()

        try archive.addFile(path: "[Content_Types].xml", data: contentTypes.data(using: .utf8)!)
        try archive.addFile(path: "_rels/.rels", data: rels.data(using: .utf8)!)
        try archive.addFile(path: "xl/workbook.xml", data: workbook.data(using: .utf8)!)
        try archive.addFile(path: "xl/worksheets/sheet1.xml", data: worksheet.data(using: .utf8)!)
        try archive.addFile(path: "xl/styles.xml", data: styles.data(using: .utf8)!)
        try archive.addFile(path: "xl/_rels/workbook.xml.rels", data: workbookRels.data(using: .utf8)!)

        return try archive.finalize()
    }

    // MARK: - XML Generation

    private func generateContentTypes() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
            <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
            <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
        """
    }

    private func generateRels() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private func generateWorkbook() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
            <sheets>
                <sheet name="Materials" sheetId="1" r:id="rId1"/>
            </sheets>
        </workbook>
        """
    }

    private func generateWorksheet() -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <sheetData>

        """

        for (rowIndex, row) in rows.enumerated() {
            let rowNumber = rowIndex + 1
            xml += "        <row r=\"\(rowNumber)\">\n"

            for (colIndex, cell) in row.enumerated() {
                let cellRef = columnLetter(for: colIndex) + "\(rowNumber)"
                let escapedCell = xmlEscape(cell)

                // Determine if cell is numeric or text
                if let _ = Double(cell) {
                    // Numeric cell
                    xml += "            <c r=\"\(cellRef)\">\n"
                    xml += "                <v>\(escapedCell)</v>\n"
                    xml += "            </c>\n"
                } else {
                    // Text cell (inline string)
                    xml += "            <c r=\"\(cellRef)\" t=\"inlineStr\">\n"
                    xml += "                <is><t>\(escapedCell)</t></is>\n"
                    xml += "            </c>\n"
                }
            }

            xml += "        </row>\n"
        }

        xml += """
            </sheetData>
        </worksheet>
        """

        return xml
    }

    private func generateStyles() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <numFmts count="0"/>
            <fonts count="1">
                <font>
                    <sz val="11"/>
                    <name val="Calibri"/>
                </font>
            </fonts>
            <fills count="1">
                <fill>
                    <patternFill patternType="none"/>
                </fill>
            </fills>
            <borders count="1">
                <border>
                    <left/>
                    <right/>
                    <top/>
                    <bottom/>
                    <diagonal/>
                </border>
            </borders>
            <cellXfs count="1">
                <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
            </cellXfs>
        </styleSheet>
        """
    }

    private func generateWorkbookRels() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
            <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """
    }

    // MARK: - Helper Functions

    private func columnLetter(for index: Int) -> String {
        var column = ""
        var num = index + 1

        while num > 0 {
            let remainder = (num - 1) % 26
            column = String(UnicodeScalar(65 + remainder)!) + column
            num = (num - 1) / 26
        }

        return column
    }

    private func xmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

/// Simple ZIP archive builder
private class ZIPArchive {
    private struct FileEntry {
        let path: String
        let data: Data
        let modificationDate: Date
    }

    private var files: [FileEntry] = []

    func addFile(path: String, data: Data) throws {
        files.append(FileEntry(path: path, data: data, modificationDate: Date()))
    }

    func finalize() throws -> Data {
        var zipData = Data()
        var centralDirectory = Data()
        var currentOffset: UInt32 = 0

        // Write each file with local file header
        for file in files {
            let localHeaderOffset = currentOffset

            // Local file header
            let localHeader = createLocalFileHeader(for: file)
            zipData.append(localHeader)

            // File name
            let fileNameData = file.path.data(using: .utf8)!
            zipData.append(fileNameData)

            // File data (stored, no compression for simplicity and compatibility)
            zipData.append(file.data)

            currentOffset = UInt32(zipData.count)

            // Add to central directory
            let centralDirHeader = createCentralDirectoryHeader(
                for: file,
                localHeaderOffset: localHeaderOffset
            )
            centralDirectory.append(centralDirHeader)
            centralDirectory.append(fileNameData)
        }

        // Write central directory
        let centralDirOffset = UInt32(zipData.count)
        zipData.append(centralDirectory)

        // Write end of central directory record
        let endOfCentralDir = createEndOfCentralDirectory(
            numberOfEntries: UInt16(files.count),
            centralDirSize: UInt32(centralDirectory.count),
            centralDirOffset: centralDirOffset
        )
        zipData.append(endOfCentralDir)

        return zipData
    }

    private func createLocalFileHeader(for file: FileEntry) -> Data {
        var header = Data()

        // Local file header signature (0x04034b50)
        header.append(contentsOf: [0x50, 0x4b, 0x03, 0x04])

        // Version needed to extract (2.0)
        header.append(contentsOf: [0x14, 0x00])

        // General purpose bit flag
        header.append(contentsOf: [0x00, 0x00])

        // Compression method (0 = stored, no compression)
        header.append(contentsOf: [0x00, 0x00])

        // Last mod time & date
        let dosDateTime = getDOSDateTime(from: file.modificationDate)
        header.append(littleEndian: UInt16(dosDateTime.time))
        header.append(littleEndian: UInt16(dosDateTime.date))

        // CRC-32
        let crc = calculateCRC32(data: file.data)
        header.append(littleEndian: crc)

        // Compressed size
        header.append(littleEndian: UInt32(file.data.count))

        // Uncompressed size
        header.append(littleEndian: UInt32(file.data.count))

        // File name length
        let fileNameData = file.path.data(using: .utf8)!
        header.append(littleEndian: UInt16(fileNameData.count))

        // Extra field length
        header.append(contentsOf: [0x00, 0x00])

        return header
    }

    private func createCentralDirectoryHeader(for file: FileEntry, localHeaderOffset: UInt32) -> Data {
        var header = Data()

        // Central directory signature (0x02014b50)
        header.append(contentsOf: [0x50, 0x4b, 0x01, 0x02])

        // Version made by
        header.append(contentsOf: [0x14, 0x00])

        // Version needed to extract
        header.append(contentsOf: [0x14, 0x00])

        // General purpose bit flag
        header.append(contentsOf: [0x00, 0x00])

        // Compression method (0 = stored)
        header.append(contentsOf: [0x00, 0x00])

        // Last mod time & date
        let dosDateTime = getDOSDateTime(from: file.modificationDate)
        header.append(littleEndian: UInt16(dosDateTime.time))
        header.append(littleEndian: UInt16(dosDateTime.date))

        // CRC-32
        let crc = calculateCRC32(data: file.data)
        header.append(littleEndian: crc)

        // Compressed size
        header.append(littleEndian: UInt32(file.data.count))

        // Uncompressed size
        header.append(littleEndian: UInt32(file.data.count))

        // File name length
        let fileNameData = file.path.data(using: .utf8)!
        header.append(littleEndian: UInt16(fileNameData.count))

        // Extra field length
        header.append(contentsOf: [0x00, 0x00])

        // File comment length
        header.append(contentsOf: [0x00, 0x00])

        // Disk number start
        header.append(contentsOf: [0x00, 0x00])

        // Internal file attributes
        header.append(contentsOf: [0x00, 0x00])

        // External file attributes
        header.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Relative offset of local header
        header.append(littleEndian: localHeaderOffset)

        return header
    }

    private func createEndOfCentralDirectory(numberOfEntries: UInt16, centralDirSize: UInt32, centralDirOffset: UInt32) -> Data {
        var record = Data()

        // End of central directory signature (0x06054b50)
        record.append(contentsOf: [0x50, 0x4b, 0x05, 0x06])

        // Number of this disk
        record.append(contentsOf: [0x00, 0x00])

        // Disk where central directory starts
        record.append(contentsOf: [0x00, 0x00])

        // Number of central directory records on this disk
        record.append(littleEndian: numberOfEntries)

        // Total number of central directory records
        record.append(littleEndian: numberOfEntries)

        // Size of central directory
        record.append(littleEndian: centralDirSize)

        // Offset of start of central directory
        record.append(littleEndian: centralDirOffset)

        // Comment length
        record.append(contentsOf: [0x00, 0x00])

        return record
    }

    private func getDOSDateTime(from date: Date) -> (time: UInt16, date: UInt16) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        let year = UInt16(max(1980, components.year ?? 1980) - 1980)
        let month = UInt16(components.month ?? 1)
        let day = UInt16(components.day ?? 1)
        let hour = UInt16(components.hour ?? 0)
        let minute = UInt16(components.minute ?? 0)
        let second = UInt16((components.second ?? 0) / 2)

        let dosDate = (year << 9) | (month << 5) | day
        let dosTime = (hour << 11) | (minute << 5) | second

        return (dosTime, dosDate)
    }

    private func calculateCRC32(data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF

        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crc32Table[index]
        }

        return crc ^ 0xFFFFFFFF
    }

    // CRC-32 lookup table
    private let crc32Table: [UInt32] = {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var crc = UInt32(i)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc >>= 1
                }
            }
            table[i] = crc
        }
        return table
    }()
}

// MARK: - Data Extensions

extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { bytes in
            self.append(contentsOf: bytes)
        }
    }
}
