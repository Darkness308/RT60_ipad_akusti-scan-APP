// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReportExport",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ReportExport",
            targets: ["ReportExport"]
        )
    ],
    dependencies: [
        // Depend on AcoustiScanConsolidated for shared report models and renderers
        .package(path: "../../AcoustiScanConsolidated")
    ],
    targets: [
        .target(
            name: "ReportExport",
            dependencies: [
                .product(name: "AcoustiScanConsolidated", package: "AcoustiScanConsolidated")
            ]
        ),
        .testTarget(
            name: "ReportExportTests",
            dependencies: [
                "ReportExport",
                .product(name: "AcoustiScanConsolidated", package: "AcoustiScanConsolidated")
            ],
            path: "Tests",
            sources: [
                "ReportContractTests.swift",
                "ReportHTMLRendererTests.swift",
                "PDFReportSnapshotTests.swift",
                "PDFRobustnessTests.swift"
            ]
        )
    ]
)