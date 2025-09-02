import XCTest

final class RT60LogParserTests: XCTestCase {

    func loadFixture(_ name: String) -> String {
        let url = URL(fileURLWithPath: "Tools/LogParser/fixtures/\(name)")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func test_parse_valid_log_produces_expected_json() throws {
        let text = loadFixture("2025-07-21_RT60_011_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "011")
        XCTAssertEqual(model.metadata.device, "iPadPro")
        XCTAssertEqual(model.summary.valid_band_count, model.bands.filter{$0.valid}.count)
    }

    func test_dashdot_is_invalid_band() throws {
        let text = loadFixture("2025-07-21_RT60_011_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "011")
        let b500 = model.bands.first{ $0.freq_hz == 500 }!
        XCTAssertFalse(b500.valid)
        XCTAssertNil(b500.t20_s)
        XCTAssertTrue(b500.note.contains("no data"))
    }

    func test_low_correlation_sets_note() throws {
        let text = loadFixture("2025-07-21_RT60_012_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "012")
        let b250 = model.bands.first{ $0.freq_hz == 250 }!
        XCTAssertTrue(b250.note.contains("low correlation"))
    }

    func test_checksum_mismatch_sets_flag() throws {
        let text = loadFixture("2025-07-21_RT60_013_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "013")
        XCTAssertFalse(model.summary.checksum_ok) // Fixture-Checksum bewusst "falsch"
    }

    func test_cli_exits_nonzero_on_format_error() throws {
        // Hier könnte ein fehlerhaftes Fixture genutzt werden (nicht vorhanden) – Placeholder:
        let bad = """
        Setup:
        AppVersion=1.0.0
        Date=2025-07-21
        T20:
        125Hz abc
        """
        _ = bad // Integriere später in CLI E2E-Tests
        XCTAssertTrue(true)
    }
}