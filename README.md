# 🎙️ PodcastPilot

> CLI macOS pour piloter Audio Hijack depuis le terminal — et automatiser l'export
> des enregistrements. Zéro reverse engineering, AppleScript officiel uniquement.

![macOS](https://img.shields.io/badge/macOS-14+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![License](https://img.shields.io/badge/License-MIT-yellow) ![Status](https://img.shields.io/badge/Status-alpha-red)

## Ce que ça fait

```bash
podcastpilot list                              # Liste les sessions Audio Hijack
podcastpilot start "Mon Podcast"               # Démarre une session
podcastpilot stop  "Mon Podcast"               # Arrête une session
podcastpilot watch --config ~/.ppilot.toml     # Auto-export des enregistrements
```

Le `watch` surveille le dossier de sortie d'Audio Hijack, normalise chaque nouvel
enregistrement à **-16 LUFS** (standard podcast), embarque les métadonnées, renomme
via un template et range dans un dossier propre. **Idempotent** : redémarre sans
retraiter.

## Installation

```bash
# Homebrew (à partir de v1.0)
brew install valorisa/tap/podcastpilot

# Depuis les sources (maintenant)
git clone https://github.com/valorisa/Podcast_Pilot_Audio-Hijack.git
cd Podcast_Pilot_Audio-Hijack && make install
```

Prérequis : macOS 14+, Audio Hijack 4.5.7+, `ffmpeg` (`brew install ffmpeg`).

## Première utilisation

```bash
podcastpilot list
```

macOS te demandera *"PodcastPilot wants to control Audio Hijack"* → **Autoriser**.
Si tu refuses, va dans `Réglages Système → Confidentialité → Automatisation`.

## Config `~/.ppilot.toml` (optionnel, pour `watch`)

```toml
source_dir       = "~/Music/Audio Hijack"
output_dir       = "~/Podcasts/Ready"
template         = "{show}/EP{episode}_{title}.m4a"
loudness_target  = -16.0
```

## Docs

- [`docs/architecture.md`](docs/architecture.md) — choix techniques (ADR)
- [`docs/applescript.md`](docs/applescript.md) — référence AppleScript Audio Hijack
- [`docs/security.md`](docs/security.md) — modèle de menaces, entitlements, TCC
- [`CHANGELOG.md`](CHANGELOG.md) — historique des versions

## Contribuer

Issues et PRs bienvenues. Lire [`CONTRIBUTING.md`](CONTRIBUTING.md) avant d'ouvrir
une PR. Conventional Commits requis.

## License

MIT © 2026 [@valorisa](https://github.com/valorisa). PodcastPilot n'est pas affilié
à Rogue Amoeba. Audio Hijack™ est une marque de Rogue Amoeba Software, Inc.
