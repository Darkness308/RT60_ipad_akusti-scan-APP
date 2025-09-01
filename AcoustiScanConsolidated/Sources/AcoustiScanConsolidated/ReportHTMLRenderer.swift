// ReportHTMLRenderer.swift
// HTML renderer for ReportModel without PDFKit dependencies

import Foundation

/// HTML renderer for ReportModel that produces UTF-8 HTML content
public class ReportHTMLRenderer {
    
    public init() {}
    
    /// Render ReportModel to HTML as UTF-8 Data
    public func render(_ model: ReportModel) -> Data {
        let html = generateHTML(model)
        return html.data(using: .utf8) ?? Data()
    }
    
    private func generateHTML(_ model: ReportModel) -> String {
        var html = """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>RT60 Bericht</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1, h2 { color: #333; }
                table { border-collapse: collapse; width: 100%; margin: 10px 0; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f5f5f5; }
                .section { margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>RT60 Bericht</h1>
        """
        
        // Metadaten section
        html += """
            <div class="section">
                <h2>Metadaten</h2>
                <table>
        """
        for (key, value) in model.metadata {
            html += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>"
        }
        html += """
                </table>
            </div>
        """
        
        // RT60 je Frequenz section
        html += """
            <div class="section">
                <h2>RT60 je Frequenz</h2>
                <table>
                    <tr><th>Frequenz (Hz)</th><th>T20 (s)</th></tr>
        """
        for band in model.rt60_bands {
            let freq = band["freq_hz"].flatMap { $0.map { Int($0.rounded()) } } ?? 0
            let t20 = band["t20_s"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            html += "<tr><td>\(freq)</td><td>\(t20)</td></tr>"
        }
        html += """
                </table>
            </div>
        """
        
        // DIN 18041 section
        html += """
            <div class="section">
                <h2>DIN 18041</h2>
                <table>
                    <tr><th>Frequenz (Hz)</th><th>T Soll (s)</th><th>Toleranz (s)</th></tr>
        """
        for target in model.din_targets {
            let freq = Int((target["freq_hz"] ?? 0).rounded())
            let tsoll = String(format: "%.2f", target["t_soll"] ?? 0)
            let tol = String(format: "%.2f", target["tol"] ?? 0.2)
            html += "<tr><td>\(freq)</td><td>\(tsoll)</td><td>\(tol)</td></tr>"
        }
        html += """
                </table>
            </div>
        """
        
        // Gültigkeit section
        html += """
            <div class="section">
                <h2>Gültigkeit</h2>
                <table>
        """
        for (key, value) in model.validity {
            html += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>"
        }
        html += """
                </table>
            </div>
        """
        
        // Empfehlungen section
        html += """
            <div class="section">
                <h2>Empfehlungen</h2>
                <ul>
        """
        for recommendation in model.recommendations {
            html += "<li>\(escapeHTML(recommendation))</li>"
        }
        html += """
                </ul>
            </div>
        """
        
        // Audit section
        html += """
            <div class="section">
                <h2>Audit</h2>
                <table>
        """
        for (key, value) in model.audit {
            html += "<tr><td>\(escapeHTML(key))</td><td>\(escapeHTML(value))</td></tr>"
        }
        html += """
                </table>
            </div>
        """
        
        html += """
        </body>
        </html>
        """
        
        return html
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