// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AcoustiScan",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Main app target - commented out as this would typically be in an Xcode project
        // .executable(name: "AcoustiScan", targets: ["AcoustiScan"]),
        
        // Library products for modules
        .library(name: "AcousticEngine", targets: ["AcousticEngine"]),
        .library(name: "ScannerEngine", targets: ["ScannerEngine"]),
        .library(name: "DIN18041", targets: ["DIN18041"]),
        .library(name: "MaterialDatabase", targets: ["MaterialDatabase"]),
        .library(name: "ReportGenerator", targets: ["ReportGenerator"])
    ],
    dependencies: [
        // External dependencies could be added here
        // .package(url: "https://github.com/AudioKit/AudioKit", from: "5.0.0"),
        // .package(url: "https://github.com/kishikawakatsumi/SwiftXLSX", from: "0.14.0"),
    ],
    targets: [
        // Acoustic Engine Module
        .target(
            name: "AcousticEngine",
            dependencies: [],
            path: "Sources/AcousticEngine",
            sources: [
                "RT60Calculation.swift",
                "ImpulseResponseAnalyzer.swift"
            ]
        ),
        
        // Scanner Engine Module  
        .target(
            name: "ScannerEngine",
            dependencies: [],
            path: "Sources/ScannerEngine",
            sources: [
                "SurfaceDetection.swift",
                "ARCoordinator.swift",
                "LabeledSurface.swift"
            ]
        ),
        
        // DIN 18041 Standard Module
        .target(
            name: "DIN18041",
            dependencies: [],
            path: "Sources/DIN18041",
            sources: [
                "RT60Evaluator.swift",
                "RoomType.swift",
                "RT60Deviation.swift",
                "RT60Measurement.swift",
                "DIN18041Target.swift"
            ]
        ),
        
        // Material Database Module
        .target(
            name: "MaterialDatabase",
            dependencies: [],
            path: "Sources/MaterialDatabase",
            sources: [
                "MaterialDatabase.swift",
                "MaterialManager.swift",
                "AcousticMaterial.swift"
            ]
        ),
        
        // Report Generator Module
        .target(
            name: "ReportGenerator",
            dependencies: [],
            path: "Sources/ReportGenerator",
            sources: [
                "PDFExportView.swift"
            ]
        ),
        
        // Test targets
        .testTarget(
            name: "AcousticEngineTests",
            dependencies: ["AcousticEngine"],
            path: "Tests/AcousticEngineTests"
        ),
        .testTarget(
            name: "DIN18041Tests", 
            dependencies: ["DIN18041"],
            path: "Tests/DIN18041Tests"
        ),
        .testTarget(
            name: "ReportGeneratorTests",
            dependencies: ["ReportGenerator"],
            path: "Tests/ReportGeneratorTests"
        )
    ]
)