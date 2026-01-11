# HTML Renderer Integration Guide

## Overview

The HTML renderer and contract tests have been successfully implemented for the RT60 iPad acoustic scan app. This implementation provides:

- **ReportHTMLRenderer.swift**: Converts `ReportModel` to styled HTML
- **PDFReportRenderer.swift**: Unified PDF renderer using the same `ReportModel`
- **HTMLPreviewView.swift**: SwiftUI component for HTML preview (iOS/macOS only)
- **ReportContractTests.swift**: Tests ensuring PDF/HTML content equivalence

## Usage Example

```swift
import ReportExport

// Create a report model
let model = ReportModel(
    metadata: [
        "device": "iPadPro",
        "app_version": "1.0.0",
        "date": "2025-07-21",
        "room": "Klassenraum A"
    ],
    rt60_bands: [
        ["freq_hz": 125.0, "t20_s": 0.70],
        ["freq_hz": 250.0, "t20_s": 0.60],
        ["freq_hz": 500.0, "t20_s": nil] // Missing values shown as "-"
    ],
    din_targets: [
        ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20],
        ["freq_hz": 250.0, "t_soll": 0.60, "tol": 0.20]
    ],
    validity: ["method": "ISO3382-1", "bands": "octave"],
    recommendations: ["Wandabsorber ergänzen", "Deckenwolken prüfen"],
    audit: ["hash": "ABC123", "source": "measurement"]
)

// Generate HTML report
let htmlRenderer = ReportHTMLRenderer()
let htmlData = htmlRenderer.render(model)

// Generate PDF report (same model)
let pdfRenderer = PDFReportRenderer()
let pdfData = pdfRenderer.render(model)

// Save HTML to file
try htmlData.write(to: URL(fileURLWithPath: "report.html"))

// Display in SwiftUI (iOS/macOS only)
#if canImport(SwiftUI)
struct ReportView: View {
    var body: some View {
        HTMLPreviewView(htmlData: htmlData)
    }
}
#endif
```

## Testing

All contract tests pass, ensuring that PDF and HTML outputs contain the same core information:

```bash
cd Modules/Export
swift test
```

Test results:
- [x] Core tokens present in both outputs
- [x] Frequency labels match between PDF and HTML
- [x] DIN target values consistent
- [x] Missing values shown as "-" in both formats

## Integration with Existing Code

The new renderers use a unified `ReportModel` structure that can be easily populated from existing `ReportData` structures:

```swift
// Convert from existing ReportData to new ReportModel
func convertToReportModel(_ reportData: ReportData) -> ReportModel {
    return ReportModel(
        metadata: [
            "device": UIDevice.current.name,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "date": reportData.date,
            "room": reportData.roomType.displayName
        ],
        rt60_bands: reportData.rt60Measurements.map { measurement in
            ["freq_hz": Double(measurement.frequency), "t20_s": measurement.rt60]
        },
        din_targets: reportData.dinResults.map { deviation in
            ["freq_hz": Double(deviation.frequency), "t_soll": deviation.targetRT60, "tol": 0.1]
        },
        validity: ["method": "ISO3382-1"],
        recommendations: ["Based on DIN 18041 analysis"],
        audit: ["timestamp": ISO8601DateFormatter().string(from: Date())]
    )
}
```

## Features

### HTML Output
- Professional styling with CSS grid layout
- Responsive design for different screen sizes
- German language labels (Gerät, Metadaten, etc.)
- Structured sections: metadata, RT60 frequencies, DIN targets, recommendations, audit

### PDF Output
- Cross-platform compatibility (UIKit and non-UIKit)
- Same content structure as HTML
- Consistent German terminology
- Text-based fallback for non-UIKit platforms

### Contract Tests
- Verify content equivalence between PDF and HTML
- Test missing value handling (nil -> "-")
- Frequency and target value validation
- Token-based content comparison (case-insensitive)

This implementation follows the minimal change principle while providing a robust foundation for HTML reports and ensuring consistency with existing PDF functionality.
