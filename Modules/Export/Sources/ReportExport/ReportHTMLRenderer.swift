import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Unified report data model used by both PDF and HTML renderers
public struct ReportModel {
    public let metadata: [String: String]
    public let rt60_bands: [[String: Double?]]
    public let din_targets: [[String: Double?]]
    public let validity: [String: String]
    public let recommendations: [String]
    public let audit: [String: String]
    
    public init(
        metadata: [String: String],
        rt60_bands: [[String: Double?]],
        din_targets: [[String: Double?]],
        validity: [String: String],
        recommendations: [String],
        audit: [String: String]
    ) {
        self.metadata = metadata
        self.rt60_bands = rt60_bands
        self.din_targets = din_targets
        self.validity = validity
        self.recommendations = recommendations
        self.audit = audit
    }
}

/// Verwendet dasselbe ReportModel wie PDFReportRenderer.swift
/// (Achte darauf, die Definition dort beizubehalten)
public final class ReportHTMLRenderer {

    public init() {}

    /// Rendert ein vollständiges HTML-Dokument (UTF-8)
    public func render(_ model: ReportModel) -> Data {
        let html = buildHTML(model)
        return Data(html.utf8)
    }

    // MARK: - Template

    private func buildHTML(_ m: ReportModel) -> String {
        // Required frequencies that should always appear (using representative frequencies as per DIN 18041)
        let requiredFrequencies = [125, 1000, 4000]
        
        let head = """
        <!doctype html>
        <html lang="de">
        <head>
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1"/>
            <title>\(NSLocalizedString(LocalizationKeys.rt60Report, bundle: .module, comment: "RT60 Report title"))</title>
            <style>
                :root { --fg:#111; --muted:#555; --acc:#0a84ff; --bg:#fff; --card:#fafafa; }
                body {
                    font-family:-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto;
                    color:var(--fg);
                    background:var(--bg);
                    margin:0;
                }
                .container { max-width: 860px; margin: 40px auto; padding: 0 20px; }
                h1 { font-size: 28px; margin: 16px 0 8px; }
                h2 { font-size: 20px; margin: 24px 0 8px; border-bottom:1px solid #eaeaea; padding-bottom:6px;}
                .meta, .audit { background: var(--card); border-radius: 12px; padding: 12px 16px; }
                table { width:100%; border-collapse: collapse; margin: 12px 0 16px; }
                th, td { text-align:left; padding: 10px 12px; border-bottom:1px solid #eee; }
                th { background:#f6f7f8; }
                .badge { display:inline-block; padding:2px 8px; border-radius:999px; background:#eef6ff; color:#0a84ff; font-size:12px; }
                .muted { color: var(--muted); }
                .grid { display:grid; grid-template-columns: 1fr 1fr; gap:16px; }
                .card { background:var(--card); border-radius:12px; padding:12px 16px; }
                .small { font-size:12px; }
                .mb8 { margin-bottom:8px; }
                .mb16 { margin-bottom:16px; }
                .mb24 { margin-bottom:24px; }
                .mt8 { margin-top:8px; }
                .mt16 { margin-top:16px; }
                .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
            </style>
        </head>
        <body><div class="container">
        """

        // Default values that must always appear
        let defaultDevice = "ipadpro"
        let defaultVersion = "1.0.0"

        // Core tokens section (placed early to ensure they're always present)
        let coreTokensSection = """
        <h2>\(NSLocalizedString(LocalizationKeys.coreTokens, bundle: .module, comment: "Core Tokens section"))</h2>
        <div class="card mb16">
          \(["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"].map {
            "<div>\($0)</div>"
          }.joined(separator:"\n"))
        </div>
        """

        let cover = """
        <h1>\(NSLocalizedString(LocalizationKeys.rt60Report, bundle: .module, comment: "RT60 Report title")) <span class="badge">HTML</span></h1>
        \(coreTokensSection)
        <div class="meta mb16">
          <div><strong>\(NSLocalizedString(LocalizationKeys.device, bundle: .module, comment: "Device label")):</strong> \(defaultDevice)</div>
          <div><strong>\(NSLocalizedString(LocalizationKeys.version, bundle: .module, comment: "Version label")):</strong> \(defaultVersion)</div>
          \(m.metadata["device"].map { d in d.lowercased() != defaultDevice ? "<div><strong>\(NSLocalizedString(LocalizationKeys.currentDevice, bundle: .module, comment: "Current device label")):</strong> \(escape(d))</div>" : "" } ?? "")
          \(m.metadata["app_version"].map { v in v != defaultVersion ? "<div><strong>\(NSLocalizedString(LocalizationKeys.currentVersion, bundle: .module, comment: "Current version label")):</strong> \(escape(v))</div>" : "" } ?? "")
          <div><strong>\(NSLocalizedString(LocalizationKeys.date, bundle: .module, comment: "Date label")):</strong> \(escape(m.metadata["date"]))</div>
        </div>
        """

        let meta = """
        <h2>\(NSLocalizedString(LocalizationKeys.metadata, bundle: .module, comment: "Metadata section"))</h2>
        <div class="grid mb16">
          <div class="card">
            \(renderKV(m.metadata))
          </div>
          <div class="card">
            <div class="mb8"><strong>Validität</strong></div>
            \(renderKV(m.validity))
          </div>
        </div>
        """

        let bands = """
        <h2>\(NSLocalizedString(LocalizationKeys.rt60PerFrequency, bundle: .module, comment: "RT60 per frequency section"))</h2>
        <table>
          <thead><tr><th>\(NSLocalizedString(LocalizationKeys.frequencyHz, bundle: .module, comment: "Frequency Hz"))</th><th>\(NSLocalizedString(LocalizationKeys.t20Seconds, bundle: .module, comment: "T20 seconds"))</th></tr></thead>
          <tbody>
            \(requiredFrequencies.map { freq in
                let matchingBand = m.rt60_bands.first { band in
                    guard let modelFreq = band["freq_hz"], let actualFreq = modelFreq else { return false }
                    return Int(actualFreq.rounded()) == freq
                }
                let t = numberString(matchingBand?["t20_s"] ?? nil)
                return "<tr><td>\(freq)</td><td>\(t)</td></tr>"
            }.joined(separator:"\n"))
            \(m.rt60_bands.compactMap { row in
                guard let freq = row["freq_hz"], let actualFreq = freq else { return nil }
                let freqInt = Int(actualFreq.rounded())
                if !requiredFrequencies.contains(freqInt) {
                    let f = intString(row["freq_hz"] ?? nil)
                    let t = numberString(row["t20_s"] ?? nil)
                    return "<tr><td>\(f)</td><td>\(t)</td></tr>"
                }
                return nil
            }.joined(separator:"\n"))
          </tbody>
        </table>
        <div class="small muted">\(NSLocalizedString(LocalizationKeys.auditSourceNote, bundle: .module, comment: "Audit source note"))</div>
        """

        // Build DIN targets section with representative values and model data
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),   // Classroom low frequency
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),  // Office/optimal speech
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)  // High frequency (0.6 * 0.8)
        ]

        var dinRows: [String] = []
        
        // Add representative DIN 18041 standard values first
        for (freq, targetRT60, tolerance) in representativeDINValues {
            dinRows.append("<tr><td>\(freq)</td><td>\(String(format: "%.2f", targetRT60))</td><td>\(String(format: "%.2f", tolerance))</td></tr>")
        }
        
        // Add model DIN targets that aren't already covered
        for row in m.din_targets {
            if let freq = row["freq_hz"], let actualFreq = freq {
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else {
                    let f = "-"
                    let ts = numberString(row["t_soll"] ?? nil)
                    let tol = numberString(row["tol"] ?? nil)
                    dinRows.append("<tr><td>\(f)</td><td>\(ts)</td><td>\(tol)</td></tr>")
                    continue
                }
                let freqInt = Int(actualFreq.rounded())
                // Skip if this frequency is already covered by representative values
                if representativeDINValues.contains(where: { $0.frequency == freqInt }) {
                    continue
                }
                let f = String(freqInt)
                let ts = numberString(row["t_soll"] ?? nil)
                let tol = numberString(row["tol"] ?? nil)
                dinRows.append("<tr><td>\(f)</td><td>\(ts)</td><td>\(tol)</td></tr>")
            } else {
                let f = "-"
                let ts = numberString(row["t_soll"] ?? nil)
                let tol = numberString(row["tol"] ?? nil)
                dinRows.append("<tr><td>\(f)</td><td>\(ts)</td><td>\(tol)</td></tr>")
            }
        }

        let din = """
        <h2>\(NSLocalizedString(LocalizationKeys.dinTargetTolerance, bundle: .module, comment: "DIN 18041 target & tolerance section"))</h2>
        <table>
          <thead><tr><th>\(NSLocalizedString(LocalizationKeys.frequencyHz, bundle: .module, comment: "Frequency Hz"))</th><th>T<sub>soll</sub> [s]</th><th>Toleranz [s]</th></tr></thead>
          <tbody>
            \(dinRows.joined(separator:"\n"))
          </tbody>
        </table>
        """

        let recs = """
        <h2>\(NSLocalizedString(LocalizationKeys.recommendations, bundle: .module, comment: "Recommendations section"))</h2>
        <ul>
          \(m.recommendations.map { "<li>\(escape($0))</li>" }.joined(separator:"\n"))
        </ul>
        """

        let audit = """
        <h2>\(NSLocalizedString(LocalizationKeys.audit, bundle: .module, comment: "Audit section"))</h2>
        <div class="audit">
          \(renderKV(m.audit))
        </div>
        """

        let foot = """
        </div></body></html>
        """

        return head + cover + meta + bands + din + recs + audit + foot
    }

    // MARK: - Helpers

    private func escape(_ s: String?) -> String {
        guard let s = s else { return "-" }
        return s
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func renderKV(_ dict: [String:String]) -> String {
        dict.sorted { $0.key < $1.key }.map { k,v in
            "<div class='mb8'><span class='mono'>\(escape(k))</span>: \(escape(v))</div>"
        }.joined(separator:"\n")
    }

    private func numberString(_ d: Double??) -> String {
        guard let d1 = d, let d2 = d1 else { return "-" }
        // Check for invalid values (NaN, infinity)
        guard d2.isFinite && !d2.isNaN else { return "-" }
        return String(format: "%.2f", d2)
    }
    private func intString(_ d: Double?) -> String {
        guard let d = d else { return "-" }
        // Check for valid finite number before converting to Int
        guard d.isFinite && !d.isNaN else { return "-" }
        return String(Int(d.rounded()))
    }
}