import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Centralized styling configuration for PDF exports
public struct PDFStyleConfiguration {

    #if canImport(CoreGraphics)
    // MARK: - Page Layout

    #if canImport(UIKit) || canImport(AppKit)
    public struct PageLayout {
        /// A4 page dimensions in points (72 points per inch)
        public static let a4Width: CGFloat = 595.2  // 210mm
        public static let a4Height: CGFloat = 841.8 // 297mm

        /// Standard margin (1 inch)
        public static let margin: CGFloat = 72

        public static var pageRect: CGRect {
            return CGRect(x: 0, y: 0, width: self.a4Width, height: self.a4Height)
        }

        public static var contentWidth: CGFloat {
            self.a4Width - (2 * self.margin)
        }
    }
    #endif

    // MARK: - Typography

    #if canImport(UIKit)
    public struct Typography {
        /// Main title font (24pt, bold)
        public static let title: UIFont = .boldSystemFont(ofSize: 24)

        /// Section headers (18pt, bold)
        public static let sectionHeader: UIFont = .boldSystemFont(ofSize: 18)

        /// Regular body text (12pt)
        public static let body: UIFont = .systemFont(ofSize: 12)

        /// Creates text attributes for a given font and color
        public static func attributes(for font: UIFont, color: UIColor = .black) -> [NSAttributedString.Key: Any] {
            [
                .font: font,
                .foregroundColor: color
            ]
        }
    }
    #endif

    #if canImport(CoreGraphics)
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
    }
    #endif
    #endif
}
