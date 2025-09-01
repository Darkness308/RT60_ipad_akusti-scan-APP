#!/bin/bash
# build.sh - Automated build script with error detection and fixing

set -e

echo "🚀 AcoustiScan Consolidated Tool - Automated Build Script"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_RETRIES=3
BUILD_LOG="build.log"

echo -e "${BLUE}📁 Project directory: ${PROJECT_DIR}${NC}"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Swift is available
check_swift() {
    if ! command -v swift &> /dev/null; then
        print_status $RED "❌ Swift is not installed or not in PATH"
        exit 1
    fi
    
    local swift_version=$(swift --version | head -n 1)
    print_status $GREEN "✅ Swift found: $swift_version"
}

# Function to clean build artifacts
clean_build() {
    print_status $YELLOW "🧹 Cleaning build artifacts..."
    if [ -d ".build" ]; then
        rm -rf .build
        print_status $GREEN "✅ Cleaned .build directory"
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
            print_status $GREEN "✅ Build successful!"
        else
            print_status $YELLOW "⚠️ Build failed, analyzing errors..."
            
            # Attempt to fix common errors
            if fix_common_errors; then
                print_status $BLUE "🔧 Applied fixes, retrying build..."
                retry_count=$((retry_count + 1))
            else
                print_status $RED "❌ Could not fix build errors automatically"
                break
            fi
        fi
    done
    
    if [ "$build_success" = false ]; then
        print_status $RED "❌ Build failed after $MAX_RETRIES attempts"
        print_status $YELLOW "📋 Build log saved to: $BUILD_LOG"
        exit 1
    fi
}

# Function to fix common build errors
fix_common_errors() {
    local fixed_something=false
    
    # Check for missing import statements
    if grep -q "No such module" $BUILD_LOG; then
        print_status $YELLOW "🔍 Detected missing module errors"
        fix_missing_imports
        fixed_something=true
    fi
    
    # Check for syntax errors
    if grep -q "expected" $BUILD_LOG; then
        print_status $YELLOW "🔍 Detected potential syntax errors"
        # Could implement basic syntax fixes here
    fi
    
    # Check for access control issues
    if grep -q "is not accessible" $BUILD_LOG; then
        print_status $YELLOW "🔍 Detected access control issues"
        # Could implement access control fixes here
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
        print_status $BLUE "📦 Adding import for module: $module"
        
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
                print_status $GREEN "✅ Added 'import $module' to $file"
            fi
        done
    done
}

# Function to run tests
run_tests() {
    print_status $BLUE "🧪 Running tests..."
    
    if swift test 2>&1 | tee test.log; then
        print_status $GREEN "✅ All tests passed!"
    else
        print_status $RED "❌ Some tests failed"
        print_status $YELLOW "📋 Test log saved to: test.log"
        return 1
    fi
}

# Function to build release version
build_release() {
    print_status $BLUE "🎯 Building release version..."
    
    if swift build -c release; then
        print_status $GREEN "✅ Release build successful!"
        
        # Show binary location
        local binary_path=$(swift build -c release --show-bin-path)/AcoustiScanTool
        if [ -f "$binary_path" ]; then
            print_status $GREEN "📦 Binary available at: $binary_path"
            
            # Show binary size
            local size=$(ls -lh "$binary_path" | awk '{print $5}')
            print_status $BLUE "📏 Binary size: $size"
        fi
    else
        print_status $RED "❌ Release build failed"
        return 1
    fi
}

# Function to generate documentation
generate_docs() {
    print_status $BLUE "📚 Generating documentation..."
    
    # Use swift-docc if available
    if command -v swift-docc &> /dev/null; then
        swift package generate-documentation
        print_status $GREEN "✅ Documentation generated"
    else
        print_status $YELLOW "⚠️ swift-docc not available, skipping documentation generation"
    fi
}

# Function to run code quality checks
run_quality_checks() {
    print_status $BLUE "🔍 Running code quality checks..."
    
    # Basic file checks
    local swift_files=$(find Sources -name "*.swift" | wc -l)
    local test_files=$(find Tests -name "*.swift" | wc -l)
    
    print_status $GREEN "📊 Found $swift_files Swift source files"
    print_status $GREEN "📊 Found $test_files test files"
    
    # Check for TODOs and FIXMEs
    local todos=$(grep -r "TODO\|FIXME" Sources | wc -l)
    if [ $todos -gt 0 ]; then
        print_status $YELLOW "⚠️ Found $todos TODO/FIXME comments"
    fi
    
    # Check for hardcoded strings (potential localization issues)
    local hardcoded=$(grep -r '"[^"]*"' Sources --include="*.swift" | grep -v "test\|Test" | wc -l)
    print_status $BLUE "📝 Found $hardcoded string literals"
}

# Function to create package
create_package() {
    print_status $BLUE "📦 Creating distribution package..."
    
    local package_name="AcoustiScanConsolidated-$(date +%Y%m%d)"
    local package_dir="dist/$package_name"
    
    mkdir -p "$package_dir"
    
    # Copy binary
    local binary_path=$(swift build -c release --show-bin-path)/AcoustiScanTool
    if [ -f "$binary_path" ]; then
        cp "$binary_path" "$package_dir/"
        print_status $GREEN "✅ Binary copied to package"
    fi
    
    # Copy documentation
    cp README.md "$package_dir/" 2>/dev/null || echo "# AcoustiScan Consolidated Tool" > "$package_dir/README.md"
    
    # Create archive
    cd dist
    tar -czf "$package_name.tar.gz" "$package_name"
    print_status $GREEN "✅ Package created: dist/$package_name.tar.gz"
    cd ..
}

# Main execution
main() {
    print_status $BLUE "🎵 Starting automated build process..."
    
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
trap 'print_status $RED "❌ Build process interrupted"; exit 1' INT TERM

# Run main function with all arguments
main "$@"