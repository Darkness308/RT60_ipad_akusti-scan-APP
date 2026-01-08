//
//  EnhancedPDFExporter.swift
//  AcoustiScanApp
//
//  Enhanced PDF Export with Charts, Traffic Light System, and Recommendations
//

import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#endif

/// Enhanced PDF Exporter for RT60 Reports with visual enhancements
public class EnhancedPDFExporter {
    
    // MARK: - Constants
    
    /// A4 page dimensions in points (72 points per inch)
    private struct PageSize {
        static let a4Width: CGFloat = 595.2  // 210mm
        static let a4Height: CGFloat = 841.8 // 297mm
    }
    
    /// Page layout constants
    private struct Layout {
        static let margin: CGFloat = 72 // 1 inch margin
        static let pageBreakThreshold: CGFloat = 100 // Space needed before page break
    }
    
    public init() {}
    
    #if canImport(UIKit)
    /// Generate enhanced PDF report with charts and traffic light system
    /// - Parameters:
    ///   - roomName: Name of the room
    ///   - volume: Room volume in m³
    ///   - rt60Values: RT60 measurements by frequency
    ///   - dinTargets: DIN 18041 target values by frequency
    ///   - surfaces: Room surfaces with materials
    ///   - recommendations: List of recommendations
    /// - Returns: PDF data
    public func generateReport(
        roomName: String,
        volume: Double,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)],
        surfaces: [(name: String, area: Double, material: String)],
        recommendations: [String]
    ) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "AcoustiScan Enhanced",
            kCGPDFContextAuthor: "MSH-Audio-Gruppe",
            kCGPDFContextTitle: "RT60 Gutachten - \(roomName)",
            kCGPDFContextSubject: "Raumakustische Messung nach DIN 18041"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: PageSize.a4Width, height: PageSize.a4Height)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            // Page 1: Cover and Summary
            context.beginPage()
            drawCoverPage(
                context: context,
                pageRect: pageRect,
                roomName: roomName,
                volume: volume,
                date: Date()
            )
            
            // Page 2: RT60 Measurements with Chart
            context.beginPage()
            drawRT60MeasurementsPage(
                context: context,
                pageRect: pageRect,
                rt60Values: rt60Values,
                dinTargets: dinTargets
            )
            
            // Page 3: DIN 18041 Classification with Traffic Lights
            context.beginPage()
            drawDINClassificationPage(
                context: context,
                pageRect: pageRect,
                rt60Values: rt60Values,
                dinTargets: dinTargets
            )
            
            // Page 4: Materials Overview
            context.beginPage()
            drawMaterialsPage(
                context: context,
                pageRect: pageRect,
                surfaces: surfaces,
                volume: volume
            )
            
            // Page 5: Recommendations and Action Plan
            context.beginPage()
            drawRecommendationsPage(
                context: context,
                pageRect: pageRect,
                recommendations: recommendations
            )
        }
    }
    
    // MARK: - Page 1: Cover
    
    private func drawCoverPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        roomName: String,
        volume: Double,
        date: Date
    ) {
        let margin: CGFloat = 72
        var y: CGFloat = 150
        
        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let title = "Raumakustik-Gutachten"
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        title.draw(
            at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: y),
            withAttributes: titleAttrs
        )
        y += titleSize.height + 60
        
        // Room Info Box
        let boxRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 200)
        UIColor.systemBlue.withAlphaComponent(0.1).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 12).fill()
        
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.darkGray
        ]
        
        y += 30
        "Raum: \(roomName)".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: infoAttrs)
        y += 35
        "Volumen: \(String(format: "%.1f", volume)) m³".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: infoAttrs)
        y += 35
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "de_DE")
        "Datum: \(dateFormatter.string(from: date))".draw(at: CGPoint(x: margin + 20, y: y), withAttributes: infoAttrs)
        
        // Footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        "Nach DIN 18041 - Hörsamkeit in Räumen".draw(
            at: CGPoint(x: margin, y: pageRect.height - 50),
            withAttributes: footerAttrs
        )
    }
    
    // MARK: - Page 2: RT60 Measurements with Chart
    
    private func drawRT60MeasurementsPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let margin: CGFloat = 72
        var y: CGFloat = margin
        
        // Page title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        "RT60-Messungen".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 50
        
        // Draw chart
        let chartRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 250)
        drawRT60Chart(in: chartRect, rt60Values: rt60Values, dinTargets: dinTargets)
        y += 270
        
        // Table of values
        drawRT60Table(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            rt60Values: rt60Values,
            dinTargets: dinTargets
        )
    }
    
    private func drawRT60Chart(
        in rect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        // Background
        UIColor.white.setFill()
        UIBezierPath(rect: rect).fill()
        
        // Border
        UIColor.lightGray.setStroke()
        let border = UIBezierPath(rect: rect)
        border.lineWidth = 1
        border.stroke()
        
        // Grid lines and axes
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        let maxRT60 = 2.0
        let minRT60 = 0.0
        
        // Draw horizontal grid lines
        UIColor.lightGray.withAlphaComponent(0.3).setStroke()
        for i in 0...4 {
            let y = rect.minY + (rect.height / 4) * CGFloat(i)
            let gridLine = UIBezierPath()
            gridLine.move(to: CGPoint(x: rect.minX, y: y))
            gridLine.addLine(to: CGPoint(x: rect.maxX, y: y))
            gridLine.lineWidth = 0.5
            gridLine.stroke()
        }
        
        // Draw frequency labels
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        for (index, freq) in frequencies.enumerated() {
            let x = rect.minX + (rect.width / CGFloat(frequencies.count - 1)) * CGFloat(index)
            "\(freq)".draw(
                at: CGPoint(x: x - 15, y: rect.maxY + 5),
                withAttributes: labelAttrs
            )
        }
        
        // Draw RT60 values as line
        if !rt60Values.isEmpty {
            let path = UIBezierPath()
            var first = true
            
            for (index, freq) in frequencies.enumerated() {
                if let rt60 = rt60Values[freq] {
                    let x = rect.minX + (rect.width / CGFloat(frequencies.count - 1)) * CGFloat(index)
                    let normalizedY = CGFloat((rt60 - minRT60) / (maxRT60 - minRT60))
                    let y = rect.maxY - (rect.height * normalizedY)
                    
                    if first {
                        path.move(to: CGPoint(x: x, y: y))
                        first = false
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    // Draw data point
                    let pointRect = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
                    UIColor.systemBlue.setFill()
                    UIBezierPath(ovalIn: pointRect).fill()
                }
            }
            
            UIColor.systemBlue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        
        // Draw target line
        if let firstTarget = dinTargets.values.first {
            let targetY = rect.maxY - (rect.height * CGFloat((firstTarget.target - minRT60) / (maxRT60 - minRT60)))
            let targetPath = UIBezierPath()
            targetPath.move(to: CGPoint(x: rect.minX, y: targetY))
            targetPath.addLine(to: CGPoint(x: rect.maxX, y: targetY))
            UIColor.systemGreen.setStroke()
            targetPath.lineWidth = 1.5
            let dashPattern: [CGFloat] = [5, 3]
            targetPath.setLineDash(dashPattern, count: 2, phase: 0)
            targetPath.stroke()
        }
        
        // Y-axis labels
        for i in 0...4 {
            let value = minRT60 + (maxRT60 - minRT60) * Double(4 - i) / 4.0
            let y = rect.minY + (rect.height / 4) * CGFloat(i)
            String(format: "%.1f s", value).draw(
                at: CGPoint(x: rect.minX - 35, y: y - 6),
                withAttributes: labelAttrs
            )
        }
    }
    
    private func drawRT60Table(
        at origin: CGPoint,
        width: CGFloat,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        let rowHeight: CGFloat = 30
        let colWidth = width / 4
        
        // Header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11)
        ]
        
        var y = origin.y
        
        // Draw header row
        UIColor.systemBlue.setFill()
        UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
        
        "Frequenz".draw(at: CGPoint(x: origin.x + 5, y: y + 8), withAttributes: headerAttrs)
        "Gemessen".draw(at: CGPoint(x: origin.x + colWidth + 5, y: y + 8), withAttributes: headerAttrs)
        "Soll".draw(at: CGPoint(x: origin.x + 2 * colWidth + 5, y: y + 8), withAttributes: headerAttrs)
        "Status".draw(at: CGPoint(x: origin.x + 3 * colWidth + 5, y: y + 8), withAttributes: headerAttrs)
        
        y += rowHeight
        
        // Draw data rows
        for (index, freq) in frequencies.enumerated() {
            if index % 2 == 0 {
                UIColor.systemGray.withAlphaComponent(0.1).setFill()
                UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
            }
            
            // Frequency
            "\(freq) Hz".draw(at: CGPoint(x: origin.x + 5, y: y + 8), withAttributes: cellAttrs)
            
            // Measured value
            if let rt60 = rt60Values[freq] {
                String(format: "%.2f s", rt60).draw(
                    at: CGPoint(x: origin.x + colWidth + 5, y: y + 8),
                    withAttributes: cellAttrs
                )
                
                // Target value
                if let target = dinTargets[freq] {
                    String(format: "%.2f s", target.target).draw(
                        at: CGPoint(x: origin.x + 2 * colWidth + 5, y: y + 8),
                        withAttributes: cellAttrs
                    )
                    
                    // Status indicator
                    let deviation = abs(rt60 - target.target)
                    let statusColor: UIColor
                    let statusText: String
                    
                    if deviation <= target.tolerance {
                        statusColor = .systemGreen
                        statusText = "✓ OK"
                    } else if deviation <= target.tolerance * 1.5 {
                        statusColor = .systemOrange
                        statusText = "⚠ Toleranz"
                    } else {
                        statusColor = .systemRed
                        statusText = "✗ Kritisch"
                    }
                    
                    let statusAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 11),
                        .foregroundColor: statusColor
                    ]
                    statusText.draw(
                        at: CGPoint(x: origin.x + 3 * colWidth + 5, y: y + 8),
                        withAttributes: statusAttrs
                    )
                }
            }
            
            y += rowHeight
        }
        
        // Border
        UIColor.lightGray.setStroke()
        let tableBorder = UIBezierPath(rect: CGRect(
            x: origin.x,
            y: origin.y,
            width: width,
            height: rowHeight * CGFloat(frequencies.count + 1)
        ))
        tableBorder.lineWidth = 1
        tableBorder.stroke()
    }
    
    // MARK: - Page 3: DIN Classification with Traffic Lights
    
    private func drawDINClassificationPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let margin: CGFloat = 72
        var y: CGFloat = margin
        
        // Page title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        "DIN 18041 Klassifizierung".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 50
        
        // Calculate compliance
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        var compliantCount = 0
        var warningCount = 0
        var criticalCount = 0
        
        for freq in frequencies {
            if let rt60 = rt60Values[freq], let target = dinTargets[freq] {
                let deviation = abs(rt60 - target.target)
                if deviation <= target.tolerance {
                    compliantCount += 1
                } else if deviation <= target.tolerance * 1.5 {
                    warningCount += 1
                } else {
                    criticalCount += 1
                }
            }
        }
        
        // Overall status
        let overallStatus: String
        let overallColor: UIColor
        
        if criticalCount > 0 {
            overallStatus = "Kritisch - Maßnahmen erforderlich"
            overallColor = .systemRed
        } else if warningCount > 0 {
            overallStatus = "Teilweise konform - Verbesserungen empfohlen"
            overallColor = .systemOrange
        } else {
            overallStatus = "Konform - DIN 18041 erfüllt"
            overallColor = .systemGreen
        }
        
        // Draw status box
        let statusBox = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 100)
        overallColor.withAlphaComponent(0.2).setFill()
        UIBezierPath(roundedRect: statusBox, cornerRadius: 12).fill()
        
        let statusAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: overallColor
        ]
        overallStatus.draw(at: CGPoint(x: margin + 20, y: y + 35), withAttributes: statusAttrs)
        
        y += 120
        
        // Traffic light visualization
        drawTrafficLights(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            compliant: compliantCount,
            warning: warningCount,
            critical: criticalCount,
            total: frequencies.count
        )
    }
    
    private func drawTrafficLights(
        at origin: CGPoint,
        width: CGFloat,
        compliant: Int,
        warning: Int,
        critical: Int,
        total: Int
    ) {
        let boxWidth = width / 3 - 20
        let boxHeight: CGFloat = 150
        
        let data = [
            ("Konform", compliant, UIColor.systemGreen),
            ("Warnung", warning, UIColor.systemOrange),
            ("Kritisch", critical, UIColor.systemRed)
        ]
        
        for (index, (label, count, color)) in data.enumerated() {
            let x = origin.x + CGFloat(index) * (boxWidth + 30)
            
            // Box background
            color.withAlphaComponent(0.2).setFill()
            let box = UIBezierPath(roundedRect: CGRect(x: x, y: origin.y, width: boxWidth, height: boxHeight), cornerRadius: 12)
            box.fill()
            
            // Circle (traffic light)
            let circleSize: CGFloat = 60
            let circleY = origin.y + 30
            color.setFill()
            let circle = UIBezierPath(ovalIn: CGRect(
                x: x + (boxWidth - circleSize) / 2,
                y: circleY,
                width: circleSize,
                height: circleSize
            ))
            circle.fill()
            
            // Count
            let countAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            let countStr = "\(count)"
            let countSize = (countStr as NSString).size(withAttributes: countAttrs)
            countStr.draw(
                at: CGPoint(x: x + (boxWidth - countSize.width) / 2, y: circleY + (circleSize - countSize.height) / 2),
                withAttributes: countAttrs
            )
            
            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            let labelSize = (label as NSString).size(withAttributes: labelAttrs)
            label.draw(
                at: CGPoint(x: x + (boxWidth - labelSize.width) / 2, y: origin.y + boxHeight - 30),
                withAttributes: labelAttrs
            )
        }
    }
    
    // MARK: - Page 4: Materials
    
    private func drawMaterialsPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        surfaces: [(name: String, area: Double, material: String)],
        volume: Double
    ) {
        let margin: CGFloat = 72
        var y: CGFloat = margin
        
        // Page title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        "Materialübersicht".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 50
        
        // Room volume
        let infoAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        "Raumvolumen: \(String(format: "%.1f", volume)) m³".draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: infoAttrs
        )
        y += 30
        
        // Materials table
        let totalArea = surfaces.reduce(0) { $0 + $1.area }
        "Gesamtfläche: \(String(format: "%.1f", totalArea)) m²".draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: infoAttrs
        )
        y += 40
        
        // Draw surfaces table
        drawSurfacesTable(at: CGPoint(x: margin, y: y), width: pageRect.width - 2 * margin, surfaces: surfaces)
    }
    
    private func drawSurfacesTable(
        at origin: CGPoint,
        width: CGFloat,
        surfaces: [(name: String, area: Double, material: String)]
    ) {
        let rowHeight: CGFloat = 35
        let col1Width = width * 0.4
        let col2Width = width * 0.3
        let col3Width = width * 0.3
        
        // Header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.white
        ]
        
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11)
        ]
        
        var y = origin.y
        
        // Draw header row
        UIColor.systemBlue.setFill()
        UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
        
        "Fläche".draw(at: CGPoint(x: origin.x + 5, y: y + 10), withAttributes: headerAttrs)
        "Fläche (m²)".draw(at: CGPoint(x: origin.x + col1Width + 5, y: y + 10), withAttributes: headerAttrs)
        "Material".draw(at: CGPoint(x: origin.x + col1Width + col2Width + 5, y: y + 10), withAttributes: headerAttrs)
        
        y += rowHeight
        
        // Draw data rows
        for (index, surface) in surfaces.enumerated() {
            if index % 2 == 0 {
                UIColor.systemGray.withAlphaComponent(0.1).setFill()
                UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
            }
            
            surface.name.draw(at: CGPoint(x: origin.x + 5, y: y + 10), withAttributes: cellAttrs)
            String(format: "%.1f", surface.area).draw(
                at: CGPoint(x: origin.x + col1Width + 5, y: y + 10),
                withAttributes: cellAttrs
            )
            surface.material.draw(
                at: CGPoint(x: origin.x + col1Width + col2Width + 5, y: y + 10),
                withAttributes: cellAttrs
            )
            
            y += rowHeight
        }
        
        // Border
        UIColor.lightGray.setStroke()
        let tableBorder = UIBezierPath(rect: CGRect(
            x: origin.x,
            y: origin.y,
            width: width,
            height: rowHeight * CGFloat(surfaces.count + 1)
        ))
        tableBorder.lineWidth = 1
        tableBorder.stroke()
    }
    
    // MARK: - Page 5: Recommendations
    
    private func drawRecommendationsPage(
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        recommendations: [String]
    ) {
        let margin: CGFloat = 72
        var y: CGFloat = margin
        
        // Page title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        "Maßnahmenempfehlungen".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 50
        
        // Intro text
        let introAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.darkGray
        ]
        let introText = "Basierend auf den Messungen werden folgende akustische Maßnahmen empfohlen:"
        introText.draw(at: CGPoint(x: margin, y: y), withAttributes: introAttrs)
        y += 40
        
        // Recommendations list
        let recAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13)
        ]
        
        let titleRecAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13)
        ]
        
        for (index, recommendation) in recommendations.enumerated() {
            // Number circle
            let circleSize: CGFloat = 28
            UIColor.systemBlue.setFill()
            let circle = UIBezierPath(ovalIn: CGRect(x: margin, y: y, width: circleSize, height: circleSize))
            circle.fill()
            
            // Number
            let numAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white
            ]
            let numStr = "\(index + 1)"
            let numSize = (numStr as NSString).size(withAttributes: numAttrs)
            numStr.draw(
                at: CGPoint(x: margin + (circleSize - numSize.width) / 2, y: y + (circleSize - numSize.height) / 2),
                withAttributes: numAttrs
            )
            
            // Recommendation text
            let textRect = CGRect(
                x: margin + circleSize + 15,
                y: y,
                width: pageRect.width - 2 * margin - circleSize - 15,
                height: 100
            )
            
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = 4
            
            let recAttrsCombined: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .paragraphStyle: paraStyle
            ]
            
            (recommendation as NSString).draw(in: textRect, withAttributes: recAttrsCombined)
            
            let textHeight = (recommendation as NSString).boundingRect(
                with: CGSize(width: textRect.width, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: recAttrsCombined,
                context: nil
            ).height
            
            y += max(circleSize, textHeight) + 25
            
            // Add page break if needed
            if y > pageRect.height - Layout.pageBreakThreshold && index < recommendations.count - 1 {
                context.beginPage()
                y = Layout.margin
            }
        }
    }
    #endif
}
