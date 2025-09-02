// ConsolidatedPDFExporter.swift
// Advanced PDF export with comprehensive reporting

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Comprehensive PDF report generator
public class ConsolidatedPDFExporter {
    
    /// Report data container
    public struct ReportData {
        public let date: String
        public let roomType: RoomType
        public let volume: Double
        public let rt60Measurements: [RT60Measurement]
        public let dinResults: [RT60Deviation]
        public let acousticFrameworkResults: [String: Double] // Parameter name -> value
        public let surfaces: [AcousticSurface]
        public let recommendations: [String]
        
        public init(date: String, roomType: RoomType, volume: Double,
                    rt60Measurements: [RT60Measurement], dinResults: [RT60Deviation],
                    acousticFrameworkResults: [String: Double], surfaces: [AcousticSurface],
                    recommendations: [String]) {
            self.date = date
            self.roomType = roomType
            self.volume = volume
            self.rt60Measurements = rt60Measurements
            self.dinResults = dinResults
            self.acousticFrameworkResults = acousticFrameworkResults
            self.surfaces = surfaces
            self.recommendations = recommendations
        }
    }
    
    #if os(iOS)
    /// Generate comprehensive PDF report on iOS
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
    
    // iOS-specific drawing functions
    private static func drawTitlePage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        // Title
        let title = "Gutachterlicher Raumakustik Report"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 60
        
        // Subtitle
        let subtitle = "RT60-Messung und DIN 18041-Bewertung"
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.darkGray
        ]
        subtitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttrs)
        yPosition += 80
        
        // Executive Summary Box
        let summaryRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 200)
        UIColor.lightGray.withAlphaComponent(0.1).setFill()
        UIRectFill(summaryRect)
        
        let summaryTitle = "Executive Summary"
        let summaryTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]
        summaryTitle.draw(at: CGPoint(x: margin + 20, y: yPosition + 20), withAttributes: summaryTitleAttrs)
        
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
        
        let summaryAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        summaryText.draw(in: CGRect(x: margin + 20, y: yPosition + 50, 
                                    width: pageRect.width - 2*margin - 40, height: 140),
                        withAttributes: summaryAttrs)
        
        // Footer
        let footer = "Erstellt mit AcoustiScan Consolidated Tool"
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        footer.draw(at: CGPoint(x: margin, y: pageRect.height - 100), withAttributes: footerAttrs)
    }
    
    private static func drawMetadataPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let pageTitle = "Messdaten und Raumkonfiguration"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        pageTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        let metadataText = """
        Grunddaten:
        • Messung durchgeführt am: \(data.date)
        • Raumtyp: \(data.roomType.displayName)
        • Raumvolumen: \(String(format: "%.2f", data.volume)) m³
        • Anzahl Oberflächenelemente: \(data.surfaces.count)
        
        Oberflächenkonfiguration:
        """
        
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        metadataText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: textAttrs)
        yPosition += 120
        
        // Surface details
        for surface in data.surfaces {
            let surfaceInfo = "• \(surface.name): \(String(format: "%.2f", surface.area)) m² - \(surface.material.name)"
            surfaceInfo.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: textAttrs)
            yPosition += 20
        }
    }
    
    private static func drawRT60AnalysisPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let pageTitle = "RT60-Frequenzanalyse"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        pageTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        // RT60 values table
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        "Frequenz (Hz)    RT60 (s)    Status".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttrs)
        yPosition += 25
        
        for measurement in data.rt60Measurements.sorted(by: { $0.frequency < $1.frequency }) {
            let dinResult = data.dinResults.first { $0.frequency == measurement.frequency }
            let status = dinResult?.status.displayName ?? "Unbekannt"
            let line = String(format: "%-15d %-11.2f %@", measurement.frequency, measurement.rt60, status)
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: valueAttrs)
            yPosition += 18
        }
    }
    
    private static func drawDINCompliancePage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let pageTitle = "DIN 18041 Konformitätsbewertung"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        pageTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        let headerText = "Frequenz    Ist-RT60    Soll-RT60    Abweichung    Status"
        headerText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttrs)
        yPosition += 25
        
        for deviation in data.dinResults.sorted(by: { $0.frequency < $1.frequency }) {
            let line = String(format: "%-10d %-11.2f %-12.2f %-13.2f %@", 
                            deviation.frequency, 
                            deviation.measuredRT60, 
                            deviation.targetRT60, 
                            deviation.deviation,
                            deviation.status.displayName)
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: valueAttrs)
            yPosition += 18
        }
    }
    
    private static func drawAcousticFrameworkPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let pageTitle = "48-Parameter Akustik-Framework Analyse"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        pageTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        let descriptionText = """
        Erweiterte akustische Bewertung basierend auf dem validierten 48-Parameter-Framework.
        Kategorien: Klangfarbe, Tonalität, Geometrie, Raum, Zeitverhalten, Dynamik, Artefakte.
        """
        
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        descriptionText.draw(in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 60), 
                           withAttributes: descAttrs)
        yPosition += 80
        
        // Framework results
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        for (parameter, value) in data.acousticFrameworkResults.sorted(by: { $0.key < $1.key }) {
            let line = "\(parameter): \(String(format: "%.2f", value))"
            line.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: valueAttrs)
            yPosition += 18
        }
    }
    
    private static func drawRecommendationsPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let pageTitle = "Empfehlungen und Maßnahmen"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        pageTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 40
        
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        
        for (index, recommendation) in data.recommendations.enumerated() {
            let line = "\(index + 1). \(recommendation)"
            let textRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 50)
            line.draw(in: textRect, withAttributes: textAttrs)
            yPosition += 60
        }
        
        // Quality assurance statement
        yPosition += 40
        let qaStatement = """
        Gutachterliche Bestätigung:
        Diese Messung wurde nach DIN 18041 durchgeführt und entspricht den wissenschaftlichen Standards
        für raumakustische Bewertungen. Die Empfehlungen basieren auf validierten akustischen Prinzipien
        und dem 48-Parameter-Framework für umfassende Audiobewertung.
        """
        
        let qaAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        qaStatement.draw(in: CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 100), 
                        withAttributes: qaAttrs)
    }
    
    #elseif os(macOS)
    /// Generate comprehensive PDF report on macOS using Core Graphics
    public static func generateReport(data: ReportData) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan Consolidated Tool",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "Gutachterlicher Raumakustik Report",
            kCGPDFContextSubject: "RT60 Messung und DIN 18041 Bewertung"
        ] as CFDictionary
        
        let pageWidth = 595.2  // A4 width in points
        let pageHeight = 841.8 // A4 height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect.mutableCopy(), pdfMetaData) else {
            return nil
        }
        
        // Page 1: Title and Executive Summary
        context.beginPDFPage(nil)
        drawTitlePageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        // Page 2: Measurement Metadata and Room Information
        context.beginPDFPage(nil)
        drawMetadataPageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        // Page 3: RT60 Curves and Frequency Analysis
        context.beginPDFPage(nil)
        drawRT60AnalysisPageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        // Page 4: DIN 18041 Compliance Results
        context.beginPDFPage(nil)
        drawDINCompliancePageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        // Page 5: 48-Parameter Acoustic Framework Results
        context.beginPDFPage(nil)
        drawAcousticFrameworkPageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        // Page 6: Recommendations and Action Items
        context.beginPDFPage(nil)
        drawRecommendationsPageMacOS(context: context, pageRect: pageRect, data: data)
        context.endPDFPage()
        
        context.closePDF()
        return mutableData as Data
    }
    
    private static func drawTextMacOS(context: CGContext, text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool, color: NSColor = .black) {
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: point.y)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -point.y)
        
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        (text as NSString).draw(at: point, withAttributes: attributes)
        context.restoreGState()
    }
    
    private static func drawTitlePageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin // macOS coordinates are flipped
        
        // Title
        let title = "Gutachterlicher Raumakustik Report"
        drawTextMacOS(context: context, text: title, at: CGPoint(x: margin, y: yPosition), fontSize: 28, bold: true)
        yPosition -= 60
        
        // Subtitle
        let subtitle = "RT60-Messung und DIN 18041-Bewertung"
        drawTextMacOS(context: context, text: subtitle, at: CGPoint(x: margin, y: yPosition), fontSize: 18, bold: false, color: .darkGray)
        yPosition -= 80
        
        // Executive Summary
        let summaryTitle = "Executive Summary"
        drawTextMacOS(context: context, text: summaryTitle, at: CGPoint(x: margin + 20, y: yPosition), fontSize: 16, bold: true)
        yPosition -= 30
        
        // Summary content
        let withinTolerance = data.dinResults.filter { $0.status == .withinTolerance }.count
        let totalMeasurements = data.dinResults.count
        let compliancePercentage = totalMeasurements > 0 ? Double(withinTolerance) / Double(totalMeasurements) * 100 : 0
        
        let summaryLines = [
            "Raum: \(data.roomType.displayName)",
            "Volumen: \(String(format: "%.1f", data.volume)) m³",
            "Messdatum: \(data.date)",
            "",
            "DIN 18041 Konformität: \(String(format: "%.1f", compliancePercentage))%",
            "Frequenzbereiche in Toleranz: \(withinTolerance)/\(totalMeasurements)",
            "",
            "Bewertung: \(compliancePercentage >= 80 ? "Sehr gut" : compliancePercentage >= 60 ? "Gut" : "Verbesserungsbedarf")"
        ]
        
        for line in summaryLines {
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin + 20, y: yPosition), fontSize: 14, bold: false)
            yPosition -= 20
        }
        
        // Footer
        let footer = "Erstellt mit AcoustiScan Consolidated Tool"
        drawTextMacOS(context: context, text: footer, at: CGPoint(x: margin, y: 100), fontSize: 12, bold: false, color: .gray)
    }
    
    private static func drawMetadataPageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin
        
        let pageTitle = "Messdaten und Raumkonfiguration"
        drawTextMacOS(context: context, text: pageTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 20, bold: true)
        yPosition -= 40
        
        let metadataLines = [
            "Grunddaten:",
            "• Messung durchgeführt am: \(data.date)",
            "• Raumtyp: \(data.roomType.displayName)",
            "• Raumvolumen: \(String(format: "%.2f", data.volume)) m³",
            "• Anzahl Oberflächenelemente: \(data.surfaces.count)",
            "",
            "Oberflächenkonfiguration:"
        ]
        
        for line in metadataLines {
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: false)
            yPosition -= 20
        }
        
        // Surface details
        for surface in data.surfaces {
            let surfaceInfo = "• \(surface.name): \(String(format: "%.2f", surface.area)) m² - \(surface.material.name)"
            drawTextMacOS(context: context, text: surfaceInfo, at: CGPoint(x: margin + 20, y: yPosition), fontSize: 14, bold: false)
            yPosition -= 20
        }
    }
    
    private static func drawRT60AnalysisPageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin
        
        let pageTitle = "RT60-Frequenzanalyse"
        drawTextMacOS(context: context, text: pageTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 20, bold: true)
        yPosition -= 40
        
        drawTextMacOS(context: context, text: "Frequenz (Hz)    RT60 (s)    Status", at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: true)
        yPosition -= 25
        
        for measurement in data.rt60Measurements.sorted(by: { $0.frequency < $1.frequency }) {
            let dinResult = data.dinResults.first { $0.frequency == measurement.frequency }
            let status = dinResult?.status.displayName ?? "Unbekannt"
            let line = String(format: "%-15d %-11.2f %@", measurement.frequency, measurement.rt60, status)
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
            yPosition -= 18
        }
    }
    
    private static func drawDINCompliancePageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin
        
        let pageTitle = "DIN 18041 Konformitätsbewertung"
        drawTextMacOS(context: context, text: pageTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 20, bold: true)
        yPosition -= 40
        
        let headerText = "Frequenz    Ist-RT60    Soll-RT60    Abweichung    Status"
        drawTextMacOS(context: context, text: headerText, at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: true)
        yPosition -= 25
        
        for deviation in data.dinResults.sorted(by: { $0.frequency < $1.frequency }) {
            let line = String(format: "%-10d %-11.2f %-12.2f %-13.2f %@", 
                            deviation.frequency, 
                            deviation.measuredRT60, 
                            deviation.targetRT60, 
                            deviation.deviation,
                            deviation.status.displayName)
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
            yPosition -= 18
        }
    }
    
    private static func drawAcousticFrameworkPageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin
        
        let pageTitle = "48-Parameter Akustik-Framework Analyse"
        drawTextMacOS(context: context, text: pageTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 20, bold: true)
        yPosition -= 40
        
        let descriptionText = "Erweiterte akustische Bewertung basierend auf dem validierten 48-Parameter-Framework."
        drawTextMacOS(context: context, text: descriptionText, at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: false)
        yPosition -= 25
        
        let categoriesText = "Kategorien: Klangfarbe, Tonalität, Geometrie, Raum, Zeitverhalten, Dynamik, Artefakte."
        drawTextMacOS(context: context, text: categoriesText, at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: false)
        yPosition -= 40
        
        // Framework results
        for (parameter, value) in data.acousticFrameworkResults.sorted(by: { $0.key < $1.key }) {
            let line = "\(parameter): \(String(format: "%.2f", value))"
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false)
            yPosition -= 18
        }
    }
    
    private static func drawRecommendationsPageMacOS(context: CGContext, pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = pageRect.height - margin
        
        let pageTitle = "Empfehlungen und Maßnahmen"
        drawTextMacOS(context: context, text: pageTitle, at: CGPoint(x: margin, y: yPosition), fontSize: 20, bold: true)
        yPosition -= 40
        
        for (index, recommendation) in data.recommendations.enumerated() {
            let line = "\(index + 1). \(recommendation)"
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 14, bold: false)
            yPosition -= 30
        }
        
        // Quality assurance statement
        yPosition -= 40
        let qaLines = [
            "Gutachterliche Bestätigung:",
            "Diese Messung wurde nach DIN 18041 durchgeführt und entspricht den wissenschaftlichen Standards",
            "für raumakustische Bewertungen. Die Empfehlungen basieren auf validierten akustischen Prinzipien",
            "und dem 48-Parameter-Framework für umfassende Audiobewertung."
        ]
        
        for line in qaLines {
            drawTextMacOS(context: context, text: line, at: CGPoint(x: margin, y: yPosition), fontSize: 12, bold: false, color: .darkGray)
            yPosition -= 18
        }
    }
    
    #else
    /// Fallback for other platforms - returns empty data
    public static func generateReport(data: ReportData) -> Data? {
        return Data()
    }
    #endif
}