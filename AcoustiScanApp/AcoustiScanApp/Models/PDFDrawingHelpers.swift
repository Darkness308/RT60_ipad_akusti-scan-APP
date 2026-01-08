//
//  PDFDrawingHelpers.swift
//  AcoustiScanApp
//
//  Common PDF drawing utilities and helpers
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// Helper utilities for drawing common PDF elements
public struct PDFDrawingHelpers {

    // MARK: - Shapes

    /// Draws a rounded rectangle with optional fill and stroke
    public static func drawRoundedBox(
        in rect: CGRect,
        cornerRadius: CGFloat = PDFStyleConfiguration.Dimensions.cornerRadius,
        fillColor: UIColor? = nil,
        strokeColor: UIColor? = nil,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.borderWidth
    ) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }

        if let strokeColor = strokeColor {
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    /// Draws a circle with optional fill and stroke
    public static func drawCircle(
        center: CGPoint,
        radius: CGFloat,
        fillColor: UIColor? = nil,
        strokeColor: UIColor? = nil,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.borderWidth
    ) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let path = UIBezierPath(ovalIn: rect)

        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }

        if let strokeColor = strokeColor {
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    /// Draws a filled circle in a rectangle
    public static func drawCircleInRect(
        _ rect: CGRect,
        fillColor: UIColor? = nil,
        strokeColor: UIColor? = nil,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.borderWidth
    ) {
        let path = UIBezierPath(ovalIn: rect)

        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }

        if let strokeColor = strokeColor {
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    // MARK: - Lines

    /// Draws a straight line from point to point
    public static func drawLine(
        from start: CGPoint,
        to end: CGPoint,
        color: UIColor,
        lineWidth: CGFloat = 1,
        dashPattern: [CGFloat]? = nil
    ) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)

        color.setStroke()
        path.lineWidth = lineWidth

        if let pattern = dashPattern {
            path.setLineDash(pattern, count: pattern.count, phase: 0)
        }

        path.stroke()
    }

    /// Draws a horizontal line across a width
    public static func drawHorizontalLine(
        y: CGFloat,
        from startX: CGFloat,
        to endX: CGFloat,
        color: UIColor,
        lineWidth: CGFloat = 1,
        dashPattern: [CGFloat]? = nil
    ) {
        drawLine(
            from: CGPoint(x: startX, y: y),
            to: CGPoint(x: endX, y: y),
            color: color,
            lineWidth: lineWidth,
            dashPattern: dashPattern
        )
    }

    /// Draws a vertical line along a height
    public static func drawVerticalLine(
        x: CGFloat,
        from startY: CGFloat,
        to endY: CGFloat,
        color: UIColor,
        lineWidth: CGFloat = 1,
        dashPattern: [CGFloat]? = nil
    ) {
        drawLine(
            from: CGPoint(x: x, y: startY),
            to: CGPoint(x: x, y: endY),
            color: color,
            lineWidth: lineWidth,
            dashPattern: dashPattern
        )
    }

    // MARK: - Grid

    /// Draws horizontal grid lines
    public static func drawHorizontalGrid(
        in rect: CGRect,
        lineCount: Int,
        color: UIColor = PDFStyleConfiguration.Colors.gridLine,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.gridLineWidth
    ) {
        guard lineCount > 0 else { return }

        color.setStroke()
        for i in 0...lineCount {
            let y = rect.minY + (rect.height / CGFloat(lineCount)) * CGFloat(i)
            drawHorizontalLine(
                y: y,
                from: rect.minX,
                to: rect.maxX,
                color: color,
                lineWidth: lineWidth
            )
        }
    }

    /// Draws vertical grid lines
    public static func drawVerticalGrid(
        in rect: CGRect,
        lineCount: Int,
        color: UIColor = PDFStyleConfiguration.Colors.gridLine,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.gridLineWidth
    ) {
        guard lineCount > 0 else { return }

        color.setStroke()
        for i in 0...lineCount {
            let x = rect.minX + (rect.width / CGFloat(lineCount)) * CGFloat(i)
            drawVerticalLine(
                x: x,
                from: rect.minY,
                to: rect.maxY,
                color: color,
                lineWidth: lineWidth
            )
        }
    }

    // MARK: - Text

    /// Draws centered text in a rectangle
    public static func drawCenteredText(
        _ text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let size = (text as NSString).size(withAttributes: attributes)
        let x = rect.midX - size.width / 2
        let y = rect.midY - size.height / 2
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
    }

    /// Draws text centered horizontally in a rectangle
    public static func drawHorizontallyCenteredText(
        _ text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let size = (text as NSString).size(withAttributes: attributes)
        let x = rect.midX - size.width / 2
        text.draw(at: CGPoint(x: x, y: rect.minY), withAttributes: attributes)
    }

    /// Draws text at a specific point
    public static func drawText(
        _ text: String,
        at point: CGPoint,
        attributes: [NSAttributedString.Key: Any]
    ) {
        text.draw(at: point, withAttributes: attributes)
    }

    /// Draws text in a specific rectangle with wrapping
    public static func drawMultilineText(
        _ text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        text.draw(in: rect, withAttributes: attributes)
    }

    // MARK: - Borders

    /// Draws a border around a rectangle
    public static func drawBorder(
        around rect: CGRect,
        color: UIColor = PDFStyleConfiguration.Colors.border,
        lineWidth: CGFloat = PDFStyleConfiguration.Dimensions.borderWidth
    ) {
        color.setStroke()
        let path = UIBezierPath(rect: rect)
        path.lineWidth = lineWidth
        path.stroke()
    }

    // MARK: - Chart Helpers

    /// Normalizes a value to a Y coordinate in a chart rect
    public static func normalizeToY(
        value: Double,
        minValue: Double,
        maxValue: Double,
        in rect: CGRect
    ) -> CGFloat {
        let normalizedValue = CGFloat((value - minValue) / (maxValue - minValue))
        return rect.maxY - (rect.height * normalizedValue)
    }

    /// Calculates X position for an index in a series
    public static func xPosition(
        for index: Int,
        totalCount: Int,
        in rect: CGRect
    ) -> CGFloat {
        guard totalCount > 1 else { return rect.midX }
        return rect.minX + (rect.width / CGFloat(totalCount - 1)) * CGFloat(index)
    }

    /// Draws a data point circle
    public static func drawDataPoint(
        at point: CGPoint,
        color: UIColor,
        size: CGFloat = PDFStyleConfiguration.Dimensions.dataPointSize
    ) {
        let rect = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        drawCircleInRect(rect, fillColor: color)
    }
}
#endif
