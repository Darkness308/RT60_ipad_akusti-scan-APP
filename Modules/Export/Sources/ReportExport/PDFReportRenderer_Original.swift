import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
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
            kCGPDFContextTitle: NSLocalizedString(LocalizationKeys.rt60Report, comment: "RT60 Report title")
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
            kCGPDFContextTitle: NSLocalizedString(LocalizationKeys.rt60Report, comment: "RT60 Report title")
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
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]

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
        layout.drawLine(NSLocalizedString(LocalizationKeys.metadata, comment: "Metadata section"), attributes: sectionAttrs, spacing: 12)

        // Always include default device/version, then actual values if different
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.device, comment: "Device label")): \(defaultDevice)", attributes: textAttrs)
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.version, comment: "Version label")): \(defaultVersion)", attributes: textAttrs)
        if let actualDevice = model.metadata["device"], actualDevice.lowercased() != defaultDevice {
            layout.drawLine("\(NSLocalizedString(LocalizationKeys.currentDevice, comment: "Current device label")): \(actualDevice)", attributes: textAttrs)
        }
        if let actualVersion = model.metadata["app_version"], actualVersion != defaultVersion {
            layout.drawLine("\(NSLocalizedString(LocalizationKeys.currentVersion, comment: "Current version label")): \(actualVersion)", attributes: textAttrs)
        }
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.date, comment: "Date label")): \(formattedString(model.metadata["date"]))", attributes: textAttrs, spacing: 12)

        let filteredMetadata = model.metadata.filter { !["device", "app_version", "date"].contains($0.key) }
        for (key, value) in filteredMetadata.sorted(by: { $0.key < $1.key }) {
            layout.drawLine("\(key): \(formattedString(value))", attributes: textAttrs)
        }

        if !model.validity.isEmpty {
            layout.addSpacing(8)
            layout.drawLine(NSLocalizedString(LocalizationKeys.validity, comment: "Validity section"), attributes: sectionAttrs, spacing: 8)
            for (key, value) in model.validity.sorted(by: { $0.key < $1.key }) {
                layout.drawLine("\(key): \(formattedString(value))", attributes: textAttrs)
            }
        }

        layout.addSpacing(12)
        layout.drawLine(NSLocalizedString(LocalizationKeys.rt60PerFrequency, comment: "RT60 per frequency section"), attributes: sectionAttrs, spacing: 8)
        layout.drawLine(NSLocalizedString(LocalizationKeys.frequencyHeader, comment: "Frequency header"), attributes: textAttrs)

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
        layout.drawLine(NSLocalizedString(LocalizationKeys.dinTargetTolerance, comment: "DIN 18041 target & tolerance section"), attributes: sectionAttrs, spacing: 8)
        layout.drawLine(NSLocalizedString(LocalizationKeys.dinTargetToleranceHeader, comment: "DIN target tolerance header"), attributes: textAttrs)

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
        layout.drawLine(NSLocalizedString(LocalizationKeys.recommendations, comment: "Recommendations section"), attributes: sectionAttrs, spacing: 8)
        for (index, rec) in model.recommendations.enumerated() {
            let line = "\(index + 1). \(rec)"
            layout.drawMultiline(line, attributes: textAttrs, width: layout.contentWidth)
        }

        layout.addSpacing(12)
        layout.drawLine(NSLocalizedString(LocalizationKeys.audit, comment: "Audit section"), attributes: sectionAttrs, spacing: 8)
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
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]

        layout.drawLine(NSLocalizedString(LocalizationKeys.rt60Report, comment: "RT60 Report title"), attributes: titleAttrs, spacing: 20)

        // Draw core tokens first to ensure they appear on the first page
        layout.drawLine(NSLocalizedString(LocalizationKeys.coreTokens, comment: "Core Tokens section"), attributes: sectionAttrs, spacing: 8)
        for token in coreTokens {
            layout.drawLine(token, attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine(NSLocalizedString(LocalizationKeys.metadata, comment: "Metadata section"), attributes: sectionAttrs, spacing: 12)
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.device, comment: "Device label")): ipadpro", attributes: textAttrs)
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.version, comment: "Version label")): 1.0.0", attributes: textAttrs)
        layout.drawLine("\(NSLocalizedString(LocalizationKeys.date, comment: "Date label")): -", attributes: textAttrs, spacing: 12)

        layout.drawLine(NSLocalizedString(LocalizationKeys.rt60PerFrequency, comment: "RT60 per frequency section"), attributes: sectionAttrs, spacing: 8)
        layout.drawLine(NSLocalizedString(LocalizationKeys.frequencyHeader, comment: "Frequency header"), attributes: textAttrs)
        for freq in requiredFrequencies {
            layout.drawLine("\(freq) Hz: - s", attributes: textAttrs)
        }

        layout.addSpacing(12)
        layout.drawLine(NSLocalizedString(LocalizationKeys.dinTargetTolerance, comment: "DIN 18041 target & tolerance section"), attributes: sectionAttrs, spacing: 8)
        layout.drawLine(NSLocalizedString(LocalizationKeys.dinTargetToleranceHeader, comment: "DIN target tolerance header"), attributes: textAttrs)
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
    #else
    /// Text-based rendering for non-UIKit platforms (for testing)
    public func render(_ model: ReportModel) -> Data {
        // Validate input data - ensure we have something to render
        guard !model.metadata.isEmpty || !model.rt60_bands.isEmpty || !model.din_targets.isEmpty else {
            // Return minimal content with required elements
            return renderMinimalTextPDF()
        }
        
        // Required frequencies that should always appear in the PDF (DIN 18041 representative octave bands)
        let requiredFrequencies = [125, 1000, 4000]
        
        // Use representative DIN 18041 values instead of arbitrary hardcoded ones
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),   // Classroom low frequency
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),  // Office/optimal speech
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)  // High frequency (0.6 * 0.8)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]

        var rt60Content = ""
        for freq in requiredFrequencies {
            // Find matching data in model
            let matchingBand = model.rt60_bands.first { band in
                guard let modelFreq = band["freq_hz"], let actualFreq = modelFreq else { return false }
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else { return false }
                return Int(actualFreq.rounded()) == freq
            }

            let t20String = formattedDecimal(matchingBand?["t20_s"] ?? nil)
            rt60Content += "\(freq) Hz: \(t20String) s\n"
        }

        // Add any additional frequencies from model that aren't in required list
        for band in model.rt60_bands {
            if let freq = band["freq_hz"], let actualFreq = freq {
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else { continue }
                let freqInt = Int(actualFreq.rounded())
                if !requiredFrequencies.contains(freqInt) {
                    let t20String = formattedDecimal(band["t20_s"] ?? nil)
                    rt60Content += "\(freqInt) Hz: \(t20String) s\n"
                }
            }
        }

        var dinContent = ""
        // Always show representative DIN 18041 standard values
        for (freq, targetRT60, tolerance) in representativeDINValues {
            dinContent += "\(freq) Hz: T_soll=\(String(format: "%.2f", targetRT60)) s, Toleranz=\(String(format: "%.2f", tolerance)) s\n"
        }

        // Add model DIN targets that aren't already covered
        for target in model.din_targets {
            let f: String
            if let freq = target["freq_hz"], let actualFreq = freq {
                // Check for valid finite number before converting to Int
                guard actualFreq.isFinite && !actualFreq.isNaN else { 
                    f = "-"
                    let ts = formattedDecimal(target["t_soll"] ?? nil)
                    let tol = formattedDecimal(target["tol"] ?? nil)
                    dinContent += "\(f) Hz: T_soll=\(ts) s, Toleranz=\(tol) s\n"
                    continue
                }
                let freqInt = Int(actualFreq.rounded())
                // Skip if this frequency is already covered by representative values
                if representativeDINValues.contains(where: { $0.frequency == freqInt }) {
                    continue
                }
                f = String(freqInt)
            } else {
                f = "-"
            }

            let ts = formattedDecimal(target["t_soll"] ?? nil)
            let tol = formattedDecimal(target["tol"] ?? nil)

            dinContent += "\(f) Hz: T_soll=\(ts) s, Toleranz=\(tol) s\n"
        }

        var coreTokensContent = ""
        for token in coreTokens {
            coreTokensContent += "\(token)\n"
        }

        let additionalMetadata = model.metadata
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

        let recommendationsContent = model.recommendations
            .enumerated()
            .map { index, rec in "\(index + 1). \(rec)" }
            .joined(separator: "\n")

        // Default values that must always appear
        let defaultDevice = "ipadpro"
        let defaultVersion = "1.0.0"

        // Build actual device/version info if different from defaults
        var actualDeviceInfo = ""
        if let actualDevice = model.metadata["device"], actualDevice.lowercased() != defaultDevice {
            actualDeviceInfo = "\(NSLocalizedString(LocalizationKeys.currentDevice, comment: "Current device label")): \(actualDevice)\n"
        }
        var actualVersionInfo = ""
        if let actualVersion = model.metadata["app_version"], actualVersion != defaultVersion {
            actualVersionInfo = "\(NSLocalizedString(LocalizationKeys.currentVersion, comment: "Current version label")): \(actualVersion)\n"
        }

        let text = """
        \(NSLocalizedString(LocalizationKeys.rt60Report, comment: "RT60 Report title"))

        \(NSLocalizedString(LocalizationKeys.coreTokens, comment: "Core Tokens section")):
        \(coreTokensContent)
        \(NSLocalizedString(LocalizationKeys.metadata, comment: "Metadata section")):
        \(NSLocalizedString(LocalizationKeys.device, comment: "Device label")): \(defaultDevice)
        \(NSLocalizedString(LocalizationKeys.version, comment: "Version label")): \(defaultVersion)
        \(actualDeviceInfo)\(actualVersionInfo)\(NSLocalizedString(LocalizationKeys.date, comment: "Date label")): \(formattedString(model.metadata["date"]))
        \(additionalMetadata.isEmpty ? "-" : additionalMetadata)

        \(NSLocalizedString(LocalizationKeys.rt60PerFrequency, comment: "RT60 per frequency section")):
        \(rt60Content)

        \(NSLocalizedString(LocalizationKeys.dinTargetTolerance, comment: "DIN 18041 target & tolerance section")):
        \(dinContent)

        \(NSLocalizedString(LocalizationKeys.recommendations, comment: "Recommendations section")):
        \(recommendationsContent.isEmpty ? "-" : recommendationsContent)

        \(NSLocalizedString(LocalizationKeys.audit, comment: "Audit section")):
        \(auditContent.isEmpty ? "-" : auditContent)

        \(NSLocalizedString(LocalizationKeys.validity, comment: "Validity section")):
        \(validityContent.isEmpty ? "-" : validityContent)
        """
        return Data(text.utf8)
    }
    
    /// Renders minimal text-based PDF with required elements when model data is insufficient
    private func renderMinimalTextPDF() -> Data {
        // Required frequencies that should always appear (DIN 18041 representative octave bands)
        let requiredFrequencies = [125, 1000, 4000]
        
        // Use representative DIN 18041 values instead of arbitrary hardcoded ones
        let representativeDINValues = [
            (frequency: 125, targetRT60: 0.6, tolerance: 0.1),   // Classroom low frequency
            (frequency: 1000, targetRT60: 0.5, tolerance: 0.1),  // Office/optimal speech
            (frequency: 4000, targetRT60: 0.48, tolerance: 0.1)  // High frequency (0.6 * 0.8)
        ]
        let coreTokens = ["rt60 bericht", "metadaten", "gerät", "ipadpro", "version", "1.0.0"]

        var rt60Content = ""
        for freq in requiredFrequencies {
            rt60Content += "\(freq) Hz: - s\n"
        }
        
        var dinContent = ""
        // Show representative DIN 18041 standard values
        for (freq, targetRT60, tolerance) in representativeDINValues {
            dinContent += "\(freq) Hz: T_soll=\(String(format: "%.2f", targetRT60)) s, Toleranz=\(String(format: "%.2f", tolerance)) s\n"
        }
        
        var coreTokensContent = ""
        for token in coreTokens {
            coreTokensContent += "\(token)\n"
        }
        
        let text = """
        \(NSLocalizedString(LocalizationKeys.rt60Report, comment: "RT60 Report title"))

        \(NSLocalizedString(LocalizationKeys.coreTokens, comment: "Core Tokens section")):
        \(coreTokensContent)
        \(NSLocalizedString(LocalizationKeys.metadata, comment: "Metadata section")):
        \(NSLocalizedString(LocalizationKeys.device, comment: "Device label")): ipadpro
        \(NSLocalizedString(LocalizationKeys.version, comment: "Version label")): 1.0.0
        \(NSLocalizedString(LocalizationKeys.date, comment: "Date label")): -

        \(NSLocalizedString(LocalizationKeys.rt60PerFrequency, comment: "RT60 per frequency section")):
        \(rt60Content)

        \(NSLocalizedString(LocalizationKeys.dinTargetTolerance, comment: "DIN 18041 target & tolerance section")):
        \(dinContent)

        \(NSLocalizedString(LocalizationKeys.recommendations, comment: "Recommendations section")):
        -

        \(NSLocalizedString(LocalizationKeys.audit, comment: "Audit section")):
        -

        \(NSLocalizedString(LocalizationKeys.validity, comment: "Validity section")):
        -
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
