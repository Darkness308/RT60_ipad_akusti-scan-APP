import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#elseif canImport(AppKit)
import AppKit
#endif

/// PDF report renderer that uses the same ReportModel as ReportHTMLRenderer
public final class PDFReportRenderer {

    public init() {}

    #if os(iOS)
    /// Rendert ein vollständiges PDF-Dokument auf iOS
    public func render(_ model: ReportModel) -> Data {
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
            drawContent(pageRect: pageRect, model: model)
        }
    }
    
    private func drawContent(pageRect: CGRect, model: ReportModel) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        // Title
        let title = "RT60 Bericht"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        // Metadata
        let metaTitle = "Metadaten"
        let sectionAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        metaTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttrs)
        yPosition += 25
        
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        // Draw metadata
        for (key, value) in model.metadata.sorted(by: { $0.key < $1.key }) {
            let line = "\(key): \(value)"
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
            yPosition += 18
        }
        
        yPosition += 20
        
        // RT60 Bands
        let bandsTitle = "RT60 je Frequenz (T20 in s)"
        bandsTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttrs)
        yPosition += 25
        
        "Frequenz [Hz]    T20 [s]".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
        yPosition += 20
        
        for band in model.rt60_bands {
            let freq = band["freq_hz"].flatMap { $0.map { String(Int($0.rounded())) } } ?? "-"
            let t20 = band["t20_s"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            let line = String(format: "%-15@ %@", freq, t20)
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
            yPosition += 18
        }
        
        yPosition += 20
        
        // DIN Targets
        let dinTitle = "DIN 18041 Ziel & Toleranz"
        dinTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttrs)
        yPosition += 25
        
        "Frequenz [Hz]    T_soll [s]    Toleranz [s]".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
        yPosition += 20
        
        for target in model.din_targets {
            let freq = target["freq_hz"].flatMap { $0.map { String(Int($0.rounded())) } } ?? "-"
            let tsoll = target["t_soll"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            let tol = target["tol"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            let line = String(format: "%-15@ %-13@ %@", freq, tsoll, tol)
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
            yPosition += 18
        }
        
        yPosition += 20
        
        // Empfehlungen
        let recTitle = "Empfehlungen"
        recTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttrs)
        yPosition += 25
        
        for (index, rec) in model.recommendations.enumerated() {
            let line = "\(index + 1). \(rec)"
            let maxWidth = pageRect.width - 2 * margin
            let textRect = CGRect(x: margin, y: yPosition, width: maxWidth, height: 50)
            line.draw(in: textRect, withAttributes: textAttrs)
            yPosition += 30
        }
        
        yPosition += 20
        
        // Audit
        let auditTitle = "Audit"
        auditTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttrs)
        yPosition += 25
        
        for (key, value) in model.audit.sorted(by: { $0.key < $1.key }) {
            let line = "\(key): \(value)"
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
            yPosition += 18
        }
    }
    
    #elseif os(macOS)
    /// macOS implementation using Core Graphics directly
    public func render(_ model: ReportModel) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan RT60 Tool",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "RT60 Bericht"
        ] as CFDictionary
        
        let pageWidth = 595.2  // A4 width in points
        let pageHeight = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect.mutableCopy, pdfMetaData) else {
            return Data()
        }
        
        context.beginPDFPage(nil)
        drawContentMacOS(context: context, pageRect: pageRect, model: model)
        context.endPDFPage()
        context.closePDF()
        
        return mutableData as Data
    }
    
    private func drawContentMacOS(context: CGContext, pageRect: CGRect, model: ReportModel) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin // macOS coordinates are flipped
        
        // Title
        let title = "RT60 Bericht"
        drawTextMacOS(context: context, text: title, at: CGPoint(x: margin, y: yPosition), fontSize: 24, bold: true)
        yPosition -= 40
        
        // Metadata
        let metaTitle = "Metadaten"
        drawTextMacOS(context: context, text: metaTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 18, bold: true)
        yPosition -= 25
        
        // Draw metadata
        for (key, value) in model.metadata.sorted(by: { $0.key < $1.key }) {
            let line = "\(key): \(value)"
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
            yPosition -= 18
        }
        
        yPosition -= 20
        
        // RT60 Bands
        let bandsTitle = "RT60 je Frequenz (T20 in s)"
        drawTextMacOS(context: context, text: bandsTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 18, bold: true)
        yPosition -= 25
        
        drawTextMacOS(context: context, text: "Frequenz [Hz]    T20 [s]", at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
        yPosition -= 20
        
        for band in model.rt60_bands {
            let freq = band["freq_hz"].flatMap { $0.map { String(Int($0.rounded())) } } ?? "-"
            let t20 = band["t20_s"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            let line = String(format: "%-15@ %@", freq, t20)
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
            yPosition -= 18
        }
    }
    
    private func drawTextMacOS(context: CGContext, text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool) {
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: point.y)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -point.y)
        
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        
        (text as NSString).draw(at: point, withAttributes: attributes)
        context.restoreGState()
    }
    
    #else
    /// Text-based rendering for other platforms
    public func render(_ model: ReportModel) -> Data {
        let text = """
        RT60 Bericht
        
        Metadaten:
        Version: \(model.metadata["app_version"] ?? "-")
        Gerät: \(model.metadata["device"] ?? "-")
        Datum: \(model.metadata["date"] ?? "-")
        \(model.metadata.filter { !["app_version", "device", "date"].contains($0.key) }.map { k, v in "\(k): \(v)" }.joined(separator: "\n"))
        
        RT60 je Frequenz (T20 in s):
        \(model.rt60_bands.map { band in
            let f = band["freq_hz"].flatMap { $0.map { String(Int($0.rounded())) } } ?? "-"
            let t = band["t20_s"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            return "\(f) Hz: \(t) s"
        }.joined(separator: "\n"))
        
        DIN 18041 Ziel & Toleranz:
        \(model.din_targets.map { target in
            let f = target["freq_hz"].flatMap { $0.map { String(Int($0.rounded())) } } ?? "-"
            let ts = target["t_soll"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            let tol = target["tol"].flatMap { $0.map { String(format: "%.2f", $0) } } ?? "-"
            return "\(f) Hz: T_soll=\(ts) s, Toleranz=\(tol) s"
        }.joined(separator: "\n"))
        
        Empfehlungen:
        \(model.recommendations.enumerated().map { i, rec in "\(i + 1). \(rec)" }.joined(separator: "\n"))
        
        Audit:
        \(model.audit.map { k, v in "\(k): \(v)" }.joined(separator: "\n"))
        """
        return Data(text.utf8)
    }
    #endif
}