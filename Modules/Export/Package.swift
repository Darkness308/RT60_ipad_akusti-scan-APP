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
    dependencies: [],
    targets: [
        .target(
            name: "ReportExport",
            dependencies: [],
            path: "Sources/ReportExport",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("PDFKit", .when(platforms: [.iOS, .macOS]))
            ]
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