// swift-tools-version: 5.9
// Package.swift for AcoustiScan Consolidated Tool

import PackageDescription

let package = Package(
    name: "AcoustiScanConsolidated",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AcoustiScanConsolidated",
            targets: ["AcoustiScanConsolidated"]
        ),
        .executable(
            name: "AcoustiScanTool",
            targets: ["AcoustiScanTool"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AcoustiScanConsolidated",
            dependencies: [],
            path: "Sources/AcoustiScanConsolidated",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .executableTarget(
            name: "AcoustiScanTool",
            dependencies: ["AcoustiScanConsolidated"],
            path: "Sources/AcoustiScanTool"
        ),
        .testTarget(
            name: "AcoustiScanConsolidatedTests",
            dependencies: ["AcoustiScanConsolidated"],
            path: "Tests/AcoustiScanConsolidatedTests"
        )
    ]
)
