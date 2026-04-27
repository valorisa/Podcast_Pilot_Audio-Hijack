# Handover — reprise du projet PodcastPilot

> Note interne de passation destinée à l'instance Claude Opus 4.7 qui
> reprendra ce projet au prochain tour, très probablement depuis le Mac mini
> M2 de l'utilisateur. Lire **entièrement** avant toute action.

## 1. Qui je suis, qui tu es

- J'ai ouvert ce projet le **2026-04-27** depuis Windows 11 + Git Bash.
- L'utilisateur est **@valorisa** (GitHub), francophone, préfère des
  réponses en français, travaille sur `C:\Users\bbrod\Projets\` côté PC, et
  dispose d'un **Mac mini M2** pour le build natif.
- Règles de collaboration persistées en mémoire utilisateur :
  1. **Toujours expliquer en détail et attendre l'accord avant toute
     commande composée / enchaînée.**
  2. Pour tout binaire installé : SHA256 + recherche VirusTotal par URL
     (pas d'upload), systématiquement.
  3. Valider SHA256 avant de distribuer un artefact.
- Tu reprends donc un **projet en phase alpha** que l'utilisateur veut
  matérialiser proprement sur son Mac, pas un repo vierge.

## 2. État du repo au moment de la passation

- **Local (PC Windows)** : `C:\Users\bbrod\Projets\Podcast_Pilot_Audio-Hijack\`
- **GitHub public** : <https://github.com/valorisa/Podcast_Pilot_Audio-Hijack>
- **Branche** : `main`, à jour avec `origin/main`.
- **Commits** poussés (du plus récent au plus ancien) :
  1. `docs: expand README and add handover note` *(ce commit, créé juste avant
     de te passer la main)*
  2. `ci: add build and release workflows`
  3. `docs: add architecture ADR and security docs`
  4. `feat: add watch command with idempotent export pipeline`
  5. `feat: add list, start, stop commands`
  6. `chore: project scaffolding (v0.1.0-alpha)`

- **Fichiers** : 37 au total. Structure :

  ```text
  Podcast_Pilot_Audio-Hijack/
  ├── README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md
  ├── .gitignore, Package.swift, Makefile, swiftlint.yml, config.example.toml
  ├── Sources/PodcastPilot/
  │   ├── PodcastPilot.swift             (entry AsyncParsableCommand)
  │   ├── Commands/{List,Start,Stop,Watch}.swift
  │   ├── Services/
  │   │   ├── AudioHijackService.swift   (protocol + OSAKit/JXA impl)
  │   │   ├── SessionWatcher.swift       (FSEvents natif)
  │   │   └── ExportPipeline.swift       (stages + ledger idempotent)
  │   ├── Models/{Session, Config}.swift
  │   └── Utilities/{OutputFormatter, ErrorHandler}.swift
  ├── Tests/PodcastPilotTests/{Session, OutputFormatter, ExportPipeline}Tests.swift
  ├── docs/{architecture, applescript, security, HANDOVER}.md
  ├── .github/workflows/{ci, release}.yml
  ├── .github/ISSUE_TEMPLATE/{bug_report, feature_request}.md
  ├── .github/PULL_REQUEST_TEMPLATE.md
  ├── scripts/{quick-start, sign-and-notarize}.sh
  └── Resources/PodcastPilot.entitlements
  ```

## 3. Ce qui a été décidé et pourquoi

L'utilisateur m'a soumis une spec initiale v3 de ~2500 lignes en 5 modules
(scaffolding + MVP Swift/Python + docs + sécurité + infrastructure
communautaire). Après revue franche, **nous avons volontairement allégé**
d'environ 40 %. Ce qui a été **retiré** :

- **Toute la stack Python** (`podcast_autoexport.py`, `pyproject.toml`,
  `mutagen`, `watchdog`). Remplacée par du **Swift natif** : FSEvents +
  `Process` vers `ffmpeg` externe. Raison : un seul toolchain, un seul lint,
  un seul runner de tests, une seule CI.
- **Module 5 communautaire complet** (Discord setup, gouvernance BDFL, RFC
  template, LTS 12 mois, support matrix 6-types, métriques "stars ≥ 1500").
  Raison : bureaucratie prématurée sur un projet à 0 utilisateur.
- **`docs/naming.md`** (tableau de 3 noms alternatifs). Raison : décision
  prise — `PodcastPilot`.
- **Exemples 02 et 03** (live-stream router, interview multi-pistes). Raison :
  feature showcase, pas MVP.
- **Matrix CI macOS 13** (EOL Apple en 2026). Remplacée par macOS 14 + 15.

Ce qui a été **gardé et renforcé** :

- 4 commandes CLI : `list`, `start`, `stop`, `watch`.
- OSAKit + **JXA** (JavaScript for Automation) au lieu de NSAppleScript +
  regex. JXA retourne du JSON natif, zéro parsing fragile.
- **Idempotence forte** : identité par SHA256(1er MB + taille), ledger JSONL
  persistant dans `~/.ppilot/ledger.jsonl`.
- **Écriture atomique** : staging `.part` + rename.
- **Pipeline composable** : protocol `ExportStage`, 4 stages testables.
- **Anti path-traversal** sur le template (whitelist `[A-Za-z0-9 _.-]`).

Détail complet dans `docs/architecture.md`.

## 4. Ce qui n'a **pas** été vérifié et doit l'être

### 4.1 Le code Swift n'a jamais été compilé

Je suis sous Windows. Aucun `swift build` n'a tourné. **Il y aura très
probablement 1 à 3 erreurs de compilation** à corriger au premier build
Mac. Endroits sensibles à vérifier en priorité :

#### `Sources/PodcastPilot/Services/SessionWatcher.swift`

- Utilise `fnmatch()` : nécessite `import Darwin` si non implicite. Si
  erreur `cannot find 'fnmatch' in scope`, ajouter `import Darwin`.
- La closure FSEvents callback est une C function pointer : vérifier que
  la signature `FSEventStreamCallback` matche (strict concurrency peut
  râler sur la capture).
- `unsafeBitCast(paths, to: UnsafePointer<UnsafePointer<CChar>>?.self)` :
  sous strict concurrency (Swift 5.9+), ça peut exiger un `@unchecked
  Sendable` ou une refonte de la capture.

#### `Sources/PodcastPilot/Services/AudioHijackService.swift`

- `OSAScript(source:language:)` : vérifier que c'est bien la signature
  exposée par OSAKit sur macOS 14. Sinon, utiliser
  `OSAScript(source: String, fromURL: nil, languageInstance: nil,
  usingStorageOptions: [])` ou l'init simple `OSAScript(source:)` +
  setter de langue.
- `descriptor.stringValue` : peut être `nil` pour un résultat numérique
  ou booléen. JXA retourne une string JSON donc OK, mais garder en tête.
- `OSAScriptErrorNumber` / `OSAScriptErrorMessage` : constantes
  globales, vérifier qu'elles sont importées implicitement.

#### `Sources/PodcastPilot/Services/ExportPipeline.swift`

- `ISO8601DateFormatter()` créé à chaque `record()` : coûteux mais safe.
  À optimiser plus tard si profiling le justifie.
- `Process` avec `/usr/bin/env ffmpeg` : si `ffmpeg` n'est pas dans le
  `PATH` (cas courant pour un binaire lancé par `launchd`), fallback
  vers `/opt/homebrew/bin/ffmpeg` à ajouter.

### 4.2 Les 6 `TODO(sdef)` dans `AudioHijackService.swift`

**Bloquant pour un vrai fonctionnement.** Tout le code AppleScript est basé
sur des **suppositions** sur les noms de propriétés et de commandes du
dictionnaire Audio Hijack 4.5.7. À valider avant d'exécuter `list`, `start`,
`stop`, `watch` pour de vrai.

**Commande à lancer sur le Mac** :

```bash
sdef /Applications/Audio\ Hijack.app > /tmp/audiohijack.sdef
```

Ce qu'il faut vérifier dans le dump `.sdef` :

| Supposition actuelle            | À confirmer contre le .sdef             |
| ------------------------------- | --------------------------------------- |
| Classe `session`                | Nom exact de la classe principale       |
| Propriété `id` (text)           | Existe ? Read-only ?                    |
| Propriété `name` (text)         | Existe ? Read-write ?                   |
| Propriété `running` (boolean)   | Existe ? Read-only ?                    |
| Commande `start`                | Verbe exact pour lancer une session     |
| Commande `stop`                 | Verbe exact pour stopper une session    |
| Accès `ah.sessions()`           | Collection de premier niveau ?          |
| Filtre `whose({name: "…"})`     | JXA whose-clause supportée ?            |

Si les noms diffèrent, **mettre à jour uniquement** le fichier
`AudioHijackService.swift` — tout le reste du code appelle ce service via
son protocole, rien d'autre à toucher.

### 4.3 Le prompt TCC au premier lancement

La CLI n'a pas d'`Info.plist` de bundle au sens classique. Sur macOS 14+,
le prompt TCC pour Apple Events devrait quand même s'afficher car il est
déclenché par le premier envoi d'Apple Event, pas par la présence d'une
clé `NSAppleEventsUsageDescription`.

**À valider concrètement** : au premier `./.build/release/podcastpilot list`
sur le Mac, macOS affiche-t-il bien le prompt
« PodcastPilot wants to control Audio Hijack » ?

Si **non** (le prompt ne s'affiche pas et la commande échoue avec code 12),
il faut embarquer un Info.plist dans la section `__TEXT,__info_plist` du
binaire. Solution SPM :

```swift
// Package.swift, dans l'executableTarget :
.executableTarget(
    name: "PodcastPilot",
    // …
    linkerSettings: [
        .unsafeFlags([
            "-Xlinker", "-sectcreate",
            "-Xlinker", "__TEXT",
            "-Xlinker", "__info_plist",
            "-Xlinker", "Resources/Info.plist",
        ])
    ]
)
```

Avec un `Resources/Info.plist` minimal contenant au moins :

```xml
<key>CFBundleIdentifier</key>
<string>io.github.valorisa.podcastpilot</string>
<key>CFBundleName</key>
<string>PodcastPilot</string>
<key>NSAppleEventsUsageDescription</key>
<string>PodcastPilot contrôle Audio Hijack pour piloter les sessions.</string>
```

**Ne pas créer ce fichier tant que le test sur Mac n'a pas confirmé le
besoin** — pas de code spéculatif.

### 4.4 La CI n'a jamais tourné

Aucun workflow n'a été déclenché pour l'instant. Au prochain push, la CI
(`ci.yml`) va s'exécuter et va probablement révéler les erreurs de
compilation mentionnées en §4.1. C'est **attendu et utile**.

Le workflow `release.yml` ne tournera pas tant qu'un tag `v*.*.*` n'est
pas poussé ET que les 8 GitHub Secrets ne sont pas configurés :

- `DEVELOPER_ID_APP`
- `DEVELOPER_ID_INSTALLER`
- `APPLE_ID`
- `APP_PASSWORD`
- `TEAM_ID`
- `DEV_ID_CERT_P12_BASE64`
- `DEV_ID_CERT_PASSWORD`
- `KEYCHAIN_PASSWORD`

## 5. Plan recommandé pour ta session

Dans l'ordre, ne pas sauter d'étapes :

### Étape 1 — Arrivée sur le Mac (confirmer avec l'utilisateur)

```bash
# Clone
cd ~/Projets  # ou ailleurs au choix de l'utilisateur
git clone https://github.com/valorisa/Podcast_Pilot_Audio-Hijack.git
cd Podcast_Pilot_Audio-Hijack

# État
git log --oneline -10
git status
```

### Étape 2 — Bootstrap

```bash
chmod +x scripts/quick-start.sh scripts/sign-and-notarize.sh
./scripts/quick-start.sh --verbose
```

Le script va faire : vérif macOS ≥ 14, vérif Swift, vérif `ffmpeg`,
`swift package resolve`, `swift build -c release`, codesign ad-hoc, smoke
test `--version`.

**Attendu** : réussite ou 1-3 erreurs de compilation à corriger (§4.1).

### Étape 3 — Lever les TODO(sdef)

Avant d'essayer `list` / `start` / `stop` :

```bash
# Dump le dictionnaire
sdef /Applications/Audio\ Hijack.app > /tmp/audiohijack.sdef
cat /tmp/audiohijack.sdef
```

Confronter le dump aux 8 suppositions listées en §4.2. Ajuster
`Sources/PodcastPilot/Services/AudioHijackService.swift` si nécessaire.
**Commit séparé** pour cette étape, message type :
`fix(applescript): align with Audio Hijack 4.5.7 sdef`.

Mettre aussi à jour `docs/applescript.md` avec les noms confirmés —
c'est aujourd'hui un squelette à compléter.

### Étape 4 — Premier vrai test end-to-end

1. Lancer Audio Hijack (avec au moins une session configurée, peu importe
   laquelle).
2. Dans le terminal :

   ```bash
   ./.build/release/podcastpilot list
   ```

3. **Attendu** : prompt TCC « PodcastPilot wants to control Audio Hijack ».
   Cliquer **Autoriser**.
4. Si pas de prompt et code 12 retourné → aller en §4.3 (ajouter Info.plist
   embarqué).
5. Si tout fonctionne : tester `start`, `stop`, `list --json`.

### Étape 5 — Tester `watch`

Créer un fichier `~/.ppilot.toml` depuis `config.example.toml`, ajuster
les chemins, puis :

```bash
./.build/release/podcastpilot watch --dry-run
```

Déposer un faux `.m4a` dans le dossier surveillé, vérifier que la
détection fonctionne. Puis sans `--dry-run` pour valider le pipeline
complet (ffmpeg + rename + ledger).

### Étape 6 — Push des corrections

Quand tout tourne, pusher les corrections en petits commits sémantiques.
**Ne pas créer de tag `v0.1.0-alpha` sans l'accord explicite de
l'utilisateur** — il préfère valider avant chaque release.

## 6. Ce qu'il ne faut **pas** faire

- **Ne pas réintroduire le Python.** L'allègement est un choix délibéré,
  pas un oubli. Si un besoin émerge, en discuter avec l'utilisateur
  avant.
- **Ne pas remettre le Module 5 communautaire** (Discord setup,
  gouvernance BDFL, RFC template, LTS, support matrix). Explicitement
  reporté à « quand le projet aura ≥ 10 utilisateurs actifs ».
- **Ne pas pousser de `--force`** sur `main`. L'historique est propre,
  ne pas le casser.
- **Ne pas publier de `.pkg` notarisé** tant que l'utilisateur n'a pas
  explicitement vérifié et approuvé le SHA256.
- **Ne pas enchaîner de commandes composées (`&&`, `;`, pipe complexe)
  sans expliquer en détail et attendre l'accord.** C'est une règle
  durable de l'utilisateur, persistée en mémoire.
- **Ne pas créer de fichier spéculatif** (ex. Info.plist embarqué) sans
  preuve sur le Mac que c'est nécessaire.
- **Ne pas mettre d'emojis** dans les fichiers (code, commits, docs)
  sauf si l'utilisateur le demande explicitement. Le README actuel
  n'en a volontairement **plus** — ne pas en réintroduire.

## 7. Mémoire persistante que j'ai laissée

Fichier : `C:\Users\bbrod\.claude\projects\C--Windows-System32\memory\`

- `MEMORY.md` — index
- `user_profile.md` — profil utilisateur
- `feedback_command_validation.md` — règle « expliquer avant commandes
  enchaînées »
- `feedback_binary_install.md` — règle SHA256 + VirusTotal
- `project_podcast_pilot.md` — **à lire obligatoirement** au début de ta
  session, contient tous les détails du projet, les décisions, les noms
  canoniques, et les points à valider sur Mac

Cette mémoire est accessible depuis le PC Windows de l'utilisateur. Si
tu démarres la session depuis le Mac et que la mémoire n'est pas
accessible, demande à l'utilisateur de te lire les points pertinents —
ne devine pas.

## 8. Contexte opérationnel important

- **Date de la passation** : 2026-04-27 (20h30 GMT+2 environ).
- **Environnement PC** : Windows 11 Enterprise, Git Bash, Git 2.54,
  `gh` 2.91 authentifié sur `valorisa`.
- **Environnement Mac (cible)** : Mac mini M2, macOS présumé 14+ (à
  confirmer), Audio Hijack 4.5.7 installé (à confirmer).
- **Fuseau de l'utilisateur** : Europe/Paris (GMT+1 en hiver, GMT+2 en
  été).

## 9. Check-list avant de rendre la main

Quand tu auras fini ta session Mac, avant de passer la main à
l'utilisateur ou à un autre agent :

- [ ] `swift build -c release` réussit sans warning.
- [ ] `swift test --parallel` passe à 100 %.
- [ ] `podcastpilot list` affiche les sessions réelles d'Audio Hijack.
- [ ] `podcastpilot start` puis `podcastpilot stop` pilotent effectivement
      une session.
- [ ] `podcastpilot watch --dry-run` détecte un nouveau fichier déposé.
- [ ] Les `TODO(sdef)` dans `AudioHijackService.swift` sont **tous**
      levés ou explicitement documentés comme « vérifiés OK ».
- [ ] `docs/applescript.md` est à jour avec les noms réels du dictionnaire.
- [ ] CHANGELOG.md mis à jour avec une section `[Unreleased]` listant les
      corrections.
- [ ] Les commits sont en Conventional Commits, poussés sur `main`.
- [ ] Ce fichier `HANDOVER.md` est mis à jour avec ce qui a été validé,
      ce qui reste à faire, et la prochaine étape recommandée.

Bonne session.

— Claude Opus 4.7 (instance du 2026-04-27, côté Windows PC)
