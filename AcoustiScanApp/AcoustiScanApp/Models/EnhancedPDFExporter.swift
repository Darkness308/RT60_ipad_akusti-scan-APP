//
//  EnhancedPDFExporter.swift
//  AcoustiScanApp
//
//  Enhanced PDF Export with Charts, Traffic Light System, and Recommendations
//  Refactored to use modular components for better maintainability
//

import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#endif

/// Enhanced PDF Exporter for RT60 Reports with visual enhancements
/// This class acts as an orchestrator, delegating rendering to specialized components
public class EnhancedPDFExporter {

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

        let pageRect = PDFStyleConfiguration.PageLayout.pageRect
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            // Page 1: Cover and Summary
            context.beginPage()
            PDFPageRenderer.drawCoverPage(
                in: pageRect,
                roomName: roomName,
                volume: volume,
                date: Date()
            )

            // Page 2: RT60 Measurements with Chart
            context.beginPage()
            PDFPageRenderer.drawRT60MeasurementsPage(
                in: pageRect,
                rt60Values: rt60Values,
                dinTargets: dinTargets
            )

            // Page 3: DIN 18041 Classification with Traffic Lights
            context.beginPage()
            PDFPageRenderer.drawDINClassificationPage(
                in: pageRect,
                rt60Values: rt60Values,
                dinTargets: dinTargets
            )

            // Page 4: Materials Overview
            context.beginPage()
            PDFPageRenderer.drawMaterialsPage(
                in: pageRect,
                surfaces: surfaces,
                volume: volume
            )

            // Page 5: Recommendations and Action Plan
            context.beginPage()
            PDFPageRenderer.drawRecommendationsPage(
                context: context,
                in: pageRect,
                recommendations: recommendations
            )
        }
    }
    #endif
}
