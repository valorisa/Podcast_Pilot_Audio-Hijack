# Changelog

Le format suit [Keep a Changelog 1.1](https://keepachangelog.com/fr/1.1.0/) et ce
projet adhère à [Semantic Versioning 2.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial scaffolding (Swift 5.9, SPM, ArgumentParser)
- Commands: `list`, `start`, `stop`, `watch`
- `AudioHijackService` via OSAKit (AppleScript officiel)
- `ExportPipeline` avec stages composables et ledger JSONL idempotent
- `SessionWatcher` via FSEvents natif
- CI GitHub Actions (macOS 14 + 15) + release workflow signed/notarized
- Docs : architecture (ADR), applescript reference, security

### Known limitations
- `AudioHijackService` utilise des noms de propriétés AppleScript à valider
  contre le dictionnaire `.sdef` réel d'Audio Hijack 4.5.7 (marqués `TODO(sdef)`
  dans le code)
- Pas de support Shortcuts/AppIntents pour l'instant (prévu v0.3)
