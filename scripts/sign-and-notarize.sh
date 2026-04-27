#!/usr/bin/env bash
#
# sign-and-notarize.sh — build + sign + notarize + staple pour distribution
# Requis (env vars, injectés via GitHub Secrets en CI) :
#   DEVELOPER_ID_APP, DEVELOPER_ID_INSTALLER, APPLE_ID, APP_PASSWORD, TEAM_ID
# Optionnel : VERSION (défaut : 0.1.0-dev)
#
set -euo pipefail

: "${DEVELOPER_ID_APP:?manque DEVELOPER_ID_APP}"
: "${DEVELOPER_ID_INSTALLER:?manque DEVELOPER_ID_INSTALLER}"
: "${APPLE_ID:?manque APPLE_ID}"
: "${APP_PASSWORD:?manque APP_PASSWORD}"
: "${TEAM_ID:?manque TEAM_ID}"

BINARY="podcastpilot"
BUNDLE_ID="io.github.valorisa.podcastpilot"
VERSION="${VERSION:-0.1.0-dev}"
BUILD_DIR=".build/release"
STAGING="staging_$$"
DIST="dist"

cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT INT TERM

log() { echo "▶ $*"; }
die() { echo "✖ $*" >&2; exit 1; }

log "Build universal (arm64 + x86_64)…"
swift build -c release --arch arm64 --arch x86_64 --product "$BINARY"

log "Sign binaire avec Hardened Runtime…"
codesign --force --deep --sign "$DEVELOPER_ID_APP" \
  --entitlements Resources/PodcastPilot.entitlements \
  --options runtime --timestamp \
  "$BUILD_DIR/$BINARY"

codesign -vvv --deep --strict "$BUILD_DIR/$BINARY" || die "Signature invalide"

log "Staging pour productbuild…"
mkdir -p "$STAGING/usr/local/bin"
cp "$BUILD_DIR/$BINARY" "$STAGING/usr/local/bin/$BINARY"

log "Création du .pkg…"
mkdir -p "$DIST"
productbuild --component "$STAGING/usr/local/bin/$BINARY" /usr/local/bin \
  --identifier "$BUNDLE_ID" \
  --version "$VERSION" \
  --sign "$DEVELOPER_ID_INSTALLER" \
  "$DIST/PodcastPilot.pkg"

log "Notarisation (notarytool --wait)…"
xcrun notarytool submit "$DIST/PodcastPilot.pkg" \
  --apple-id "$APPLE_ID" \
  --password "$APP_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

log "Stapling du ticket…"
xcrun stapler staple "$DIST/PodcastPilot.pkg"

log "Audit final spctl…"
spctl --assess -vv --type install "$DIST/PodcastPilot.pkg"

log "SHA256…"
shasum -a 256 "$DIST/PodcastPilot.pkg" > "$DIST/PodcastPilot.pkg.sha256"

log "✓ Livré : $DIST/PodcastPilot.pkg ($VERSION)"
cat "$DIST/PodcastPilot.pkg.sha256"
