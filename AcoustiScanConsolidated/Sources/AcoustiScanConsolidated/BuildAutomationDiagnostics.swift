// BuildAutomationDiagnostics.swift
// Shared helpers for parsing Swift build output. Extracted to their own type
// so that heuristic logic can be tested independently from process execution.

import Foundation

internal enum BuildAutomationDiagnostics {
    internal struct ErrorClassificationConfig {
        internal let missingImportKeywords: [String]
        internal let undeclaredIdentifierKeywords: [String]
        internal let typeErrorKeywords: [String]
        internal let syntaxErrorKeywords: [String]
        internal let deprecationKeywords: [String]
        internal let minimumKeywordMatches: Int

        /// Creates error classification keyword configuration.
        /// - Parameter minimumKeywordMatches: Minimum keyword matches required to classify.
        ///   Values below 1 are clamped to 1.
        internal init(
            missingImportKeywords: [String] = ["import", "module"],
            undeclaredIdentifierKeywords: [String] = ["unresolved identifier", "undeclared", "cannot find"],
            typeErrorKeywords: [String] = ["type"],
            syntaxErrorKeywords: [String] = ["expected", "syntax"],
            deprecationKeywords: [String] = ["deprecated"],
            minimumKeywordMatches: Int = 1
        ) {
            self.missingImportKeywords = missingImportKeywords
            self.undeclaredIdentifierKeywords = undeclaredIdentifierKeywords
            self.typeErrorKeywords = typeErrorKeywords
            self.syntaxErrorKeywords = syntaxErrorKeywords
            self.deprecationKeywords = deprecationKeywords
            // Keyword thresholds below 1 are invalid and treated as 1 because
            // error classification should never succeed without at least one
            // explicit keyword match; a zero-threshold would make all messages
            // match every category in sequence and return whichever is checked first.
            self.minimumKeywordMatches = max(1, minimumKeywordMatches)
        }
    }

    private static let defaultClassificationConfig = ErrorClassificationConfig()

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

    internal static func classifyError(
        message: String,
        config: ErrorClassificationConfig = defaultClassificationConfig
    ) -> BuildAutomation.BuildError.ErrorType {
        let normalized = message.lowercased()
        if keywordMatchCount(in: normalized, keywords: config.missingImportKeywords) >= config.minimumKeywordMatches {
            return .missingImport
        } else if keywordMatchCount(in: normalized, keywords: config.undeclaredIdentifierKeywords)
            >= config.minimumKeywordMatches {
            return .undeclaredIdentifier
        } else if keywordMatchCount(in: normalized, keywords: config.typeErrorKeywords) >= config.minimumKeywordMatches {
            return .typeError
        } else if keywordMatchCount(in: normalized, keywords: config.syntaxErrorKeywords)
            >= config.minimumKeywordMatches {
            return .syntaxError
        } else if keywordMatchCount(in: normalized, keywords: config.deprecationKeywords)
            >= config.minimumKeywordMatches {
            return .deprecation
        } else {
            return .other
        }
    }

    private static func keywordMatchCount(in message: String, keywords: [String]) -> Int {
        return keywords.reduce(into: 0) { count, keyword in
            if message.contains(keyword.lowercased()) {
                count += 1
            }
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
