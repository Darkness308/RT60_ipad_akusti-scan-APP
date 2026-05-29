import XCTest
@testable import AcoustiScanConsolidated

final class BuildAutomationDiagnosticsTests: XCTestCase {
    func testParseErrorLineIgnoresWarnings() {
        let warningLine = "/tmp/file.swift:10:5: warning: something minor"
        XCTAssertNil(BuildAutomationDiagnostics.parseErrorLine(warningLine))
    }

    func testParseErrorLineExtractsMetadata() throws {
        let errorLine = "/tmp/source.swift:21:9: error: use of unresolved identifier 'foo'"

        let result = try XCTUnwrap(BuildAutomationDiagnostics.parseErrorLine(errorLine))
        XCTAssertEqual(result.file, "/tmp/source.swift")
        XCTAssertEqual(result.line, 21)
        XCTAssertEqual(result.column, 9)
        XCTAssertEqual(result.type, .undeclaredIdentifier)
    }

    func testParseErrorsCollapsesMultiLineOutput() {
        let output = [
            "/tmp/source.swift:21:9: error: use of unresolved identifier 'foo'",
            "/tmp/source.swift:22:13: warning: this is fine",
            "/tmp/other.swift:1:1: error: No such module 'UIKit'"
        ].joined(separator: "\n")

        let errors = BuildAutomationDiagnostics.parseErrors(from: output)
        XCTAssertEqual(errors.count, 2)
        XCTAssertEqual(errors[0].type, .undeclaredIdentifier)
        XCTAssertEqual(errors[1].type, .missingImport)
    }

    func testExtractMissingModuleUsesHeuristics() {
        XCTAssertEqual(
            BuildAutomationDiagnostics.extractMissingModule(from: "No such module 'Combine'"),
            "Combine"
        )

        XCTAssertEqual(
            BuildAutomationDiagnostics.extractMissingModule(from: "Type 'UIView' has no member 'foo'"),
            "UIKit"
        )

        XCTAssertNil(
            BuildAutomationDiagnostics.extractMissingModule(from: "generic failure without hints")
        )
    }

    func testParseErrorsHandlesEmptyOutput() {
        let errors = BuildAutomationDiagnostics.parseErrors(from: "")
        XCTAssertTrue(errors.isEmpty)
    }

    func testParseErrorsIgnoresWarningsOnlyOutput() {
        let output = [
            "/tmp/file.swift:1:1: warning: deprecated API",
            "/tmp/file.swift:2:5: warning: minor issue"
        ].joined(separator: "\n")

        let errors = BuildAutomationDiagnostics.parseErrors(from: output)
        XCTAssertTrue(errors.isEmpty)
    }

    func testParseErrorsIncludesMultipleErrorLines() {
        let output = [
            "/tmp/a.swift:10:2: error: expected expression",
            "some continuation line that should be ignored",
            "/tmp/b.swift:20:4: error: cannot find 'foo' in scope"
        ].joined(separator: "\n")

        let errors = BuildAutomationDiagnostics.parseErrors(from: output)
        XCTAssertEqual(errors.count, 2)
        XCTAssertEqual(errors[0].type, .syntaxError)
        XCTAssertEqual(errors[1].type, .undeclaredIdentifier)
    }

    func testClassifyErrorSupportsParameterizedThresholds() {
        let config = BuildAutomationDiagnostics.ErrorClassificationConfig(
            missingImportKeywords: ["module", "import"],
            minimumKeywordMatches: 2
        )

        XCTAssertEqual(
            BuildAutomationDiagnostics.classifyError(
                message: "No such module import issue detected",
                config: config
            ),
            .missingImport
        )

        XCTAssertEqual(
            BuildAutomationDiagnostics.classifyError(
                message: "No such module",
                config: config
            ),
            .other
        )
    }
}
