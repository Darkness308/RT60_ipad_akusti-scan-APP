// PDFTextExtractor.swift
// Helper functions for extracting text from PDF data in tests

import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// Helper functions for PDF text extraction in tests
public struct PDFTextExtractor {
    
    /// Extract text content from PDF data for testing
    public static func extractText(from pdfData: Data) -> String {
        #if canImport(PDFKit)
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return ""
        }
        
        var text = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                text += page.string ?? ""
                text += "\n"
            }
        }
        return text
        #else
        // Fallback for platforms without PDFKit
        // Look for common PDF text markers
        let pdfString = String(data: pdfData, encoding: .ascii) ?? ""
        
        // Extract text between BT and ET markers (simplified PDF text extraction)
        var extractedText = ""
        let components = pdfString.components(separatedBy: "BT")
        for component in components {
            if let endIndex = component.range(of: "ET")?.lowerBound {
                let textPortion = String(component[..<endIndex])
                // Very basic text extraction - look for text in parentheses
                let matches = textPortion.components(separatedBy: "(")
                for match in matches {
                    if let closeIndex = match.range(of: ")")?.lowerBound {
                        let text = String(match[..<closeIndex])
                        extractedText += text + " "
                    }
                }
            }
        }
        
        return extractedText
        #endif
    }
}