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
}
