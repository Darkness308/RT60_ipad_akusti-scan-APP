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
        let head = """
        <!doctype html>
        <html lang="de">
        <head>
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1"/>
            <title>RT60 Bericht</title>
            <style>
                :root { --fg:#111; --muted:#555; --acc:#0a84ff; --bg:#fff; --card:#fafafa; }
                body { font-family:-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto; color:var(--fg); background:var(--bg); margin:0; }
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

        let cover = """
        <h1>RT60 Bericht <span class="badge">HTML</span></h1>
        <div class="meta mb16">
          <div><strong>Version:</strong> \(escape(m.metadata["app_version"]))</div>
          <div><strong>Gerät:</strong> \(escape(m.metadata["device"]))</div>
          <div><strong>Datum:</strong> \(escape(m.metadata["date"]))</div>
        </div>
        """

        let meta = """
        <h2>Metadaten</h2>
        <div class="grid mb16">
          <div class="card">
            \(renderKV(m.metadata))
          </div>
          <div class="card">
            <div class="mb8"><strong>Validität/Unsicherheiten</strong></div>
            \(renderKV(m.validity))
          </div>
        </div>
        """

        let bands = """
        <h2>RT60 je Frequenz (T20 in s)</h2>
        <table>
          <thead><tr><th>Frequenz [Hz]</th><th>T20 [s]</th></tr></thead>
          <tbody>
            \(m.rt60_bands.map { row in
                let f = intString(row["freq_hz"] ?? nil)
                let t = numberString(row["t20_s"] ?? nil)
                return "<tr><td>\(f)</td><td>\(t)</td></tr>"
            }.joined(separator:"\n"))
          </tbody>
        </table>
        <div class="small muted">Hinweis: Werte aus Audit-Quelle (T20), Einheiten geprüft.</div>
        """

        let din = """
        <h2>DIN 18041 Ziel & Toleranz</h2>
        <table>
          <thead><tr><th>Frequenz [Hz]</th><th>T<sub>soll</sub> [s]</th><th>Toleranz [s]</th></tr></thead>
          <tbody>
            \(m.din_targets.map { row in
                let f = intString(row["freq_hz"] ?? nil)
                let ts = numberString(row["t_soll"] ?? nil)
                let tol = numberString(row["tol"] ?? nil)
                return "<tr><td>\(f)</td><td>\(ts)</td><td>\(tol)</td></tr>"
            }.joined(separator:"\n"))
          </tbody>
        </table>
        """

        let recs = """
        <h2>Empfehlungen</h2>
        <ul>
          \(m.recommendations.map { "<li>\(escape($0))</li>" }.joined(separator:"\n"))
        </ul>
        """

        let audit = """
        <h2>Audit</h2>
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
    }

    private func renderKV(_ dict: [String:String]) -> String {
        dict.sorted { $0.key < $1.key }.map { k,v in
            "<div class='mb8'><span class='mono'>\(escape(k))</span>: \(escape(v))</div>"
        }.joined(separator:"\n")
    }

    private func numberString(_ d: Double??) -> String {
        guard let d1 = d, let d2 = d1 else { return "-" }
        return String(format: "%.2f", d2)
    }
    private func intString(_ d: Double?) -> String {
        guard let d = d else { return "-" }
        return String(Int(d.rounded()))
    }
}