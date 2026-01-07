#!/bin/bash
set -euo pipefail

# SessionStart Hook for AcoustiScan RT60 iPad App
# This hook installs dependencies for Swift development on Claude Code Web

# Only run in remote (web) environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Not running in Claude Code remote environment, skipping..."
  exit 0
fi

echo "🚀 AcoustiScan Session Start Hook"
echo "================================="

# Check if Swift is available
if command -v swift &> /dev/null; then
  echo "✅ Swift found: $(swift --version 2>&1 | head -1)"
else
  echo "⚠️ Swift not found - this environment may not support Swift/iOS development"
  echo "   Tests and builds will not work without Swift toolchain"
fi

# Install SwiftLint if not present (for linting)
if command -v swiftlint &> /dev/null; then
  echo "✅ SwiftLint found: $(swiftlint version)"
else
  echo "📦 Installing SwiftLint..."
  if command -v brew &> /dev/null; then
    brew install swiftlint || echo "⚠️ SwiftLint installation failed"
  elif command -v apt-get &> /dev/null; then
    # Try installing via apt on Linux
    sudo apt-get update -qq && sudo apt-get install -y swiftlint 2>/dev/null || echo "⚠️ SwiftLint not available via apt"
  else
    echo "⚠️ Cannot install SwiftLint - no package manager found"
  fi
fi

# Install SwiftFormat if not present (for formatting)
if command -v swiftformat &> /dev/null; then
  echo "✅ SwiftFormat found: $(swiftformat --version)"
else
  echo "📦 Installing SwiftFormat..."
  if command -v brew &> /dev/null; then
    brew install swiftformat || echo "⚠️ SwiftFormat installation failed"
  else
    echo "⚠️ Cannot install SwiftFormat - brew not available"
  fi
fi

# Resolve Swift Package dependencies
echo ""
echo "📦 Resolving Swift Package dependencies..."

# AcoustiScanConsolidated
if [ -d "$CLAUDE_PROJECT_DIR/AcoustiScanConsolidated" ]; then
  echo "  → AcoustiScanConsolidated"
  cd "$CLAUDE_PROJECT_DIR/AcoustiScanConsolidated"
  swift package resolve 2>/dev/null || echo "    ⚠️ Package resolution failed (Swift may not be available)"
fi

# Modules/Export
if [ -d "$CLAUDE_PROJECT_DIR/Modules/Export" ]; then
  echo "  → Modules/Export"
  cd "$CLAUDE_PROJECT_DIR/Modules/Export"
  swift package resolve 2>/dev/null || echo "    ⚠️ Package resolution failed"
fi

# Return to project root
cd "$CLAUDE_PROJECT_DIR"

echo ""
echo "✅ Session start hook completed!"
echo ""
echo "Available commands:"
echo "  swift build    - Build Swift packages"
echo "  swift test     - Run tests"
echo "  swiftlint      - Run linter"
echo "  swiftformat .  - Format code"
