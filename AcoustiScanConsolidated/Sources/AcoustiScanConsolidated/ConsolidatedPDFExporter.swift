// ConsolidatedPDFExporter.swift
// Advanced PDF export with comprehensive reporting

import Foundation
#if canImport(UIKit)
import UIKit
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
    
    #if canImport(UIKit)
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
        
        Bewertung: \(compliancePercentage >= 80 ? "Sehr gut" : compliancePercentage >= 60 ? "Gut" : "Verbesserungsbedarf")
        """
        
        let summaryAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        summaryText.draw(in: CGRect(x: margin + 20, y: yPosition + 50, width: pageRect.width - 2*margin - 40, height: 140), 
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
        
        "Frequenz    Ist-RT60    Soll-RT60    Abweichung    Status".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttrs)
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
    #endif
}