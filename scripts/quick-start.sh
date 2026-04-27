#!/usr/bin/env bash
#
# quick-start.sh — bootstrap idempotent PodcastPilot
# Usage : ./scripts/quick-start.sh [--verbose]
#
set -euo pipefail

VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --verbose|-v) VERBOSE=1 ;;
    --help|-h) echo "Usage: $0 [--verbose]"; exit 0 ;;
  esac
done

log()  { echo "▶ $*"; }
warn() { echo "⚠ $*" >&2; }
die()  { echo "✖ $*" >&2; exit 1; }

# --- Checks macOS
[[ "$(uname)" == "Darwin" ]] || die "PodcastPilot nécessite macOS."

macos_version="$(sw_vers -productVersion | cut -d. -f1)"
[[ "$macos_version" -ge 14 ]] || die "macOS 14+ requis (détecté: $macos_version)."

# --- Toolchain
command -v swift >/dev/null 2>&1 || die "Swift introuvable. Installer Xcode CLT : xcode-select --install"

if ! command -v ffmpeg >/dev/null 2>&1; then
  warn "ffmpeg non installé — requis pour 'watch'. Installe-le : brew install ffmpeg"
fi

# --- Audio Hijack détection (non bloquant)
if [[ ! -d "/Applications/Audio Hijack.app" ]]; then
  warn "Audio Hijack.app introuvable dans /Applications (la CLI se lance quand même)."
fi

# --- Dépendances SPM
log "Résolution des dépendances SPM…"
swift package resolve ${VERBOSE:+--verbose}

# --- Build
log "Build release (universal)…"
swift build -c release --arch arm64 --arch x86_64 --product podcastpilot

# --- Ad-hoc sign (pour dev local)
log "Ad-hoc sign…"
codesign --force --deep --sign - \
  --entitlements Resources/PodcastPilot.entitlements \
  .build/release/podcastpilot

# --- Smoke test
log "Smoke test : podcastpilot --version"
.build/release/podcastpilot --version

log "✓ OK. Binaire : .build/release/podcastpilot"
log "  Installer système : make install"
log "  Test fumée : .build/release/podcastpilot list"
