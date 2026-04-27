# Sécurité — PodcastPilot

## Modèle de menaces (court)

| Menace | Impact | Mitigation |
|--------|--------|------------|
| Binaire malveillant redistribué | Haut | Developer ID + Hardened Runtime + notarisation Apple |
| Exfiltration de fichiers audio | Moyen | Pas d'accès réseau dans le chemin par défaut, logs locaux uniquement |
| Path traversal via template utilisateur | Moyen | `ApplyTemplateStage` whiteliste `[A-Za-z0-9 _.-]` |
| Escalade via Apple Events non ciblés | Moyen | Entitlement `automation.apple-events`, prompt TCC explicite |
| Tampering d'un `.pkg` | Haut | Ticket de notarisation stappé, SHA256 publié |

## Entitlements

Voir `Resources/PodcastPilot.entitlements`. Minimaux :

- `com.apple.security.automation.apple-events = true` — requis pour parler à
  Audio Hijack via OSAKit.
- `com.apple.security.device.audio-input = false` — explicite : PodcastPilot
  ne capte **pas** l'audio. C'est Audio Hijack qui gère le hardware.

Pas de sandbox App Store (accès chemins utilisateur nécessaire). Hardened
Runtime activé au signing : `codesign --options runtime`.

## TCC

Au premier `podcastpilot list`, macOS affiche :
> *« PodcastPilot wants to control Audio Hijack. »*

Cliquer **Autoriser**. Visible ensuite dans *Réglages Système → Confidentialité
→ Automatisation*. Si refusé : exit code `12` + message pointant vers les
réglages.

## Audit pré-distribution

```bash
# 1. Signature binaire
codesign -vvv --deep --strict .build/release/podcastpilot

# 2. Entitlements embarqués
codesign -d --entitlements :- .build/release/podcastpilot

# 3. Package installable
spctl --assess -vv --type install dist/PodcastPilot.pkg

# 4. Ticket de notarisation stappé
xcrun stapler validate dist/PodcastPilot.pkg
```

Tous doivent retourner `satisfies its Designated Requirement` — sinon, ne pas
publier.

## Secrets CI

Injectés via GitHub Secrets, jamais en clair :
`DEVELOPER_ID_APP`, `DEVELOPER_ID_INSTALLER`, `APPLE_ID`, `APP_PASSWORD`,
`TEAM_ID`, `DEV_ID_CERT_P12_BASE64`, `DEV_ID_CERT_PASSWORD`, `KEYCHAIN_PASSWORD`.

## Responsible disclosure

Mail : `security@valorisa.github.io` (placeholder — DM GitHub en attendant).
Pas d'issue publique pour une faille. Réponse sous 48h, patch critique sous 7 jours.
