// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AcoustiScanApp",
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
        .package(path: "../AcoustiScanConsolidated")
    ],
    targets: [
        .target(
            name: "AcoustiScanApp",
            dependencies: [
                .product(name: "AcoustiScanConsolidated", package: "AcoustiScanConsolidated")
            ],
            path: "AcoustiScanApp"
        ),
        .testTarget(
            name: "AcoustiScanAppTests",
            dependencies: ["AcoustiScanApp"],
            path: "AcoustiScanAppTests"
        )
    ]
)
