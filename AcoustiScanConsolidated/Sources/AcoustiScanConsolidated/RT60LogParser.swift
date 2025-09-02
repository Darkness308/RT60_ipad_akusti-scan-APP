// RT60LogParser.swift
// Safe parser for RT60 log files with locale and edge-case handling

import Foundation

/// Parser for RT60 log files with robust edge-case handling
public class RT60LogParser {
    
    /// Parse RT60 log text with locale-tolerant number parsing
    public func parse(text: String, sourceFile: String) throws -> RT60LogModel {
        AppLog.parse.info("Parsing log from \(sourceFile)")
        
        let lines = text.components(separatedBy: .newlines)
        var metadata: [String: String] = [:]
        var bands: [RT60Band] = []
        var checksum: String?
        
        var currentSection: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty || trimmed.hasPrefix("//") {
                continue
            }
            
            // Section headers
            if trimmed.hasSuffix(":") {
                currentSection = String(trimmed.dropLast())
                continue
            }
            
            // Process line based on current section
            switch currentSection {
            case "Setup":
                parseSetupLine(trimmed, into: &metadata)
            case "T20":
                if let band = parseT20Line(trimmed) {
                    bands.append(band)
                }
            case "Correltn":
                parseCorrelationLine(trimmed, into: &bands)
            case "CheckSum":
                checksum = trimmed
            default:
                break
            }
        }
        
        AppLog.parse.info("Parsed \(bands.count) frequency bands")
        return RT60LogModel(
            metadata: metadata,
            bands: bands,
            checksum: checksum ?? "",
            sourceFile: sourceFile
        )
    }
    
    private func parseSetupLine(_ line: String, into metadata: inout [String: String]) {
        let parts = line.split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            metadata[key] = value
        }
    }
    
    private func parseT20Line(_ line: String) -> RT60Band? {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }
        
        // Parse frequency
        guard let freq = parseFrequency(String(parts[0])) else { return nil }
        
        // Parse T20 value with locale handling and "-.--" detection
        let t20String = String(parts[1])
        let (t20Value, isValid) = parseT20Value(t20String)
        
        AppLog.logMeasurement(freq, t20Value ?? -1, "s")
        AppLog.logValidation("T20 \(freq)Hz", isValid, isValid ? "" : "value was \(t20String)")
        
        return RT60Band(
            freq_hz: freq,
            t20_s: t20Value,
            correlation: nil,
            valid: isValid
        )
    }
    
    private func parseCorrelationLine(_ line: String, into bands: inout [RT60Band]) {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return }
        
        guard let freq = parseFrequency(String(parts[0])) else { return }
        guard let correlation = parseDoubleLocaleAware(String(parts[1])) else { return }
        
        // Find matching band and update correlation
        if let index = bands.firstIndex(where: { $0.freq_hz == freq }) {
            bands[index].correlation = Guardrails.validateCorrelation(correlation / 100.0) // Convert percentage
        }
    }
    
    private func parseFrequency(_ freqString: String) -> Int? {
        // Remove "Hz" suffix if present
        let cleaned = freqString.replacingOccurrences(of: "Hz", with: "")
        return Int(cleaned)
    }
    
    private func parseT20Value(_ valueString: String) -> (Double?, Bool) {
        // Check for "-.--" pattern (invalid measurement)
        if valueString.contains("-.--") || valueString.contains("-.-") {
            return (nil, false)
        }
        
        // Try locale-aware parsing
        if let value = parseDoubleLocaleAware(valueString) {
            let clampedValue = Guardrails.clampRT60(value)
            return (SafeMath.isValid(clampedValue) ? clampedValue : nil, SafeMath.isValid(clampedValue))
        }
        
        return (nil, false)
    }
    
    /// Parse double with locale tolerance (handles both "0.70" and "0,70")
    private func parseDoubleLocaleAware(_ string: String) -> Double? {
        // First try direct parsing
        if let value = Double(string) {
            return value
        }
        
        // Try replacing comma with dot for European locales
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

/// RT60 measurement data model
public struct RT60LogModel {
    public let metadata: [String: String]
    public let bands: [RT60Band]
    public let checksum: String
    public let sourceFile: String
    
    public init(metadata: [String: String], bands: [RT60Band], checksum: String, sourceFile: String) {
        self.metadata = metadata
        self.bands = bands
        self.checksum = checksum
        self.sourceFile = sourceFile
    }
}

/// Individual frequency band measurement
public struct RT60Band {
    public let freq_hz: Int
    public let t20_s: Double?
    public var correlation: Double?
    public let valid: Bool
    
    public init(freq_hz: Int, t20_s: Double?, correlation: Double?, valid: Bool) {
        self.freq_hz = freq_hz
        self.t20_s = t20_s
        self.correlation = correlation
        self.valid = valid
    }
}