//
//  ErrorLogger.swift
//  AcoustiScanApp
//
//  Simple error logging utility for the application
//

import Foundation
import os.log

/// Simple error logging utility for consistent error handling across the app
public enum ErrorLogger {

    /// Log levels for different severity
    public enum Level {
        case error
        case warning
        case info
        case debug
    }

    /// Log an error with context information
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Context string describing where/what failed
    ///   - level: Log level (defaults to .error)
    public static func log(
        _ error: Error,
        context: String,
        level: Level = .error
    ) {
        let message = "[\(context)] Error: \(error.localizedDescription)"

        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "com.acoustiscan.app", category: context)
            switch level {
            case .error:
                logger.error("\(message, privacy: .public)")
            case .warning:
                logger.warning("\(message, privacy: .public)")
            case .info:
                logger.info("\(message, privacy: .public)")
            case .debug:
                logger.debug("\(message, privacy: .public)")
            }
        } else {
            // Fallback for older iOS versions
            print(message)
        }
    }

    /// Log a message without an error
    /// - Parameters:
    ///   - message: The message to log
    ///   - context: Context string
    ///   - level: Log level
    public static func log(
        message: String,
        context: String,
        level: Level = .info
    ) {
        let fullMessage = "[\(context)] \(message)"

        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "com.acoustiscan.app", category: context)
            switch level {
            case .error:
                logger.error("\(fullMessage, privacy: .public)")
            case .warning:
                logger.warning("\(fullMessage, privacy: .public)")
            case .info:
                logger.info("\(fullMessage, privacy: .public)")
            case .debug:
                logger.debug("\(fullMessage, privacy: .public)")
            }
        } else {
            // Fallback for older iOS versions
            print(fullMessage)
        }
    }
}
