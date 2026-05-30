import XCTest

final class TimeoutConfigurationTests: XCTestCase {
    private func repositoryRootURL(file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        let fileManager = FileManager.default
        var candidateURL = URL(fileURLWithPath: "\(file)").deletingLastPathComponent()

        while true {
            if [".github", ".copilot"].contains(where: { marker in
                fileManager.fileExists(atPath: candidateURL.appendingPathComponent(marker).path)
            }) {
                return candidateURL
            }

            let parentURL = candidateURL.deletingLastPathComponent()
            if parentURL == candidateURL {
                XCTFail("Unable to locate repository root from \(file)", line: line)
                throw NSError(domain: "TimeoutConfigurationTests", code: 1)
            }
            candidateURL = parentURL
        }
    }

    func testBuildAutomationTimeoutsAreUnifiedTo120Seconds() throws {
        let repoRootURL = try repositoryRootURL()
        let configURL = repoRootURL.appendingPathComponent(".copilot/build-automation.json")
        // This file is an optional repository artifact, not part of the Swift
        // package sources. When it is absent (e.g. a clean checkout) the test
        // validates nothing about the package, so skip rather than fail.
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw XCTSkip("Build automation config not present at \(configURL.path); skipping (optional repo artifact).")
        }
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
        let repoRootURL = try repositoryRootURL()
        let htmlURL = repoRootURL.appendingPathComponent("RT60_014_Report_Erstellung/Raumakustikdaten/report.html")
        // Generated report artifact, not part of the package sources. Skip when
        // absent instead of failing the package test suite.
        guard FileManager.default.fileExists(atPath: htmlURL.path) else {
            throw XCTSkip("HTML report not present at \(htmlURL.path); skipping (generated artifact, not in repo).")
        }
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
