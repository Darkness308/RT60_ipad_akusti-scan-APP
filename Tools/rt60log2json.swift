#!/usr/bin/env swift

import Foundation

// Simple RT60 log to JSON converter (standalone script)
// Usage: swift rt60log2json.swift input.txt [-o output.json]

struct RT60Band {
    let freq_hz: Int
    let t20_s: Double?
    let correlation: Double?
    let valid: Bool
}

struct RT60LogModel {
    let metadata: [String: String]
    let bands: [RT60Band]
    let checksum: String
    let sourceFile: String
}

func parseDoubleLocaleAware(_ string: String) -> Double? {
    if let value = Double(string) {
        return value
    }
    let normalized = string.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
}

func parseT20Value(_ valueString: String) -> (Double?, Bool) {
    if valueString.contains("-.--") || valueString.contains("-.-") {
        return (nil, false)
    }
    
    if let value = parseDoubleLocaleAware(valueString) {
        let clampedValue = max(0.1, min(10.0, value))
        return (clampedValue, value >= 0)
    }
    
    return (nil, false)
}

func parseLogFile(_ text: String, sourceFile: String) -> RT60LogModel {
    let lines = text.components(separatedBy: .newlines)
    var metadata: [String: String] = [:]
    var bands: [RT60Band] = []
    var checksum: String?
    var currentSection: String?
    
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty || trimmed.hasPrefix("//") { continue }
        
        if trimmed.hasSuffix(":") {
            currentSection = String(trimmed.dropLast())
            continue
        }
        
        switch currentSection {
        case "Setup":
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                metadata[key] = value
            }
        case "T20":
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2 {
                let freqString = String(parts[0]).replacingOccurrences(of: "Hz", with: "")
                if let freq = Int(freqString) {
                    let (t20Value, isValid) = parseT20Value(String(parts[1]))
                    bands.append(RT60Band(freq_hz: freq, t20_s: t20Value, correlation: nil, valid: isValid))
                }
            }
        case "Correltn":
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2 {
                let freqString = String(parts[0]).replacingOccurrences(of: "Hz", with: "")
                if let freq = Int(freqString), let correlation = parseDoubleLocaleAware(String(parts[1])) {
                    if let index = bands.firstIndex(where: { $0.freq_hz == freq }) {
                        let validCorr = correlation >= 0 && correlation <= 100 ? correlation / 100.0 : nil
                        bands[index] = RT60Band(
                            freq_hz: bands[index].freq_hz,
                            t20_s: bands[index].t20_s,
                            correlation: validCorr,
                            valid: bands[index].valid
                        )
                    }
                }
            }
        case "CheckSum":
            checksum = trimmed
        default:
            break
        }
    }
    
    return RT60LogModel(
        metadata: metadata,
        bands: bands,
        checksum: checksum ?? "",
        sourceFile: sourceFile
    )
}

func createAuditJSON(from model: RT60LogModel) -> Data {
    let audit: [String: Any] = [
        "source": model.sourceFile,
        "checksum": model.checksum,
        "timestamp": ISO8601DateFormatter().string(from: Date()),
        "metadata": model.metadata,
        "measurements": model.bands.map { band in
            return [
                "frequency_hz": band.freq_hz,
                "t20_s": band.t20_s as Any,
                "correlation": band.correlation as Any,
                "valid": band.valid
            ]
        },
        "validation": [
            "total_bands": model.bands.count,
            "valid_bands": model.bands.filter { $0.valid }.count,
            "invalid_bands": model.bands.filter { !$0.valid }.count,
            "checksum_present": !model.checksum.isEmpty
        ]
    ]
    
    return try! JSONSerialization.data(withJSONObject: audit, options: [.prettyPrinted, .sortedKeys])
}

// Main execution
let args = CommandLine.arguments

if args.count < 2 {
    print("Usage: swift rt60log2json.swift <input.txt> [-o <output.json>]")
    exit(1)
}

let inputFile = args[1]
var outputFile: String?

if args.count >= 4 && args[2] == "-o" {
    outputFile = args[3]
}

do {
    let content = try String(contentsOfFile: inputFile, encoding: .utf8)
    let model = parseLogFile(content, sourceFile: inputFile)
    let auditData = createAuditJSON(from: model)
    
    if let outputFile = outputFile {
        try auditData.write(to: URL(fileURLWithPath: outputFile))
        print("✅ Audit saved to: \(outputFile)")
    } else {
        if let jsonString = String(data: auditData, encoding: .utf8) {
            print(jsonString)
        }
    }
    
    let validBands = model.bands.filter { $0.valid }
    print("📊 Summary: \(validBands.count)/\(model.bands.count) valid measurements", to: &standardError)
    
} catch {
    print("❌ Error: \(error.localizedDescription)")
    exit(1)
}

// Helper for stderr output
extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}

var standardError = FileHandle.standardError