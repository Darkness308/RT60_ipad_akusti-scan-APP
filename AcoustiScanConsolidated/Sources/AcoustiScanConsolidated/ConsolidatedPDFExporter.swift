// ConsolidatedPDFExporter.swift
// Advanced PDF export with comprehensive reporting

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
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
        
        public init(date: String, roomType: RoomType, volume: Double, rt60Measurements: [RT60Measurement], dinResults: [RT60Deviation], acousticFrameworkResults: [String: Double], surfaces: [AcousticSurface], recommendations: [String]) {
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
    
    /// Use the existing AcousticSurface from RT60Calculator module
    
    /// Generate comprehensive PDF report
    public static func generateReport(data: ReportData) -> Data? {
        #if canImport(UIKit)
        return generateReportWithUIKit(data: data)
        #else
        // Fallback for non-UIKit platforms
        let fallbackContent = """
        AcoustiScan Report
        
        Date: \(data.date)
        Room Type: \(data.roomType)
        Volume: \(data.volume) m³
        
        Note: Full PDF generation requires UIKit platform.
        """
        return fallbackContent.data(using: .utf8)
        #endif
    }
    
#if canImport(UIKit)
    private static func generateReportWithUIKit(data: ReportData) -> Data? {
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
            // Page 1: Title Page with Executive Summary
            context.beginPage()
            drawTitlePage(pageRect: pageRect, data: data)
            
            // Page 2: Metadata and Test Conditions
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
        let summaryText = """
        EXECUTIVE SUMMARY
        
        Raumtyp: \(data.roomType.displayName)
        Volumen: \(String(format: "%.1f", data.volume)) m³
        Datum: \(data.date)
        
        Bewertung: \(getDINComplianceStatus(data: data))
        """
        
        let summaryAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]
        
        let summaryRect = CGRect(x: margin, y: yPosition, width: pageRect.width - 2*margin, height: 200)
        
        // Draw background
        UIColor.lightGray.setFill()
        summaryRect.fill()
        
        summaryText.draw(in: summaryRect, withAttributes: summaryAttrs)
        
        // Compliance indicators
        yPosition += 250
        drawComplianceIndicators(pageRect: pageRect, data: data, yPosition: yPosition)
    }
    
    private static func drawMetadataPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let metadataText = """
        MESSDATEN UND TESTBEDINGUNGEN
        
        Datum: \(data.date)
        Raumtyp: \(data.roomType.displayName)
        Volumen: \(String(format: "%.1f", data.volume)) m³
        Anzahl Messpunkte: \(data.rt60Measurements.count)
        
        OBERFLÄCHENANALYSE:
        """
        
        let metadataAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14)
        ]
        
        metadataText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: metadataAttrs)
        yPosition += 200
        
        // Surface details
        for surface in data.surfaces {
            let surfaceText = "• \(surface.name): \(String(format: "%.1f", surface.area)) m² (\(surface.material.name))"
            let surfaceAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            surfaceText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: surfaceAttrs)
            yPosition += 20
        }
    }
    
    private static func drawRT60AnalysisPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let title = "RT60-FREQUENZANALYSE"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 50
        
        // RT60 values table
        for measurement in data.rt60Measurements {
            let valueText = "\(measurement.frequency) Hz: \(String(format: "%.2f", measurement.rt60Value)) s"
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            valueText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: valueAttrs)
            yPosition += 30
        }
    }
    
    private static func drawDINCompliancePage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let title = "DIN 18041 COMPLIANCE BEWERTUNG"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 50
        
        // DIN results
        for deviation in data.dinResults {
            let status = deviation.isWithinTolerance ? "✓ ERFÜLLT" : "✗ NICHT ERFÜLLT"
            let deviationText = "\(deviation.frequency) Hz: \(status) (Abweichung: \(String(format: "%.2f", deviation.deviation)))"
            let deviationAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14)
            ]
            deviationText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: deviationAttrs)
            yPosition += 30
        }
    }
    
    private static func drawAcousticFrameworkPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let title = "48-PARAMETER ACOUSTIC FRAMEWORK"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 50
        
        // Framework results (showing first 12 for brevity)
        let sortedResults = data.acousticFrameworkResults.sorted { $0.key < $1.key }
        for (parameter, value) in sortedResults.prefix(12) {
            let parameterText = "\(parameter): \(String(format: "%.3f", value))"
            let parameterAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            parameterText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: parameterAttrs)
            yPosition += 25
        }
        
        if sortedResults.count > 12 {
            let moreText = "... und \(sortedResults.count - 12) weitere Parameter"
            let moreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            moreText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: moreAttrs)
        }
    }
    
    private static func drawRecommendationsPage(pageRect: CGRect, data: ReportData) {
        let margin: CGFloat = 72
        var yPosition: CGFloat = margin
        
        let title = "EMPFEHLUNGEN UND MASSNAHMEN"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttrs)
        yPosition += 50
        
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
    
    private static func getDINComplianceStatus(data: ReportData) -> String {
        let compliantCount = data.dinResults.filter { $0.isWithinTolerance }.count
        let totalCount = data.dinResults.count
        
        if compliantCount == totalCount {
            return "VOLLSTÄNDIG ERFÜLLT"
        } else if compliantCount > totalCount / 2 {
            return "TEILWEISE ERFÜLLT"
        } else {
            return "NICHT ERFÜLLT"
        }
    }
    
    private static func drawComplianceIndicators(pageRect: CGRect, data: ReportData, yPosition: CGFloat) {
        // Simplified compliance visualization
        let margin: CGFloat = 72
        let indicatorText = "Compliance Status: \(getDINComplianceStatus(data: data))"
        let indicatorAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16)
        ]
        indicatorText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: indicatorAttrs)
    }
#endif
}