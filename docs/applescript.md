# Référence AppleScript — Audio Hijack

> ⚠️ Ce document est un squelette. Les noms exacts de propriétés / commandes
> doivent être confirmés contre le dictionnaire réel d'Audio Hijack 4.5.7.
> Sur Mac : `sdef /Applications/Audio\ Hijack.app > audiohijack.sdef`

## Bundle ID

```
com.rogueamoeba.audiohijack
```

## Classe `session` (à confirmer)

| Propriété | Type    | Accès | Note |
|-----------|---------|-------|------|
| `id`      | text    | r/o   | UUID session |
| `name`    | text    | r/w   | Nom affiché dans l'UI |
| `running` | boolean | r/o   | `true` si la session enregistre/joue |

Commandes supposées :

| Commande | Effet |
|----------|-------|
| `start`  | Démarre la session ciblée |
| `stop`   | Arrête la session ciblée |

## Exemples

### Lister (JXA)

```javascript
const ah = Application('com.rogueamoeba.audiohijack');
JSON.stringify(ah.sessions().map(s => ({
  id: String(s.id()), name: String(s.name()), running: Boolean(s.running())
})));
```

### Démarrer par nom (JXA)

```javascript
const ah = Application('com.rogueamoeba.audiohijack');
const match = ah.sessions.whose({name: "Mon Podcast"})[0];
if (!match) throw new Error('SESSION_NOT_FOUND');
match.start();
```

## Codes d'erreur utiles

| Code   | Signification |
|--------|---------------|
| -1728  | Objet introuvable (session avec ce nom inexistante) |
| -1743  | Permission d'automatisation refusée (TCC) |
| -609   | Application pas lancée |

## Dépannage TCC

```bash
# Révoquer pour tester le premier run
tccutil reset AppleEvents io.github.valorisa.podcastpilot
```

Puis : *Réglages Système → Confidentialité et sécurité → Automatisation →
PodcastPilot → Audio Hijack = activé*.
