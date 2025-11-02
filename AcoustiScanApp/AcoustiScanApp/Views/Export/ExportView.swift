import SwiftUI

struct ExportView: View {
    @ObservedObject var store: SurfaceStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Datenexport")
                .font(.title2)
                .padding(.top)

            NavigationLink(destination: PDFExportView(store: store)) {
                Label("RT60-Bericht als PDF exportieren", systemImage: "doc.richtext")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Export")
    }
}
