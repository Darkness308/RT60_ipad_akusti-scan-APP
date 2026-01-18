// ConsolidatedPDFExporter.swift
// Advanced PDF export with comprehensive reporting

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Comprehensive PDF report generator
public class ConsolidatedPDFExporter {

    // Backward compatibility: Use the consolidated ReportData model
    public typealias ReportData = AcoustiScanConsolidated.ReportData

    #if canImport(UIKit)
    private enum PDFStyling {
        private static let margin: CGFloat = 72

        private static func titleAttributes(
            size: CGFloat,
            weight: UIFont.Weight = .regular,
            color: UIColor = .black
        ) -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: color
            ]
        }

        private static func bodyAttributes(
            size: CGFloat = 14,
            color: UIColor = .black
        ) -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: size),
                .foregroundColor: color
            ]
        }

        private static func footerAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
        }

        private static func draw(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any]) {
            text.draw(at: point, withAttributes: attributes)
        }

        private static func draw(_ text: String, in rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
            text.draw(in: rect, withAttributes: attributes)
        }
    }

    private enum PDFListRenderer {
        private static func drawBulletedList(
            _ items: [String],
            startY: CGFloat,
            margin: CGFloat,
            attributes: [NSAttributedString.Key: Any],
            bullet: String = "•",
            width: CGFloat? = nil,
            lineSpacing: CGFloat = 20
        ) -> CGFloat {
            var yPosition = startY
            for item in items {
                let text = bullet.isEmpty ? item : "\(bullet) \(item)"

                if let width = width {
                    let rect = CGRect(x: margin, y: yPosition, width: width, height: .greatestFiniteMagnitude)
                    PDFStyling.draw(text, in: rect, attributes: attributes)

                    let bounding = text.boundingRect(
                        with: CGSize(width: width, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attributes,
                        context: nil
                    )
                    yPosition += ceil(bounding.height) + max(0, lineSpacing - 20)
                } else {
                    PDFStyling.draw(text, at: CGPoint(x: margin, y: yPosition), attributes: attributes)
                    yPosition += lineSpacing
                }
            }
            return yPosition
        }
    }

    /// Generate comprehensive PDF report
    public static func generateReport(data: ReportData) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan Consolidated Tool",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "Gutachterlicher Raumakustik Report",
            kCGPDFContextSubject: "RT60 Messung und DIN 18041 Bewertung"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2  // A4 width in points
        let pageHeight = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            // Page 1: Title and Executive Summary
            context.beginPage()
            drawTitlePage(pageRect: pageRect, data: data)

            // Page 2: Measurement Metadata and Room Information
            context.beginPage()
            drawMetadataPage(pageRect: pageRect, data: data)

            // Page 3: RT60 Curves and Frequency Analysis
            context.beginPage()
            drawRT60AnalysisPage(pageRect: pageRect, data: data)

            // Page 4: DIN 18041 Compliance Results
            context.beginPage()
            drawDINCompliancePage(pageRect: pageRect, data: data)

            // Page 5: 48-Parameter Acoustic Framework Results
            context.beginPage()
            drawAcousticFrameworkPage(pageRect: pageRect, data: data)

            // Page 6: Recommendations and Action Items
            context.beginPage()
            drawRecommendationsPage(pageRect: pageRect, data: data)
        }
    }

    private static func drawTitlePage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        // Title
        let title = "Gutachterlicher Raumakustik Report"
        let titleAttrs = PDFStyling.titleAttributes(size: 28, weight: .bold)
        PDFStyling.draw(title, at: CGPoint(x: margin, y: yPosition), attributes: titleAttrs)
        yPosition += 60

        // Subtitle
        let subtitle = "RT60-Messung und DIN 18041-Bewertung"
        let subtitleAttrs = PDFStyling.titleAttributes(size: 18, color: .darkGray)
        PDFStyling.draw(subtitle, at: CGPoint(x: margin, y: yPosition), attributes: subtitleAttrs)
        yPosition += 80

        // Executive Summary Box
        let summaryRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 200)
        UIColor.lightGray.withAlphaComponent(0.1).setFill()
        UIRectFill(summaryRect)

        let summaryTitle = "Executive Summary"
        let summaryTitleAttrs = PDFStyling.titleAttributes(size: 16, weight: .bold)
        PDFStyling.draw(summaryTitle, at: CGPoint(x: margin + 20, y: yPosition + 20), attributes: summaryTitleAttrs)

        // Summary content
        let withinTolerance = data.dinResults.filter { $0.status == .withinTolerance }.count
        let totalMeasurements = data.dinResults.count
        let compliancePercentage = totalMeasurements > 0 ? Double(withinTolerance) / Double(totalMeasurements) * 100 : 0

        let summaryText = """
        Raum: \(data.roomType.displayName)
        Volumen: \(String(format: "%.1f", data.volume)) m³
        Messdatum: \(data.date)

        DIN 18041 Konformität: \(String(format: "%.1f", compliancePercentage))%
        Frequenzbereiche in Toleranz: \(withinTolerance)/\(totalMeasurements)

        Bewertung: \(compliancePercentage >= 80 ? "Sehr gut" :
                    compliancePercentage >= 60 ? "Gut" : "Verbesserungsbedarf")
        """

        let summaryAttrs = PDFStyling.bodyAttributes()
        PDFStyling.draw(summaryText, in: CGRect(x: margin + 20, y: yPosition + 50,
                                                width: pageRect.width - 2*margin - 40, height: 140),
                         attributes: summaryAttrs)

        // Footer
        let footer = "Erstellt mit AcoustiScan Consolidated Tool"
        PDFStyling.draw(
            footer,
            at: CGPoint(x: margin, y: pageRect.height - 100),
            attributes: PDFStyling.footerAttributes()
        )
    }

    private static func drawMetadataPage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        let pageTitle = "Messdaten und Raumkonfiguration"
        let titleAttrs = PDFStyling.titleAttributes(size: 20, weight: .bold)
        PDFStyling.draw(pageTitle, at: CGPoint(x: margin, y: yPosition), attributes: titleAttrs)
        yPosition += 40

        let metadataText = """
        Grunddaten:
        • Messung durchgeführt am: \(data.date)
        • Raumtyp: \(data.roomType.displayName)
        • Raumvolumen: \(String(format: "%.2f", data.volume)) m³
        • Anzahl Oberflächenelemente: \(data.surfaces.count)

        Oberflächenkonfiguration:
        """

        let textAttrs = PDFStyling.bodyAttributes()
        PDFStyling.draw(
            metadataText,
            at: CGPoint(x: margin, y: yPosition),
            attributes: textAttrs
        )
        yPosition += 120

        let surfaceLines = data.surfaces.map { surface in
            let areaFormatted = String(format: "%.2f", surface.area)
            return "\(surface.name): \(areaFormatted) m² - \(surface.material.name)"
        }
        _ = PDFListRenderer.drawBulletedList(
            surfaceLines,
            startY: yPosition,
            margin: margin + 20,
            attributes: textAttrs
        )
    }

    private static func drawRT60AnalysisPage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        let pageTitle = "RT60-Frequenzanalyse"
        let titleAttrs = PDFStyling.titleAttributes(size: 20, weight: .bold)
        PDFStyling.draw(
            pageTitle,
            at: CGPoint(x: margin, y: yPosition),
            attributes: titleAttrs
        )
        yPosition += 40

        // RT60 values table
        let headerAttrs = PDFStyling.titleAttributes(size: 14, weight: .bold)
        let valueAttrs = PDFStyling.bodyAttributes(size: 12)

        PDFStyling.draw("Frequenz (Hz)    RT60 (s)    Status", at: CGPoint(x: margin, y: yPosition), attributes: headerAttrs)
        yPosition += 25

        for measurement in data.rt60Measurements.sorted(by: { $0.frequency < $1.frequency }) {
            let dinResult = data.dinResults.first { $0.frequency == measurement.frequency }
            let status = dinResult?.status.displayName ?? "Unbekannt"
            let line = String(format: "%-15d %-11.2f %@", measurement.frequency, measurement.rt60, status)
            PDFStyling.draw(line, at: CGPoint(x: margin, y: yPosition), attributes: valueAttrs)
            yPosition += 18
        }
    }

    private static func drawDINCompliancePage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        let pageTitle = "DIN 18041 Konformitätsbewertung"
        let titleAttrs = PDFStyling.titleAttributes(size: 20, weight: .bold)
        PDFStyling.draw(pageTitle, at: CGPoint(x: margin, y: yPosition), attributes: titleAttrs)
        yPosition += 40

        let headerAttrs = PDFStyling.titleAttributes(size: 14, weight: .bold)
        let valueAttrs = PDFStyling.bodyAttributes(size: 12)

        let headerText = "Frequenz    Ist-RT60    Soll-RT60    Abweichung    Status"
        PDFStyling.draw(headerText, at: CGPoint(x: margin, y: yPosition), attributes: headerAttrs)
        yPosition += 25

        for deviation in data.dinResults.sorted(by: { $0.frequency < $1.frequency }) {
            let line = String(format: "%-10d %-11.2f %-12.2f %-13.2f %@",
                            deviation.frequency,
                            deviation.measuredRT60,
                            deviation.targetRT60,
                            deviation.deviation,
                            deviation.status.displayName)
            PDFStyling.draw(line, at: CGPoint(x: margin, y: yPosition), attributes: valueAttrs)
            yPosition += 18
        }
    }

    private static func drawAcousticFrameworkPage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        let pageTitle = "48-Parameter Akustik-Framework Analyse"
        let titleAttrs = PDFStyling.titleAttributes(size: 20, weight: .bold)
        PDFStyling.draw(pageTitle, at: CGPoint(x: margin, y: yPosition), attributes: titleAttrs)
        yPosition += 40

        let descriptionText = """
        Erweiterte akustische Bewertung basierend auf dem validierten 48-Parameter-Framework.
        Kategorien: Klangfarbe, Tonalität, Geometrie, Raum, Zeitverhalten, Dynamik, Artefakte.
        """

        let descAttrs = PDFStyling.bodyAttributes()
        PDFStyling.draw(descriptionText, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 60),
                        attributes: descAttrs)
        yPosition += 80

        // Framework results
        let valueAttrs = PDFStyling.bodyAttributes(size: 12)

        for (parameter, value) in data.acousticFrameworkResults.sorted(by: { $0.key < $1.key }) {
            let line = "\(parameter): \(String(format: "%.2f", value))"
            PDFStyling.draw(line, at: CGPoint(x: margin, y: yPosition), attributes: valueAttrs)
            yPosition += 18
        }
    }

    private static func drawRecommendationsPage(pageRect: CGRect, data: ReportData) {
        let margin = PDFStyling.margin
        var yPosition: CGFloat = margin

        let pageTitle = "Empfehlungen und Maßnahmen"
        let titleAttrs = PDFStyling.titleAttributes(size: 20, weight: .bold)
        PDFStyling.draw(pageTitle, at: CGPoint(x: margin, y: yPosition), attributes: titleAttrs)
        yPosition += 40

        let textAttrs = PDFStyling.bodyAttributes()
        let numberedItems = data.recommendations.enumerated().map { "\($0.offset + 1). \($0.element)" }
        yPosition = PDFListRenderer.drawBulletedList(
            numberedItems,
            startY: yPosition,
            margin: margin,
            attributes: textAttrs,
            bullet: "",
            width: pageRect.width - 2*margin,
            lineSpacing: 30
        )

        // Quality assurance statement
        yPosition += 40
        let qaStatement = """
        Gutachterliche Bestätigung:
        Diese Messung wurde nach DIN 18041 durchgeführt und entspricht den wissenschaftlichen Standards
        für raumakustische Bewertungen. Die Empfehlungen basieren auf validierten akustischen Prinzipien
        und dem 48-Parameter-Framework für umfassende Audiobewertung.
        """

        let qaAttrs = PDFStyling.bodyAttributes(size: 12, color: .darkGray)
        PDFStyling.draw(qaStatement, in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 100),
                        attributes: qaAttrs)
    }
    #endif
}
