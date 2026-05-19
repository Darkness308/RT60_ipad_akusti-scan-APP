//
//  PDFPageRenderer.swift
//  AcoustiScanApp
//
//  Individual page rendering for PDF reports
//

import Foundation
#if canImport(UIKit)
import UIKit
import PDFKit
#endif

#if canImport(UIKit)
/// Renders individual pages for PDF reports
public struct PDFPageRenderer {

    // MARK: - Page 1: Cover Page

    /// Draws the cover page with room information
    /// - Parameters:
    ///   - pageRect: Page bounds
    ///   - roomName: Name of the room
    ///   - volume: Room volume in m3
    ///   - date: Report date
    public static func drawCoverPage(
        in pageRect: CGRect,
        roomName: String,
        volume: Double,
        date: Date
    ) {
        let margin = PDFStyleConfiguration.PageLayout.margin
        var y: CGFloat = 150

        // Title
        let titleAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.title
        )
        let title = NSLocalizedString(LocalizationKeys.acousticReport, comment: "Acoustic report title")
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)

        PDFDrawingHelpers.drawHorizontallyCenteredText(
            title,
            in: CGRect(x: 0, y: y, width: pageRect.width, height: titleSize.height),
            attributes: titleAttrs
        )
        y += titleSize.height + PDFStyleConfiguration.Spacing.title

        // Room Info Box
        let boxRect = CGRect(
            x: margin,
            y: y,
            width: pageRect.width - 2 * margin,
            height: 200
        )
        PDFDrawingHelpers.drawRoundedBox(
            in: boxRect,
            fillColor: PDFStyleConfiguration.Colors.boxBackground
        )

        let infoAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.info,
            color: PDFStyleConfiguration.Colors.textSecondary
        )

        y += PDFStyleConfiguration.Spacing.xl
        "Raum: \(roomName)".draw(
            at: CGPoint(x: margin + 20, y: y),
            withAttributes: infoAttrs
        )
        y += 35
        "Volumen: \(String(format: "%.1f", volume)) m3".draw(
            at: CGPoint(x: margin + 20, y: y),
            withAttributes: infoAttrs
        )
        y += 35

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "de_DE")
        "Datum: \(dateFormatter.string(from: date))".draw(
            at: CGPoint(x: margin + 20, y: y),
            withAttributes: infoAttrs
        )

        // Footer
        let footerAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.small,
            color: PDFStyleConfiguration.Colors.textTertiary
        )
        NSLocalizedString(LocalizationKeys.dinStandard, comment: "DIN standard text").draw(
            at: CGPoint(x: margin, y: pageRect.height - 50),
            withAttributes: footerAttrs
        )
    }

    // MARK: - Page 2: RT60 Measurements

    /// Draws RT60 measurements page with chart and table
    /// - Parameters:
    ///   - pageRect: Page bounds
    ///   - rt60Values: RT60 measurements by frequency
    ///   - dinTargets: DIN 18041 target values by frequency
    public static func drawRT60MeasurementsPage(
        in pageRect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let margin = PDFStyleConfiguration.PageLayout.margin
        var y: CGFloat = margin

        // Page title
        let titleAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.pageTitle
        )
        let rt60Title = NSLocalizedString(
            LocalizationKeys.rt60Measurements,
            comment: "RT60 measurements title"
        )
        rt60Title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += PDFStyleConfiguration.Spacing.section

        // Draw chart
        let chartRect = CGRect(
            x: margin,
            y: y,
            width: pageRect.width - 2 * margin,
            height: 250
        )
        PDFChartRenderer.drawRT60Chart(
            in: chartRect,
            rt60Values: rt60Values,
            dinTargets: dinTargets
        )
        y += 270

        // Table of values
        PDFTableRenderer.drawRT60Table(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            rt60Values: rt60Values,
            dinTargets: dinTargets
        )
    }

    // MARK: - Page 3: DIN Classification

    /// Draws DIN 18041 classification page with traffic lights
    /// - Parameters:
    ///   - pageRect: Page bounds
    ///   - rt60Values: RT60 measurements by frequency
    ///   - dinTargets: DIN 18041 target values by frequency
    public static func drawDINClassificationPage(
        in pageRect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let margin = PDFStyleConfiguration.PageLayout.margin
        var y: CGFloat = margin

        // Page title
        let titleAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.pageTitle
        )
        let dinTitle = NSLocalizedString(
            LocalizationKeys.dinClassification,
            comment: "DIN 18041 classification title"
        )
        dinTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += PDFStyleConfiguration.Spacing.section

        // Calculate compliance
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        let compliance = calculateCompliance(
            rt60Values: rt60Values,
            dinTargets: dinTargets,
            frequencies: frequencies
        )

        // Overall status box
        drawStatusBox(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            compliance: compliance
        )
        y += 120

        // Traffic light visualization
        drawTrafficLights(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            compliance: compliance,
            total: frequencies.count
        )
    }

    // MARK: - Page 4: Materials

    /// Draws materials overview page
    /// - Parameters:
    ///   - pageRect: Page bounds
    ///   - surfaces: Room surfaces with materials
    ///   - volume: Room volume in m3
    public static func drawMaterialsPage(
        in pageRect: CGRect,
        surfaces: [(name: String, area: Double, material: String)],
        volume: Double
    ) {
        let margin = PDFStyleConfiguration.PageLayout.margin
        var y: CGFloat = margin

        // Page title
        let titleAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.pageTitle
        )
        let materialTitle = NSLocalizedString(
            LocalizationKeys.materialOverview,
            comment: "Material overview title"
        )
        materialTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += PDFStyleConfiguration.Spacing.section

        // Room volume
        let infoAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.body,
            color: PDFStyleConfiguration.Colors.textSecondary
        )
        let volumeLabel = NSLocalizedString(
            LocalizationKeys.roomVolume,
            comment: "Room volume label"
        )
        let volumeText = "\(volumeLabel): \(String(format: "%.1f", volume)) m3"
        volumeText.draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
        y += PDFStyleConfiguration.Spacing.xl

        // Total area
        let totalArea = surfaces.reduce(0) { $0 + $1.area }
        let areaLabel = NSLocalizedString(
            LocalizationKeys.totalArea,
            comment: "Total area label"
        )
        let areaText = "\(areaLabel): \(String(format: "%.1f", totalArea)) m^2"
        areaText.draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
        y += PDFStyleConfiguration.Spacing.xxl

        // Draw surfaces table
        PDFTableRenderer.drawSurfacesTable(
            at: CGPoint(x: margin, y: y),
            width: pageRect.width - 2 * margin,
            surfaces: surfaces
        )
    }

    // MARK: - Page 5: Recommendations

    /// Draws recommendations and action plan page
    /// - Parameters:
    ///   - context: PDF rendering context
    ///   - pageRect: Page bounds
    ///   - recommendations: List of recommendations
    public static func drawRecommendationsPage(
        context: UIGraphicsPDFRendererContext,
        in pageRect: CGRect,
        recommendations: [String]
    ) {
        let margin = PDFStyleConfiguration.PageLayout.margin
        var y: CGFloat = margin

        // Page title
        let titleAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.pageTitle
        )
        let recommendationsTitle = NSLocalizedString(
            LocalizationKeys.recommendationsTitle,
            comment: "Recommendations title"
        )
        recommendationsTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += PDFStyleConfiguration.Spacing.section

        // Intro text
        let introAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.body,
            color: PDFStyleConfiguration.Colors.textSecondary
        )
        let introText = NSLocalizedString(LocalizationKeys.recommendationsIntro, comment: "Recommendations intro text")
        introText.draw(at: CGPoint(x: margin, y: y), withAttributes: introAttrs)
        y += PDFStyleConfiguration.Spacing.xxl

        // Recommendations list
        let circleSize = PDFStyleConfiguration.Dimensions.recommendationCircleSize

        for (index, recommendation) in recommendations.enumerated() {
            // Number circle
            let circleRect = CGRect(x: margin, y: y, width: circleSize, height: circleSize)
            PDFDrawingHelpers.drawCircleInRect(
                circleRect,
                fillColor: PDFStyleConfiguration.Colors.primary
            )

            // Number
            let numAttrs = PDFStyleConfiguration.Typography.attributes(
                for: PDFStyleConfiguration.Typography.recommendationNumber,
                color: .white
            )
            let numStr = "\(index + 1)"
            PDFDrawingHelpers.drawCenteredText(numStr, in: circleRect, attributes: numAttrs)

            // Recommendation text
            let textRect = CGRect(
                x: margin + circleSize + 15,
                y: y,
                width: pageRect.width - 2 * margin - circleSize - 15,
                height: 100
            )

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = 4

            let recAttrs: [NSAttributedString.Key: Any] = [
                .font: PDFStyleConfiguration.Typography.body,
                .paragraphStyle: paraStyle
            ]

            (recommendation as NSString).draw(in: textRect, withAttributes: recAttrs)

            let textHeight = (recommendation as NSString).boundingRect(
                with: CGSize(width: textRect.width, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: recAttrs,
                context: nil
            ).height

            y += max(circleSize, textHeight) + 25

            // Add page break if needed
            if y > pageRect.height - PDFStyleConfiguration.PageLayout.pageBreakThreshold
                && index < recommendations.count - 1 {
                context.beginPage()
                y = PDFStyleConfiguration.PageLayout.margin
            }
        }
    }

    // MARK: - Helper Methods

    /// Calculates compliance statistics
    private static func calculateCompliance(
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)],
        frequencies: [Int]
    ) -> (compliant: Int, warning: Int, critical: Int) {
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

        return (compliantCount, warningCount, criticalCount)
    }

    /// Draws the overall status box
    private static func drawStatusBox(
        at origin: CGPoint,
        width: CGFloat,
        compliance: (compliant: Int, warning: Int, critical: Int)
    ) {
        let (overallStatus, overallColor) = getOverallStatus(compliance: compliance)

        // Status box
        let statusBox = CGRect(x: origin.x, y: origin.y, width: width, height: 100)
        PDFDrawingHelpers.drawRoundedBox(
            in: statusBox,
            fillColor: overallColor.withAlphaComponent(0.2)
        )

        let statusAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.largeStatus,
            color: overallColor
        )
        overallStatus.draw(
            at: CGPoint(x: origin.x + 20, y: origin.y + 35),
            withAttributes: statusAttrs
        )
    }

    /// Gets overall status based on compliance
    private static func getOverallStatus(
        compliance: (compliant: Int, warning: Int, critical: Int)
    ) -> (status: String, color: UIColor) {
        if compliance.critical > 0 {
            let criticalText = NSLocalizedString(
                LocalizationKeys.criticalActionRequired,
                comment: "Critical action required"
            )
            return (criticalText, PDFStyleConfiguration.Colors.critical)
        } else if compliance.warning > 0 {
            let warningText = NSLocalizedString(
                LocalizationKeys.partiallyCompliant,
                comment: "Partially compliant"
            )
            return (warningText, PDFStyleConfiguration.Colors.warning)
        } else {
            let successText = NSLocalizedString(
                LocalizationKeys.conformDIN,
                comment: "Conform to DIN"
            )
            return (successText, PDFStyleConfiguration.Colors.success)
        }
    }

    /// Draws traffic light visualization
    private static func drawTrafficLights(
        at origin: CGPoint,
        width: CGFloat,
        compliance: (compliant: Int, warning: Int, critical: Int),
        total: Int
    ) {
        let boxWidth = width / 3 - 20
        let boxHeight = PDFStyleConfiguration.Dimensions.trafficLightBoxHeight

        let compliantLabel = NSLocalizedString(LocalizationKeys.compliant, comment: "Compliant")
        let warningLabel = NSLocalizedString(LocalizationKeys.warning, comment: "Warning")
        let criticalLabel = NSLocalizedString(LocalizationKeys.critical, comment: "Critical")

        let data = [
            (compliantLabel, compliance.compliant, PDFStyleConfiguration.Colors.success),
            (warningLabel, compliance.warning, PDFStyleConfiguration.Colors.warning),
            (criticalLabel, compliance.critical, PDFStyleConfiguration.Colors.critical)
        ]

        for (index, (label, count, color)) in data.enumerated() {
            let x = origin.x + CGFloat(index) * (boxWidth + 30)

            // Box background
            let box = CGRect(x: x, y: origin.y, width: boxWidth, height: boxHeight)
            PDFDrawingHelpers.drawRoundedBox(in: box, fillColor: color.withAlphaComponent(0.2))

            // Circle (traffic light)
            let circleSize = PDFStyleConfiguration.Dimensions.trafficLightCircleSize
            let circleY = origin.y + 30
            let circleRect = CGRect(
                x: x + (boxWidth - circleSize) / 2,
                y: circleY,
                width: circleSize,
                height: circleSize
            )
            PDFDrawingHelpers.drawCircleInRect(circleRect, fillColor: color)

            // Count
            let countAttrs = PDFStyleConfiguration.Typography.attributes(
                for: PDFStyleConfiguration.Typography.trafficLightCount,
                color: .white
            )
            PDFDrawingHelpers.drawCenteredText("\(count)", in: circleRect, attributes: countAttrs)

            // Label
            let labelAttrs = PDFStyleConfiguration.Typography.attributes(
                for: PDFStyleConfiguration.Typography.body,
                color: PDFStyleConfiguration.Colors.textSecondary
            )
            let labelY = origin.y + boxHeight - 30
            let labelRect = CGRect(x: x, y: labelY, width: boxWidth, height: 30)
            PDFDrawingHelpers.drawHorizontallyCenteredText(label, in: labelRect, attributes: labelAttrs)
        }
    }
}
#endif
