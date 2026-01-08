//
//  PDFChartRenderer.swift
//  AcoustiScanApp
//
//  Chart rendering component for PDF exports
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// Renders RT60 charts for PDF reports
public struct PDFChartRenderer {

    // MARK: - Public Methods

    /// Draws an RT60 frequency response chart
    /// - Parameters:
    ///   - rect: Rectangle to draw the chart in
    ///   - rt60Values: RT60 measurements by frequency
    ///   - dinTargets: DIN 18041 target values by frequency
    public static func drawRT60Chart(
        in rect: CGRect,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        // Draw chart background
        drawChartBackground(in: rect)

        // Define chart parameters
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        let minRT60 = 0.0
        let maxRT60 = 2.0

        // Draw grid
        drawGrid(in: rect, horizontalLines: 4)

        // Draw axes labels
        drawFrequencyLabels(in: rect, frequencies: frequencies)
        drawYAxisLabels(in: rect, minValue: minRT60, maxValue: maxRT60)

        // Draw target line
        if let firstTarget = dinTargets.values.first {
            drawTargetLine(
                in: rect,
                targetValue: firstTarget.target,
                minValue: minRT60,
                maxValue: maxRT60
            )
        }

        // Draw RT60 measurement line
        drawRT60Line(
            in: rect,
            rt60Values: rt60Values,
            frequencies: frequencies,
            minValue: minRT60,
            maxValue: maxRT60
        )
    }

    // MARK: - Private Drawing Methods

    /// Draws the chart background and border
    private static func drawChartBackground(in rect: CGRect) {
        // White background
        UIColor.white.setFill()
        UIBezierPath(rect: rect).fill()

        // Border
        PDFDrawingHelpers.drawBorder(around: rect, color: PDFStyleConfiguration.Colors.border)
    }

    /// Draws horizontal grid lines
    private static func drawGrid(in rect: CGRect, horizontalLines: Int) {
        PDFDrawingHelpers.drawHorizontalGrid(
            in: rect,
            lineCount: horizontalLines,
            color: PDFStyleConfiguration.Colors.gridLine,
            lineWidth: PDFStyleConfiguration.Dimensions.gridLineWidth
        )
    }

    /// Draws frequency labels on the X-axis
    private static func drawFrequencyLabels(in rect: CGRect, frequencies: [Int]) {
        let labelAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tiny,
            color: PDFStyleConfiguration.Colors.textSecondary
        )

        for (index, freq) in frequencies.enumerated() {
            let x = PDFDrawingHelpers.xPosition(for: index, totalCount: frequencies.count, in: rect)
            let label = "\(freq)"
            let size = (label as NSString).size(withAttributes: labelAttrs)
            label.draw(
                at: CGPoint(x: x - size.width / 2, y: rect.maxY + 5),
                withAttributes: labelAttrs
            )
        }
    }

    /// Draws Y-axis labels with RT60 values
    private static func drawYAxisLabels(in rect: CGRect, minValue: Double, maxValue: Double) {
        let labelAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tiny,
            color: PDFStyleConfiguration.Colors.textSecondary
        )

        for i in 0...4 {
            let value = minValue + (maxValue - minValue) * Double(4 - i) / 4.0
            let y = rect.minY + (rect.height / 4) * CGFloat(i)
            let label = String(format: "%.1f s", value)
            label.draw(
                at: CGPoint(x: rect.minX - 35, y: y - 6),
                withAttributes: labelAttrs
            )
        }
    }

    /// Draws the DIN target line
    private static func drawTargetLine(
        in rect: CGRect,
        targetValue: Double,
        minValue: Double,
        maxValue: Double
    ) {
        let y = PDFDrawingHelpers.normalizeToY(
            value: targetValue,
            minValue: minValue,
            maxValue: maxValue,
            in: rect
        )

        PDFDrawingHelpers.drawHorizontalLine(
            y: y,
            from: rect.minX,
            to: rect.maxX,
            color: PDFStyleConfiguration.Colors.success,
            lineWidth: PDFStyleConfiguration.Dimensions.targetLineWidth,
            dashPattern: [5, 3]
        )
    }

    /// Draws the RT60 measurement line with data points
    private static func drawRT60Line(
        in rect: CGRect,
        rt60Values: [Int: Double],
        frequencies: [Int],
        minValue: Double,
        maxValue: Double
    ) {
        guard !rt60Values.isEmpty else { return }

        let path = UIBezierPath()
        var first = true

        // Build path and draw data points
        for (index, freq) in frequencies.enumerated() {
            guard let rt60 = rt60Values[freq] else { continue }

            let x = PDFDrawingHelpers.xPosition(for: index, totalCount: frequencies.count, in: rect)
            let y = PDFDrawingHelpers.normalizeToY(
                value: rt60,
                minValue: minValue,
                maxValue: maxValue,
                in: rect
            )

            if first {
                path.move(to: CGPoint(x: x, y: y))
                first = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            // Draw data point
            PDFDrawingHelpers.drawDataPoint(
                at: CGPoint(x: x, y: y),
                color: PDFStyleConfiguration.Colors.primary
            )
        }

        // Draw the line
        PDFStyleConfiguration.Colors.primary.setStroke()
        path.lineWidth = PDFStyleConfiguration.Dimensions.chartLineWidth
        path.stroke()
    }
}
#endif
