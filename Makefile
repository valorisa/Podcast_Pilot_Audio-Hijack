.PHONY: help build test lint clean install sign-dev

BINARY := podcastpilot
BUILD_DIR := .build/release

help:
	@echo "PodcastPilot — cibles disponibles :"
	@echo "  build     Build universal (arm64 + x86_64)"
	@echo "  test      swift test"
	@echo "  lint      swiftlint --strict"
	@echo "  clean     rm -rf .build"
	@echo "  install   build + ad-hoc sign + copy vers /usr/local/bin"
	@echo "  sign-dev  Ad-hoc sign du binaire pour tests locaux"

build:
	swift build -c release --arch arm64 --arch x86_64 --product $(BINARY)

test:
	swift test --parallel

lint:
	swiftlint lint --strict Sources/ Tests/

clean:
	rm -rf .build .swiftpm dist staging_*

sign-dev: build
	codesign --force --deep --sign - \
		--entitlements Resources/PodcastPilot.entitlements \
		$(BUILD_DIR)/$(BINARY)
	codesign -vvv $(BUILD_DIR)/$(BINARY)

install: sign-dev
	sudo cp $(BUILD_DIR)/$(BINARY) /usr/local/bin/$(BINARY)
	@echo "Installé : /usr/local/bin/$(BINARY)"
