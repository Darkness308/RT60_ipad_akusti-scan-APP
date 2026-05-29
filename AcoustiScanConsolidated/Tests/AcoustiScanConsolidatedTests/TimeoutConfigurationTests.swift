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
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configURL.path),
            "Missing build automation config at \(configURL.path)"
        )
        guard FileManager.default.fileExists(atPath: configURL.path) else { return }
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
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: htmlURL.path),
            "Missing HTML report at \(htmlURL.path)"
        )
        guard FileManager.default.fileExists(atPath: htmlURL.path) else { return }
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
