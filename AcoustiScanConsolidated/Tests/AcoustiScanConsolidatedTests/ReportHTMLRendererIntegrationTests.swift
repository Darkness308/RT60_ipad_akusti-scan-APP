import XCTest
@testable import AcoustiScanConsolidated

final class ReportHTMLRendererIntegrationTests: XCTestCase {
    private func makeMaliciousModel() -> ReportModel {
        let scriptTagPayload = "<script>alert(1)</script>"
        let attributeBreakoutPayload = "\"><img src=x onerror=alert(1)>"
        let jsStringBreakoutPayload = "';alert(String.fromCharCode(88,83,83))//"
        let protocolPayload = "javascript:alert(1)"
        let doubleEncodedPayload = "&lt;script&gt;"
        let svgEventPayload = "<svg/onload=alert(1)>"

        return ReportModel(
            metadata: [
                "device": scriptTagPayload,
                "app_version": attributeBreakoutPayload,
                "date": jsStringBreakoutPayload
            ],
            rt60_bands: [
                ["freq_hz": 125.0, "t20_s": 0.72],
                ["freq_hz": 250.0, "t20_s": nil]
            ],
            din_targets: [
                ["freq_hz": 125.0, "t_soll": 0.60, "tol": 0.20]
            ],
            validity: [
                "method": protocolPayload,
                "bands": doubleEncodedPayload
            ],
            recommendations: [svgEventPayload, scriptTagPayload],
            audit: ["hash": attributeBreakoutPayload],
            sourceOrigin: "input-malicious-test"
        )
    }

    func testRendererEscapesMaliciousPayloads() {
        let html = String(decoding: ReportHTMLRenderer().render(makeMaliciousModel()), as: UTF8.self)

        XCTAssertFalse(html.contains("<script>"))
        XCTAssertFalse(html.contains("<svg/onload"))
        XCTAssertFalse(html.contains("<img src=x"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testRendererPreservesLegitimateContent() {
        let model = ReportModel(
            metadata: ["device": "iPad Pro", "room": "Music Room"],
            rt60_bands: [["freq_hz": 500.0, "t20_s": 0.58]],
            din_targets: [["freq_hz": 500.0, "t_soll": 0.60, "tol": 0.20]],
            validity: ["method": "ISO3382-1"],
            recommendations: ["Add wall absorber"],
            audit: ["source": "integration-test"],
            sourceOrigin: "baseline-report.json"
        )

        let html = String(decoding: ReportHTMLRenderer().render(model), as: UTF8.self)
        XCTAssertTrue(html.contains("iPad Pro"))
        XCTAssertTrue(html.contains("Music Room"))
        XCTAssertTrue(html.contains("Add wall absorber"))
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

    func testMultiFileModeSanitizesInvalidResourcePath() {
        let html = String(
            decoding: ReportHTMLRenderer(mode: .multiFile(resourcesPath: "\"../bad path\""))
                .render(makeMaliciousModel()),
            as: UTF8.self
        )

        XCTAssertTrue(html.contains("<link rel=\"stylesheet\" href=\"assets/report.css\">"))
    }
}
