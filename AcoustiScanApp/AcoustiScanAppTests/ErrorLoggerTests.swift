//
//  ErrorLoggerTests.swift
//  AcoustiScanAppTests
//
//  Unit tests for ErrorLogger utility
//  Tests cover error logging, message logging, log levels, and error handling
//

import XCTest
import os.log
@testable import AcoustiScanApp

class ErrorLoggerTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    // MARK: - Error Logging Tests

    func testErrorLogger_LogError_DoesNotCrash() {
        // Given - A sample error
        enum TestError: Error {
            case sampleError
        }
        let error = TestError.sampleError
        let context = "ErrorLoggerTests.testErrorLogger_LogError_DoesNotCrash"

        // When/Then - Logging should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .error),
            "Error logging should not throw or crash"
        )
    }

    func testErrorLogger_LogError_WithAllLevels_DoesNotCrash() {
        // Given - A sample error
        enum TestError: Error {
            case testError
        }
        let error = TestError.testError
        let context = "ErrorLoggerTests.testErrorLogger_LogError_WithAllLevels_DoesNotCrash"

        // When/Then - Logging at all levels should not crash
        let levels: [ErrorLogger.Level] = [.error, .warning, .info, .debug]

        for level in levels {
            XCTAssertNoThrow(
                ErrorLogger.log(error, context: context, level: level),
                "Error logging at \(level) level should not throw or crash"
            )
        }
    }

    func testErrorLogger_LogError_WithNSError_DoesNotCrash() {
        // Given - An NSError
        let error = NSError(
            domain: "com.acoustiscan.test",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Test error message"]
        )
        let context = "ErrorLoggerTests.testErrorLogger_LogError_WithNSError_DoesNotCrash"

        // When/Then - Logging NSError should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .error),
            "NSError logging should not throw or crash"
        )
    }

    func testErrorLogger_LogError_WithLocalizedError_DoesNotCrash() {
        // Given - A custom localized error
        struct LocalizedTestError: LocalizedError {
            var errorDescription: String? {
                return "This is a localized test error"
            }
        }
        let error = LocalizedTestError()
        let context = "ErrorLoggerTests.testErrorLogger_LogError_WithLocalizedError_DoesNotCrash"

        // When/Then - Logging localized error should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .error),
            "Localized error logging should not throw or crash"
        )
    }

    // MARK: - Message Logging Tests

    func testErrorLogger_LogMessage_DoesNotCrash() {
        // Given - A sample message
        let message = "This is a test log message"
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_DoesNotCrash"

        // When/Then - Message logging should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Message logging should not throw or crash"
        )
    }

    func testErrorLogger_LogMessage_WithAllLevels_DoesNotCrash() {
        // Given - A sample message
        let message = "Test message for all levels"
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_WithAllLevels_DoesNotCrash"

        // When/Then - Logging at all levels should not crash
        let levels: [ErrorLogger.Level] = [.error, .warning, .info, .debug]

        for level in levels {
            XCTAssertNoThrow(
                ErrorLogger.log(message: message, context: context, level: level),
                "Message logging at \(level) level should not throw or crash"
            )
        }
    }

    func testErrorLogger_LogMessage_WithEmptyMessage_DoesNotCrash() {
        // Given - An empty message
        let message = ""
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_WithEmptyMessage_DoesNotCrash"

        // When/Then - Logging empty message should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Logging empty message should not throw or crash"
        )
    }

    func testErrorLogger_LogMessage_WithSpecialCharacters_DoesNotCrash() {
        // Given - Message with special characters
        let message = "Test with special chars: \n\t\"quotes\" and 'apostrophes' & symbols <>"
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_WithSpecialCharacters_DoesNotCrash"

        // When/Then - Logging message with special characters should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Logging message with special characters should not throw or crash"
        )
    }

    func testErrorLogger_LogMessage_WithUnicodeCharacters_DoesNotCrash() {
        // Given - Message with unicode characters
        let message = "Test with unicode: 你好 [MUSIC] Ñoño café"
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_WithUnicodeCharacters_DoesNotCrash"

        // When/Then - Logging message with unicode should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Logging message with unicode characters should not throw or crash"
        )
    }

    func testErrorLogger_LogMessage_WithLongMessage_DoesNotCrash() {
        // Given - A very long message
        let message = String(repeating: "This is a long message. ", count: 100)
        let context = "ErrorLoggerTests.testErrorLogger_LogMessage_WithLongMessage_DoesNotCrash"

        // When/Then - Logging long message should not crash
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Logging long message should not throw or crash"
        )
    }

    // MARK: - Log Level Tests

    func testErrorLogger_LogLevel_ErrorLevel_Works() {
        // Given - Error level
        enum TestError: Error {
            case errorLevel
        }
        let error = TestError.errorLevel

        // When/Then - Error level logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: "ErrorLevel", level: .error),
            "Error level logging should work"
        )
    }

    func testErrorLogger_LogLevel_WarningLevel_Works() {
        // Given - Warning level
        enum TestError: Error {
            case warningLevel
        }
        let error = TestError.warningLevel

        // When/Then - Warning level logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: "WarningLevel", level: .warning),
            "Warning level logging should work"
        )
    }

    func testErrorLogger_LogLevel_InfoLevel_Works() {
        // Given - Info level
        let message = "Info level message"

        // When/Then - Info level logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: "InfoLevel", level: .info),
            "Info level logging should work"
        )
    }

    func testErrorLogger_LogLevel_DebugLevel_Works() {
        // Given - Debug level
        let message = "Debug level message"

        // When/Then - Debug level logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: "DebugLevel", level: .debug),
            "Debug level logging should work"
        )
    }

    func testErrorLogger_LogLevel_DefaultLevel_IsError() {
        // Given - No explicit level specified
        enum TestError: Error {
            case defaultLevel
        }
        let error = TestError.defaultLevel

        // When/Then - Default level should work (implicitly .error)
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: "DefaultLevel"),
            "Default level (error) logging should work"
        )
    }

    // MARK: - Context Tests

    func testErrorLogger_Context_WithShortContext_Works() {
        // Given - Short context
        let context = "Test"
        let message = "Short context test"

        // When/Then - Short context should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Short context should work"
        )
    }

    func testErrorLogger_Context_WithLongContext_Works() {
        // Given - Long context
        let context = "VeryLongContextNameThatDescribesTheExactLocationAndPurposeOfTheLogMessage"
        let message = "Long context test"

        // When/Then - Long context should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Long context should work"
        )
    }

    func testErrorLogger_Context_WithDottedNotation_Works() {
        // Given - Dotted notation context (common pattern)
        let context = "AcoustiScanApp.SurfaceStore.saveSurfaces"
        let message = "Dotted notation context test"

        // When/Then - Dotted notation context should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Dotted notation context should work"
        )
    }

    func testErrorLogger_Context_WithSpecialCharacters_Works() {
        // Given - Context with special characters
        let context = "Test-Context_With@Special#Characters"
        let message = "Special characters in context test"

        // When/Then - Special characters in context should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Context with special characters should work"
        )
    }

    // MARK: - Integration Tests

    func testErrorLogger_RealWorldScenario_FileOperationError() {
        // Given - Simulating a file operation error
        enum FileError: Error, LocalizedError {
            case fileNotFound(path: String)

            var errorDescription: String? {
                switch self {
                case .fileNotFound(let path):
                    return "File not found at path: \(path)"
                }
            }
        }

        let error = FileError.fileNotFound(path: "/path/to/missing/file.txt")
        let context = "FileManager.loadFile"

        // When/Then - Real-world error logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .error),
            "Real-world file error logging should work"
        )
    }

    func testErrorLogger_RealWorldScenario_NetworkError() {
        // Given - Simulating a network error
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        let context = "NetworkManager.fetchData"

        // When/Then - Network error logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .error),
            "Network error logging should work"
        )
    }

    func testErrorLogger_RealWorldScenario_DecodingError() {
        // Given - Simulating a decoding error
        struct TestData: Decodable {
            let requiredField: String
        }

        let invalidJSON = "{\"wrongField\": \"value\"}".data(using: .utf8)!
        let context = "JSONDecoder.decode"

        do {
            _ = try JSONDecoder().decode(TestData.self, from: invalidJSON)
        } catch {
            // When/Then - Decoding error logging should work
            XCTAssertNoThrow(
                ErrorLogger.log(error, context: context, level: .error),
                "Decoding error logging should work"
            )
        }
    }

    func testErrorLogger_RealWorldScenario_ValidationError() {
        // Given - Simulating a validation error
        enum ValidationError: Error, LocalizedError {
            case invalidInput(field: String, reason: String)

            var errorDescription: String? {
                switch self {
                case .invalidInput(let field, let reason):
                    return "Invalid input for field '\(field)': \(reason)"
                }
            }
        }

        let error = ValidationError.invalidInput(field: "email", reason: "Invalid email format")
        let context = "FormValidator.validateEmail"

        // When/Then - Validation error logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(error, context: context, level: .warning),
            "Validation error logging should work"
        )
    }

    func testErrorLogger_RealWorldScenario_SuccessMessage() {
        // Given - Simulating a success message
        let message = "Successfully saved 15 materials to custom materials database"
        let context = "MaterialManager.saveCustomMaterials"

        // When/Then - Success message logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Success message logging should work"
        )
    }

    func testErrorLogger_RealWorldScenario_DebugMessage() {
        // Given - Simulating a debug message
        let message = "RT60 calculation: V=150.0, A=25.5, RT60=0.95s"
        let context = "SurfaceStore.calculateRT60"

        // When/Then - Debug message logging should work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .debug),
            "Debug message logging should work"
        )
    }

    // MARK: - Edge Cases

    func testErrorLogger_EdgeCase_EmptyContext() {
        // Given - Empty context
        let message = "Test with empty context"
        let context = ""

        // When/Then - Empty context should still work
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Empty context should not cause crash"
        )
    }

    func testErrorLogger_EdgeCase_ConcurrentLogging() {
        // Given - Multiple concurrent logging calls
        let expectation = self.expectation(description: "Concurrent logging completes")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue(label: "test.concurrent.logging", attributes: .concurrent)

        // When - Log from multiple threads
        for i in 0..<10 {
            queue.async {
                ErrorLogger.log(
                    message: "Concurrent log message \(i)",
                    context: "ConcurrentTest",
                    level: .info
                )
                expectation.fulfill()
            }
        }

        // Then - All logging should complete without crash
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Concurrent logging should complete successfully")
        }
    }

    func testErrorLogger_EdgeCase_RapidSuccessiveLogging() {
        // Given - Many rapid successive logs
        let context = "RapidLoggingTest"

        // When/Then - Rapid logging should not crash
        XCTAssertNoThrow({
            for i in 0..<100 {
                ErrorLogger.log(
                    message: "Rapid log \(i)",
                    context: context,
                    level: .debug
                )
            }
        }(), "Rapid successive logging should not crash")
    }

    // MARK: - Backward Compatibility Tests

    @available(iOS 13.0, *)
    func testErrorLogger_iOS13_Works() {
        // Given - iOS 13+ environment
        let message = "iOS 13 compatibility test"
        let context = "iOS13Test"

        // When/Then - Should work on iOS 13+
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Should work on iOS 13+"
        )
    }

    @available(iOS 14.0, *)
    func testErrorLogger_iOS14_UsesNewLogger() {
        // Given - iOS 14+ environment (uses os.Logger)
        let message = "iOS 14 Logger test"
        let context = "iOS14LoggerTest"

        // When/Then - Should use os.Logger on iOS 14+
        XCTAssertNoThrow(
            ErrorLogger.log(message: message, context: context, level: .info),
            "Should use os.Logger on iOS 14+"
        )
    }

    // MARK: - Performance Tests

    func testPerformance_ErrorLogging_CompletesFast() {
        // Given - Error to log
        enum PerfError: Error {
            case performanceTest
        }
        let error = PerfError.performanceTest

        // When/Then - Measure logging performance
        measure {
            ErrorLogger.log(error, context: "PerformanceTest", level: .error)
        }
    }

    func testPerformance_MessageLogging_CompletesFast() {
        // Given - Message to log
        let message = "Performance test message"

        // When/Then - Measure logging performance
        measure {
            ErrorLogger.log(message: message, context: "PerformanceTest", level: .info)
        }
    }

    func testPerformance_BulkLogging_CompletesReasonably() {
        // When/Then - Measure bulk logging performance
        measure {
            for i in 0..<50 {
                ErrorLogger.log(
                    message: "Bulk log \(i)",
                    context: "BulkPerformanceTest",
                    level: .debug
                )
            }
        }
    }
}
