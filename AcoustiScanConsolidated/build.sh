#!/bin/bash
# build.sh - Automated build script with error detection and fixing

set -e

echo "[LAUNCH] AcoustiScan Consolidated Tool - Automated Build Script"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACTS_DIR="$PROJECT_DIR/../Artifacts"
MAX_RETRIES=3
BUILD_LOG="build.log"

echo -e "${BLUE}📁 Project directory: ${PROJECT_DIR}${NC}"

# Create Artifacts directory at project root for CI/CD integration
mkdir -p "$ARTIFACTS_DIR"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Swift is available
check_swift() {
    if ! command -v swift &> /dev/null; then
        print_status $RED "[FAILED] Swift is not installed or not in PATH"
        exit 1
    fi

    local swift_version=$(swift --version | head -n 1)
    print_status $GREEN "[DONE] Swift found: $swift_version"
}

# Function to clean build artifacts
clean_build() {
    print_status $YELLOW "🧹 Cleaning build artifacts..."
    if [ -d ".build" ]; then
        rm -rf .build
        print_status $GREEN "[DONE] Cleaned .build directory"
    fi
}

# Function to run swift build with retry logic
build_with_retry() {
    local retry_count=0
    local build_success=false

    while [ $retry_count -lt $MAX_RETRIES ] && [ "$build_success" = false ]; do
        print_status $BLUE "🔨 Build attempt $((retry_count + 1))/$MAX_RETRIES"

        # Run swift build and capture output
        if swift build 2>&1 | tee $BUILD_LOG; then
            build_success=true
            print_status $GREEN "[DONE] Build successful!"
        else
            print_status $YELLOW "[WARNING]️ Build failed, analyzing errors..."

            # Attempt to fix common errors
            if fix_common_errors; then
                print_status $BLUE "[FIX] Applied fixes, retrying build..."
                retry_count=$((retry_count + 1))
            else
                print_status $RED "[FAILED] Could not fix build errors automatically"
                break
            fi
        fi
    done

    if [ "$build_success" = false ]; then
        print_status $RED "[FAILED] Build failed after $MAX_RETRIES attempts"
        print_status $YELLOW "[LIST] Build log saved to: $BUILD_LOG"
        # Copy build log to Artifacts directory for CI/CD upload
        if ! cp "$BUILD_LOG" "$ARTIFACTS_DIR/"; then
            print_status $YELLOW "[WARNING]️  Failed to copy build log to Artifacts directory"
        fi
        exit 1
    fi
}

# Function to fix common build errors
fix_common_errors() {
    local fixed_something=false

    print_status $BLUE "[CHECK] Analyzing build errors..."

    # Check for missing import statements
    if grep -q "No such module" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected missing module errors"
        if fix_missing_imports; then
            fixed_something=true
        fi
    fi

    # Check for syntax errors
    if grep -q "expected" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected potential syntax errors"
        if fix_syntax_errors; then
            fixed_something=true
        fi
    fi

    # Check for access control issues
    if grep -q "is not accessible" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected access control issues"
        if fix_access_control_issues; then
            fixed_something=true
        fi
    fi

    # Check for deprecated API usage
    if grep -q "deprecated" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected deprecated API usage"
        if fix_deprecated_apis; then
            fixed_something=true
        fi
    fi

    # Check for type mismatch errors
    if grep -q "Cannot convert value of type" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected type conversion errors"
        if fix_type_errors; then
            fixed_something=true
        fi
    fi

    # Check for package resolution issues
    if grep -q "package dependency" $BUILD_LOG || grep -q "could not resolve" $BUILD_LOG; then
        print_status $YELLOW "[CHECK] Detected package dependency issues"
        if fix_package_issues; then
            fixed_something=true
        fi
    fi

    return $([ "$fixed_something" = true ])
}

# Function to fix missing import statements
fix_missing_imports() {
    local modules_to_add=()

    # Extract missing modules from build log
    while IFS= read -r line; do
        if [[ $line =~ "No such module '"([^\']+)"'" ]]; then
            modules_to_add+=("${BASH_REMATCH[1]}")
        fi
    done < $BUILD_LOG

    # Add missing imports to files
    for module in "${modules_to_add[@]}"; do
        print_status $BLUE "[PACKAGE] Adding import for module: $module"

        # Find Swift files that might need this import
        find Sources -name "*.swift" -exec grep -l "$module" {} \; | while read -r file; do
            if ! grep -q "^import $module" "$file"; then
                # Add import after existing imports or at the top
                if grep -q "^import " "$file"; then
                    # Add after last import
                    sed -i.bak "/^import /a\\
import $module
" "$file"
                else
                    # Add at the top
                    sed -i.bak "1i\\
import $module
" "$file"
                fi
                print_status $GREEN "[DONE] Added 'import $module' to $file"
            fi
        done
    done
    return 0
}

# Function to fix syntax errors
fix_syntax_errors() {
    print_status $BLUE "[FIX] Attempting to fix syntax errors..."
    local fixed_any=false

    # Look for common syntax issues
    while IFS= read -r line; do
        if [[ $line =~ "expected ',' separator" ]]; then
            print_status $YELLOW "Found missing comma separator issue"
            # Could implement specific fixes here
        elif [[ $line =~ "expected '}'" ]]; then
            print_status $YELLOW "Found missing closing brace issue"
            # Could implement specific fixes here
        elif [[ $line =~ "expected ']'" ]]; then
            print_status $YELLOW "Found missing closing bracket issue"
            # Could implement specific fixes here
        fi
    done < $BUILD_LOG

    return $fixed_any
}

# Function to fix access control issues
fix_access_control_issues() {
    print_status $BLUE "[FIX] Attempting to fix access control issues..."
    local fixed_any=false

    # Look for access control patterns
    while IFS= read -r line; do
        if [[ $line =~ "'([^']+)' is not accessible due to '([^']+)' protection level" ]]; then
            local symbol="${BASH_REMATCH[1]}"
            local protection="${BASH_REMATCH[2]}"
            print_status $YELLOW "Found inaccessible symbol: $symbol (protection: $protection)"
            # Could implement specific access control fixes here
            # For now, just log the issue
        fi
    done < $BUILD_LOG

    return $fixed_any
}

# Function to fix deprecated API usage
fix_deprecated_apis() {
    print_status $BLUE "[FIX] Attempting to fix deprecated API usage..."
    local fixed_any=false

    # Look for deprecation warnings
    while IFS= read -r line; do
        if [[ $line =~ "'([^']+)' is deprecated" ]]; then
            local deprecated_api="${BASH_REMATCH[1]}"
            print_status $YELLOW "Found deprecated API: $deprecated_api"
            # Log for manual review - automated fixing could be risky
        fi
    done < $BUILD_LOG

    return $fixed_any
}

# Function to fix type errors
fix_type_errors() {
    print_status $BLUE "[FIX] Attempting to fix type conversion errors..."
    local fixed_any=false

    # Look for type conversion issues
    while IFS= read -r line; do
        if [[ $line =~ "Cannot convert value of type '([^']+)' to expected argument type '([^']+)'" ]]; then
            local from_type="${BASH_REMATCH[1]}"
            local to_type="${BASH_REMATCH[2]}"
            print_status $YELLOW "Found type mismatch: $from_type -> $to_type"
            # Could implement specific type conversion fixes here
        fi
    done < $BUILD_LOG

    return $fixed_any
}

# Function to fix package dependency issues
fix_package_issues() {
    print_status $BLUE "[FIX] Attempting to fix package dependency issues..."
    local fixed_any=false

    # Try common package fixes
    print_status $YELLOW "Cleaning package cache..."
    swift package clean

    print_status $YELLOW "Resetting package state..."
    rm -rf .build Package.resolved

    print_status $YELLOW "Resolving dependencies..."
    if swift package resolve; then
        print_status $GREEN "[DONE] Dependencies resolved successfully"
        fixed_any=true
    else
        print_status $RED "[FAILED] Could not resolve dependencies"

        # Try updating dependencies
        print_status $YELLOW "Attempting to update dependencies..."
        if swift package update; then
            print_status $GREEN "[DONE] Dependencies updated successfully"
            fixed_any=true
        fi
    fi

    return $([ "$fixed_any" = true ])
}

# Function to run tests
run_tests() {
    print_status $BLUE "🧪 Running tests..."

    if swift test 2>&1 | tee test.log; then
        print_status $GREEN "[DONE] All tests passed!"
    else
        print_status $RED "[FAILED] Some tests failed"
        print_status $YELLOW "[LIST] Test log saved to: test.log"
        # Copy test log to Artifacts directory for CI/CD upload
        if ! cp test.log "$ARTIFACTS_DIR/"; then
            print_status $YELLOW "[WARNING]️  Failed to copy test log to Artifacts directory"
        fi
        return 1
    fi
}

# Function to build release version
build_release() {
    print_status $BLUE "[TARGET] Building release version..."

    if swift build -c release; then
        print_status $GREEN "[DONE] Release build successful!"

        # Show binary location
        local binary_path=$(swift build -c release --show-bin-path)/AcoustiScanTool
        if [ -f "$binary_path" ]; then
            print_status $GREEN "[PACKAGE] Binary available at: $binary_path"

            # Show binary size
            local size=$(ls -lh "$binary_path" | awk '{print $5}')
            print_status $BLUE "📏 Binary size: $size"
        fi
    else
        print_status $RED "[FAILED] Release build failed"
        return 1
    fi
}

# Function to generate documentation
generate_docs() {
    print_status $BLUE "[DOCS] Generating documentation..."

    # Use swift-docc if available
    if command -v swift-docc &> /dev/null; then
        swift package generate-documentation
        print_status $GREEN "[DONE] Documentation generated"
    else
        print_status $YELLOW "[WARNING]️ swift-docc not available, skipping documentation generation"
    fi
}

# Function to run code quality checks
run_quality_checks() {
    print_status $BLUE "[CHECK] Running code quality checks..."

    # Basic file checks
    local swift_files=$(find Sources -name "*.swift" | wc -l)
    local test_files=$(find Tests -name "*.swift" | wc -l)

    print_status $GREEN "[STATS] Found $swift_files Swift source files"
    print_status $GREEN "[STATS] Found $test_files test files"

    # Check for TODOs and FIXMEs
    local todos=$(grep -r "TODO\|FIXME" Sources | wc -l)
    if [ $todos -gt 0 ]; then
        print_status $YELLOW "[WARNING]️ Found $todos TODO/FIXME comments"
    fi

    # Check for hardcoded strings (potential localization issues)
    local hardcoded=$(grep -r '"[^"]*"' Sources --include="*.swift" | grep -v "test\|Test" | wc -l)
    print_status $BLUE "[NOTE] Found $hardcoded string literals"
}

# Function to create package
create_package() {
    print_status $BLUE "[PACKAGE] Creating distribution package..."

    local package_name="AcoustiScanConsolidated-$(date +%Y%m%d)"
    local package_dir="dist/$package_name"

    mkdir -p "$package_dir"

    # Copy binary
    local binary_path=$(swift build -c release --show-bin-path)/AcoustiScanTool
    if [ -f "$binary_path" ]; then
        cp "$binary_path" "$package_dir/"
        print_status $GREEN "[DONE] Binary copied to package"
    fi

    # Copy documentation
    cp README.md "$package_dir/" 2>/dev/null || echo "# AcoustiScan Consolidated Tool" > "$package_dir/README.md"

    # Create archive
    cd dist
    tar -czf "$package_name.tar.gz" "$package_name"
    print_status $GREEN "[DONE] Package created: dist/$package_name.tar.gz"
    cd ..
}

# Main execution
main() {
    print_status $BLUE "[MUSIC] Starting automated build process..."

    # Change to project directory
    cd "$PROJECT_DIR"

    # Check prerequisites
    check_swift

    # Parse command line arguments
    case "${1:-build}" in
        "clean")
            clean_build
            ;;
        "test")
            build_with_retry
            run_tests
            ;;
        "release")
            clean_build
            build_with_retry
            run_tests
            build_release
            ;;
        "package")
            clean_build
            build_with_retry
            run_tests
            build_release
            create_package
            ;;
        "docs")
            generate_docs
            ;;
        "quality")
            run_quality_checks
            ;;
        "all")
            clean_build
            build_with_retry
            run_tests
            build_release
            generate_docs
            run_quality_checks
            create_package
            ;;
        *)
            build_with_retry
            ;;
    esac

    print_status $GREEN "🎉 Build process completed successfully!"
}

# Handle script interruption
trap 'print_status $RED "[FAILED] Build process interrupted"; exit 1' INT TERM

# Run main function with all arguments
main "$@"