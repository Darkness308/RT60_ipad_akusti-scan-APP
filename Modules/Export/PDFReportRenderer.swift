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
}