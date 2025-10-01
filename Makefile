.PHONY: build run clean format lint help

help:
	@echo "VoiceOS - macOS Menu Bar Transcription App"
	@echo ""
	@echo "Available commands:"
	@echo "  make build   - Build the app"
	@echo "  make run     - Build and run the app"
	@echo "  make clean   - Clean build artifacts"
	@echo "  make format  - Format Swift code"
	@echo "  make lint    - Lint Swift code"
	@echo "  make help    - Show this help message"

build:
	@echo "Building VoiceOS..."
	@swift build

run: build
	@echo "Running VoiceOS..."
	@./.build/debug/VoiceOS

clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build

format:
	@echo "Formatting Swift code..."
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format -i -r VoiceOS/; \
		echo "Code formatted successfully"; \
	else \
		echo "swift-format not installed. Install with: brew install swift-format"; \
	fi

lint:
	@echo "Linting Swift code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint VoiceOS/; \
	else \
		echo "swiftlint not installed. Install with: brew install swiftlint"; \
	fi
