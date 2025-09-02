// AppLogger.swift
// Structured logging system for RT60 application

import Foundation
#if canImport(os)
import os
#endif

/// Structured logging system for different application subsystems
public enum AppLog {
    
    #if canImport(os)
    /// Digital Signal Processing operations
    public static let dsp = Logger(subsystem: "RT60", category: "DSP")
    
    /// Parsing operations for log files and data
    public static let parse = Logger(subsystem: "RT60", category: "Parse")
    
    /// Export and rendering operations
    public static let export = Logger(subsystem: "RT60", category: "Export")
    
    /// Room scanning and geometry operations
    public static let room = Logger(subsystem: "RT60", category: "Room")
    
    /// Material and absorption calculations
    public static let material = Logger(subsystem: "RT60", category: "Material")
    
    /// DIN compliance and validation
    public static let compliance = Logger(subsystem: "RT60", category: "Compliance")
    
    /// General application events
    public static let app = Logger(subsystem: "RT60", category: "App")
    
    /// Performance and timing measurements
    public static let perf = Logger(subsystem: "RT60", category: "Performance")
    #else
    // Fallback logging for non-Apple platforms
    public static let dsp = ConsoleLogger(category: "DSP")
    public static let parse = ConsoleLogger(category: "Parse")
    public static let export = ConsoleLogger(category: "Export")
    public static let room = ConsoleLogger(category: "Room")
    public static let material = ConsoleLogger(category: "Material")
    public static let compliance = ConsoleLogger(category: "Compliance")
    public static let app = ConsoleLogger(category: "App")
    public static let perf = ConsoleLogger(category: "Performance")
    #endif
}

#if !canImport(os)
/// Console-based logger for non-Apple platforms
public struct ConsoleLogger {
    let category: String
    
    public func debug(_ message: String) {
        print("🔍 [\(category)] \(message)")
    }
    
    public func info(_ message: String) {
        print("ℹ️ [\(category)] \(message)")
    }
    
    public func warning(_ message: String) {
        print("⚠️ [\(category)] \(message)")
    }
    
    public func error(_ message: String) {
        print("❌ [\(category)] \(message)")
    }
}
#endif

/// Helper extension for logging structured data
public extension AppLog {
    
    /// Log a measurement with frequency and value
    static func logMeasurement(_ freq: Int, _ value: Double, _ unit: String) {
        AppLog.dsp.debug("Measurement: \(freq)Hz = \(value)\(unit)")
    }
    
    /// Log a validation result
    static func logValidation(_ item: String, _ isValid: Bool, _ reason: String = "") {
        if isValid {
            AppLog.app.info("✓ \(item) valid")
        } else {
            AppLog.app.warning("✗ \(item) invalid: \(reason)")
        }
    }
    
    /// Log timing information
    static func logTiming(_ operation: String, _ duration: TimeInterval) {
        AppLog.perf.info("⏱ \(operation): \(duration)ms")
    }
    
    /// Log error with context
    static func logError(_ error: Error, _ context: String) {
        AppLog.app.error("❌ \(context): \(error.localizedDescription)")
    }
}

#if canImport(os)
/// Helper extension for Apple platforms Logger
public extension Logger {
    
    /// Log a measurement with frequency and value
    func measurement(_ freq: Int, _ value: Double, _ unit: String) {
        self.debug("Measurement: \(freq)Hz = \(value, privacy: .public)\(unit)")
    }
    
    /// Log a validation result
    func validation(_ item: String, _ isValid: Bool, _ reason: String = "") {
        if isValid {
            self.info("✓ \(item) valid")
        } else {
            self.warning("✗ \(item) invalid: \(reason)")
        }
    }
    
    /// Log timing information
    func timing(_ operation: String, _ duration: TimeInterval) {
        self.info("⏱ \(operation): \(duration, privacy: .public)ms")
    }
    
    /// Log error with context
    func errorWithContext(_ error: Error, _ context: String) {
        self.error("❌ \(context): \(error.localizedDescription)")
    }
}
#endif