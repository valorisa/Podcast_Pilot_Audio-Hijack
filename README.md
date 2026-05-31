# PodcastPilot

> CLI macOS pour piloter Audio Hijack depuis le terminal, et automatiser
> l'export des enregistrements. Zéro reverse engineering, AppleScript officiel
> uniquement.

[![macOS](https://img.shields.io/badge/macOS-14+-blue)][macos]
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)][swift]
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Status](https://img.shields.io/badge/Status-alpha-red)](CHANGELOG.md)

[macos]: https://www.apple.com/macos/
[swift]: https://swift.org

## Sommaire

- [À qui ça s'adresse](#à-qui-ça-sadresse)
- [Ce que ça fait](#ce-que-ça-fait)
- [Ce que ça ne fait pas](#ce-que-ça-ne-fait-pas)
- [Installation](#installation)
- [Première utilisation](#première-utilisation)
- [Commandes](#commandes)
- [Configuration de `watch`](#configuration-de-watch)
- [Idempotence et fiabilité](#idempotence-et-fiabilité)
- [Architecture en une image](#architecture-en-une-image)
- [Codes de sortie](#codes-de-sortie)
- [Dépannage](#dépannage)
- [Sécurité](#sécurité)
- [Feuille de route](#feuille-de-route)
- [Contribuer](#contribuer)
- [License et marques](#license-et-marques)

## À qui ça s'adresse

Podcasteurs, streamers et producteurs audio sur macOS qui utilisent déjà
[Audio Hijack](https://rogueamoeba.com/audiohijack/) et qui veulent arrêter de
cliquer partout. Si tu :

- automatises ton workflow avec Shortcuts, cron, ou un script shell,
- enregistres plusieurs sessions par semaine et veux standardiser la post-prod,
- publies sur Spotify, Apple Podcasts ou RSS et dois livrer à `-16 LUFS`,
- préfères une ligne de commande scriptable à une UI graphique,

tu es exactement le public cible. Si tu n'as jamais ouvert un terminal,
PodcastPilot n'est probablement pas pour toi — Audio Hijack seul fait déjà
très bien le travail en interactif.

## Ce que ça fait

PodcastPilot expose quatre commandes qui parlent à Audio Hijack via son
dictionnaire AppleScript officiel :

```bash
podcastpilot list                              # Liste les sessions Audio Hijack
podcastpilot start "Mon Podcast"               # Démarre une session
podcastpilot stop  "Mon Podcast"               # Arrête une session
podcastpilot watch --config ~/.ppilot.toml     # Auto-export des enregistrements
```

La commande `watch` est la plus intéressante. Elle surveille le dossier de
sortie d'Audio Hijack, et pour chaque nouveau fichier :

1. attend que l'écriture soit terminée (taille stable),
2. calcule une empreinte SHA256 pour détecter les doublons,
3. normalise le niveau sonore à `-16 LUFS` avec `ffmpeg loudnorm` (standard
   des plateformes podcast),
4. extrait les métadonnées depuis le nom de fichier (format
   `Show_Episode_Title.m4a`),
5. applique un template de nommage configurable,
6. range le fichier traité dans un dossier de destination, atomiquement
   (staging `.part` + rename).

## Ce que ça ne fait pas

Pour éviter tout malentendu :

- **Ce n'est pas un enregistreur audio.** Audio Hijack reste le logiciel qui
  capte le micro, la carte son, les applications. PodcastPilot ne touche jamais
  au hardware audio (l'entitlement `device.audio-input` est explicitement à
  `false`).
- **Ce n'est pas un DAW.** Pas d'édition, pas de mixage, pas d'effets au-delà
  de la normalisation loudness.
- **Ce n'est pas un hébergeur.** PodcastPilot produit un fichier prêt à
  uploader, pas un flux RSS.
- **Pas de reverse engineering.** Toute interaction avec Audio Hijack passe par
  le dictionnaire AppleScript officiel publié par Rogue Amoeba.
- **Pas multi-plateforme.** macOS 14+ uniquement, point. Audio Hijack n'existe
  pas ailleurs.

## Installation

### Depuis les sources (disponible maintenant)

```bash
git clone https://github.com/valorisa/Podcast_Pilot_Audio-Hijack.git
cd Podcast_Pilot_Audio-Hijack
./scripts/quick-start.sh
sudo make install
```

Le script `quick-start.sh` vérifie ta version de macOS, la présence du
toolchain Swift, build un binaire universel (arm64 + x86_64) et le signe en
ad-hoc pour les tests locaux. `make install` copie ensuite le binaire dans
`/usr/local/bin/podcastpilot`.

### Homebrew (prévu à partir de v1.0)

```bash
brew tap valorisa/podcast-pilot
brew install podcastpilot
```

### Prérequis

| Composant            | Min     | Notes                                 |
| -------------------- | ------- | ------------------------------------- |
| macOS                | 14      | Apple Silicon et Intel                |
| Audio Hijack         | 4.5.7   | Licence Rogue Amoeba requise          |
| Xcode CLT            | 15+     | `xcode-select --install`              |
| `ffmpeg`             | 6.0+    | `brew install ffmpeg`, requis `watch` |

## Première utilisation

Lance Audio Hijack, puis :

```bash
podcastpilot list
```

Au premier appel, macOS affiche :

> *PodcastPilot veut contrôler Audio Hijack.*

**Clique sur « Autoriser »**. Sans cette autorisation, aucune commande ne
fonctionnera (tu auras le code de sortie `12`). Le réglage est ensuite visible
dans `Réglages Système → Confidentialité et sécurité → Automatisation`,
révocable à tout moment.

Une sortie typique :

```text
Name         ID          State
-----------  ----------  --------
Mon Podcast  abc123de…   stopped
Interview    def456gh…   running
```

Pour piloter en script :

```bash
podcastpilot list --json | jq '.[] | select(.state == "running") | .name'
```

## Commandes

### `list`

```bash
podcastpilot list [--json]
```

Affiche toutes les sessions définies dans Audio Hijack. Le flag `--json`
retourne un tableau JSON directement exploitable par `jq`, par un script
Shortcuts, ou par un autre outil.

### `start`

```bash
podcastpilot start "Nom Exact De La Session"
```

Démarre la session dont le nom correspond **exactement** (sensible à la
casse). Si la session n'existe pas, le binaire sort avec le code `11`.

### `stop`

```bash
podcastpilot stop "Nom Exact De La Session"
```

Symétrique de `start`. Idempotent côté Audio Hijack : arrêter une session
déjà stoppée ne lève pas d'erreur.

### `watch`

```bash
podcastpilot watch [--config PATH] [--dry-run]
```

Démarre la surveillance du dossier source défini dans la configuration. Tourne
en avant-plan jusqu'à `Ctrl-C`. Pour un démarrage automatique au login, voir
`launchd` ou une entrée dans ton `~/.zshrc` selon tes préférences.

Le flag `--dry-run` affiche ce qui serait traité sans rien déplacer — utile
pour valider ton template avant un traitement en masse.

## Configuration de `watch`

Copie le template et adapte :

```bash
cp config.example.toml ~/.ppilot.toml
$EDITOR ~/.ppilot.toml
```

Fichier `~/.ppilot.toml` minimal :

```toml
source_dir       = "~/Music/Audio Hijack"
output_dir       = "~/Podcasts/Ready"
pattern          = "*.m4a"
template         = "{show}/EP{episode}_{title}.m4a"
loudness_target  = -16.0
embed_metadata   = true
artist           = "Mon Nom"
copyright        = "© 2026 Mon Studio"
```

Variables disponibles dans `template` : `{show}`, `{episode}`, `{title}`,
`{date}`. Les valeurs sont **sanitisées** automatiquement (seuls les
caractères `[A-Za-z0-9 _.-]` sont conservés) pour empêcher toute tentative
de path traversal via un nom de session malveillant.

Le format attendu par défaut pour les fichiers d'entrée est
`Show_Episode_Title.m4a`. Exemple : `MonPodcast_EP042_LInvitéeDuMois.m4a`
donne `MonPodcast / EP042 / LInvitéeDuMois.m4a` après traitement.

## Idempotence et fiabilité

`watch` est conçu pour tourner en continu et supporter les redémarrages sans
retraiter inutilement.

- **Identité par contenu, pas par nom** : chaque fichier source reçoit une
  empreinte `SHA256(premier_1MB + taille)`. Renommer la source ne déclenche pas
  un nouveau traitement.
- **Ledger persistant** : `~/.ppilot/ledger.jsonl` stocke une ligne JSON par
  fichier traité. Au démarrage, `watch` charge le ledger et ignore tout ce qui
  a déjà le statut `exported`.
- **Écritures atomiques** : le fichier final est d'abord écrit sous
  `destination.part`, puis renommé sur la destination finale une fois complet.
  Pas de fichier à moitié écrit visible en cas de crash.
- **Détection de fin d'écriture** : avant de traiter un fichier, `watch`
  attend deux lectures consécutives de taille stable (Audio Hijack peut
  écrire par chunks).
- **Reprise après échec** : si une étape échoue, une entrée `failed` est
  consignée au ledger. La reprise repart de zéro pour ce fichier au prochain
  démarrage, jusqu'à succès.

## Architecture en une image

```text
┌────────────────────────────────┐
│      podcastpilot (CLI)        │
│  ArgumentParser subcommands    │
└──────────────┬─────────────────┘
               │
      ┌────────┴─────────┐
      │                  │
      ▼                  ▼
┌──────────────┐  ┌─────────────────────┐
│ AudioHijack  │  │  SessionWatcher     │
│   Service    │  │  (FSEvents natif)   │
│  (OSAKit+JXA)│  │                     │
└──────┬───────┘  └──────────┬──────────┘
       │                     │
       │ Apple Events        │ ExportPipeline
       ▼                     ▼
┌──────────────┐   ┌──────────────────┐
│ Audio Hijack │   │  ExtractMetadata │
│ (closed src) │   │ LoudnessNormalize│
└──────────────┘   │  ApplyTemplate   │
                   │  AtomicMove      │
                   └─────────┬────────┘
                             │
                             ▼
                     ~/.ppilot/ledger.jsonl
```

Plus de détails dans [`docs/architecture.md`](docs/architecture.md).

## Codes de sortie

| Code | Signification                   | Cas typique                        |
| ---- | ------------------------------- | ---------------------------------- |
| 0    | Succès                          | Commande exécutée normalement      |
| 1    | Erreur générique                | Exception non catégorisée          |
| 10   | Audio Hijack n'est pas lancé    | Lance l'app avant de réessayer     |
| 11   | Session introuvable             | Vérifie le nom avec `list`         |
| 12   | Automation refusée (TCC)        | Autorise dans Réglages Système     |
| 13   | Échec AppleScript               | Voir stderr, souvent lié au `.sdef`|
| 14   | Argument invalide               | Flag ou argument mal formé         |
| 15   | Erreur de configuration         | `~/.ppilot.toml` invalide          |

## Dépannage

### « Audio Hijack n'est pas lancé » (code 10)

Lance Audio Hijack manuellement ou via `open -a "Audio Hijack"`. PodcastPilot
ne lance pas l'application automatiquement pour rester prévisible.

### « Permission d'automatisation refusée » (code 12)

Ouvre `Réglages Système → Confidentialité et sécurité → Automatisation`.
Trouve l'entrée `podcastpilot` ou `PodcastPilot`, puis coche `Audio Hijack`.

Pour réinitialiser le prompt et le revoir :

```bash
tccutil reset AppleEvents io.github.valorisa.podcastpilot
```

### « Session introuvable » (code 11)

Les noms sont sensibles à la casse. Utilise `podcastpilot list` pour voir les
noms exacts, y compris les espaces et caractères accentués.

### `watch` ne traite pas mes fichiers

Vérifie dans l'ordre :

1. `source_dir` dans `~/.ppilot.toml` pointe bien vers le dossier de sortie
   configuré dans Audio Hijack ?
2. Le `pattern` (glob) correspond à l'extension de tes fichiers ?
3. `ffmpeg` est bien dans le `PATH` ? (`which ffmpeg`)
4. Le ledger ne croit pas les avoir déjà traités ? Vérifie avec
   `cat ~/.ppilot/ledger.jsonl | jq '.source'`.

## Sécurité

- Binaire signé Developer ID + notarisé pour les releases publiques.
- Hardened Runtime activé (`codesign --options runtime`).
- Entitlements minimaux (voir [`docs/security.md`](docs/security.md)) :
  uniquement `automation.apple-events`, explicitement **pas**
  `device.audio-input`.
- Vérification avant installation :

  ```bash
  spctl --assess -vv --type install PodcastPilot.pkg
  xcrun stapler validate PodcastPilot.pkg
  shasum -a 256 PodcastPilot.pkg
  ```

Pour signaler une vulnérabilité, **ne pas ouvrir d'issue publique**. DM GitHub
à [@valorisa](https://github.com/valorisa) ou voir le contact dans
[`docs/security.md`](docs/security.md).

## Feuille de route

Ordre indicatif, priorités ajustables selon les retours :

- **v0.1** (actuel) : `list`, `start`, `stop`, `watch` fonctionnels. Code signé
  en ad-hoc pour dev local.
- **v0.2** : presets JSON (`preset save`, `preset load`) pour enchaîner
  plusieurs sessions en une commande.
- **v0.3** : intégration Shortcuts (AppIntents), Siri compatible.
- **v1.0** : tap Homebrew, `.pkg` notarisé, docs stables, engagement de
  support 12 mois.

Pas de menubar SwiftUI prévu tant que la CLI n'a pas trouvé son public. Pas
d'extension Windows/Linux (Audio Hijack n'existe pas ailleurs).

## Contribuer

Issues et PRs bienvenues.

- Lire [`CONTRIBUTING.md`](CONTRIBUTING.md) pour le workflow et le style.
- Respecter [Conventional Commits](https://www.conventionalcommits.org/fr/)
  (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `ci:`, `chore:`).
- Deux approbations nécessaires sur une PR avant merge.
- CI verte obligatoire (`swift test` + `swiftlint` + `shellcheck`).

## License et marques

MIT © 2026 [@valorisa](https://github.com/valorisa). Voir [`LICENSE`](LICENSE).

PodcastPilot n'est pas affilié à Rogue Amoeba Software, Inc. Audio Hijack est
une marque de Rogue Amoeba Software, Inc. L'interaction se fait exclusivement
via le dictionnaire AppleScript officiel publié par Rogue Amoeba.
