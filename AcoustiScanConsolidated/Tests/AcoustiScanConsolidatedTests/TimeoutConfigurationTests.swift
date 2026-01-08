import XCTest

final class TimeoutConfigurationTests: XCTestCase {
    private var repoRootURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        // .../AcoustiScanConsolidated/Tests/AcoustiScanConsolidatedTests
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        return url
    }

    func testBuildAutomationTimeoutsAreUnifiedTo120Seconds() throws {
        let configURL = repoRootURL.appendingPathComponent(".copilot/build-automation.json")
        let data = try Data(contentsOf: configURL)
        let automationConfig = try JSONDecoder().decode(AutomationConfig.self, from: data)
        let timeouts = automationConfig.copilot_build_automation.build_pipeline.steps.map { $0.timeout_seconds }
        XCTAssertFalse(timeouts.isEmpty, "Expected at least one build pipeline step to validate timeouts")
        XCTAssertTrue(
            timeouts.allSatisfy { $0 == 120 },
            "Found timeouts that do not match the expected 120 seconds value: \(timeouts)"
        )
    }

    func testHTMLReportTimeoutUses120Seconds() throws {
        let htmlURL = repoRootURL.appendingPathComponent("RT60_014_Report_Erstellung/Raumakustikdaten/report.html")
        let html = try String(contentsOf: htmlURL, encoding: .utf8)
        XCTAssertTrue(html.contains("setTimeout(() => document.getElementById(`freq-${freq}`).style.backgroundColor = '', 120000)"),
                      "HTML report highlight timeout should be 120000 ms (120 seconds)")
    }
}

private struct AutomationConfig: Decodable {
    let copilot_build_automation: BuildAutomationConfiguration
}

private struct BuildAutomationConfiguration: Decodable {
    let build_pipeline: BuildPipeline
}

private struct BuildPipeline: Decodable {
    let steps: [BuildStep]
}

private struct BuildStep: Decodable {
    let timeout_seconds: Int
}
