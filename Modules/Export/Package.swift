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
            dependencies: ["ReportExport"],
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