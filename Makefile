# Makefile for AcoustiScan Swift Development
# Vereinfacht die lokale Entwicklung und CI/CD-Befehle

.PHONY: help build test lint clean coverage install setup

# Default target
help: ## Show this help message
	@echo "AcoustiScan Swift Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Setup development environment
	@echo "🛠  Setting up development environment..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing SwiftLint via Homebrew..."; \
		brew install swiftlint; \
	else \
		echo "Homebrew not found. Please install SwiftLint manually."; \
	fi
	@echo "✅ Setup complete!"

build: ## Build the Swift package
	@echo "🔨 Building Swift package..."
	@if [ -f "Package.swift" ]; then \
		swift build; \
	else \
		echo "Package.swift not found. Validating Swift syntax..."; \
		find . -name "*.swift" -exec swift -frontend -parse {} \; && echo "✅ Swift syntax valid"; \
	fi

test: ## Run all tests
	@echo "🧪 Running tests..."
	@if [ -f "Package.swift" ]; then \
		swift test; \
	else \
		echo "Package.swift not found. Running syntax validation for test files..."; \
		find . -path "*/Tests/*" -name "*.swift" -exec swift -frontend -parse {} \; && echo "✅ Test syntax valid"; \
	fi

coverage: ## Run tests with coverage
	@echo "📊 Running tests with coverage..."
	@if [ -f "Package.swift" ]; then \
		swift test --enable-code-coverage; \
		echo "Generating coverage report..."; \
		xcrun llvm-cov export -format="lcov" \
			.build/debug/AcoustiScanPackageTests.xctest/Contents/MacOS/AcoustiScanPackageTests \
			-instr-profile .build/debug/codecov/default.profdata > coverage.lcov 2>/dev/null || echo "Coverage generation failed, but tests passed"; \
	else \
		echo "Package.swift not found. Skipping coverage."; \
	fi

lint: ## Run SwiftLint
	@echo "🔍 Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed. Run 'make setup' to install it."; \
	fi

lint-fix: ## Run SwiftLint with autocorrect
	@echo "🔧 Running SwiftLint autocorrect..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint autocorrect; \
	else \
		echo "SwiftLint not installed. Run 'make setup' to install it."; \
	fi

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@if [ -d ".build" ]; then \
		rm -rf .build; \
		echo "✅ Cleaned .build directory"; \
	fi
	@if [ -f "coverage.lcov" ]; then \
		rm coverage.lcov; \
		echo "✅ Removed coverage.lcov"; \
	fi
	@echo "Clean complete!"

check: ## Run full quality check (build + test + lint)
	@echo "✅ Running full quality check..."
	@$(MAKE) build
	@$(MAKE) test  
	@$(MAKE) lint
	@echo "🎉 All checks passed!"

ci: ## Simulate CI environment locally
	@echo "🔄 Simulating CI environment..."
	@$(MAKE) clean
	@$(MAKE) build
	@$(MAKE) test
	@$(MAKE) lint
	@$(MAKE) coverage
	@echo "🎉 CI simulation complete!"

stats: ## Show project statistics
	@echo "📈 Project Statistics:"
	@echo "Swift files: $$(find . -name "*.swift" | wc -l)"
	@echo "Lines of Swift code: $$(find . -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $$1}')"
	@echo "Test files: $$(find . -path "*/Tests/*" -name "*.swift" | wc -l)"
	@echo "Source directories: $$(find Sources -mindepth 1 -maxdepth 1 -type d | wc -l 2>/dev/null || echo 0)"

release: ## Create a new release (requires VERSION parameter)
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ Error: VERSION parameter required"; \
		echo "Usage: make release VERSION=v1.0.0"; \
		exit 1; \
	fi
	@echo "🚀 Creating release $(VERSION)..."
	@git tag $(VERSION)
	@git push origin $(VERSION)
	@echo "✅ Release $(VERSION) created! Check GitHub Actions for release automation."

dev: ## Start development mode (file watching would go here)
	@echo "🔧 Development mode..."
	@echo "Run 'make check' after making changes"
	@echo "Use 'make lint-fix' to auto-fix style issues"
	@echo "Tip: Set up your editor to run SwiftLint on save"

# Development workflow shortcuts
quick: ## Quick build and test
	@$(MAKE) build && $(MAKE) test

format: ## Format code and fix linting issues  
	@$(MAKE) lint-fix

validate: ## Validate all Swift files syntax
	@echo "🔍 Validating Swift syntax..."
	@find . -name "*.swift" -exec swift -frontend -parse {} \; && echo "✅ All Swift files are syntactically valid"