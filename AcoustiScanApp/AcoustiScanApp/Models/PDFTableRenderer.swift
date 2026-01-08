//
//  PDFTableRenderer.swift
//  AcoustiScanApp
//
//  Table rendering component for PDF exports
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// Renders tables for PDF reports
public struct PDFTableRenderer {

    // MARK: - RT60 Table

    /// Draws RT60 measurements table with status indicators
    /// - Parameters:
    ///   - origin: Top-left corner of the table
    ///   - width: Total width of the table
    ///   - rt60Values: RT60 measurements by frequency
    ///   - dinTargets: DIN 18041 target values by frequency
    public static func drawRT60Table(
        at origin: CGPoint,
        width: CGFloat,
        rt60Values: [Int: Double],
        dinTargets: [Int: (target: Double, tolerance: Double)]
    ) {
        let frequencies = [125, 250, 500, 1000, 2000, 4000]
        let rowHeight = PDFStyleConfiguration.Dimensions.tableRowHeight
        let colWidth = width / 4

        // Define attributes
        let headerAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tableHeader,
            color: .white
        )
        let cellAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tableCell
        )

        var y = origin.y

        // Draw header row
        drawTableHeader(
            at: CGPoint(x: origin.x, y: y),
            width: width,
            height: rowHeight,
            columns: [
                NSLocalizedString(LocalizationKeys.frequency, comment: "Frequency label"),
                NSLocalizedString(LocalizationKeys.measured, comment: "Measured label"),
                NSLocalizedString(LocalizationKeys.target, comment: "Target label"),
                NSLocalizedString(LocalizationKeys.status, comment: "Status label")
            ],
            columnWidths: [colWidth, colWidth, colWidth, colWidth],
            attributes: headerAttrs
        )
        y += rowHeight

        // Draw data rows
        for (index, freq) in frequencies.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
                PDFStyleConfiguration.Colors.tableRowAlternate.setFill()
                UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
            }

            // Frequency
            "\(freq) Hz".draw(
                at: CGPoint(x: origin.x + 5, y: y + 8),
                withAttributes: cellAttrs
            )

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
                    let (statusText, statusColor) = getStatusIndicator(
                        measured: rt60,
                        target: target.target,
                        tolerance: target.tolerance
                    )

                    let statusAttrs = PDFStyleConfiguration.Typography.attributes(
                        for: PDFStyleConfiguration.Typography.statusBold,
                        color: statusColor
                    )
                    statusText.draw(
                        at: CGPoint(x: origin.x + 3 * colWidth + 5, y: y + 8),
                        withAttributes: statusAttrs
                    )
                }
            }

            y += rowHeight
        }

        // Table border
        let totalHeight = rowHeight * CGFloat(frequencies.count + 1)
        PDFDrawingHelpers.drawBorder(
            around: CGRect(x: origin.x, y: origin.y, width: width, height: totalHeight)
        )
    }

    // MARK: - Surfaces Table

    /// Draws room surfaces table with materials
    /// - Parameters:
    ///   - origin: Top-left corner of the table
    ///   - width: Total width of the table
    ///   - surfaces: List of surfaces with area and material
    public static func drawSurfacesTable(
        at origin: CGPoint,
        width: CGFloat,
        surfaces: [(name: String, area: Double, material: String)]
    ) {
        let rowHeight = PDFStyleConfiguration.Dimensions.surfaceTableRowHeight
        let col1Width = width * 0.4
        let col2Width = width * 0.3
        let col3Width = width * 0.3

        // Define attributes
        let headerAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tableHeader,
            color: .white
        )
        let cellAttrs = PDFStyleConfiguration.Typography.attributes(
            for: PDFStyleConfiguration.Typography.tableCell
        )

        var y = origin.y

        // Draw header row
        drawTableHeader(
            at: CGPoint(x: origin.x, y: y),
            width: width,
            height: rowHeight,
            columns: [
                NSLocalizedString(LocalizationKeys.surface, comment: "Surface label"),
                NSLocalizedString(LocalizationKeys.areaSquareMeters, comment: "Area square meters label"),
                NSLocalizedString(LocalizationKeys.material, comment: "Material label")
            ],
            columnWidths: [col1Width, col2Width, col3Width],
            attributes: headerAttrs
        )
        y += rowHeight

        // Draw data rows
        for (index, surface) in surfaces.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
                PDFStyleConfiguration.Colors.tableRowAlternate.setFill()
                UIBezierPath(rect: CGRect(x: origin.x, y: y, width: width, height: rowHeight)).fill()
            }

            // Surface name
            surface.name.draw(
                at: CGPoint(x: origin.x + 5, y: y + 10),
                withAttributes: cellAttrs
            )

            // Area
            String(format: "%.1f", surface.area).draw(
                at: CGPoint(x: origin.x + col1Width + 5, y: y + 10),
                withAttributes: cellAttrs
            )

            // Material
            surface.material.draw(
                at: CGPoint(x: origin.x + col1Width + col2Width + 5, y: y + 10),
                withAttributes: cellAttrs
            )

            y += rowHeight
        }

        // Table border
        let totalHeight = rowHeight * CGFloat(surfaces.count + 1)
        PDFDrawingHelpers.drawBorder(
            around: CGRect(x: origin.x, y: origin.y, width: width, height: totalHeight)
        )
    }

    // MARK: - Helper Methods

    /// Draws a table header row
    private static func drawTableHeader(
        at origin: CGPoint,
        width: CGFloat,
        height: CGFloat,
        columns: [String],
        columnWidths: [CGFloat],
        attributes: [NSAttributedString.Key: Any]
    ) {
        // Header background
        PDFStyleConfiguration.Colors.primary.setFill()
        UIBezierPath(rect: CGRect(x: origin.x, y: origin.y, width: width, height: height)).fill()

        // Header text
        var x = origin.x
        for (column, columnWidth) in zip(columns, columnWidths) {
            column.draw(
                at: CGPoint(x: x + 5, y: origin.y + 8),
                withAttributes: attributes
            )
            x += columnWidth
        }
    }

    /// Determines status indicator based on deviation from target
    private static func getStatusIndicator(
        measured: Double,
        target: Double,
        tolerance: Double
    ) -> (text: String, color: UIColor) {
        let deviation = abs(measured - target)

        if deviation <= tolerance {
            let statusOk = NSLocalizedString(LocalizationKeys.statusOk, comment: "Status OK")
            return (statusOk, PDFStyleConfiguration.Colors.success)
        } else if deviation <= tolerance * 1.5 {
            let statusTolerance = NSLocalizedString(
                LocalizationKeys.statusTolerance,
                comment: "Status tolerance"
            )
            return (statusTolerance, PDFStyleConfiguration.Colors.warning)
        } else {
            let statusCritical = NSLocalizedString(
                LocalizationKeys.statusCritical,
                comment: "Status critical"
            )
            return (statusCritical, PDFStyleConfiguration.Colors.critical)
        }
    }
}
#endif
