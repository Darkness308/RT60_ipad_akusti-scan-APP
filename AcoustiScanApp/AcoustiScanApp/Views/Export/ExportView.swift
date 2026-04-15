import SwiftUI

struct ExportView: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationKeys.dataExport.localized(comment: "Data export title"))
                .font(.title2)
                .padding(.top)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("exportTitle")

            NavigationLink(destination: PDFExportPlaceholderView(store: store)) {
                Label(LocalizationKeys.exportRT60AsPDF.localized(comment: "Export RT60 report as PDF"), systemImage: "doc.richtext")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .accessibilityLabel("Export RT60 as PDF")
            .accessibilityHint("Opens PDF export options for RT60 report")
            .accessibilityIdentifier("exportPDFButton")
            .accessibilityAddTraits(.isButton)

            Spacer()
        }
        .padding()
        .navigationTitle(LocalizationKeys.export.localized(comment: "Export navigation title"))
    }
}

// Placeholder view for PDF export until full integration with ReportExport module
struct PDFExportPlaceholderView: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .accessibilityLabel("PDF document icon")
                .accessibilityIdentifier("pdfIcon")

            Text(LocalizationKeys.pdfExport.localized(comment: "PDF Export title"))
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("pdfExportTitle")

            Text(LocalizationKeys.featureInIntegration.localized(comment: "Feature in integration message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityLabel("Feature in integration")
                .accessibilityIdentifier("integrationMessage")

            // Show basic room info
            VStack(alignment: .leading, spacing: 10) {
                Text("\(LocalizationKeys.room.localized(comment: "Room label")): \(store.roomName)")
                    .accessibilityLabel("Room name")
                    .accessibilityValue(store.roomName)
                    .accessibilityIdentifier("roomNameText")
                Text("\(LocalizationKeys.volume.localized(comment: "Volume label")): \(String(format: "%.1f m3", store.roomVolume))")
                    .accessibilityLabel("Room volume")
                    .accessibilityValue(String(format: "%.1f cubic meters", store.roomVolume))
                    .accessibilityIdentifier("roomVolumeText")
                Text("\(LocalizationKeys.surfaces.localized(comment: "Surfaces label")): \(store.surfaces.count)")
                    .accessibilityLabel("Number of surfaces")
                    .accessibilityValue("\(store.surfaces.count) surfaces")
                    .accessibilityIdentifier("surfacesCountText")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Room information summary")
            .accessibilityIdentifier("roomInfoGroup")

            Spacer()
        }
        .padding()
        .navigationTitle(LocalizationKeys.pdfExport.localized(comment: "PDF Export navigation title"))
    }
}
