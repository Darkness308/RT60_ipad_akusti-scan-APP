# Swift Development Workflows

Dieses Dokument beschreibt die automatisierten Workflows für die AcoustiScan Swift-Entwicklung.

## 🚀 Workflow-Übersicht

Das Repository verfügt über vier Haupt-Workflows für die Swift-Entwicklung:

### 1. Swift CI (`swift-ci.yml`)
**Trigger:** Push/PR auf `main` oder `develop` Branch
**Funktionen:**
- ✅ Automatisches Kompilieren aller Swift-Dateien
- ✅ Ausführung von Unit-Tests
- ✅ Swift-Syntax-Validierung
- ✅ Code-Qualitätsanalyse

### 2. SwiftLint (`swiftlint.yml`)
**Trigger:** Push/PR auf `main` oder `develop` Branch
**Funktionen:**
- ✅ Code-Style-Prüfung mit SwiftLint
- ✅ Automatische Korrekturvorschläge
- ✅ Projektspezifische Regeln für RT60/Akustik-Code

### 3. Test Coverage (`test-coverage.yml`)
**Trigger:** Push/PR auf `main` oder `develop` Branch
**Funktionen:**
- ✅ Test-Coverage-Berichterstattung
- ✅ Codecov-Integration
- ✅ Coverage-Statistiken in PRs

### 4. Release (`release.yml`)
**Trigger:** Tag-Push (`v*.*.*`)
**Funktionen:**
- ✅ Automatische Release-Erstellung
- ✅ Source-Code-Archivierung
- ✅ Release-Notes-Generierung

## 📁 Projektstruktur

```
RT60_ipad_akusti-scan-APP/
├── .github/workflows/          # GitHub Actions Workflows
├── Sources/                    # Swift Modul-Quellcode
│   ├── AcousticEngine/        # RT60-Berechnungen
│   ├── ScannerEngine/         # LiDAR-Scanning
│   ├── DIN18041/              # Normen-Compliance
│   ├── MaterialDatabase/      # Materialdatenbank
│   └── ReportGenerator/       # PDF-Report-Export
├── Tests/                     # Unit- und Integrationstests
├── Package.swift              # Swift Package Manager
├── .swiftlint.yml            # SwiftLint-Konfiguration
└── .gitignore                # Git-Ignore für Swift/Xcode
```

## 🛠 Lokale Entwicklung

### Voraussetzungen
- Xcode 15+ oder Swift 5.9+
- SwiftLint (optional, aber empfohlen)

### Installation von SwiftLint
```bash
# Mit Homebrew
brew install swiftlint

# Mit CocoaPods (falls Podfile vorhanden)
pod install
```

### Lokale Builds
```bash
# Swift Package Manager Build
swift build

# Tests ausführen
swift test

# Mit Coverage
swift test --enable-code-coverage

# SwiftLint lokal ausführen
swiftlint
swiftlint autocorrect  # Automatische Korrekturen
```

## 📋 SwiftLint-Regeln

Die Konfiguration in `.swiftlint.yml` umfasst:

### Aktivierte Regeln
- `force_unwrapping`: Warnung vor Force-Unwrapping
- `empty_count`: Bevorzugung von `.isEmpty` statt `.count == 0`
- `multiline_arguments`: Konsistente mehrzeilige Argumentformatierung

### Projektspezifische Regeln
- **Deutsche Kommentare**: Bevorzugung deutscher Kommentare für das Projekt
- **RT60-Naming**: Konsistente Benennung von RT60-bezogenen Variablen

### Angepasste Limits
- Zeilenlänge: 120 Zeichen (Warnung), 150 (Fehler)
- Funktionslänge: 50 Zeilen (Warnung), 100 (Fehler)
- Dateigröße: 400 Zeilen (Warnung), 500 (Fehler)

## 🔄 Workflow-Trigger

| Aktion | Swift CI | SwiftLint | Coverage | Release |
|--------|----------|-----------|----------|---------|
| Push zu `main` | ✅ | ✅ | ✅ | ❌ |
| Push zu `develop` | ✅ | ✅ | ✅ | ❌ |
| Pull Request | ✅ | ✅ | ✅ | ❌ |
| Tag `v*.*.*` | ❌ | ❌ | ❌ | ✅ |

## 📊 Test Coverage

Test Coverage wird automatisch für folgende Module gemessen:
- **AcousticEngine**: RT60-Berechnungen und Impulsantwortanalyse
- **DIN18041**: Normen-Compliance und Bewertungslogik
- **ReportGenerator**: PDF-Export-Funktionalität

Coverage-Berichte sind verfügbar über:
- GitHub Actions Logs
- Codecov (bei aktivierter Integration)
- Lokale Coverage-Generierung mit `swift test --enable-code-coverage`

## 🚀 Release-Prozess

### Automatisches Release
1. Tag erstellen: `git tag v1.0.0`
2. Tag pushen: `git push origin v1.0.0`
3. GitHub Actions erstellt automatisch:
   - GitHub Release
   - Source-Code-Archive
   - Release-Notes

### Release-Versioning
- **Major** (1.0.0): Breaking Changes, neue Hauptfeatures
- **Minor** (1.1.0): Neue Features, rückwärtskompatibel
- **Patch** (1.1.1): Bugfixes, kleine Verbesserungen
- **Prerelease** (1.0.0-beta): Beta/Alpha-Versionen

## 🔧 Konfiguration

### Branch-Schutz-Regeln (empfohlen)
Für `main` Branch:
- ✅ Require status checks to pass
  - Swift CI
  - SwiftLint
  - Test Coverage
- ✅ Require pull request reviews
- ✅ Require up-to-date branches

### Secrets (falls erforderlich)
- `CODECOV_TOKEN`: Für Coverage-Upload (optional)
- `GITHUB_TOKEN`: Automatisch verfügbar für Releases

## 📝 Best Practices

### Code-Qualität
1. **SwiftLint vor jedem Commit ausführen**
2. **Tests für neue Features schreiben**
3. **Deutsche Kommentare für Fachbegriffe**
4. **RT60-spezifische Namenskonventionen befolgen**

### Workflow-Optimierung
1. **Kleine, fokussierte Commits**
2. **Aussagekräftige Commit-Messages**
3. **Feature-Branches für neue Entwicklungen**
4. **Regular merges zu `develop`**

## 🆘 Troubleshooting

### Häufige Probleme

**Swift Build fehlgeschlagen:**
```bash
# Dependencies neu auflösen
swift package reset
swift build
```

**SwiftLint-Fehler:**
```bash
# Automatische Korrekturen anwenden
swiftlint autocorrect

# Spezifische Regeln deaktivieren (in .swiftlint.yml)
disabled_rules:
  - rule_name
```

**Test-Fehler:**
```bash
# Einzelne Tests ausführen
swift test --filter TestClassName.testMethodName

# Verbose Test-Output
swift test --verbose
```

### Support
Bei Fragen zu den Workflows:
1. GitHub Actions Logs prüfen
2. SwiftLint-Dokumentation konsultieren
3. Swift Package Manager Dokumentation

---

**Letzte Aktualisierung:** September 2024  
**Workflow-Version:** 1.0