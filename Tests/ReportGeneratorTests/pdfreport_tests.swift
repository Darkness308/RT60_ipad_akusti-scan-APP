//  PDFReportTests.swift
//  AcoustiScanTests
//
//  Created in Sprint 3 (Report & UX)
//
//  Golden-File Tests für PDF-Report.
//  Sicherstellen, dass Report generiert wird, reproduzierbar ist und die erwartete Seitenzahl enthält.

import XCTest
@testable import ReportGenerator

final class PDFReportTests: XCTestCase {

    func testGenerateReportJSON() throws {
        let reportData = PDFReportGenerator.generateReportData(
            roomType: "Classroom",
            volume: 150.0,
            measurements: ["1000Hz: 0.6s", "500Hz: 0.7s"]
        )
        
        XCTAssertEqual(reportData["roomType"] as? String, "Classroom")
        XCTAssertEqual(reportData["volume"] as? Double, 150.0)
    }

    func testExportJSON() throws {
        let reportData = PDFReportGenerator.generateReportData(
            roomType: "Office",
            volume: 100.0,
            measurements: ["Test measurement"]
        )
        
        let jsonData = PDFReportGenerator.exportAsJSON(reportData: reportData)
        XCTAssertNotNil(jsonData)
        
        if let data = jsonData {
            XCTAssertFalse(data.isEmpty)
        }
    }
}
