import XCTest

final class RT60LogParserTests: XCTestCase {

    func loadFixture(_ name: String) -> String {
        let url = URL(fileURLWithPath: "Tools/LogParser/fixtures/\(name)")
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            XCTFail("Failed to load fixture '\(name)': \(error.localizedDescription)")
            return ""
        }
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
        guard let b500 = model.bands.first(where: { $0.freq_hz == 500 }) else {
            XCTFail("Expected to find 500 Hz band")
            return
        }
        XCTAssertFalse(b500.valid)
        XCTAssertNil(b500.t20_s)
        XCTAssertTrue(b500.note.contains("no data"))
    }

    func test_low_correlation_sets_note() throws {
        let text = loadFixture("2025-07-21_RT60_012_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "012")
        guard let b250 = model.bands.first(where: { $0.freq_hz == 250 }) else {
            XCTFail("Expected to find 250 Hz band")
            return
        }
        XCTAssertTrue(b250.note.contains("low correlation"))
    }

    func test_checksum_mismatch_sets_flag() throws {
        let text = loadFixture("2025-07-21_RT60_013_Report.txt")
        let model = try RT60LogParser().parse(text: text, sourceFile: "013")
        XCTAssertFalse(model.summary.checksum_ok) // Fixture-Checksum bewusst "falsch"
    }

    func test_malformed_band_line_does_not_yield_valid_band() throws {
        // Previously a placeholder (XCTAssertTrue(true)). A malformed T20 line
        // ("125Hz abc" — no numeric value) must not parse into a valid 125 Hz band.
        let bad = """
        Setup:
        AppVersion=1.0.0
        Date=2025-07-21
        T20:
        125Hz abc
        """
        let model = try RT60LogParser().parse(text: bad, sourceFile: "bad")
        if let b125 = model.bands.first(where: { $0.freq_hz == 125 }) {
            XCTAssertFalse(b125.valid, "Malformed '125Hz abc' must not be a valid band")
            XCTAssertNil(b125.t20_s, "Malformed line must not yield a numeric T20")
        }
        // (If the parser drops the malformed line entirely, that is also acceptable;
        // the contract is simply that it must never become a valid numeric band.)
    }
}
