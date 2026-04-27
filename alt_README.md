# 🎙️ PodcastPilot — Documentation Détaillée et Enrichie

> **PodcastPilot** est une interface en ligne de commande (CLI) native pour macOS, conçue pour offrir un contrôle précis et programmatique de l'application **Audio Hijack** directement depuis votre terminal. Cet outil permet non seulement de piloter les sessions d'enregistrement, mais également d'automatiser entièrement le processus d'exportation, de normalisation audio et d'organisation de vos productions podcast, le tout en respectant scrupuleusement les API officielles d'Apple.

![macOS](https://img.shields.io/badge/macOS-14+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Status](https://img.shields.io/badge/Status-Alpha-yellow?style=flat-square)

---

## 📋 Table des Matières

- [Présentation Générale](#-présentation-générale)
- [Fonctionnalités Principales](#-fonctionnalités-principales)
- [Commandes Disponibles](#-commandes-disponibles)
- [Processus d'Installation](#-processus-dinstallation)
- [Configuration Initiale et Autorisations](#-configuration-initiale-et-autorisations)
- [Configuration Avancée du Mode Watch](#-configuration-avancée-du-mode-watch)
- [Architecture Technique et Documentation](#-architecture-technique-et-documentation)
- [Contribuer au Projet](#-contribuer-au-projet)
- [Licence et Mentions Légales](#-licence-et-mentions-légales)

---

## 🎯 Présentation Générale

PodcastPilot a été développé pour répondre aux besoins des créateurs de contenu audio professionnel qui recherchent une solution robuste, reproductible et intégrable dans des workflows d'automatisation. L'outil s'appuie exclusivement sur le framework **AppleScript officiel** fourni par Rogue Amoeba pour Audio Hijack, garantissant ainsi une compatibilité durable et une absence totale de techniques de reverse engineering potentiellement fragiles face aux mises à jour logicielles.

L'approche philosophique du projet privilégie :

- **La transparence** : chaque action entreprise par l'outil est traçable et compréhensible.
- **L'idempotence** : les opérations peuvent être relancées sans risque de duplication ou de corruption des données.
- **La conformité aux standards** : respect des normes de loudness podcast (-16 LUFS) et des bonnes pratiques de métadonnées.
- **La sécurité** : modèle de menaces documenté, entitlements minimalistes et gestion rigoureuse des permissions TCC (Transparency, Consent, and Control).

---

## ⚡ Fonctionnalités Principales

### Pilotage des Sessions Audio Hijack

PodcastPilot vous permet d'interagir avec vos sessions Audio Hijack de manière programmatique :

- **Lister** l'ensemble des sessions configurées dans Audio Hijack, avec leurs états actuels (en cours, arrêtée, planifiée).
- **Démarrer** une session spécifique par son nom exact, déclenchant ainsi l'enregistrement sans intervention manuelle.
- **Arrêter** proprement une session en cours d'exécution, garantissant la finalisation correcte du fichier de sortie.

### Automatisation Intelligente avec `watch`

La fonctionnalité phare de PodcastPilot réside dans sa commande `watch`, qui orchestre un pipeline d'exportation entièrement automatisé :

1. **Surveillance en temps réel** du dossier de sortie configuré dans Audio Hijack, avec un mécanisme de *debouncing* de 1,5 seconde pour s'assurer que le fichier est entièrement écrit avant traitement.
2. **Extraction et validation des métadonnées** embarquées dans le fichier audio (titre, épisode, show, date, etc.).
3. **Normalisation audio professionnelle** vers la cible de **-16 LUFS** (Loudness Units Full Scale), conformément aux standards de diffusion podcast recommandés par Apple Podcasts, Spotify et les principales plateformes de distribution. Cette étape s'appuie sur le filtre `loudnorm` de `ffmpeg` pour un traitement de haute qualité.
4. **Application d'un template de nommage** personnalisable, permettant d'organiser automatiquement vos fichiers selon une arborescence logique (par exemple : `NomDuShow/EP042_TitreDeLEpisode.m4a`).
5. **Déplacement atomique** vers le dossier de destination final, utilisant une écriture intermédiaire en `.part` suivie d'un `rename` pour garantir l'intégrité des fichiers même en cas d'interruption inattendue.
6. **Gestion idempotente via fingerprinting** : chaque fichier traité est identifié par une empreinte numérique unique (SHA256 des premiers 1 Mo + taille du fichier), persistée dans un registre local (`~/.ppilot/ledger.jsonl`). Cette approche garantit qu'un redémarrage du processus `watch` ne retraitera jamais un fichier déjà exporté avec succès.

---

## 🛠️ Commandes Disponibles

Voici un aperçu détaillé des commandes principales offertes par l'interface en ligne de commande de PodcastPilot :

```bash
# Afficher la liste complète des sessions Audio Hijack disponibles
podcastpilot list

# Démarrer l'enregistrement d'une session spécifique (remplacer "Mon Podcast" par le nom exact)
podcastpilot start "Mon Podcast"

# Arrêter proprement une session en cours d'exécution
podcastpilot stop "Mon Podcast"

# Activer le mode de surveillance automatique avec configuration personnalisée
podcastpilot watch --config ~/.ppilot.toml

# Mode sec (dry-run) pour tester la configuration sans appliquer de modifications
podcastpilot watch --config ~/.ppilot.toml --dry-run
```

> 💡 **Conseil d'utilisation** : Les noms de sessions sont sensibles à la casse et aux espaces. Utilisez la commande `list` pour vérifier l'orthographe exacte avant d'exécuter `start` ou `stop`.

---

## 📦 Processus d'Installation

### Méthode Recommandée : Homebrew (à partir de la version 1.0)

Lorsque la première version stable sera publiée, l'installation sera simplifiée via Homebrew :

```bash
brew tap valorisa/tap
brew install valorisa/tap/podcastpilot
```

### Méthode Alternative : Compilation depuis les Sources

Pour les utilisateurs souhaitant contribuer au projet ou tester les dernières fonctionnalités en développement :

```bash
# Cloner le dépôt officiel depuis GitHub
git clone https://github.com/valorisa/Podcast_Pilot_Audio-Hijack.git

# Accéder au répertoire du projet
cd Podcast_Pilot_Audio-Hijack

# Exécuter le processus de compilation et d'installation via Makefile
make install
```

### Prérequis Système et Dépendances Logicielles

Avant de procéder à l'installation, veuillez vous assurer que votre environnement répond aux critères suivants :

| Composant | Version Minimale | Commande de Vérification / Installation |
|-----------|-----------------|----------------------------------------|
| **macOS** | 14.0 (Sonoma) ou supérieur | `sw_vers -productVersion` |
| **Audio Hijack** | 4.5.7 ou supérieur | Lancer l'application et vérifier dans `Audio Hijack → À propos` |
| **Swift Toolchain** | 5.9 ou supérieur | `swift --version` (inclus avec Xcode 15+) |
| **ffmpeg** | Version récente recommandée | `brew install ffmpeg` |

> ⚠️ **Note importante** : L'outil `ffmpeg` est indispensable pour les étapes de normalisation audio et de manipulation des métadonnées. Son absence empêchera le fonctionnement de la commande `watch`, bien que les commandes de pilotage de base (`list`, `start`, `stop`) resteront opérationnelles.

---

## 🔐 Configuration Initiale et Autorisations Système

### Première Exécution et Gestion des Permissions TCC

Lors de la première invocation de PodcastPilot, le système d'exploitation macOS affichera une invite de sécurité de type :

> *"PodcastPilot wants to control Audio Hijack"*

Cette demande relève du framework **TCC (Transparency, Consent, and Control)** d'Apple, qui régit l'accès des applications aux fonctionnalités d'automatisation inter-processus.

**Procédure à suivre :**

1. Cliquez sur le bouton **Autoriser** pour accorder les permissions nécessaires.
2. Si vous avez accidentellement refusé l'accès, ou si l'invite n'apparaît pas, accédez manuellement aux réglages système :
   - Ouvrez `Réglages Système` (ou `Préférences Système` selon votre version de macOS)
   - Naviguez vers `Confidentialité et Sécurité` → `Automatisation`
   - Localisez `PodcastPilot` dans la liste des applications
   - Cochez la case correspondant à `Audio Hijack` pour lui accorder le contrôle

> 🔍 **Dépannage** : Si les commandes échouent avec des erreurs liées aux permissions, exécutez `tccutil reset AppleEvents fr.valorisa.podcastpilot` dans le terminal pour réinitialiser les autorisations, puis relancez PodcastPilot.

---

## ⚙️ Configuration Avancée du Mode Watch

Pour exploiter pleinement les capacités d'automatisation de PodcastPilot, vous pouvez créer un fichier de configuration au format TOML dans votre répertoire utilisateur : `~/.ppilot.toml`.

### Exemple de Configuration Complète

```toml
# -----------------------------------------------------------------------------
# Configuration PodcastPilot - Mode Watch
# -----------------------------------------------------------------------------

# Répertoire source : emplacement où Audio Hijack enregistre ses fichiers bruts
# Les tilde (~) sont automatiquement expansés vers votre dossier personnel
source_dir = "~/Music/Audio Hijack"

# Répertoire de destination : où seront rangés les fichiers traités et normalisés
output_dir = "~/Podcasts/Ready"

# Template de nommage : définit la structure et le format des fichiers de sortie
# Variables disponibles : {show}, {episode}, {title}, {date}, {original_filename}
# Caractères autorisés : [A-Za-z0-9 _.-] pour éviter les problèmes de compatibilité
template = "{show}/EP{episode}_{title}.m4a"

# Cible de loudness : valeur LUFS pour la normalisation audio (standard podcast)
# Valeurs recommandées : -16.0 (Apple Podcasts), -14.0 (YouTube), -19.0 (radio)
loudness_target = -16.0

# Optionnel : tolérance de variation de loudness (en LU)
# loudness_tolerance = 1.0

# Optionnel : format de sortie préféré (m4a, mp3, wav)
# output_format = "m4a"

# Optionnel : activer le mode verbeux pour le débogage
# verbose = true
```

### Variables Disponibles dans les Templates

| Variable | Description | Exemple de Valeur |
|----------|-------------|------------------|
| `{show}` | Nom du podcast / émission | `TechTalk Daily` |
| `{episode}` | Numéro ou identifiant d'épisode | `042`, `S03E12` |
| `{title}` | Titre de l'épisode | `Introduction_au_ML` |
| `{date}` | Date d'enregistrement (format ISO) | `2026-04-27` |
| `{original_filename}` | Nom du fichier source tel qu'exporté par Audio Hijack | `Session_20260427_143022.m4a` |

> ⚠️ **Sécurité des templates** : Pour prévenir les vulnérabilités de type *path traversal*, PodcastPilot applique un filtrage strict sur les caractères autorisés dans les variables injectées. Seuls les caractères alphanumériques, espaces, underscores, points et tirets sont conservés.

---

## 📚 Architecture Technique et Documentation

Le projet PodcastPilot est accompagné d'une documentation technique complète, organisée en plusieurs modules spécialisés :

### 🏗️ `docs/architecture.md` — Décisions Architecturales (ADR)

Ce document présente les **Architecture Decision Records** qui ont guidé les choix fondamentaux du projet :

- Justification de l'usage exclusif d'AppleScript officiel plutôt que du reverse engineering
- Sélection de Swift 5.9 et du framework `ArgumentParser` pour la CLI
- Conception modulaire du pipeline d'exportation via le protocole `ExportStage`
- Stratégie d'idempotence basée sur le fingerprinting SHA256
- Alternatives envisagées et rejetées (orchestration Python, application Electron, etc.)

### 🎭 `docs/applescript.md` — Référence AppleScript pour Audio Hijack

Guide de référence détaillant l'interface de scriptabilité d'Audio Hijack :

- Inventaire complet des classes, propriétés et commandes exposées via le fichier `.sdef`
- Exemples d'utilisation en AppleScript natif et via JavaScript for Automation (JXA)
- Codes d'erreur TCC courants et stratégies de résolution
- Bonnes pratiques pour l'interaction programmatique avec l'application hôte

### 🔒 `docs/security.md` — Modèle de Menaces et Bonnes Pratiques de Sécurité

Analyse approfondie des considérations de sécurité :

- **Modèle de menaces** : identification des vecteurs d'attaque potentiels et des mesures d'atténuation
- **Entitlements** : justification des permissions minimales requises (`com.apple.security.automation.apple-events` uniquement, sans accès au microphone)
- **Flux TCC** : explication détaillée du cycle de vie des autorisations utilisateur
- **Audit pré-distribution** : commandes de vérification (`codesign`, `spctl`, `stapler`) pour valider l'intégrité du binaire
- **Gestion des secrets en CI** : pratiques recommandées pour l'injection sécurisée des certificats Developer ID
- **Politique de divulgation responsable** : procédure à suivre pour signaler une vulnérabilité

### 🔄 `CHANGELOG.md` — Historique des Versions

Journal exhaustif des évolutions du projet, suivant les principes du [Keep a Changelog](https://keepachangelog.com/) et du [Semantic Versioning](https://semver.org/) :

- Nouveautés fonctionnelles et améliorations techniques par version
- Corrections de bugs et ajustements de compatibilité
- Notes de migration pour les mises à jour majeures
- Références aux issues GitHub et aux pull requests associées

---

## 🤝 Contribuer au Projet

PodcastPilot est un projet open source qui accueille avec enthousiasme les contributions de la communauté. Avant de soumettre une modification, veuillez consulter attentivement les documents suivants :

### 📖 Guide de Contribution

Le fichier [`CONTRIBUTING.md`](CONTRIBUTING.md) détaille :

- Le workflow de développement recommandé (fork → branche → PR)
- Les standards de codage Swift (SwiftLint en mode strict, force_unwrapping interdit)
- Les exigences en matière de tests unitaires et d'intégration
- Le processus de revue de code et les critères d'acceptation

### ✍️ Conventional Commits

Tous les messages de commit doivent respecter la spécification [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types reconnus** : `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`

**Exemples** :
```
feat(watch): add debouncing mechanism for file detection
fix(metadata): handle missing ID3 tags gracefully
docs(security): expand threat model with supply chain risks
```

### 🧪 Exécution des Tests et de la Lint

```bash
# Exécuter la suite de tests unitaires
make test

# Appliquer les vérifications de style SwiftLint
make lint

# Exécuter ShellCheck sur les scripts Bash
make check-scripts

# Build de développement avec signature ad-hoc
make sign-dev
```

---

## ⚖️ Licence et Mentions Légales

### Licence Open Source

Ce projet est distribué sous les termes de la licence **MIT**, une licence permissive qui vous accorde les libertés suivantes :

- ✅ Utiliser, copier, modifier et fusionner le logiciel
- ✅ Publier, distribuer et sous-licencier des copies
- ✅ Vendre des copies du logiciel

**Condition unique** : La notice de copyright et la permission doivent être incluses dans toutes les copies ou portions substantielles du logiciel.

> 📄 Consultez le fichier [`LICENSE`](LICENSE) pour le texte intégral de la licence.

### Avertissements et Affiliations

- **PodcastPilot** est un projet indépendant développé par @valorisa. Il n'est **ni affilié, ni endossé, ni soutenu** par Rogue Amoeba Software, Inc.
- **Audio Hijack™** est une marque déposée de Rogue Amoeba Software, Inc. Toute référence à ce produit dans le cadre de PodcastPilot vise exclusivement à décrire une fonctionnalité d'interopérabilité technique.
- L'utilisation de PodcastPilot requiert une licence valide d'Audio Hijack, disponible sur [rogueamoeba.com](https://rogueamoeba.com/).

### Copyright

```
MIT License

Copyright (c) 2026 @valorisa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

> 🎧 **Bonne production podcast !**  
> *PodcastPilot — Automatisez. Normalisez. Publiez.*