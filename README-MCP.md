# MCP Server Configuration for AcoustiScan RT60

Dieses Dokument erklärt, wie Sie Model Context Protocol (MCP) Server für das AcoustiScan RT60 Projekt konfigurieren.

## Was ist MCP?

Model Context Protocol (MCP) ist ein offener Standard von Anthropic, der es KI-Modellen ermöglicht, sicher mit lokalen Tools und Datenquellen zu interagieren. MCP Server bieten strukturierten Zugriff auf:

- Dateisysteme
- Git-Repositories
- Datenbanken
- APIs
- Und mehr...

## Installation

### Voraussetzungen

```bash
# Node.js erforderlich (für MCP Server)
node --version  # v18+

# Claude Desktop App oder Claude Code CLI
```

### MCP Server installieren

```bash
# Filesystem Server
npm install -g @modelcontextprotocol/server-filesystem

# Git Server
npm install -g @modelcontextprotocol/server-git

# Memory Server
npm install -g @modelcontextprotocol/server-memory
```

## Konfiguration

### Für Claude Desktop

Füge folgende Konfiguration zu `~/Library/Application Support/Claude/claude_desktop_config.json` hinzu:

```json
{
  "mcpServers": {
    "acoustiscan-fs": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/YOUR_USERNAME/Projects/RT60_ipad_akusti-scan-APP"
      ]
    },
    "acoustiscan-git": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "/Users/YOUR_USERNAME/Projects/RT60_ipad_akusti-scan-APP"
      ]
    },
    "acoustiscan-memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ]
    }
  }
}
```

**Wichtig**: Ersetze `/Users/YOUR_USERNAME/Projects/RT60_ipad_akusti-scan-APP` mit dem tatsächlichen Pfad zu deinem Projekt!

### Für Claude Code CLI

Claude Code verwendet automatisch die `.mcp-config.json` im Projekt-Root.

## Verfügbare MCP Tools

### Filesystem Server

**Zugriff auf Projektdateien**:

```markdown
# Beispiel-Nutzung in Claude
"Read the RT60Calculator.swift file"
"Search for all files containing 'DIN 18041'"
"List all Swift files in AcoustiScanConsolidated/Sources"
```

**Capabilities**:
- Dateien lesen
- Dateien schreiben
- Verzeichnisse durchsuchen
- Datei-Metadaten abrufen

### Git Server

**Zugriff auf Git-Historie**:

```markdown
# Beispiel-Nutzung
"Show recent commits"
"Show diff between main and current branch"
"List all branches"
"Show commit history for RT60Calculator.swift"
```

**Capabilities**:
- Commit-Historie
- Diffs anzeigen
- Branch-Informationen
- Blame-Informationen
- Status prüfen

### Memory Server

**Persistenter Kontext**:

```markdown
# Beispiel-Nutzung
"Remember that we're consolidating the duplicate renderers"
"What did we discuss about DIN 18041 compliance?"
"Recall the test coverage targets"
```

**Capabilities**:
- Kontext speichern
- Informationen abrufen
- Projekt-Wissen aufbauen

## Agent-Integration

Die MCP-Konfiguration ist mit den Agents aus `.github/agents.md` integriert:

### RT60Architect

Nutzt **Filesystem** + **Git** Server:
- Analysiert Code-Struktur
- Prüft Architektur-Patterns
- Identifiziert Duplikationen

### AcousticsExpert

Nutzt **Filesystem** + **Memory** Server:
- Validiert akustische Berechnungen
- Speichert DIN 18041 Standards
- Prüft Formeln und Konstanten

### SwiftCraftsman

Nutzt **Filesystem** + **Git** Server:
- Reviewt Swift Code
- Prüft Code-Qualität
- Verfolgt Änderungen

### TestMaster

Nutzt **Filesystem** + **Git** Server:
- Analysiert Test-Coverage
- Identifiziert fehlende Tests
- Prüft Test-Historie

### CIGuardian

Nutzt **Git** + **Filesystem** Server:
- Monitort Workflows
- Analysiert Build-Logs
- Prüft CI/CD-Konfiguration

### DocScribe

Nutzt **Filesystem** + **Memory** Server:
- Liest bestehende Dokumentation
- Speichert Dokumentations-Standards
- Generiert API-Docs

## Verwendung

### Mit Claude Desktop

1. Starte Claude Desktop neu nach Konfiguration
2. MCP Server werden automatisch gestartet
3. Nutze natürliche Sprache für Anfragen:

```markdown
"Show me all files that implement RT60 calculations"
"What's the current test coverage for the Export module?"
"Search for usages of ReportData in the codebase"
```

### Mit Claude Code CLI

```bash
# Claude Code erkennt automatisch .mcp-config.json
claude-code "Analyze the code duplication in renderers"
```

### In Git Commits

```bash
# Claude kann via MCP auf Git zugreifen
claude-code "Review my last 5 commits and suggest improvements"
```

## Troubleshooting

### MCP Server startet nicht

```bash
# Prüfe Node.js Version
node --version  # Sollte v18+ sein

# Teste MCP Server manuell
npx @modelcontextprotocol/server-filesystem /path/to/project
```

### Pfad-Probleme

**Problem**: `Permission denied` oder `Path not found`

**Lösung**:
1. Prüfe absolute Pfade in der Konfiguration
2. Stelle sicher, dass Claude Zugriff auf das Verzeichnis hat
3. Prüfe Dateisystem-Berechtigungen

### Server reagiert nicht

**Lösung**:
1. Neustart von Claude Desktop
2. Prüfe MCP Server Logs:
   ```bash
   # macOS
   ~/Library/Logs/Claude/mcp*.log
   ```
3. Re-installiere MCP Server:
   ```bash
   npm install -g @modelcontextprotocol/server-filesystem --force
   ```

## Security

### Best Practices

1. **Filesystem Server**: Nur Projekt-Verzeichnis freigeben
   ```json
   {
     "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/project"]
     // NICHT "/" oder "/Users"!
   }
   ```

2. **Git Server**: Read-only Zugriff empfohlen
   - Server kann standardmäßig nicht pushen/force-push
   - Nur lokales Repository

3. **Memory Server**: Namespace verwenden
   ```json
   {
     "env": { "MEMORY_NAMESPACE": "acoustiscan-rt60" }
   }
   ```

### Berechtigungen

MCP Server haben **nur Zugriff** auf:
- Explizit konfigurierte Verzeichnisse
- Lokales Git Repository
- Memory Namespace

**Kein Zugriff** auf:
- Andere Dateien/Verzeichnisse
- Netzwerk (außer konfiguriert)
- System-Befehle

## Erweiterte Konfiguration

### Custom MCP Server

Erstelle einen projektspezifischen MCP Server:

```javascript
// acoustiscan-mcp-server.js
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "acoustiscan-tools",
  version: "1.0.0"
});

// Tool: RT60 Calculation Validator
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "validate_rt60") {
    const { volume, absorptionArea } = request.params.arguments;
    const rt60 = 0.161 * volume / absorptionArea;

    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          rt60,
          valid: rt60 > 0 && rt60 < 10,
          formula: "RT60 = 0.161 × V / A"
        })
      }]
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

Füge zu `.mcp-config.json` hinzu:

```json
{
  "mcpServers": {
    "acoustiscan-tools": {
      "command": "node",
      "args": ["./acoustiscan-mcp-server.js"]
    }
  }
}
```

## Ressourcen

- **MCP Dokumentation**: https://modelcontextprotocol.io
- **MCP SDK**: https://github.com/modelcontextprotocol/sdk
- **Verfügbare Server**: https://github.com/modelcontextprotocol/servers
- **Claude Desktop**: https://claude.ai/download

## Support

Bei Problemen:

1. **MCP Logs prüfen**: `~/Library/Logs/Claude/mcp*.log`
2. **Issue erstellen**: GitHub Issues im Projekt
3. **MCP Community**: https://github.com/modelcontextprotocol/community

---

**Version**: 1.0.0
**Maintainer**: Marc Schneider-Handrup (@Darkness308)
**Letztes Update**: 2025-11-03
