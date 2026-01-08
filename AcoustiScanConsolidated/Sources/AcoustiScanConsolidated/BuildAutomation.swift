// BuildAutomation.swift
// Automated build system with error detection and fixing

import Foundation

/// Automated build system that detects and fixes common Swift compilation errors
public class BuildAutomation {
    
    public enum BuildResult {
        case success(String)
        case failure(String, [BuildError])
        case fixedAndRetrying([BuildError])
    }
    
    public struct BuildError {
        public let file: String
        public let line: Int
        public let column: Int
        public let message: String
        public let type: ErrorType
        
        public enum ErrorType {
            case missingImport
            case undeclaredIdentifier
            case typeError
            case syntaxError
            case deprecation
            case other
        }
        
        public init(file: String, line: Int, column: Int, message: String, type: ErrorType) {
            self.file = file
            self.line = line
            self.column = column
            self.message = message
            self.type = type
        }
    }
    
    /// Run automated build with error detection and fixing
    public static func runAutomatedBuild(projectPath: String, maxRetries: Int = 3) -> BuildResult {
        var retryCount = 0
        
        while retryCount < maxRetries {
            let buildResult = runBuild(projectPath: projectPath)
            
            switch buildResult {
            case .success(let output):
                return .success(output)
                
            case .failure(let output, let errors):
                let fixedErrors = attemptToFixErrors(errors, projectPath: projectPath)
                
                if !fixedErrors.isEmpty {
                    retryCount += 1
                    continue // Retry build after fixes
                } else {
                    return .failure(output, errors)
                }
                
            case .fixedAndRetrying:
                retryCount += 1
                continue
            }
        }
        
        return .failure("Max retries exceeded", [])
    }
    
    /// Execute swift build and parse output
    private static func runBuild(projectPath: String) -> BuildResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        task.arguments = ["build", "--package-path", projectPath]
        
        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return .failure("Failed to execute swift build: \(error)", [])
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if task.terminationStatus == 0 {
            return .success(output)
        } else {
            let errors = BuildAutomationDiagnostics.parseErrors(from: output)
            return .failure(output, errors)
        }
    }

    /// Attempt to automatically fix common errors
    private static func attemptToFixErrors(_ errors: [BuildError], projectPath: String) -> [BuildError] {
        var fixedErrors: [BuildError] = []

        for error in errors {
            switch error.type {
            case .missingImport:
                if fixMissingImport(error, projectPath: projectPath) {
                    fixedErrors.append(error)
                }
                
            case .undeclaredIdentifier:
                if fixUndeclaredIdentifier(error, projectPath: projectPath) {
                    fixedErrors.append(error)
                }
                
            case .typeError:
                if fixTypeError(error, projectPath: projectPath) {
                    fixedErrors.append(error)
                }
                
            case .syntaxError:
                if fixSyntaxError(error, projectPath: projectPath) {
                    fixedErrors.append(error)
                }
                
            default:
                break
            }
        }
        
        return fixedErrors
    }
    
    /// Fix missing import statements
    private static func fixMissingImport(_ error: BuildError, projectPath: String) -> Bool {
        guard let fileContent = try? String(contentsOfFile: error.file),
              let missingModule = BuildAutomationDiagnostics.extractMissingModule(from: error.message) else {
            return false
        }
        
        let lines = fileContent.components(separatedBy: .newlines)
        var newLines = lines
        
        // Find insertion point for import
        var insertIndex = 0
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("import ") {
                insertIndex = index + 1
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty && !line.hasPrefix("//") {
                break
            }
        }
        
        let importStatement = "import \(missingModule)"
        
        // Check if import already exists
        if !lines.contains(where: { $0.trimmingCharacters(in: .whitespaces) == importStatement }) {
            newLines.insert(importStatement, at: insertIndex)
            let newContent = newLines.joined(separator: "\n")
            
            do {
                try newContent.write(toFile: error.file, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }
        
        return false
    }
    
    /// Extract missing module name from error message
    private static func extractMissingModule(from message: String) -> String? {
        // Common patterns for missing modules
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

        // Try to infer common modules
        if message.contains("UIKit") || message.contains("UIView") || message.contains("UIColor") {
            return "UIKit"
        } else if message.contains("SwiftUI") || message.contains("View") || message.contains("@State") {
            return "SwiftUI"
        } else if message.contains("Foundation") || message.contains("NSString") || message.contains("URL") {
            return "Foundation"
        }

        return nil
    }
    
    /// Fix undeclared identifier errors
    private static func fixUndeclaredIdentifier(_ error: BuildError, projectPath: String) -> Bool {
        // This would require more sophisticated analysis
        // For now, we'll just log and return false
        print("Cannot automatically fix undeclared identifier: \(error.message)")
        return false
    }
    
    /// Fix type errors
    private static func fixTypeError(_ error: BuildError, projectPath: String) -> Bool {
        // Basic type fixes could be implemented here
        print("Cannot automatically fix type error: \(error.message)")
        return false
    }
    
    /// Fix syntax errors
    private static func fixSyntaxError(_ error: BuildError, projectPath: String) -> Bool {
        // Basic syntax fixes like missing semicolons, brackets, etc.
        print("Cannot automatically fix syntax error: \(error.message)")
        return false
    }
    
    /// Get build status summary
    public static func getBuildStatus(projectPath: String) -> String {
        let result = runBuild(projectPath: projectPath)
        
        switch result {
        case .success:
            return "✅ Build successful"
        case .failure(_, let errors):
            return "❌ Build failed with \(errors.count) error(s)"
        case .fixedAndRetrying:
            return "🔄 Build retrying after fixes"
        }
    }
}

/// Continuous integration helpers
public class ContinuousIntegration {
    
    /// Run complete CI pipeline
    public static func runCIPipeline(projectPath: String) -> Bool {
        print("🚀 Starting CI Pipeline...")
        
        // Step 1: Build
        print("📦 Building project...")
        let buildResult = BuildAutomation.runAutomatedBuild(projectPath: projectPath)
        
        switch buildResult {
        case .success:
            print("✅ Build successful")
        case .failure(let output, let errors):
            print("❌ Build failed:")
            print(output)
            for error in errors {
                print("  - \(error.file):\(error.line): \(error.message)")
            }
            return false
        case .fixedAndRetrying:
            print("🔄 Build retrying after automatic fixes")
        }
        
        // Step 2: Run tests
        print("🧪 Running tests...")
        let testResult = runTests(projectPath: projectPath)
        if !testResult {
            print("❌ Tests failed")
            return false
        }
        print("✅ Tests passed")
        
        // Step 3: Code quality checks
        print("🔍 Running code quality checks...")
        let qualityResult = runQualityChecks(projectPath: projectPath)
        if !qualityResult {
            print("⚠️ Code quality issues detected")
            // Don't fail CI for quality issues, just warn
        }
        
        print("🎉 CI Pipeline completed successfully!")
        return true
    }
    
    private static func runTests(projectPath: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        task.arguments = ["test", "--package-path", projectPath]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return false
        }
        
        return task.terminationStatus == 0
    }
    
    private static func runQualityChecks(projectPath: String) -> Bool {
        // Placeholder for code quality checks
        // Could integrate with SwiftLint, etc.
        return true
    }
}