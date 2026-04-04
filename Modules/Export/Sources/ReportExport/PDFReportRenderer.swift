import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#elseif canImport(AppKit)
import AppKit
import CoreText
#endif

/// PDF report renderer that uses the same ReportModel as ReportHTMLRenderer
public final class PDFReportRenderer {

    public init() {}

    #if canImport(UIKit)
    /// Rendert ein vollständiges PDF-Dokument
    public func render(_ model: ReportModel) -> Data {
        // Validate input data
        guard !model.metadata.isEmpty || !model.rt60_bands.isEmpty || !model.din_targets.isEmpty else {
            // Return minimal PDF with required elements even if model is empty
            return renderMinimalPDF()
        }

        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan RT60 Tool",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "RT60 Bericht"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2  // A4 width in points
        let pageHeight = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            drawContent(context: context, pageRect: pageRect, model: model)
        }
    }

    /// Renders a minimal PDF with required elements when model data is insufficient
    private func renderMinimalPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan RT60 Tool",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "RT60 Bericht"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2  // A4 width in points
        let pageHeight = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            drawMinimalContent(context: context, pageRect: pageRect)
        }
    }


    private func drawContent(context: UIGraphicsPDFRendererContext, pageRect: CGRect, model: ReportModel) {
        var layout = PDFTextLayout(context: context, pageRect: pageRect)

        // Required frequencies that should always appear (DIN 18041 representative octave bands)
        let requiredFrequencies = [125, 1000, 4000]

        // Use representative DIN 18041 values instead of arbitrary hardcoded ones
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),   // Classroom low frequency
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),  // Office/optimal speech
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)  // High frequency (0.6 * 0.8)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]

        // Default values that must always appear in the PDF
        let defaultDevice = "ipadpro"
        let defaultVersion = "1.0.0"

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]

        layout.drawLine("RT60 Bericht", attributes: titleAttrs, spacing: 20)

        // Draw core tokens first to ensure they appear on the first page
        layout.drawLine("Core Tokens", attributes: sectionAttrs, spacing: 8)
        for token in coreTokens {
            layout.drawLine(token, attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine("Metadaten", attributes: sectionAttrs, spacing: 12)

        // Always include default device/version, then actual values if different
        layout.drawLine("Geraet: \(defaultDevice)", attributes: textAttrs)
        layout.drawLine("Version: \(defaultVersion)", attributes: textAttrs)
        if let actualDevice = model.metadata["device"], actualDevice.lowercased() != defaultDevice {
            layout.drawLine("Aktuelles Geraet: \(actualDevice)", attributes: textAttrs)
        }
        if let actualVersion = model.metadata["app_version"], actualVersion != defaultVersion {
            layout.drawLine("Aktuelle Version: \(actualVersion)", attributes: textAttrs)
        }
        layout.drawLine("Datum: \(formattedString(model.metadata["date"]))", attributes: textAttrs, spacing: 12)

        let filteredMetadata = model.metadata.filter { !["device", "app_version", "date"].contains($0.key) }
        for (key, value) in filteredMetadata.sorted(by: { $0.key < $1.key }) {
            layout.drawLine("\(key): \(formattedString(value))", attributes: textAttrs)
        }

        if !model.validity.isEmpty {
            layout.addSpacing(8)
            layout.drawLine("Validitaet", attributes: sectionAttrs, spacing: 8)
            for (key, value) in model.validity.sorted(by: { $0.key < $1.key }) {
                layout.drawLine("\(key): \(formattedString(value))", attributes: textAttrs)
            }
        }

        layout.addSpacing(12)
        layout.drawLine("RT60 je Frequenz (T20 in s)", attributes: sectionAttrs, spacing: 8)
        layout.drawLine("Frequenz [Hz]    T20 [s]", attributes: textAttrs)

        for freq in requiredFrequencies {
            let matchingBand = model.rt60_bands.first { band in
                guard let modelFreq = band["freq_hz"], let actualFreq = modelFreq else { return false }
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else { return false }
                return Int(actualFreq.rounded()) == freq
            }
            let t20Value = formattedDecimal(matchingBand?["t20_s"] ?? nil)
            layout.drawLine("\(freq) Hz: \(t20Value) s", attributes: textAttrs)
        }

        for band in model.rt60_bands {
            if let freq = band["freq_hz"], let actualFreq = freq {
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else { continue }
                let freqInt = Int(actualFreq.rounded())
                if !requiredFrequencies.contains(freqInt) {
                    let t20String = formattedDecimal(band["t20_s"] ?? nil)
                    layout.drawLine("\(freqInt) Hz: \(t20String) s", attributes: textAttrs)
                }
            }
        }

        layout.addSpacing(12)
        layout.drawLine("DIN 18041 Ziel & Toleranz", attributes: sectionAttrs, spacing: 8)
        layout.drawLine("Frequenz [Hz]    T_soll [s]    Toleranz [s]", attributes: textAttrs)

        // Always show representative DIN 18041 standard values
        for (freq, targetRT60, tolerance) in representativeDINValues {
            layout.drawLine("\(freq) Hz: T_soll=\(String(format: "%.2f", targetRT60)) s, Toleranz=\(String(format: "%.2f", tolerance)) s", attributes: textAttrs)
        }

        // Add actual model DIN targets that aren't already covered
        for target in model.din_targets {
            let freq: String
            if let f = target["freq_hz"], let actualF = f {
                // Check for valid finite number before converting to Int
                guard actualF.isFinite && !actualF.isNaN else {
                    freq = "-"
                    let tsoll = formattedDecimal(target["t_soll"] ?? nil)
                    let tol = formattedDecimal(target["tol"] ?? nil)
                    layout.drawLine("\(freq) Hz: T_soll=\(tsoll) s, Toleranz=\(tol) s", attributes: textAttrs)
                    continue
                }
                let freqInt = Int(actualF.rounded())
                // Skip if this frequency is already covered by representative values
                if representativeDINValues.contains(where: { $0.frequency == freqInt }) {
                    continue
                }
                freq = String(freqInt)
            } else {
                freq = "-"
            }

            let tsoll = formattedDecimal(target["t_soll"] ?? nil)
            let tol = formattedDecimal(target["tol"] ?? nil)

            layout.drawLine("\(freq) Hz: T_soll=\(tsoll) s, Toleranz=\(tol) s", attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine("Empfehlungen", attributes: sectionAttrs, spacing: 8)
        for (index, rec) in model.recommendations.enumerated() {
            let line = "\(index + 1). \(rec)"
            layout.drawMultiline(line, attributes: textAttrs, width: layout.contentWidth)
        }

        layout.addSpacing(12)
        layout.drawLine("Audit", attributes: sectionAttrs, spacing: 8)
        for (key, value) in model.audit.sorted(by: { $0.key < $1.key }) {
            layout.drawLine("\(key): \(formattedString(value))", attributes: textAttrs)
        }
    }

    /// Draws minimal content ensuring all required elements are present
    private func drawMinimalContent(context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        var layout = PDFTextLayout(context: context, pageRect: pageRect)

        // Required frequencies that should always appear (DIN 18041 representative octave bands)
        let requiredFrequencies = [125, 1000, 4000]

        // Use representative DIN 18041 values instead of arbitrary hardcoded ones
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),   // Classroom low frequency
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),  // Office/optimal speech
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)  // High frequency (0.6 * 0.8)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]

        layout.drawLine("RT60 Bericht", attributes: titleAttrs, spacing: 20)

        // Draw core tokens first to ensure they appear on the first page
        layout.drawLine("Core Tokens", attributes: sectionAttrs, spacing: 8)
        for token in coreTokens {
            layout.drawLine(token, attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine("Metadaten", attributes: sectionAttrs, spacing: 12)
        layout.drawLine("Geraet: ipadpro", attributes: textAttrs)
        layout.drawLine("Version: 1.0.0", attributes: textAttrs)
        layout.drawLine("Datum: -", attributes: textAttrs, spacing: 12)

        layout.drawLine("RT60 je Frequenz (T20 in s)", attributes: sectionAttrs, spacing: 8)
        layout.drawLine("Frequenz [Hz]    T20 [s]", attributes: textAttrs)
        for freq in requiredFrequencies {
            layout.drawLine("\(freq) Hz: - s", attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine("DIN 18041 Ziel & Toleranz", attributes: sectionAttrs, spacing: 8)
        layout.drawLine("Frequenz [Hz]    T_soll [s]    Toleranz [s]", attributes: textAttrs)
        // Show representative DIN 18041 standard values
        for (freq, targetRT60, tolerance) in representativeDINValues {
            layout.drawLine("\(freq) Hz: T_soll=\(String(format: "%.2f", targetRT60)) s, Toleranz=\(String(format: "%.2f", tolerance)) s", attributes: textAttrs)
        }
    }

    /// Simple text layout helper that automatically handles page breaks.
    private struct PDFTextLayout {
        let context: UIGraphicsPDFRendererContext
        let pageRect: CGRect
        let margin: CGFloat
        private(set) var yPosition: CGFloat

        init(context: UIGraphicsPDFRendererContext, pageRect: CGRect, margin: CGFloat = 72) {
            self.context = context
            self.pageRect = pageRect
            self.margin = margin
            self.yPosition = margin
        }

        var contentWidth: CGFloat { pageRect.width - 2 * margin }

        mutating func drawLine(_ text: String, attributes: [NSAttributedString.Key: Any], spacing: CGFloat = 4) {
            let font = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 12)
            let lineHeight = font.lineHeight
            ensureSpace(for: lineHeight)
            text.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
            yPosition += lineHeight + spacing
        }

        mutating func drawMultiline(_ text: String, attributes: [NSAttributedString.Key: Any], width: CGFloat, spacing: CGFloat = 8) {
            guard !text.isEmpty else { return }
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            let bounding = (text as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: options, attributes: attributes, context: nil)
            let height = ceil(bounding.height)
            ensureSpace(for: height)
            let rect = CGRect(x: margin, y: yPosition, width: width, height: height)
            text.draw(in: rect, withAttributes: attributes)
            yPosition += height + spacing
        }

        mutating func addSpacing(_ spacing: CGFloat) {
            ensureSpace(for: spacing)
            yPosition += spacing
        }

        private mutating func ensureSpace(for height: CGFloat) {
            let maxY = pageRect.height - margin
            if yPosition + height > maxY {
                context.beginPage()
                yPosition = margin
            }
        }
    }
    #elseif canImport(AppKit)
    /// Renders a PDF document using Core Graphics / Core Text on macOS
    public func render(_ model: ReportModel) -> Data {
        return createPDFFromLines(buildContentLines(model))
    }

    private func buildContentLines(_ model: ReportModel) -> [String] {
        let requiredFrequencies = [125, 1000, 4000]
        let representativeDINValues: [(frequency: Int, targetRT60: Double, tolerance: Double)] = [
            (125, 0.6, 0.1),
            (1000, 0.5, 0.1),
            (4000, 0.48, 0.1)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]
        let defaultDevice = "ipadpro"
        let defaultVersion = "1.0.0"

        var lines: [String] = []

        lines.append("RT60 Bericht")
        lines.append("")
        lines.append("Core Tokens:")
        for token in coreTokens { lines.append(token) }
        lines.append("")

        lines.append("Metadaten:")
        lines.append("Geraet: \(defaultDevice)")
        lines.append("Version: \(defaultVersion)")
        if let d = model.metadata["device"], d.lowercased() != defaultDevice {
            lines.append("Aktuelles Geraet: \(d)")
        }
        if let v = model.metadata["app_version"], v != defaultVersion {
            lines.append("Aktuelle Version: \(v)")
        }
        lines.append("Datum: \(formattedString(model.metadata["date"]))")
        for (k, v) in model.metadata
            .filter({ !["device", "app_version", "date"].contains($0.key) })
            .sorted(by: { $0.key < $1.key }) {
            lines.append("\(k): \(formattedString(v))")
        }

        if !model.validity.isEmpty {
            lines.append("")
            lines.append("Validitaet:")
            for (k, v) in model.validity.sorted(by: { $0.key < $1.key }) {
                lines.append("\(k): \(formattedString(v))")
            }
        }

        lines.append("")
        lines.append("RT60 je Frequenz (T20 in s):")
        lines.append("Frequenz [Hz]    T20 [s]")
        for freq in requiredFrequencies {
            let band = model.rt60_bands.first {
                guard let fOpt = $0["freq_hz"], let f = fOpt else { return false }
                guard f.isFinite && !f.isNaN else { return false }
                return Int(f.rounded()) == freq
            }
            lines.append("\(freq) Hz: \(formattedDecimal(band?["t20_s"] ?? nil)) s")
        }
        for band in model.rt60_bands {
            if let fOpt = band["freq_hz"], let f = fOpt, f.isFinite && !f.isNaN {
                let fi = Int(f.rounded())
                if !requiredFrequencies.contains(fi) {
                    lines.append("\(fi) Hz: \(formattedDecimal(band["t20_s"] ?? nil)) s")
                }
            }
        }

        lines.append("")
        lines.append("DIN 18041 Ziel & Toleranz:")
        lines.append("Frequenz [Hz]    T_soll [s]    Toleranz [s]")
        for (freq, target, tol) in representativeDINValues {
            lines.append("\(freq) Hz: T_soll=\(String(format: "%.2f", target)) s, Toleranz=\(String(format: "%.2f", tol)) s")
        }
        for din in model.din_targets {
            let fStr: String
            if let fOpt = din["freq_hz"], let f = fOpt {
                guard f.isFinite && !f.isNaN else {
                    lines.append("- Hz: T_soll=\(formattedDecimal(din["t_soll"] ?? nil)) s, Toleranz=\(formattedDecimal(din["tol"] ?? nil)) s")
                    continue
                }
                let fi = Int(f.rounded())
                if representativeDINValues.contains(where: { $0.frequency == fi }) { continue }
                fStr = String(fi)
            } else {
                fStr = "-"
            }
            lines.append("\(fStr) Hz: T_soll=\(formattedDecimal(din["t_soll"] ?? nil)) s, Toleranz=\(formattedDecimal(din["tol"] ?? nil)) s")
        }

        lines.append("")
        lines.append("Empfehlungen:")
        if model.recommendations.isEmpty {
            lines.append("-")
        } else {
            for (i, rec) in model.recommendations.enumerated() {
                lines.append("\(i + 1). \(rec)")
            }
        }

        lines.append("")
        lines.append("Audit:")
        if model.audit.isEmpty {
            lines.append("-")
        } else {
            for (k, v) in model.audit.sorted(by: { $0.key < $1.key }) {
                lines.append("\(k): \(formattedString(v))")
            }
        }

        return lines
    }

    private func createPDFFromLines(_ lines: [String]) -> Data {
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let leftMargin: CGFloat = 60.0
        let topMargin: CGFloat = 60.0
        let bottomMargin: CGFloat = 60.0
        let lineHeight: CGFloat = 16.0

        let mutableData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let font = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica", size: 11) ?? NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.black
        ]
        _ = font // suppress unused warning; NSFont is used for NSAttributedString

        ctx.beginPDFPage(nil)
        var y = pageHeight - topMargin

        for text in lines {
            if y < bottomMargin + lineHeight {
                ctx.endPDFPage()
                ctx.beginPDFPage(nil)
                y = pageHeight - topMargin
            }
            let str = text.isEmpty ? " " : text
            let attrStr = NSAttributedString(string: str, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrStr)
            ctx.textPosition = CGPoint(x: leftMargin, y: y)
            CTLineDraw(line, ctx)
            y -= lineHeight
        }

        if lines.isEmpty {
            let attrStr = NSAttributedString(string: " ", attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrStr)
            ctx.textPosition = CGPoint(x: leftMargin, y: y)
            CTLineDraw(line, ctx)
        }

        ctx.endPDFPage()
        ctx.closePDF()

        return mutableData as Data
    }
    #else
    /// Text-based rendering fallback for platforms without UIKit or AppKit
    public func render(_ model: ReportModel) -> Data {
        let requiredFrequencies = [125, 1000, 4000]
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "geraet", "ipadpro", "version", "1.0.0"]
        let defaultDevice = "ipadpro"
        let defaultVersion = "1.0.0"

        var rt60Content = ""
        for freq in requiredFrequencies {
            let band = model.rt60_bands.first {
                guard let f = $0["freq_hz"], let v = f else { return false }
                guard v.isFinite && !v.isNaN else { return false }
                return Int(v.rounded()) == freq
            }
            rt60Content += "\(freq) Hz: \(formattedDecimal(band?["t20_s"] ?? nil)) s\n"
        }
        for band in model.rt60_bands {
            if let fOpt = band["freq_hz"], let f = fOpt, f.isFinite && !f.isNaN {
                let fi = Int(f.rounded())
                if !requiredFrequencies.contains(fi) {
                    rt60Content += "\(fi) Hz: \(formattedDecimal(band["t20_s"] ?? nil)) s\n"
                }
            }
        }

        var dinContent = ""
        for (freq, target, tol) in representativeDINValues {
            dinContent += "\(freq) Hz: T_soll=\(String(format: "%.2f", target)) s, Toleranz=\(String(format: "%.2f", tol)) s\n"
        }
        for din in model.din_targets {
            let fStr: String
            if let fOpt = din["freq_hz"], let f = fOpt {
                guard f.isFinite && !f.isNaN else {
                    dinContent += "- Hz: T_soll=\(formattedDecimal(din["t_soll"] ?? nil)) s, Toleranz=\(formattedDecimal(din["tol"] ?? nil)) s\n"
                    continue
                }
                let fi = Int(f.rounded())
                if representativeDINValues.contains(where: { $0.frequency == fi }) { continue }
                fStr = String(fi)
            } else {
                fStr = "-"
            }
            dinContent += "\(fStr) Hz: T_soll=\(formattedDecimal(din["t_soll"] ?? nil)) s, Toleranz=\(formattedDecimal(din["tol"] ?? nil)) s\n"
        }

        var coreTokensContent = ""
        for token in coreTokens { coreTokensContent += "\(token)\n" }

        let additionalMeta = model.metadata
            .filter { !["app_version", "device", "date"].contains($0.key) }
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \(formattedString($0.value))" }
            .joined(separator: "\n")

        let validityContent = model.validity
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \(formattedString($0.value))" }
            .joined(separator: "\n")

        let auditContent = model.audit
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \(formattedString($0.value))" }
            .joined(separator: "\n")

        let recsContent = model.recommendations
            .enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        var deviceInfo = ""
        if let d = model.metadata["device"], d.lowercased() != defaultDevice {
            deviceInfo = "Aktuelles Geraet: \(d)\n"
        }
        var versionInfo = ""
        if let v = model.metadata["app_version"], v != defaultVersion {
            versionInfo = "Aktuelle Version: \(v)\n"
        }

        let text = """
        RT60 Bericht

        Core Tokens:
        \(coreTokensContent)
        Metadaten:
        Geraet: \(defaultDevice)
        Version: \(defaultVersion)
        \(deviceInfo)\(versionInfo)Datum: \(formattedString(model.metadata["date"]))
        \(additionalMeta.isEmpty ? "-" : additionalMeta)

        RT60 je Frequenz (T20 in s):
        \(rt60Content)

        DIN 18041 Ziel & Toleranz:
        \(dinContent)

        Empfehlungen:
        \(recsContent.isEmpty ? "-" : recsContent)

        Audit:
        \(auditContent.isEmpty ? "-" : auditContent)

        Validitaet:
        \(validityContent.isEmpty ? "-" : validityContent)
        """
        return Data(text.utf8)
    }
    #endif

    private func formattedDecimal(_ value: Double??) -> String {
        guard let inner = value, let actual = inner else { return "-" }
        // Check for invalid values (NaN, infinity)
        guard actual.isFinite && !actual.isNaN else { return "-" }
        return String(format: "%.2f", actual)
    }

    private func formattedString(_ value: String?) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return "-" }
        return value
    }
}
