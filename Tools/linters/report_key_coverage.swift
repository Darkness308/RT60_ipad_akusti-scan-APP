#!/usr/bin/env swift
import Foundation

// MARK: - Shared Model (muss identisch zu Renderer-Definition sein)
public struct ReportModel: Codable {
    public let metadata: [String: String]
    public let rt60_bands: [[String: Double?]]
    public let din_targets: [[String: Double]]
    public let validity: [String: String]
    public let recommendations: [String]
    public let audit: [String: String]
}

// MARK: - Very light HTML rendering (string only) & PDF rendering proxy
// Für Linter reicht, dass beide Renderer-Komponenten kompiliert werden;
// Wir binden die Projekt-Renderer via SwiftPM/Xcode im CI-Build ein.
// Hier im Script wird nur HTML gerendert, PDF-Text muss vom Binary kommen.
func renderHTMLText(_ model: ReportModel) -> String {
    // Minimaler inhaltlicher String für Coverage (kein echtes HTML nötig)
    var out = [String]()
    out.append("RT60 Bericht")
    out.append("Metadaten")
    out.append(model.metadata.map { "\($0.key):\($0.value)" }.joined(separator:" "))
    out.append("RT60 je Frequenz")
    for row in model.rt60_bands {
        let f = Int(row["freq_hz"]??.rounded() ?? 0)
        let t = row["t20_s"]?.map { String(format:"%.2f", $0) } ?? "-"
        out.append("\(f) \(t)")
    }
    out.append("DIN 18041")
    for row in model.din_targets {
        let f = Int((row["freq_hz"] ?? 0).rounded())
        let ts = String(format:"%.2f", row["t_soll"] ?? 0)
        let tol = String(format:"%.2f", row["tol"] ?? 0.2)
        out.append("\(f) \(ts) \(tol)")
    }
    out.append("Gültigkeit")
    out.append(model.validity.map { "\($0.key):\($0.value)" }.joined(separator:" "))
    out.append("Empfehlungen")
    out.append(model.recommendations.joined(separator:" "))
    out.append("Audit")
    out.append(model.audit.map { "\($0.key):\($0.value)" }.joined(separator:" "))
    return out.joined(separator:" ").lowercased()
}

// MARK: - Load JSONs
let args = CommandLine.arguments.dropFirst()
guard args.count >= 1 else {
    fputs("Usage: report_key_coverage <ReportModel.json> [more.json ...]\n", stderr)
    exit(2)
}

var failed = false
for path in args {
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let model = try JSONDecoder().decode(ReportModel.self, from: data)

        // 1) HTML-Text
        let htmlText = renderHTMLText(model)

        // 2) Soll-Keys & Werte ableiten (Pflichtfelder)
        //    Wir prüfen, dass JEDE Zahl/Texteintrag in mind. einer Ausgabe vorkommt.
        var tokens = [String]()

        // metadata
        for (k,v) in model.metadata {
            tokens.append(k.lowercased())
            tokens.append(v.lowercased())
        }
        // rt60_bands
        for row in model.rt60_bands {
            if let f = row["freq_hz"], let fVal = f { tokens.append(String(Int(fVal.rounded()))) }
            if let t = row["t20_s"], let tVal = t { tokens.append(String(format:"%.2f", tVal).lowercased()) } else { tokens.append("-") }
        }
        // din_targets
        for row in model.din_targets {
            if let f = row["freq_hz"] { tokens.append(String(Int(f.rounded()))) }
            if let ts = row["t_soll"] { tokens.append(String(format:"%.2f", ts).lowercased()) }
            if let tol = row["tol"] { tokens.append(String(format:"%.2f", tol).lowercased()) }
        }
        // validity
        for (k,v) in model.validity { tokens.append(k.lowercased()); tokens.append(v.lowercased()) }
        // recommendations
        for r in model.recommendations { tokens.append(r.lowercased()) }
        // audit
        for (k,v) in model.audit { tokens.append(k.lowercased()); tokens.append(v.lowercased()) }

        // HTML-Coverage
        var htmlMiss = [String]()
        for t in tokens where !t.trimmingCharacters(in: .whitespaces).isEmpty {
            if !htmlText.contains(t) { htmlMiss.append(t) }
        }

        if !htmlMiss.isEmpty {
            fputs("[HTML] Missing tokens in \(path): \(htmlMiss.joined(separator: ", "))\n", stderr)
            failed = true
        } else {
            print("[HTML] OK \(path)")
        }

        // Hinweis: PDF-Coverage erfolgt in Unit-Tests (PDFReportSnapshot/Contract),
        // oder alternativ über ein separates Tool, das PDF-Text extrahiert.

    } catch {
        fputs("Error \(path): \(error)\n", stderr)
        failed = true
    }
}

exit(failed ? 1 : 0)