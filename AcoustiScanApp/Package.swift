// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AcoustiScanApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AcoustiScanApp",
            targets: ["AcoustiScanApp"]
        )
    ],
    dependencies: [
        .package(path: "../AcoustiScanConsolidated"),
        .package(name: "ReportExport", path: "../Modules/Export")
    ],
    targets: [
        .target(
            name: "AcoustiScanApp",
            dependencies: [
                .product(name: "AcoustiScanConsolidated", package: "AcoustiScanConsolidated"),
                .product(name: "ReportExport", package: "ReportExport")
            ],
            path: "AcoustiScanApp",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ],
            linkerSettings: [
                .linkedFramework("Charts", .when(platforms: [.iOS]))
            ]
        ),
        .testTarget(
            name: "AcoustiScanAppTests",
            dependencies: [
                "AcoustiScanApp",
                .product(name: "AcoustiScanConsolidated", package: "AcoustiScanConsolidated")
            ],
            path: "AcoustiScanAppTests"
        )
    ]
)
