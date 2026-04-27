# Contribuer à PodcastPilot

Merci de l'intérêt. Guide court, au point.

## Setup

```bash
git clone https://github.com/valorisa/Podcast_Pilot_Audio-Hijack.git
cd Podcast_Pilot_Audio-Hijack
swift package resolve
swift test
```

Requis : macOS 14+, Xcode 15+, `ffmpeg` pour les tests d'intégration optionnels.

## Workflow

1. Fork + branche : `feat/xyz`, `fix/xyz`, `docs/xyz`, `refactor/xyz`.
2. Commits en [Conventional Commits](https://www.conventionalcommits.org/fr/) :
   `feat(cli): add --json flag to list`.
3. `swift test` passe. `swiftlint` sans erreur.
4. PR avec description claire + lien vers l'issue si applicable.

## Style

- Swift API Design Guidelines.
- Pas de `!` (force unwrap) en code prod.
- `actor` pour l'état partagé async. `Sendable` sur les modèles.
- Tests unitaires XCTest. Mock via protocoles, pas de swizzling.

## Issues de sécurité

Ne pas ouvrir d'issue publique. Mail : `security@valorisa.github.io` (placeholder
tant que le domaine n'est pas configuré — en attendant, DM GitHub).
