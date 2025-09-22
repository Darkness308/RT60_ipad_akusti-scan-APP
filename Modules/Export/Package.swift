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
    targets: [
        .target(
            name: "ReportExport",
            dependencies: []
        ),
        .testTarget(
            name: "ReportExportTests",
copilot/fix-151d7a9d-31a9-451a-bc46-9ca33c7437e3
            dependencies: ["ReportExport"],
            path: "Tests",
            sources: [
                "ReportContractTests.swift",
                "ReportHTMLRendererTests.swift",
                "PDFReportSnapshotTests.swift"
            ]

            dependencies: ["ReportExport"]
main
        )
    ]
)