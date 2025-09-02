import Foundation

public struct AuditBand: Codable, Equatable {
    public let freq_hz: Int
    public let t20_s: Double?
    public let corr_percent: Double?
    public let valid: Bool
    public let note: String
}

public struct AuditSummary: Codable, Equatable {
    public let checksum_ok: Bool
    public let valid_band_count: Int
    public let mean_t20_s_valid: Double?
}

public struct AuditMetadata: Codable, Equatable {
    public let source_file: String
    public let timestamp_iso: String
    public let device: String
    public let app_version: String
}

public struct AuditModel: Codable, Equatable {
    public let metadata: AuditMetadata
    public let bands: [AuditBand]
    public let summary: AuditSummary
}

public enum RT60LogParserError: Error, CustomStringConvertible {
    case format(String)
    case checksum(String)
    public var description: String {
        switch self {
        case .format(let s): return "Formatfehler: \(s)"
        case .checksum(let s): return "Checksumme ungültig: \(s)"
        }
    }
}

public final class RT60LogParser {
    public init() {}

    public func parse(text: String, sourceFile: String) throws -> AuditModel {
        let lines = text.components(separatedBy: .newlines)

        // Abschnitte sammeln
        var section: String? = nil
        var setup: [String: String] = [:]
        var t20: [Int: String] = [:]
        var corr: [Int: String] = [:]
        var checksumStr: String?

        let ws = CharacterSet.whitespaces

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line.hasSuffix(":") { section = String(line.dropLast()); continue }

            switch section {
            case "Setup":
                // Key=Value
                let parts = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: ws) }
                if parts.count == 2 { setup[parts[0]] = parts[1] }

            case "T20":
                // "125Hz   0.89" oder "-.--"
                let comps = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                guard comps.count >= 2 else { continue }
                let freq = comps[0].replacingOccurrences(of: "Hz", with: "")
                if let f = Int(freq) { t20[f] = comps[1] }

            case "Correltn":
                let comps = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                guard comps.count >= 2 else { continue }
                let freq = comps[0].replacingOccurrences(of: "Hz", with: "")
                if let f = Int(freq) { corr[f] = comps[1] }

            default:
                if line.hasPrefix("Checksum=") {
                    checksumStr = String(line.dropFirst("Checksum=".count))
                }
            }
        }

        // Metadaten
        let meta = AuditMetadata(
            source_file: sourceFile,
            timestamp_iso: (setup["Date"] != nil ? "\(setup["Date"]!)T00:00:00Z" : ISO8601DateFormatter().string(from: Date())),
            device: setup["Device"] ?? "unknown",
            app_version: setup["AppVersion"] ?? "unknown"
        )

        // Bänder mergen
        let freqs = Set(t20.keys).union(corr.keys).sorted()
        var bands: [AuditBand] = []
        var validVals: [Double] = []

        for f in freqs {
            let t20raw = t20[f]
            let corrRaw = corr[f]
            let isNoData = (t20raw == "-.--")
            let isValid = !isNoData && (t20Val != nil) && (corrVal != nil) && (corrVal! >= 95.0)
            var note: [String] = []
            if isNoData { note.append("no data") }
            if let c = corrVal, c < 95.0 { note.append("low correlation") }
            if isValid, let v = t20Val { validVals.append(v) }

            bands.append(AuditBand(
                freq_hz: f,
                t20_s: t20Val,
                corr_percent: corrVal,
                valid: isValid,
                note: note.joined(separator: ", ")
            ))
        }

        // Checksumme (deterministisch über valide T20)
        let checksumOK = Self.verifyChecksum(values: validVals, checksum: checksumStr)

        let summary = AuditSummary(
            checksum_ok: checksumOK,
            valid_band_count: validVals.count,
            mean_t20_s_valid: validVals.isEmpty ? nil : validVals.reduce(0,+) / Double(validVals.count)
        )

        return AuditModel(metadata: meta, bands: bands, summary: summary)
    }

    private static func parseNumber(_ s: String?) -> Double? {
        guard var s = s else { return nil }
        if s == "-.--" { return nil }
        s = s.replacingOccurrences(of: ",", with: ".")
        return Double(s)
    }

    private static func verifyChecksum(values: [Double], checksum: String?) -> Bool {
        guard let checksum = checksum else { return false }
        // Simple deterministischer Hash: Summe * 1000 gerundet → Base36
        let sum = values.reduce(0,+)
        let key = Int((sum * 1000.0).rounded())
        let base36 = String(key, radix: 36).uppercased()
        return base36 == checksum.uppercased()
    }
}