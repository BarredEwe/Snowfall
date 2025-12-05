.PHONY: build archive release clean sha256 test audit install-local uninstall

APP_NAME = Snowfall
EXPORT_APP_NAME = SnowfallApp
SCHEME = SnowfallApp
BUILD_DIR = build
ARCHIVE_PATH = $(BUILD_DIR)/$(APP_NAME).xcarchive
EXPORT_PATH = $(BUILD_DIR)/export
APP_PATH = $(EXPORT_PATH)/$(EXPORT_APP_NAME).app
ZIP_PATH = $(BUILD_DIR)/$(APP_NAME).zip
VERSION = $(shell git describe --tags --abbrev=0 2>/dev/null || echo "0.0.1")
CASK_FILE = Casks/snowfall.rb

build:
	@echo "Building $(APP_NAME) for release..."
	xcodebuild -scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		archive

archive: build
	@echo "Exporting app..."
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist ExportOptions.plist
	
	@echo "Creating zip archive..."
	cd $(EXPORT_PATH) && zip -r ../../$(ZIP_PATH) $(EXPORT_APP_NAME).app
	@echo "Archive created: $(ZIP_PATH)"

release: archive
	@echo "Creating GitHub release..."
	gh release create $(VERSION) $(ZIP_PATH) \
		--title "$(APP_NAME) $(VERSION)" \
		--notes "Release $(VERSION)"

clean:
	rm -rf $(BUILD_DIR)

sha256:
	@echo "SHA256 hash:"
	@shasum -a 256 $(ZIP_PATH)

audit:
	@echo "🔍 Auditing cask formula..."
	@if [ -f "$(CASK_FILE)" ]; then \
		brew audit --cask snowfall; \
		brew style --fix $(CASK_FILE); \
	else \
		echo "❌ Cask file not found at $(CASK_FILE)"; \
		exit 1; \
	fi

install-local:
	@echo "📦 Installing from local cask..."
	@if [ -f "$(CASK_FILE)" ]; then \
		brew install --cask $(CASK_FILE); \
	else \
		echo "❌ Cask file not found at $(CASK_FILE)"; \
		exit 1; \
	fi

uninstall:
	@echo "🗑️  Uninstalling..."
	brew uninstall --cask snowfall

test: clean
	@echo "🚀 Starting full test cycle..."
	@echo ""
	@echo "📝 Step 1: Building and archiving..."
	@$(MAKE) archive
	@echo ""
	@echo "📝 Step 2: Calculating SHA256..."
	@$(MAKE) sha256
	@echo ""
	@echo "📝 Step 3: Verifying archive..."
	@if [ ! -f "$(ZIP_PATH)" ]; then \
		echo "❌ Archive not found!"; \
		exit 1; \
	fi
	@unzip -l $(ZIP_PATH) | grep -q "$(EXPORT_APP_NAME).app" && \
		echo "✅ Archive contains $(EXPORT_APP_NAME).app" || \
		(echo "❌ App not found in archive!" && exit 1)
	@echo ""
	@echo "📝 Step 4: Checking archive size..."
	@ls -lh $(ZIP_PATH) | awk '{print "Archive size: " $$5}'
	@echo ""
	@if [ -f "$(CASK_FILE)" ]; then \
		echo "📝 Step 5: Auditing cask..."; \
		$(MAKE) audit; \
	else \
		echo "⚠️  Step 5: Skipped (cask file not found)"; \
	fi
	@echo ""
	@echo "✨ All checks passed! Ready for release."

pre-release: test
	@echo ""
	@echo "🎯 Pre-release checklist:"
	@echo "  ✅ Build completed"
	@echo "  ✅ Archive created"
	@echo "  ✅ SHA256 calculated"
	@if [ -f "$(CASK_FILE)" ]; then \
		echo "  ✅ Cask audited"; \
	fi
	@echo ""
	@echo "Ready to create release with:"
	@echo "  make release"
	@echo "or manually with:"
	@echo "  gh release create $(VERSION) $(ZIP_PATH) --title '$(APP_NAME) $(VERSION)' --notes 'Release $(VERSION)'" 

help:
	@echo "Available commands:"
	@echo "  make build          - Build the app"
	@echo "  make archive        - Build and create zip archive"
	@echo "  make release        - Create GitHub release"
	@echo "  make clean          - Clean build directory"
	@echo "  make sha256         - Calculate SHA256 of archive"
	@echo "  make audit          - Audit homebrew cask"
	@echo "  make install-local  - Install from local cask file"
	@echo "  make uninstall      - Uninstall the app"
	@echo "  make test           - Run full test cycle"
	@echo "  make pre-release    - Check everything before release"
	@echo "  make help           - Show this help"
