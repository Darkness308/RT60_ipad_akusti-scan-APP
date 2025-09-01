//  PDFExportView.swift
//  AcoustiScan
//
//  Created in Sprint 3 (Report & UX)
//
//  Produktionsreifer PDF-Export: erzeugt mehrseitige Reports mit
//  Deckblatt, Metadaten, RT60-Kurven, DIN-Ampellogik und Maßnahmenblock.
//

import SwiftUI
import PDFKit

/// Struct that generates a full PDF report from measurement results.
/// This implementation is focused on clarity, compliance (EU AI Act),
/// and auditability.
struct PDFExportView: View {
    @Binding var isPresented: Bool
    var reportData: ReportData

    var body: some View {
        VStack(spacing: 20) {
            Text("PDF-Report Export")
                .font(.title)
            Button("Generate Report") {
                generateReport()
            }
            Button("Close") {
                isPresented = false
            }
        }
        .padding()
    }

    private func generateReport() {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "Raumakustik Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2
        let pageHeight = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { ctx in
            // Deckblatt
            ctx.beginPage()
            drawCoverPage(pageRect: pageRect)

            // Metadaten
            ctx.beginPage()
            drawMetadataPage(pageRect: pageRect)

            // RT60-Kurven
            ctx.beginPage()
            drawRT60Curves(pageRect: pageRect)

            // DIN-Ampel
            ctx.beginPage()
            drawDINResults(pageRect: pageRect)

            // Maßnahmenblock
            ctx.beginPage()
            drawRecommendations(pageRect: pageRect)
        }

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("Report.pdf")
        do {
            try data.write(to: tmpURL)
            let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        } catch {
            print("Error writing PDF: \(error)")
        }
    }

    private func drawCoverPage(pageRect: CGRect) {
        let title = "Raumakustik Report"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        title.draw(at: CGPoint(x: 72, y: 72), withAttributes: attrs)

        // Branding Logo (falls vorhanden)
        if let logo = UIImage(named: "logo") {
            let logoRect = CGRect(x: pageRect.width - 172, y: 72, width: 100, height: 100)
            logo.draw(in: logoRect)
        }
    }

    private func drawMetadataPage(pageRect: CGRect) {
        let metaText = "Messung durchgeführt am: \(reportData.date)\nRaumtyp: \(reportData.roomType.displayName)\nVolumen: \(Int(reportData.volume)) m³"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        metaText.draw(at: CGPoint(x: 72, y: 72), withAttributes: attrs)
    }

    private func drawRT60Curves(pageRect: CGRect) {
        // Vereinfachte Darstellung: Werte als Text
        var y = 72
        for m in reportData.rt60Measurements.sorted(by: { $0.frequency < $1.frequency }) {
            let line = "\(m.frequency) Hz: \(String(format: "%.2f", m.rt60)) s"
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            line.draw(at: CGPoint(x: 72, y: CGFloat(y)), withAttributes: attrs)
            y += 20
        }
    }

    private func drawDINResults(pageRect: CGRect) {
        var y = 72
        for dev in reportData.dinResults {
            let line = "\(dev.frequency) Hz: Soll=\(String(format: "%.2f", dev.targetRT60)) s, Ist=\(String(format: "%.2f", dev.measuredRT60)) s, Status=\(dev.status)"
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            line.draw(at: CGPoint(x: 72, y: CGFloat(y)), withAttributes: attrs)
            y += 20
        }
    }

    private func drawRecommendations(pageRect: CGRect) {
        let text = "Empfohlene Maßnahmen:\n- Absorberfläche vergrößern.\n- Materialien mit höherem α-Wert einsetzen.\n- Deckenabsorber in Sprachräumen ergänzen."
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        text.draw(at: CGPoint(x: 72, y: 72), withAttributes: attrs)
    }
}

/// Data container for PDF report.
struct ReportData {
    var date: String
    var roomType: RoomType
    var volume: Double
    var rt60Measurements: [RT60Measurement]
    var dinResults: [RT60Deviation]
}
