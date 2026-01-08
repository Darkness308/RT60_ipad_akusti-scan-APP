import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// Simple text layout helper that automatically handles page breaks
public struct PDFTextLayout {
    let context: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    private(set) var yPosition: CGFloat

    public init(context: UIGraphicsPDFRendererContext, pageRect: CGRect, margin: CGFloat = 72) {
        self.context = context
        self.pageRect = pageRect
        self.margin = margin
        self.yPosition = margin
    }

    public var contentWidth: CGFloat {
        pageRect.width - 2 * margin
    }

    /// Draws a single line of text at the current position
    /// - Parameters:
    ///   - text: The text to draw
    ///   - attributes: Text attributes (font, color, etc.)
    ///   - spacing: Additional spacing after the line (default: 4pt)
    public mutating func drawLine(
        _ text: String,
        attributes: [NSAttributedString.Key: Any],
        spacing: CGFloat = 4
    ) {
        let font = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 12)
        let lineHeight = font.lineHeight
        ensureSpace(for: lineHeight)
        text.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
        yPosition += lineHeight + spacing
    }

    /// Draws multi-line text that wraps within the specified width
    /// - Parameters:
    ///   - text: The text to draw
    ///   - attributes: Text attributes (font, color, etc.)
    ///   - width: Maximum width for text wrapping
    ///   - spacing: Additional spacing after the text block (default: 8pt)
    public mutating func drawMultiline(
        _ text: String,
        attributes: [NSAttributedString.Key: Any],
        width: CGFloat,
        spacing: CGFloat = 8
    ) {
        guard !text.isEmpty else { return }
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let bounding = (text as NSString).boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: options,
            attributes: attributes,
            context: nil
        )
        let height = ceil(bounding.height)
        ensureSpace(for: height)
        let rect = CGRect(x: margin, y: yPosition, width: width, height: height)
        text.draw(in: rect, withAttributes: attributes)
        yPosition += height + spacing
    }

    /// Adds vertical spacing
    /// - Parameter spacing: Amount of spacing to add
    public mutating func addSpacing(_ spacing: CGFloat) {
        ensureSpace(for: spacing)
        yPosition += spacing
    }

    /// Ensures there's enough space on the current page, starts a new page if needed
    private mutating func ensureSpace(for height: CGFloat) {
        let maxY = pageRect.height - margin
        if yPosition + height > maxY {
            context.beginPage()
            yPosition = margin
        }
    }
}
#endif
