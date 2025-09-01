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
    dependencies: [
        // Add dependencies for testing and build automation
        .package(url: "https://github.com/apple/swift-testing", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "AcoustiScanConsolidated",
            dependencies: [],
            path: "Sources/AcoustiScanConsolidated"
        ),
        .executableTarget(
            name: "AcoustiScanTool",
            dependencies: ["AcoustiScanConsolidated"],
            path: "Sources/AcoustiScanTool"
        ),
        .testTarget(
            name: "AcoustiScanConsolidatedTests",
            dependencies: [
                "AcoustiScanConsolidated",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/AcoustiScanConsolidatedTests"
        )
    ]
)