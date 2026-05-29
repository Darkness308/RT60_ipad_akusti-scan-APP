// ReportHTMLRenderer.swift
// HTML renderer for ReportModel without PDFKit dependencies

import Foundation

public enum RenderMode: Equatable {
    case standalone
    case multiFile(resourcesPath: String)
}

public struct EscapedHTML: Equatable, CustomStringConvertible {
    public let value: String
    public var description: String { value }

    fileprivate init(_ value: String) {
        self.value = value
    }
}

/// HTML renderer for ReportModel that produces UTF-8 HTML content
public class ReportHTMLRenderer {
    private let mode: RenderMode

    public init(mode: RenderMode = .standalone) {
        self.mode = mode
    }

    /// Render ReportModel to HTML data
    public func render(_ model: ReportModel) -> Data {
        let html = generateHTML(model)
        return html.data(using: .utf8) ?? Data()
    }

    private func generateHTML(_ model: ReportModel) -> String {
        let origin = escaped(model.sourceOrigin)
        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="report-origin" content="\(origin.value)">
            <title>Raumakustik Report</title>
            \(renderCSSReference())
        </head>
        <body>
            <div class="header">
                <h1>RT60 Bericht</h1>
                <p>RT60-Messung und DIN 18041-Bewertung</p>
            </div>

            \(renderMetadataSection(model.metadata, origin: origin))
            \(renderRT60Section(model.rt60_bands, origin: origin))
            \(renderDINTargetsSection(model.din_targets, origin: origin))
            \(renderValiditySection(model.validity, origin: origin))
            \(renderRecommendationsSection(model.recommendations, origin: origin))
            \(renderAuditSection(model.audit, origin: origin))

            <div class="footer">
                <p>Erstellt mit AcoustiScan Consolidated Tool</p>
            </div>
        </body>
        </html>
        """
    }

    private func renderCSSReference() -> String {
        switch mode {
        case .standalone:
            return """
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; color: #333; }
                .header { text-align: center; margin-bottom: 40px; }
                .section { margin: 30px 0; }
                .section h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
                table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
                th { background-color: #f2f2f2; font-weight: bold; }
                .metadata-table td:first-child { font-weight: bold; width: 30%; }
                .status-green { color: #27ae60; font-weight: bold; }
                .status-red { color: #e74c3c; font-weight: bold; }
                .status-orange { color: #f39c12; font-weight: bold; }
                ul { padding-left: 20px; }
                .footer { margin-top: 60px; text-align: center; color: #7f8c8d; font-size: 12px; }
                .origin-badge {
                    display: inline-block;
                    margin-left: 8px;
                    padding: 2px 6px;
                    font-size: 11px;
                    color: #2c3e50;
                    border: 1px solid #bdc3c7;
                    border-radius: 4px;
                    background: #f8f9fa;
                }
            </style>
            """
        case .multiFile(let resourcesPath):
            // Expected input is a relative resources path for deployed static assets.
            let escapedPath = escapeHTML(resourcesPath)
            return "<link rel=\"stylesheet\" href=\"\(escapedPath)/report.css\">"
        }
    }

    private func renderSection(title: EscapedHTML, body: String, origin: EscapedHTML) -> String {
        return """
        <div class="section" data-origin="\(origin.value)">
            <h2>\(title.value) <span class="origin-badge">Origin: \(origin.value)</span></h2>
            \(body)
        </div>
        """
    }

    private func renderMetadataSection(_ metadata: [String: String], origin: EscapedHTML) -> String {
        var rows = ""
        for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escaped(key).value)</td><td>\(escaped(value).value)</td></tr>\n"
        }

        return renderSection(
            title: escaped("Metadaten"),
            body: """
            <table class="metadata-table">
                \(rows)
            </table>
            """,
            origin: origin
        )
    }

    private func renderRT60Section(_ rt60_bands: [[String: Double?]], origin: EscapedHTML) -> String {
        var rows = ""
        for band in rt60_bands.sorted(by: {
            ($0["freq_hz"] as? Double ?? 0) < ($1["freq_hz"] as? Double ?? 0)
        }) {
            let freq = Int(band["freq_hz"] as? Double ?? 0)
            if let t20_s = band["t20_s"], let value = t20_s {
                let t20_display = String(format: "%.2f", value)
                rows += "<tr><td>\(freq)</td><td>\(t20_display)</td></tr>\n"
            } else {
                rows += "<tr><td>\(freq)</td><td>-</td></tr>\n"
            }
        }

        return renderSection(
            title: escaped("RT60 je Frequenz"),
            body: """
            <table>
                <thead>
                    <tr><th>Frequenz (Hz)</th><th>RT60 (s)</th></tr>
                </thead>
                <tbody>
                    \(rows)
                </tbody>
            </table>
            """,
            origin: origin
        )
    }

    private func renderDINTargetsSection(_ din_targets: [[String: Double]], origin: EscapedHTML) -> String {
        var rows = ""
        for target in din_targets.sorted(by: {
            ($0["freq_hz"] ?? 0) < ($1["freq_hz"] ?? 0)
        }) {
            let freq = Int(target["freq_hz"] ?? 0)
            let t_soll = String(format: "%.2f", target["t_soll"] ?? 0)
            let tol = String(format: "%.2f", target["tol"] ?? 0)
            rows += "<tr><td>\(freq)</td><td>\(t_soll)</td><td>\(tol)</td></tr>\n"
        }

        return renderSection(
            title: escaped("DIN 18041 Zielwerte"),
            body: """
            <table>
                <thead>
                    <tr><th>Frequenz (Hz)</th><th>Soll-RT60 (s)</th><th>Toleranz (s)</th></tr>
                </thead>
                <tbody>
                    \(rows)
                </tbody>
            </table>
            """,
            origin: origin
        )
    }

    private func renderValiditySection(_ validity: [String: String], origin: EscapedHTML) -> String {
        var rows = ""
        for (key, value) in validity.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escaped(key).value)</td><td>\(escaped(value).value)</td></tr>\n"
        }

        return renderSection(
            title: escaped("Gültigkeit"),
            body: """
            <table class="metadata-table">
                \(rows)
            </table>
            """,
            origin: origin
        )
    }

    private func renderRecommendationsSection(_ recommendations: [String], origin: EscapedHTML) -> String {
        let items = recommendations.map { "<li>\(escaped($0).value)</li>" }.joined(separator: "\n")

        return renderSection(
            title: escaped("Empfehlungen"),
            body: """
            <ul>
                \(items)
            </ul>
            """,
            origin: origin
        )
    }

    private func renderAuditSection(_ audit: [String: String], origin: EscapedHTML) -> String {
        var rows = ""
        for (key, value) in audit.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escaped(key).value)</td><td>\(escaped(value).value)</td></tr>\n"
        }

        return renderSection(
            title: escaped("Audit-Informationen"),
            body: """
            <table class="metadata-table">
                \(rows)
            </table>
            """,
            origin: origin
        )
    }

    private func escaped(_ text: String) -> EscapedHTML {
        EscapedHTML(escapeHTML(text))
    }

    /// Escape HTML entities to prevent XSS and ensure proper rendering
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "onerror=", with: "onerror&#61;", options: .caseInsensitive)
            .replacingOccurrences(of: "onload=", with: "onload&#61;", options: .caseInsensitive)
            .replacingOccurrences(of: "javascript:", with: "javascript&#58;", options: .caseInsensitive)
    }
}
