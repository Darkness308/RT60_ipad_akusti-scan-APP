// BuildAutomationDiagnostics.swift
// Shared helpers for parsing Swift build output. Extracted to their own type
// so that heuristic logic can be tested independently from process execution.

import Foundation

internal enum BuildAutomationDiagnostics {
    internal static func parseErrors(from output: String) -> [BuildAutomation.BuildError] {
        return output
            .components(separatedBy: .newlines)
            .compactMap(parseErrorLine)
    }

    internal static func parseErrorLine(_ line: String) -> BuildAutomation.BuildError? {
        let pattern = #"(.+?):(\d+):(\d+):\s*(error|warning):\s*(.+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard let fileRange = Range(match.range(at: 1), in: line),
              let lineRange = Range(match.range(at: 2), in: line),
              let columnRange = Range(match.range(at: 3), in: line),
              let severityRange = Range(match.range(at: 4), in: line),
              let messageRange = Range(match.range(at: 5), in: line) else {
            return nil
        }

        let file = String(line[fileRange])
        let lineNum = Int(String(line[lineRange])) ?? 0
        let column = Int(String(line[columnRange])) ?? 0
        let severity = String(line[severityRange])
        let message = String(line[messageRange])

        guard severity == "error" else { return nil }

        let errorType = classifyError(message: message)

        return BuildAutomation.BuildError(
            file: file,
            line: lineNum,
            column: column,
            message: message,
            type: errorType
        )
    }

    internal static func classifyError(message: String) -> BuildAutomation.BuildError.ErrorType {
        if message.contains("import") || message.contains("module") {
            return .missingImport
        } else if message.contains("unresolved identifier") || message.contains("undeclared") {
            return .undeclaredIdentifier
        } else if message.contains("type") {
            return .typeError
        } else if message.contains("expected") || message.contains("syntax") {
            return .syntaxError
        } else if message.contains("deprecated") {
            return .deprecation
        } else {
            return .other
        }
    }

    internal static func extractMissingModule(from message: String) -> String? {
        let patterns = [
            #"No such module '(.+?)'"#,
            #"module '(.+?)' not found"#,
            #"Cannot find '(.+?)' in scope"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
               let moduleRange = Range(match.range(at: 1), in: message) {
                return String(message[moduleRange])
            }
        }

        if message.contains("UIKit") || message.contains("UIView") || message.contains("UIColor") {
            return "UIKit"
        } else if message.contains("SwiftUI") || message.contains("View") || message.contains("@State") {
            return "SwiftUI"
        } else if message.contains("Foundation") || message.contains("NSString") || message.contains("URL") {
            return "Foundation"
        }

        return nil
    }
}
