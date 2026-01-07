# Self-Healing CI System

Dieses Repository verwendet ein automatisches Self-Healing-System für CI/CD-Fehler.

## Übersicht

```
┌─────────────────────┐
│   CI Build/Test     │
│   (build-test.yml)  │
└──────────┬──────────┘
           │
           ▼
    ┌──────┴──────┐
    │   Failure?  │
    └──────┬──────┘
           │ Ja
           ▼
┌─────────────────────┐
│   Self-Healing      │
│ (self-healing.yml)  │
├─────────────────────┤
│ 1. Fehler-Analyse   │
│ 2. Error-Log Parsing│
│ 3. Pattern-Matching │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Autofix Agent     │
│ (autofix-agent.yml) │
├─────────────────────┤
│ 1. Diagnostik       │
│ 2. Fix anwenden     │
│ 3. Commit & Push    │
│ 4. CI neu starten   │
└──────────┬──────────┘
           │
           ▼
    ┌──────┴──────┐
    │ Versuch < 5?│──────┐
    └──────┬──────┘      │ Ja
           │ Nein        │
           ▼             │
┌─────────────────────┐  │
│  Human Escalation   │  │
│  (Issue erstellen)  │  │
└─────────────────────┘  │
           ▲             │
           └─────────────┘
```

## Workflows

### 1. `self-healing.yml`
Wird automatisch ausgelöst, wenn ein CI-Workflow fehlschlägt.

**Funktionen:**
- Extrahiert Fehler-Logs aus dem fehlgeschlagenen Workflow
- Zählt Heal-Versuche pro Commit
- Erstellt Issues für AI-Agenten (Copilot, Claude)
- Eskaliert an Menschen nach 5 fehlgeschlagenen Versuchen

### 2. `autofix-agent.yml`
Führt automatische Fixes aus.

**Funktionen:**
- Erkennt Fehlertypen (PDF-Tests, Build, Lint)
- Wendet passende Fixes an
- Committet und pusht Änderungen
- Startet CI neu

### 3. `auto-retry.yml`
Einfache Retry-Logik für transiente Fehler.

## Fehlertypen und Fixes

| Fehlertyp | Pattern | Auto-Fix |
|-----------|---------|----------|
| PDF-Test | `PDFRobustnessTests`, `required frequency` | Core-Tokens und Pflicht-Elemente sicherstellen |
| Build | `error: cannot find`, `Build failed` | Clean rebuild, Dependencies neu auflösen |
| Lint | `SwiftLint`, `swiftformat` | `swiftformat` und `swiftlint --fix` ausführen |
| Dependencies | `package resolution failed` | Package.resolved löschen, neu auflösen |

## Konfiguration

Die Konfiguration befindet sich in `.github/self-healing-config.json`:

```json
{
  "settings": {
    "max_heal_attempts": 5,
    "escalation_enabled": true
  },
  "required_elements": {
    "frequencies": [125, 1000, 4000],
    "din_values": [0.6, 0.5, 0.48],
    "core_tokens": ["rt60 bericht", "metadaten", ...]
  }
}
```

## Eskalation

Nach 5 fehlgeschlagenen Auto-Fix-Versuchen:

1. **Issue wird erstellt** mit Label `needs-human`
2. **Alle offenen Auto-Fix-Issues werden geschlossen**
3. **Detaillierte Fehlerbeschreibung** wird bereitgestellt
4. **Empfohlene manuelle Schritte** werden aufgelistet

## Manuelles Triggern

Der Autofix-Agent kann manuell getriggert werden:

```bash
# Über GitHub Actions UI
# Workflow: "AI Autofix Agent"
# Inputs: branch, error_type
```

Oder über API:
```bash
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"ci-failure-autofix","client_payload":{"branch":"main","error_type":"pdf-test"}}'
```

## Labels

| Label | Bedeutung |
|-------|-----------|
| `auto-fix` | Issue wurde für automatische Korrektur erstellt |
| `ci-failure` | CI ist fehlgeschlagen |
| `needs-human` | Menschliches Eingreifen erforderlich |
| `bot` | Von Bot erstellt |

## Logs und Debugging

1. **Workflow-Logs:** GitHub Actions → Workflow runs
2. **Heal-Versuche:** `.github/heal-attempts.json`
3. **Issues:** Alle mit Label `auto-fix` oder `ci-failure`

## Bekannte Einschränkungen

- AI-Agenten (Copilot, Claude) müssen manuell auf Issues antworten
- Komplexe Fehler erfordern oft menschliches Eingreifen
- Push-Rechte für `github-actions[bot]` erforderlich
