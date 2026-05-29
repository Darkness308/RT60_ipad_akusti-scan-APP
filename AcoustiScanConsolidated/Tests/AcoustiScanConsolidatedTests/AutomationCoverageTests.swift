import XCTest
@testable import AcoustiScanConsolidated

final class AutomationCoverageTests: XCTestCase {
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
}
