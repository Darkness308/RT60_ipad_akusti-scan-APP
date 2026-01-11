#if canImport(SwiftUI) && canImport(PDFKit) && canImport(UIKit)
import SwiftUI
import PDFKit
import UIKit

public struct PDFExportView: View {
    @State private var isBusy = false
    @State private var pdfData: Data?

    public let reportModel: ReportModel

    public init(reportModel: ReportModel) { self.reportModel = reportModel }

    public var body: some View {
        VStack(spacing: 16) {
            if isBusy { ProgressView("Report wird erstellt …") }
            Button("Report generieren") {
                isBusy = true
                Task {
                    let data = PDFReportRenderer().render(reportModel)
                    await MainActor.run {
                        self.pdfData = data
                        self.isBusy = false
                    }
                }
            }
            if let data = pdfData {
                PDFKitView(data: data).frame(minHeight: 300)
                ShareLink(item: data, preview: .init("RT60_Report.pdf"))
            }
        }
        .padding()
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.document = PDFDocument(data: data)
        v.autoScales = true
        return v
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
#else
// Fallback for non-UIKit platforms
import Foundation

public struct PDFExportView {
    public let reportModel: ReportModel

    public init(reportModel: ReportModel) {
        self.reportModel = reportModel
    }

    /// Generate PDF data for non-UIKit platforms
    public func generatePDF() -> Data {
        return PDFReportRenderer().render(reportModel)
    }
}
#endif
