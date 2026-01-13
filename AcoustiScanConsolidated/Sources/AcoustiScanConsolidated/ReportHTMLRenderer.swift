// ReportHTMLRenderer.swift
// HTML renderer for ReportModel without PDFKit dependencies

import Foundation

/// HTML renderer for ReportModel that produces UTF-8 HTML content
public class ReportHTMLRenderer {

    public init() {}

    /// Render ReportModel to HTML data
    public func render(_ model: ReportModel) -> Data {
        let html = generateHTML(model)
        return html.data(using: .utf8) ?? Data()
    }

    private func generateHTML(_ model: ReportModel) -> String {
        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Raumakustik Report</title>
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
            </style>
        </head>
        <body>
            <div class="header">
                <h1>RT60 Bericht</h1>
                <p>RT60-Messung und DIN 18041-Bewertung</p>
            </div>

            \(renderMetadataSection(model.metadata))
            \(renderRT60Section(model.rt60_bands))
            \(renderDINTargetsSection(model.din_targets))
            \(renderValiditySection(model.validity))
            \(renderRecommendationsSection(model.recommendations))
            \(renderAuditSection(model.audit))

            <div class="footer">
                <p>Erstellt mit AcoustiScan Consolidated Tool</p>
            </div>
        </body>
        </html>
        """
    }

    private func renderMetadataSection(_ metadata: [String: String]) -> String {
        var rows = ""
        for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>\n"
        }

        return """
        <div class="section">
            <h2>Metadaten</h2>
            <table class="metadata-table">
                \(rows)
            </table>
        </div>
        """
    }

    private func renderRT60Section(_ rt60_bands: [[String: Double?]]) -> String {
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

        return """
        <div class="section">
            <h2>RT60 je Frequenz</h2>
            <table>
                <thead>
                    <tr><th>Frequenz (Hz)</th><th>RT60 (s)</th></tr>
                </thead>
                <tbody>
                    \(rows)
                </tbody>
            </table>
        </div>
        """
    }

    private func renderDINTargetsSection(_ din_targets: [[String: Double]]) -> String {
        var rows = ""
        for target in din_targets.sorted(by: {
            ($0["freq_hz"] ?? 0) < ($1["freq_hz"] ?? 0)
        }) {
            let freq = Int(target["freq_hz"] ?? 0)
            let t_soll = String(format: "%.2f", target["t_soll"] ?? 0)
            let tol = String(format: "%.2f", target["tol"] ?? 0)
            rows += "<tr><td>\(freq)</td><td>\(t_soll)</td><td>\(tol)</td></tr>\n"
        }

        return """
        <div class="section">
            <h2>DIN 18041 Zielwerte</h2>
            <table>
                <thead>
                    <tr><th>Frequenz (Hz)</th><th>Soll-RT60 (s)</th><th>Toleranz (s)</th></tr>
                </thead>
                <tbody>
                    \(rows)
                </tbody>
            </table>
        </div>
        """
    }

    private func renderValiditySection(_ validity: [String: String]) -> String {
        var rows = ""
        for (key, value) in validity.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>\n"
        }

        return """
        <div class="section">
            <h2>Gültigkeit</h2>
            <table class="metadata-table">
                \(rows)
            </table>
        </div>
        """
    }

    private func renderRecommendationsSection(_ recommendations: [String]) -> String {
        let items = recommendations.map { "<li>\(escapeHTML($0))</li>" }.joined(separator: "\n")

        return """
        <div class="section">
            <h2>Empfehlungen</h2>
            <ul>
                \(items)
            </ul>
        </div>
        """
    }

    private func renderAuditSection(_ audit: [String: String]) -> String {
        var rows = ""
        for (key, value) in audit.sorted(by: { $0.key < $1.key }) {
            rows += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>\n"
        }

        return """
        <div class="section">
            <h2>Audit-Informationen</h2>
            <table class="metadata-table">
                \(rows)
            </table>
        </div>
        """
    }

    /// Escape HTML entities to prevent XSS and ensure proper rendering
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}