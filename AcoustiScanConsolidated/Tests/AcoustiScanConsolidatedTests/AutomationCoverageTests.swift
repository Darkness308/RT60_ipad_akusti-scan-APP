import XCTest
@testable import AcoustiScanConsolidated

final class AutomationCoverageTests: XCTestCase {
    private let swiftExecutablePath = "/usr/share/swift/usr/bin/swift"
    private var originalSwiftExecutablePath: String?

    override func setUp() {
        super.setUp()
        originalSwiftExecutablePath = BuildAutomation.swiftExecutablePath
        BuildAutomation.swiftExecutablePath = swiftExecutablePath
    }

    override func tearDown() {
        if let originalSwiftExecutablePath {
            BuildAutomation.swiftExecutablePath = originalSwiftExecutablePath
        }
        super.tearDown()
    }

    private func makeTemporaryPackage(
        source: String,
        tests: String = """
        import XCTest
        @testable import TempPkg

        final class TempPkgTests: XCTestCase {
            func testSmoke() {
                XCTAssertTrue(true)
            }
        }
        """
    ) throws -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("build-automation-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let packageSwift = root.appendingPathComponent("Package.swift")
        let sourcesDir = root.appendingPathComponent("Sources/TempPkg", isDirectory: true)
        let testsDir = root.appendingPathComponent("Tests/TempPkgTests", isDirectory: true)

        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: testsDir, withIntermediateDirectories: true)

        let manifest = """
        // swift-tools-version: 5.9
        import PackageDescription

        let package = Package(
            name: "TempPkg",
            products: [
                .library(name: "TempPkg", targets: ["TempPkg"])
            ],
            targets: [
                .target(name: "TempPkg"),
                .testTarget(name: "TempPkgTests", dependencies: ["TempPkg"])
            ]
        )
        """

        try manifest.write(to: packageSwift, atomically: true, encoding: .utf8)
        try source.write(
            to: sourcesDir.appendingPathComponent("TempPkg.swift"),
            atomically: true,
            encoding: .utf8
        )
        try tests.write(
            to: testsDir.appendingPathComponent("TempPkgTests.swift"),
            atomically: true,
            encoding: .utf8
        )

        return root
    }

    private func withTemporaryPackage(
        source: String,
        tests: String? = nil,
        perform: (String) throws -> Void
    ) throws {
        let packageURL = try makeTemporaryPackage(source: source, tests: tests ?? """
        import XCTest
        @testable import TempPkg

        final class TempPkgTests: XCTestCase {
            func testSmoke() {
                XCTAssertTrue(true)
            }
        }
        """)
        defer { try? FileManager.default.removeItem(at: packageURL) }
        try perform(packageURL.path)
    }

    private func withTemporarySwiftExecutable(
        scriptBody: String,
        perform: (String) throws -> Void
    ) throws {
        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fake-swift-\(UUID().uuidString).sh")
        try scriptBody.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path
        )
        defer { try? FileManager.default.removeItem(at: scriptURL) }
        try perform(scriptURL.path)
    }

    func testPDFTextExtractorExtractsTextFromSimpleBTETSections() {
        let pseudoPDF = "%PDF-1.4\nBT (Hello) Tj ET\nBT (World) Tj ET\n"
        let extracted = PDFTextExtractor.extractText(from: Data(pseudoPDF.utf8))

        XCTAssertTrue(extracted.contains("Hello"))
        XCTAssertTrue(extracted.contains("World"))
    }

    func testPDFTextExtractorReturnsEmptyForNoBTETSections() {
        let pseudoPDF = "%PDF-1.4\n/Type /Catalog\n"
        let extracted = PDFTextExtractor.extractText(from: Data(pseudoPDF.utf8))

        XCTAssertEqual(extracted, "")
    }

    func testBuildAutomationReturnsFailureForMissingPackagePath() {
        let missingPath = "/tmp/workspace/nonexistent-package-for-build-automation"
        let result = BuildAutomation.runAutomatedBuild(projectPath: missingPath, maxRetries: 1)

        switch result {
        case .failure(let output, _):
            XCTAssertFalse(output.isEmpty)
            XCTAssertTrue(output.lowercased().contains("error"))
        default:
            XCTFail("Expected build failure for missing package path")
        }
    }

    func testBuildAutomationStatusReportsFailureForMissingPackagePath() {
        let missingPath = "/tmp/workspace/nonexistent-package-for-build-automation"
        let status = BuildAutomation.getBuildStatus(projectPath: missingPath)

        XCTAssertTrue(status.hasPrefix("❌ Build failed"))
    }

    func testBuildAutomationReturnsSuccessForCompilablePackage() throws {
        try withTemporaryPackage(
            source: """
            public struct Greeter {
                public static func message() -> String {
                    "hello"
                }
            }
            """
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
            switch result {
            case .success(let output):
                XCTAssertFalse(output.isEmpty)
            default:
                XCTFail("Expected success for compilable package")
            }
        }
    }

    func testBuildAutomationReturnsMaxRetriesExceededWhenConfiguredToSkipLoop() throws {
        try withTemporaryPackage(
            source: "public struct Greeter { public static let value = 1 }"
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 0)
            switch result {
            case .failure(let output, let errors):
                XCTAssertEqual(output, "Max retries exceeded")
                XCTAssertTrue(errors.isEmpty)
            default:
                XCTFail("Expected max-retries-exceeded failure")
            }
        }
    }

    func testBuildAutomationParsesUndeclaredIdentifierErrors() throws {
        try withTemporaryPackage(
            source: """
            public struct Broken {
                public static let value = missingSymbol
            }
            """
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
            guard case .failure(_, let errors) = result else {
                return XCTFail("Expected failure for undeclared identifier package")
            }
            XCTAssertFalse(errors.isEmpty)
            XCTAssertTrue(errors.contains(where: { $0.type == .undeclaredIdentifier }))
        }
    }

    func testBuildAutomationParsesTypeErrors() throws {
        try withTemporaryPackage(
            source: """
            public struct BrokenTypes {
                public static func number() -> Int {
                    "not-an-int"
                }
            }
            """
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
            guard case .failure(_, let errors) = result else {
                return XCTFail("Expected failure for type-mismatch package")
            }
            XCTAssertFalse(errors.isEmpty)
            XCTAssertTrue(errors.contains(where: { $0.type == .typeError }))
        }
    }

    func testBuildAutomationParsesSyntaxErrors() throws {
        try withTemporaryPackage(
            source: """
            public struct BrokenSyntax {
                public static func value() -> Int {
                    let values = [1, 2,
                    return values.count
                }
            }
            """
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
            guard case .failure(_, let errors) = result else {
                return XCTFail("Expected failure for syntax-error package")
            }
            XCTAssertFalse(errors.isEmpty)
            XCTAssertTrue(errors.contains(where: { $0.type == .syntaxError }))
        }
    }

    func testBuildAutomationParsesMissingModuleErrors() throws {
        try withTemporaryPackage(
            source: """
            import DefinitelyMissingModule

            public struct BrokenImport {
                public static let value = 1
            }
            """
        ) { packagePath in
            let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
            guard case .failure(_, let errors) = result else {
                return XCTFail("Expected failure for missing-module package")
            }
            XCTAssertFalse(errors.isEmpty)
            XCTAssertTrue(errors.contains(where: { $0.type == .missingImport }))
        }
    }

    func testBuildAutomationStatusReportsSuccessForCompilablePackage() throws {
        try withTemporaryPackage(
            source: "public struct BuildStatusProbe { public static let ok = true }"
        ) { packagePath in
            let status = BuildAutomation.getBuildStatus(projectPath: packagePath)
            XCTAssertEqual(status, "✅ Build successful")
        }
    }

    func testContinuousIntegrationSucceedsForCompilablePackage() throws {
        try withTemporaryPackage(
            source: "public struct CiProbe { public static let ok = true }"
        ) { packagePath in
            XCTAssertTrue(ContinuousIntegration.runCIPipeline(projectPath: packagePath))
        }
    }

    func testContinuousIntegrationFailsForMissingPackagePath() {
        XCTAssertFalse(
            ContinuousIntegration.runCIPipeline(
                projectPath: "/tmp/workspace/nonexistent-package-for-ci-pipeline"
            )
        )
    }

    func testBuildAutomationRetriesAfterFixingMissingImportAndSucceeds() throws {
        let script = """
        #!/usr/bin/env bash
        command="$1"
        package_path=""
        while [[ "$#" -gt 0 ]]; do
          if [[ "$1" == "--package-path" ]]; then
            package_path="$2"
            shift 2
          else
            shift
          fi
        done

        source_file="${package_path}/Sources/TempPkg/TempPkg.swift"
        if [[ "$command" == "build" ]]; then
          if grep -q "^import Foundation$" "$source_file"; then
            echo "Build complete"
            exit 0
          fi
          echo "${source_file}:1:1: error: No such module 'Foundation'" >&2
          exit 1
        fi

        if [[ "$command" == "test" ]]; then
          exit 0
        fi
        """

        try withTemporaryPackage(
            source: """
            public struct NeedsFix {
                public static let value = Date()
            }
            """
        ) { packagePath in
            try withTemporarySwiftExecutable(scriptBody: script) { scriptPath in
                BuildAutomation.swiftExecutablePath = scriptPath
                let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 2)

                guard case .success = result else {
                    return XCTFail("Expected success after import auto-fix and retry")
                }

                let updatedSource = try String(
                    contentsOfFile: "\(packagePath)/Sources/TempPkg/TempPkg.swift"
                )
                XCTAssertTrue(updatedSource.contains("import Foundation"))
            }
        }
    }

    func testBuildAutomationReturnsFailureWhenSwiftExecutableIsInvalid() {
        BuildAutomation.swiftExecutablePath = "/tmp/workspace/nonexistent-swift-binary"
        let result = BuildAutomation.runAutomatedBuild(
            projectPath: "/tmp/workspace/nonexistent-package-for-invalid-swift",
            maxRetries: 1
        )

        guard case .failure(let output, let errors) = result else {
            return XCTFail("Expected failure when Swift executable cannot be launched")
        }
        XCTAssertTrue(output.contains("Failed to execute swift build"))
        XCTAssertTrue(errors.isEmpty)
    }

    func testBuildAutomationReturnsMaxRetriesExceededWhenFixNeverStabilizes() throws {
        let script = """
        #!/usr/bin/env bash
        command="$1"
        package_path=""
        while [[ "$#" -gt 0 ]]; do
          if [[ "$1" == "--package-path" ]]; then
            package_path="$2"
            shift 2
          else
            shift
          fi
        done

        source_file="${package_path}/Sources/TempPkg/TempPkg.swift"
        if [[ "$command" == "build" ]]; then
          sed -i '/^import Foundation$/d' "$source_file"
          echo "${source_file}:1:1: error: No such module 'Foundation'" >&2
          exit 1
        fi
        exit 0
        """

        try withTemporaryPackage(
            source: """
            public struct FlakyFix {
                public static let value = 1
            }
            """
        ) { packagePath in
            try withTemporarySwiftExecutable(scriptBody: script) { scriptPath in
                BuildAutomation.swiftExecutablePath = scriptPath
                let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)
                guard case .failure(let output, let errors) = result else {
                    return XCTFail("Expected max retries exceeded when fix cannot stabilize")
                }
                XCTAssertEqual(output, "Max retries exceeded")
                XCTAssertTrue(errors.isEmpty)
            }
        }
    }

    func testContinuousIntegrationFailsWhenTestsCommandFails() throws {
        let script = """
        #!/usr/bin/env bash
        command="$1"
        if [[ "$command" == "build" ]]; then
          exit 0
        fi
        if [[ "$command" == "test" ]]; then
          exit 1
        fi
        exit 0
        """

        try withTemporaryPackage(
            source: "public struct CiFailingTests { public static let ok = true }"
        ) { packagePath in
            try withTemporarySwiftExecutable(scriptBody: script) { scriptPath in
                BuildAutomation.swiftExecutablePath = scriptPath
                XCTAssertFalse(ContinuousIntegration.runCIPipeline(projectPath: packagePath))
            }
        }
    }

    func testBuildAutomationParsesOtherErrorsWithoutAutoFix() throws {
        let script = """
        #!/usr/bin/env bash
        command="$1"
        package_path=""
        while [[ "$#" -gt 0 ]]; do
          if [[ "$1" == "--package-path" ]]; then
            package_path="$2"
            shift 2
          else
            shift
          fi
        done

        if [[ "$command" == "build" ]]; then
          echo "${package_path}/Sources/TempPkg/TempPkg.swift:1:1: error: custom compiler failure" >&2
          exit 1
        fi
        exit 0
        """

        try withTemporaryPackage(
            source: "public struct OtherErrorProbe { public static let ok = true }"
        ) { packagePath in
            try withTemporarySwiftExecutable(scriptBody: script) { scriptPath in
                BuildAutomation.swiftExecutablePath = scriptPath
                let result = BuildAutomation.runAutomatedBuild(projectPath: packagePath, maxRetries: 1)

                guard case .failure(_, let errors) = result else {
                    return XCTFail("Expected failure for custom compiler error")
                }
                XCTAssertEqual(errors.count, 1)
                XCTAssertEqual(errors.first?.type, .other)
            }
        }
    }
}
