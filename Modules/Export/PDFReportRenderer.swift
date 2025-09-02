copilot/fix-61f5a74e-22f9-4da7-953e-05aa7d3a29f4
import UIKit
import PDFKit

public struct ReportModel: Codable {
    public let metadata: [String: String]
    public let rt60_bands: [[String: Double?]]  // [{ "freq_hz": 125, "t20_s": 0.7 }]
    public let din_targets: [[String: Double]]  // [{ "freq_hz": 125, "t_soll": 0.6, "tol": 0.2 }]
    public let validity: [String: String]       // {"method":"ISO3382-1", "notes":"..."}
    public let recommendations: [String]
    public let audit: [String: String]          // {"hash":"...", "source":"..."}
}

public final class PDFReportRenderer {
    public init() {}

    public func render(_ model: ReportModel) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        return renderer.pdfData { ctx in
            ctx.beginPage(); drawCover(ctx.cgContext, model)
            ctx.beginPage(); drawMetadata(ctx.cgContext, model)
            ctx.beginPage(); drawRT60(ctx.cgContext, model)
            ctx.beginPage(); drawDIN(ctx.cgContext, model)
            ctx.beginPage(); drawValidity(ctx.cgContext, model)
            ctx.beginPage(); drawRecommendations(ctx.cgContext, model)
            ctx.beginPage(); drawAudit(ctx.cgContext, model)
        }
    }

    private func title(_ s: String, _ g: CGContext, _ y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18)]
        (s as NSString).draw(at: CGPoint(x: 48, y: y), withAttributes: attrs)
        y += 28
    }
    private func text(_ s: String, _ g: CGContext, _ y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
        (s as NSString).draw(at: CGPoint(x: 48, y: y), withAttributes: attrs)
        y += 18
    }

    private func drawCover(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 120
        title("RT60 Bericht", g, &y)
        text("Version: \(model.metadata["app_version"] ?? "-")", g, &y)
        text("Gerät: \(model.metadata["device"] ?? "-")", g, &y)
        text("Datum: \(model.metadata["date"] ?? "-")", g, &y)
    }
    private func drawMetadata(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("Metadaten", g, &y)
        for (k,v) in model.metadata.sorted(by: {$0.key < $1.key}) {
            text("\(k): \(v)", g, &y)
        }
    }
    private func drawRT60(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("RT60 je Frequenz (T20 in s)", g, &y); text("x: Hz, y: s", g, &y)
        for b in model.rt60_bands {
            let f = Int(b["freq_hz"]??.rounded() ?? 0)
            let t = (b["t20_s"] ?? nil)??.description ?? "-"
            text("\(f) Hz : \(t)", g, &y)
        }
    }
    private func drawDIN(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("DIN 18041 Ziel + Toleranz", g, &y)
        for t in model.din_targets {
            let f = Int(t["freq_hz"]?.rounded() ?? 0)
            let ts = t["t_soll"] ?? 0
            let tol = t["tol"] ?? 0.2
            text("\(f) Hz : Tsoll=\(String(format:"%.2f", ts)) s ±\(String(format:"%.2f", tol)) s", g, &y)
        }
    }
    private func drawValidity(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("Gültigkeit / Unsicherheiten", g, &y)
        for (k,v) in model.validity.sorted(by: {$0.key < $1.key}) { text("\(k): \(v)", g, &y) }
    }
    private func drawRecommendations(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("Empfehlungen", g, &y)
        for r in model.recommendations { text("• \(r)", g, &y) }
    }
    private func drawAudit(_ g: CGContext, _ model: ReportModel) {
        var y: CGFloat = 72
        title("Audit", g, &y)
        for (k,v) in model.audit.sorted(by: {$0.key < $1.key}) { text("\(k): \(v)", g, &y) }
    }

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
            let freq = band["freq_hz"] != nil ? String(Int((band["freq_hz"]!)!.rounded())) : "-"
            let t20 = band["t20_s"] != nil && band["t20_s"]! != nil ? String(format: "%.2f", band["t20_s"]!!) : "-"
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
            let freq = target["freq_hz"] != nil ? String(Int((target["freq_hz"]!)!.rounded())) : "-"
            let tsoll = target["t_soll"] != nil && target["t_soll"]! != nil ? String(format: "%.2f", target["t_soll"]!!) : "-"
            let tol = target["tol"] != nil && target["tol"]! != nil ? String(format: "%.2f", target["tol"]!!) : "-"
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
    #else
    /// Text-based rendering for non-UIKit platforms (for testing)
    public func render(_ model: ReportModel) -> Data {
        let text = """
        RT60 Bericht
        
        Metadaten:
        Version: \(model.metadata["app_version"] ?? "-")
        Gerät: \(model.metadata["device"] ?? "-")
        Datum: \(model.metadata["date"] ?? "-")
        \(model.metadata.filter { !["app_version", "device", "date"].contains($0.key) }.map { k, v in "\(k): \(v)" }.joined(separator: "\n"))
        
        RT60 je Frequenz (T20 in s):
        \(model.rt60_bands.map { row in
            let f = row["freq_hz"] != nil ? String(Int((row["freq_hz"]!)!.rounded())) : "-"
            let t = row["t20_s"] != nil && row["t20_s"]! != nil ? String(format: "%.2f", row["t20_s"]!!) : "-"
            return "\(f) Hz: \(t) s"
        }.joined(separator: "\n"))
        
        DIN 18041 Ziel & Toleranz:
        \(model.din_targets.map { row in
            let f = row["freq_hz"] != nil ? String(Int((row["freq_hz"]!)!.rounded())) : "-"
            let ts = row["t_soll"] != nil && row["t_soll"]! != nil ? String(format: "%.2f", row["t_soll"]!!) : "-"
            let tol = row["tol"] != nil && row["tol"]! != nil ? String(format: "%.2f", row["tol"]!!) : "-"
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
main
}