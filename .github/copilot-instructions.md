# RT60 iPad Akusti-Scan-APP Repository Instructions

Always follow these instructions first and fallback to additional search and context gathering only when the information in these instructions is incomplete or found to be in error.

## Working Effectively

### Repository Structure
- **Primary project**: `/AcoustiScanConsolidated/` - Swift Package Manager project with RT60 acoustic analysis tools
- **Documentation**: Root level markdown files (CONSOLIDATION_REPORT.md, audio_framework_validierung.md)
- **Legacy components**: `/RT60_014_Report_Erstellung/`, `/swift_coding/` - archived implementations
- **Main executable**: AcoustiScanTool CLI interface

### Dependencies and Prerequisites
- Swift 6.1.2+ (available at `/usr/local/bin/swift`)
- Linux environment (tested on Ubuntu)
- No additional system dependencies required

### Essential Build and Test Commands
Navigate to the main project directory first:
```bash
cd AcoustiScanConsolidated
```

#### Bootstrap and Build Process
```bash
# Resolve dependencies (takes ~15 seconds)
swift package resolve

# Debug build (takes ~9 seconds) 
swift build

# NEVER CANCEL: Release build (takes ~5 minutes, NEVER CANCEL, set timeout to 10+ minutes)
swift build -c release

# NEVER CANCEL: Run tests (takes ~2.5 minutes, NEVER CANCEL, set timeout to 5+ minutes)
swift test
```

#### Using the Automated Build Script
```bash
# Basic build
./build.sh

# NEVER CANCEL: Full release with tests (takes ~1.5 minutes, NEVER CANCEL, set timeout to 5+ minutes)
./build.sh release

# NEVER CANCEL: Complete package creation (takes ~2 minutes, NEVER CANCEL, set timeout to 5+ minutes)
./build.sh package

# Run code quality checks (takes ~10 seconds)
./build.sh quality

# Clean build artifacts
./build.sh clean
```

## Validation and Testing

### Manual Validation Requirements
Always test the CLI tool functionality after making changes:

```bash
# Test basic help (works)
swift run AcoustiScanTool --help

# Test acoustic analysis (works - outputs RT60 calculations)
swift run AcoustiScanTool analyze

# Test framework info (works - shows 48-parameter framework)
swift run AcoustiScanTool framework

# Test comparison tool (works - shows consolidation summary)
swift run AcoustiScanTool compare

# Test PDF report (works but limited on Linux - shows platform warning)
swift run AcoustiScanTool report
```

### Commands That Currently Fail
**IMPORTANT**: These CLI commands fail due to hardcoded Swift path (`/usr/bin/swift` vs actual `/usr/local/bin/swift`):
```bash
# DO NOT USE - These crash the application:
swift run AcoustiScanTool build    # Crashes - BuildAutomation module issue
swift run AcoustiScanTool ci       # Crashes - same BuildAutomation issue
```

If you need to fix the BuildAutomation module, update the hardcoded Swift path from `/usr/bin/swift` to `/usr/local/bin/swift` in `Sources/AcoustiScanConsolidated/BuildAutomation.swift`.

### Test Framework Execution
```bash
# NEVER CANCEL: Run complete test suite (2.5 minutes, set timeout to 5+ minutes)
swift test

# Specific test groups (if needed for debugging)
swift test --filter RT60CalculatorTests
swift test --filter DIN18041Tests
swift test --filter AcousticFrameworkTests
```

All tests should pass (16 tests total across multiple suites).

## Build Performance Expectations
- **Package resolution**: ~15 seconds
- **Debug build**: ~9 seconds  
- **Release build**: ~5 minutes (NEVER CANCEL)
- **Test execution**: ~2.5 minutes (NEVER CANCEL)
- **Full release build with tests**: ~1.5 minutes (NEVER CANCEL)

**CRITICAL**: Always set timeouts to at least double the expected time. NEVER CANCEL builds or tests even if they seem to hang.

## Project Navigation

### Key Source Files
- `Sources/AcoustiScanConsolidated/RT60Calculator.swift` - Core RT60 calculations using Sabine formula
- `Sources/AcoustiScanConsolidated/AcousticFramework.swift` - 48-parameter acoustic analysis framework
- `Sources/AcoustiScanConsolidated/ConsolidatedPDFExporter.swift` - PDF report generation
- `Sources/AcoustiScanConsolidated/BuildAutomation.swift` - Automated build system (has known Swift path issue)
- `Sources/AcoustiScanTool/main.swift` - CLI interface and command handling
- `Tests/AcoustiScanConsolidatedTests/AcoustiScanConsolidatedTests.swift` - Complete test suite

### Configuration Files  
- `Package.swift` - Swift Package Manager configuration (targets iOS 15+, macOS 12+)
- `build.sh` - Automated build script with error detection and retry logic
- `.gitignore` - Excludes build artifacts, logs, and distribution packages

### Documentation and Reports
- `README.md` (in AcoustiScanConsolidated/) - Comprehensive project documentation in German
- `../CONSOLIDATION_REPORT.md` - Details about consolidating 109 Swift files from 5 archives
- `../audio_framework_validierung.md` - 48-parameter framework validation details

## Common Development Tasks

### Making Code Changes
1. Navigate to `cd AcoustiScanConsolidated`
2. Make your changes to source files
3. Build and test: `swift build && swift test`
4. Validate CLI functionality: `swift run AcoustiScanTool analyze`
5. Run quality checks: `./build.sh quality`

### Adding New Features
- Follow existing patterns in the modular architecture
- Add tests in the test suite for new functionality
- Update README.md if adding new CLI commands
- Test both debug and release builds

### Debugging Build Issues
- Check `build.log` for detailed build output when using `./build.sh`
- Common deprecation warnings in BuildAutomation.swift are expected (use of `launchPath` and `launch()`)
- For Swift path issues, verify Swift location with `which swift`

## Platform Limitations
- **PDF generation**: Requires iOS/macOS platforms (UIKit/AppKit), limited on Linux
- **BuildAutomation**: Currently hardcoded for `/usr/bin/swift` path
- **Cross-platform testing**: Architecture tested on x86_64-unknown-linux-gnu

## Important Notes
- Project is primarily documented in German
- Contains consolidated acoustic analysis tools from multiple Swift implementations  
- 48-parameter framework represents significant scientific research in acoustic analysis
- CLI tool provides professional-grade RT60 calculations and DIN 18041 compliance checking
- Always run the working CLI commands for validation rather than the failing build/ci commands