# ADR — Architecture PodcastPilot

**Statut** : accepted — 2026-04-27
**Décideur** : @valorisa

## Contexte

Piloter Audio Hijack (closed-source) depuis une CLI macOS, sans reverse
engineering et sans dépendance à un SDK propriétaire. Le binaire doit rester
léger, universel (arm64 + x86_64), signable et notarisable.

## Décision

- **CLI Swift 5.9** (`swift-argument-parser`), target `macOS 14`.
- **AppleScript via OSAKit + JXA** (JavaScript for Automation) plutôt que
  NSAppleScript : JXA retourne du JSON natif → parsing robuste, pas de regex
  sur des records AppleScript.
- **FSEvents natif** pour le watch, pas de Python/`watchdog`. Un seul binaire,
  un seul toolchain.
- **Pipeline composable** (protocol `ExportStage` + `ExportPipeline.run`) : les
  étapes (extract metadata, loudnorm, template, atomic move) sont testables et
  skippables individuellement.
- **Idempotence par empreinte SHA256** du contenu (1er mégaoctet + taille),
  persistée dans `~/.ppilot/ledger.jsonl`. Redémarrer `watch` ne retraite pas
  les fichiers déjà exportés.
- **ffmpeg externe** uniquement pour `loudnorm` (pas de wrapper natif). Dépendance
  assumée, détectée via `which ffmpeg` dans `quick-start.sh`.

## Conséquences

### + Positives
- Un langage de build, un runner de tests, un lint — maintenance divisée par 2
  vs dual Swift+Python.
- Pipeline reprenable : un crash en plein `loudnorm` n'oblige pas à re-fingerprinter
  les fichiers déjà traités.
- JSON sortie de `list` → scriptable proprement (jq, Shortcuts).

### − Négatives / trade-offs
- **Dépendance au `.sdef`** : si Rogue Amoeba change les noms de propriétés,
  rework du `AudioHijackService`. Mitigation : tous les appels passent par un
  seul fichier, protocole stable, changement localisé.
- **Parser TOML minimal** : pas de tables imbriquées. Suffisant pour un fichier
  utilisateur à plat. Si besoin croît → swap vers `TOMLKit` en SPM dep.
- **OSAKit est mode maintenance** chez Apple. À surveiller. Migration possible
  vers AppIntents quand Rogue Amoeba exposera un intent.

## Rejeté

- **Python orchestration** : doublon de stack. `watchdog` + `mutagen` remplaçables
  par FSEvents + AVFoundation natifs.
- **Reverse engineering du binaire Audio Hijack** : violation EULA, fragilité
  à chaque release, non négociable.
- **Electron menubar** : 100 Mo pour 2 commandes, absurde.
- **Sandbox App Store** : la CLI a besoin d'accéder à des chemins utilisateur
  arbitraires. Hardened Runtime + Developer ID suffit.
