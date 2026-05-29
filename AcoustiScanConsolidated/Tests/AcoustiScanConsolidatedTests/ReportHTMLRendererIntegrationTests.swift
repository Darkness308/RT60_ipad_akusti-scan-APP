import XCTest
@testable import AcoustiScanConsolidated

final class ReportHTMLRendererIntegrationTests: XCTestCase {
    private func makeMaliciousModel() -> ReportModel {
        let payloadA = "<script>alert(1)</script>"
        let payloadB = "\"><img src=x onerror=alert(1)>"
        let payloadC = "';alert(String.fromCharCode(88,83,83))//"
        let payloadD = "javascript:alert(1)"
        let payloadE = "&lt;script&gt;"
        let payloadF = "<svg/onload=alert(1)>"

        return ReportModel(
            metadata: [
                "device": payloadA,
                "app_version": payloadB,
                "date": payloadC
            ],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.72],
                ["freq_hz": 250.0, "t20_s": nil]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: [
                "method": payloadD,
                "bands": payloadE
            ],
            recommendations: [payloadF, payloadA],
            audit: ["hash": payloadB],
            sourceOrigin: "input-malicious-test"
        )
    }

    func testRendererEscapesMaliciousPayloads() {
        let html = String(decoding: ReportHTMLRenderer().render(makeMaliciousModel()), as: UTF8.self)

        XCTAssertFalse(html.contains("<script>"))
        XCTAssertFalse(html.contains("onerror="))
        XCTAssertFalse(html.contains("<svg/onload"))
        XCTAssertFalse(html.contains("javascript:"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testRendererInjectsProvenanceIntoHeadAndSections() {
        let html = String(decoding: ReportHTMLRenderer().render(makeMaliciousModel()), as: UTF8.self)

        XCTAssertTrue(html.contains("<meta name=\"report-origin\""))
        XCTAssertTrue(html.contains("data-origin=\""))
        XCTAssertTrue(html.contains("origin-badge"))
    }

    func testStandaloneModeUsesInlineStyleWithoutStylesheetLink() {
        let html = String(
            decoding: ReportHTMLRenderer(mode: .standalone).render(makeMaliciousModel()),
            as: UTF8.self
        )

        XCTAssertTrue(html.contains("<style>"))
        XCTAssertFalse(html.contains("<link rel=\"stylesheet\""))
    }

    func testMultiFileModeUsesStylesheetLinkWithoutInlineStyle() {
        let html = String(
            decoding: ReportHTMLRenderer(mode: .multiFile(resourcesPath: "assets/css"))
                .render(makeMaliciousModel()),
            as: UTF8.self
        )

        XCTAssertTrue(html.contains("<link rel=\"stylesheet\" href=\"assets/css/report.css\">"))
        XCTAssertFalse(html.contains("<style>"))
    }
}
