//
//  PDFStyleConfiguration.swift
//  AcoustiScanApp
//
//  PDF Styling Configuration - Colors, Fonts, Spacing
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Centralized styling configuration for PDF exports
public struct PDFStyleConfiguration {

    // MARK: - Page Layout

    public struct PageLayout {
        /// A4 page dimensions in points (72 points per inch)
        public static let a4Width: CGFloat = 595.2  // 210mm
        public static let a4Height: CGFloat = 841.8 // 297mm

        /// Standard margin (1 inch)
        public static let margin: CGFloat = 72

        /// Space needed before page break
        public static let pageBreakThreshold: CGFloat = 100

        public static var pageRect: CGRect {
            CGRect(x: 0, y: 0, width: a4Width, height: a4Height)
        }

        public static var contentWidth: CGFloat {
            a4Width - (2 * margin)
        }
    }

    // MARK: - Typography

    #if canImport(UIKit)
    public struct Typography {
        /// Main title font (36pt, bold)
        public static let title: UIFont = .systemFont(ofSize: 36, weight: .bold)

        /// Page section headers (24pt, bold)
        public static let pageTitle: UIFont = .boldSystemFont(ofSize: 24)

        /// Section headers (18pt, bold)
        public static let sectionHeader: UIFont = .boldSystemFont(ofSize: 18)

        /// Regular body text (13pt)
        public static let body: UIFont = .systemFont(ofSize: 13)

        /// Info text (18pt)
        public static let info: UIFont = .systemFont(ofSize: 18)

        /// Small text for labels and captions (12pt)
        public static let small: UIFont = .systemFont(ofSize: 12)

        /// Tiny text for chart labels (10pt)
        public static let tiny: UIFont = .systemFont(ofSize: 10)

        /// Table header text (12pt, bold)
        public static let tableHeader: UIFont = .boldSystemFont(ofSize: 12)

        /// Table cell text (11pt)
        public static let tableCell: UIFont = .systemFont(ofSize: 11)

        /// Status text (11pt, bold)
        public static let statusBold: UIFont = .boldSystemFont(ofSize: 11)

        /// Recommendation number (14pt, bold)
        public static let recommendationNumber: UIFont = .boldSystemFont(ofSize: 14)

        /// Large status text (20pt, bold)
        public static let largeStatus: UIFont = .boldSystemFont(ofSize: 20)

        /// Traffic light count (28pt, bold)
        public static let trafficLightCount: UIFont = .boldSystemFont(ofSize: 28)

        /// Regular text with attributes
        public static func attributes(for font: UIFont, color: UIColor = .black) -> [NSAttributedString.Key: Any] {
            [
                .font: font,
                .foregroundColor: color
            ]
        }
    }

    // MARK: - Colors

    public struct Colors {
        /// Primary brand color
        public static let primary: UIColor = .systemBlue

        /// Success/compliant color
        public static let success: UIColor = .systemGreen

        /// Warning color
        public static let warning: UIColor = .systemOrange

        /// Critical/error color
        public static let critical: UIColor = .systemRed

        /// Standard text color
        public static let text: UIColor = .black

        /// Secondary text color
        public static let textSecondary: UIColor = .darkGray

        /// Tertiary text color
        public static let textTertiary: UIColor = .gray

        /// Border color
        public static let border: UIColor = .lightGray

        /// Background for alternating table rows
        public static let tableRowAlternate: UIColor = .systemGray.withAlphaComponent(0.1)

        /// Highlight box background
        public static let boxBackground: UIColor = .systemBlue.withAlphaComponent(0.1)

        /// Grid lines
        public static let gridLine: UIColor = .lightGray.withAlphaComponent(0.3)
    }

    // MARK: - Spacing

    public struct Spacing {
        /// Extra small spacing (4pt)
        public static let xs: CGFloat = 4

        /// Small spacing (8pt)
        public static let sm: CGFloat = 8

        /// Medium spacing (12pt)
        public static let md: CGFloat = 12

        /// Large spacing (20pt)
        public static let lg: CGFloat = 20

        /// Extra large spacing (30pt)
        public static let xl: CGFloat = 30

        /// Huge spacing (40pt)
        public static let xxl: CGFloat = 40

        /// Section spacing (50pt)
        public static let section: CGFloat = 50

        /// Title spacing (60pt)
        public static let title: CGFloat = 60
    }

    // MARK: - Dimensions

    public struct Dimensions {
        /// Standard corner radius
        public static let cornerRadius: CGFloat = 12

        /// Standard border width
        public static let borderWidth: CGFloat = 1

        /// Chart line width
        public static let chartLineWidth: CGFloat = 2

        /// Target line width
        public static let targetLineWidth: CGFloat = 1.5

        /// Grid line width
        public static let gridLineWidth: CGFloat = 0.5

        /// Table row height
        public static let tableRowHeight: CGFloat = 30

        /// Surface table row height
        public static let surfaceTableRowHeight: CGFloat = 35

        /// Data point size
        public static let dataPointSize: CGFloat = 6

        /// Recommendation circle size
        public static let recommendationCircleSize: CGFloat = 28

        /// Traffic light circle size
        public static let trafficLightCircleSize: CGFloat = 60

        /// Traffic light box height
        public static let trafficLightBoxHeight: CGFloat = 150
    }
    #endif
}
