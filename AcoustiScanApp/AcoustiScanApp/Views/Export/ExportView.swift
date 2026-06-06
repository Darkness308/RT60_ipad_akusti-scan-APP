import SwiftUI
import AcoustiScanConsolidated

struct ExportView: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        VStack(spacing: 20) {
            Text(LocalizationKeys.dataExport.localized(comment: "Data export title"))
                .font(.title2)
                .padding(.top)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("exportTitle")

            NavigationLink(destination: PDFReportExportView(store: store)) {
                Label(
                    LocalizationKeys.exportRT60AsPDF
                        .localized(comment: "Export RT60 report as PDF"),
                    systemImage: "doc.richtext"
                )
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

/// Real PDF report export: builds `ReportData` from the room state and renders it
/// with the norm-faithful `ConsolidatedPDFExporter` (RT60 = Sabine calculation,
/// DIN 18041 evaluation), then shares the resulting PDF.
struct PDFReportExportView: View {
    @ObservedObject var store: SurfaceStore
    @AppStorage("din.roomType") private var roomTypeRaw: String = RoomType.a3Education.rawValue

    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var errorMessage: String?

    private var roomType: RoomType { RoomType(rawValue: roomTypeRaw) ?? .a3Education }

    var body: some View {
        List {
            Section(
                header: Text("Bericht"),
                footer: Text("Erzeugt ein PDF-Gutachten: RT60 nach Sabine berechnet (keine Messung), DIN-18041-Bewertung der Gruppe \(roomType.groupLabel).")
            ) {
                LabeledContent("Raum", value: store.roomName)
                LabeledContent("Volumen", value: String(format: "%.1f m³", store.roomVolume))
                LabeledContent("DIN-Gruppe", value: roomType.displayName)
                LabeledContent("Flächen", value: "\(store.surfaces.count)")
            }

            Section {
                Button {
                    generate()
                } label: {
                    Label("PDF erzeugen & teilen", systemImage: "square.and.arrow.up")
                }
                .disabled(store.roomVolume <= 0)
                .accessibilityIdentifier("generatePDFButton")

                if store.roomVolume <= 0 {
                    Text("Kein Raumvolumen – erst Maße eingeben oder scannen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("exportError")
                }
            }
        }
        .navigationTitle("PDF-Export")
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }

    private func generate() {
        errorMessage = nil
        let data = ReportBuilder.makeReportData(store: store, roomType: roomType)
        guard let pdf = ConsolidatedPDFExporter.generateReport(data: data) else {
            errorMessage = "PDF konnte nicht erzeugt werden."
            return
        }
        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("AcoustiScan-Report.pdf")
            try pdf.write(to: url)
            shareURL = url
            showShare = true
        } catch {
            errorMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
