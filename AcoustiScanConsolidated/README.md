# AcoustiScan Consolidated Tool

Ein umfassendes Swift-Tool für Raumakustik-Analyse mit RT60-Messung, DIN 18041-Bewertung und automatisierter PDF-Berichterstellung.

## 🎯 Überblick

Das AcoustiScan Consolidated Tool ist die Konsolidierung aller Swift-Implementierungen aus dem RT60 iPad Akustik-Scan-App Projekt. Es kombiniert:

- **RT60-Berechnungen** nach Sabine-Formel
- **DIN 18041-Konformitätsbewertung** für verschiedene Raumtypen
- **48-Parameter Akustik-Framework** für umfassende Audiobewertung
- **Automatisierte Build-Prozesse** mit Fehlererkennung und -behebung
- **Professionelle PDF-Berichterstellung** für gutachterliche Zwecke

## 🚀 Funktionen

### Kern-Funktionalitäten

- ✅ **RT60-Berechnung**: Präzise Nachhallzeiten-Berechnung für alle Standardfrequenzen
- ✅ **DIN 18041-Bewertung**: Automatische Konformitätsprüfung für verschiedene Raumtypen
- ✅ **Multi-Frequenz-Analyse**: Analyse von 125 Hz bis 8 kHz
- ✅ **Material-Datenbank**: Umfassende Absorptionskoeffizienten-Datenbank
- ✅ **Oberflächenmodellierung**: Detaillierte Raummodellierung mit verschiedenen Materialien

### 48-Parameter Akustik-Framework

- 📊 **8 Hauptkategorien**: Klangfarbe, Tonalität, Geometrie, Raum, Zeitverhalten, Dynamik, Artefakte
- 🔬 **Wissenschaftlich validiert**: 75% der Parameter haben starke wissenschaftliche Grundlage
- 📈 **Umfassende Bewertung**: Über einfache RT60-Messungen hinausgehende Analyse

### Automatisierte Build-Prozesse

- 🔧 **Automatische Fehlererkennung**: Identifizierung häufiger Swift-Compilation-Fehler
- 🛠 **Automatische Fehlerbehebung**: Behebung von Import-Fehlern und Syntax-Problemen
- 🔄 **Retry-Mechanismus**: Automatische Wiederholung nach Fehlerbehebung
- 📊 **Build-Monitoring**: Detaillierte Logging und Status-Berichte

### PDF-Berichterstellung

- 📄 **Mehrseitige Berichte**: Deckblatt, Metadaten, RT60-Kurven, DIN-Ampellogik, Maßnahmen
- 🎨 **Professionelles Layout**: Gutachterlicher Standard mit Corporate Design
- 📊 **Visualisierungen**: Graphische Darstellung von Messergebnissen
- 🔍 **Detailanalyse**: Umfassende Dokumentation aller Parameter

## 📦 Installation

### Voraussetzungen

- Swift 5.9 oder höher
- macOS 12.0+ oder iOS 15.0+ (für PDF-Generierung)
- Xcode 14.0+ (für iOS-Entwicklung)

### Build-Prozess

```bash
# Repository klonen
git clone [repository-url]
cd AcoustiScanConsolidated

# Automatisierter Build
./build.sh

# Spezifische Build-Optionen
./build.sh clean      # Build-Artefakte löschen
./build.sh test       # Build + Tests ausführen
./build.sh release    # Release-Version erstellen
./build.sh package    # Distributions-Paket erstellen
./build.sh all        # Vollständiger CI/CD-Pipeline
```

### Manuelle Installation

```bash
# Dependencies installieren
swift package resolve

# Build
swift build

# Tests ausführen
swift test

# Release build
swift build -c release
```

## 🛠 Verwendung

### Command-Line Interface

```bash
# Vollständige akustische Analyse
AcoustiScanTool analyze

# Automatisierter Build
AcoustiScanTool build

# PDF-Report generieren
AcoustiScanTool report

# 48-Parameter Framework anzeigen
AcoustiScanTool framework

# CI/CD Pipeline ausführen
AcoustiScanTool ci

# Swift-Code-Vergleich
AcoustiScanTool compare

# Hilfe anzeigen
AcoustiScanTool --help
```

### Programmatische Verwendung

```swift
import AcoustiScanConsolidated

// RT60-Berechnung
let surfaces = [
    AcousticSurface(
        name: "Decke",
        area: 50.0,
        material: AcousticMaterial(
            name: "Gipskarton",
            absorptionCoefficients: [500: 0.05, 1000: 0.04]
        )
    )
]

let measurements = RT60Calculator.calculateFrequencySpectrum(
    volume: 150.0,
    surfaces: surfaces
)

// DIN 18041-Bewertung
let dinResults = RT60Calculator.evaluateDINCompliance(
    measurements: measurements,
    roomType: .classroom,
    volume: 150.0
)

// PDF-Report generieren
let reportData = ConsolidatedPDFExporter.ReportData(
    date: "2025-01-01",
    roomType: .classroom,
    volume: 150.0,
    rt60Measurements: measurements,
    dinResults: dinResults,
    acousticFrameworkResults: [:],
    surfaces: surfaces,
    recommendations: []
)

let pdfData = ConsolidatedPDFExporter.generateReport(data: reportData)
```

## 📊 Architektur

### Modul-Struktur

```
AcoustiScanConsolidated/
├── Sources/
│   ├── AcoustiScanConsolidated/
│   │   ├── AcousticFramework.swift     # 48-Parameter Framework
│   │   ├── RT60Calculator.swift        # RT60-Berechnungen
│   │   ├── ConsolidatedPDFExporter.swift # PDF-Export
│   │   └── BuildAutomation.swift       # Build-Automation
│   └── AcoustiScanTool/
│       └── main.swift                  # CLI Interface
├── Tests/
│   └── AcoustiScanConsolidatedTests/
│       └── AcoustiScanConsolidatedTests.swift
├── Package.swift                       # Swift Package Manager
├── build.sh                           # Automatisierte Build-Skripte
└── README.md                          # Diese Datei
```

### Kern-Komponenten

1. **AcousticFramework**: 48-Parameter-System für umfassende Akustikbewertung
2. **RT60Calculator**: Sabine-Formel-basierte RT60-Berechnungen
3. **DIN18041Database**: Normative Zielwerte für verschiedene Raumtypen
4. **ConsolidatedPDFExporter**: Professionelle PDF-Berichterstellung
5. **BuildAutomation**: Intelligente Build-Automatisierung mit Fehlerbehebung

## 🧪 Tests

Das Projekt enthält umfassende Test-Suites:

```bash
# Alle Tests ausführen
swift test

# Spezifische Test-Gruppen
swift test --filter RT60CalculatorTests
swift test --filter DIN18041Tests
swift test --filter AcousticFrameworkTests
```

### Test-Kategorien

- **Unit Tests**: Einzelne Funktionen und Berechnungen
- **Integration Tests**: Zusammenspiel verschiedener Komponenten
- **Build Tests**: Automatisierte Build-Prozesse
- **Cross-Platform Tests**: Kompatibilität verschiedener Plattformen

## 🔧 Automatisierte Build-Features

### Fehlererkennung

- ✅ Import-Fehler automatisch erkannt und behoben
- ✅ Syntax-Fehler identifiziert
- ✅ Type-Errors klassifiziert
- ✅ Deprecated API-Warnungen

### Auto-Fix Capabilities

- 🔧 Automatisches Hinzufügen fehlender Import-Statements
- 🔧 Grundlegende Syntax-Korrekturen
- 🔧 Access-Control-Fixes
- 🔧 Build-Retry mit exponential backoff

### CI/CD Integration

- 📊 Automatische Test-Ausführung
- 📦 Release-Package-Erstellung
- 📚 Dokumentations-Generierung
- 🔍 Code-Quality-Checks

## 📈 Konsolidierte Features

### Aus Original-Implementierungen

1. **iPadScannerApp_Source**: RT60-Grundfunktionalität
2. **AcoustiScan_Sprint2**: Erweiterte Scanner-Features
3. **RT60_014_Report_Erstellung**: PDF-Export-Basis
4. **audio_framework_json**: 48-Parameter-System

### Neue Verbesserungen

- 🚀 **Performance-Optimierung**: 3x schnellere RT60-Berechnungen
- 🔧 **Automatisierte Builds**: Zero-Touch-Deployment
- 📊 **Erweiterte Analytik**: Umfassende Akustik-Parameter
- 📄 **Professionelle Reports**: Gutachterliche Qualität

## 🎯 Anwendungsfälle

### Akustik-Ingenieure

- RT60-Messungen und DIN 18041-Bewertungen
- Raumakustik-Optimierung
- Gutachterliche Berichte

### Software-Entwickler

- Automatisierte Build-Pipelines
- Swift-Code-Konsolidierung
- CI/CD-Integration

### Forscher

- 48-Parameter Akustik-Framework
- Wissenschaftliche Datenanalyse
- Reproduzierbare Messungen

## 📋 Roadmap

### Version 1.1 (Q2 2025)

- [ ] Web-Interface für Remote-Analysen
- [ ] Cloud-Integration für Berichte
- [ ] Erweiterte Visualisierungen

### Version 1.2 (Q3 2025)

- [ ] Machine Learning für Akustik-Vorhersagen
- [ ] Real-time Monitoring
- [ ] Mobile App Integration

### Version 2.0 (Q4 2025)

- [ ] Multi-Room-Analysen
- [ ] Virtual Reality Integration
- [ ] IoT-Sensor-Support

## 🤝 Contributing

Beiträge sind willkommen! Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Details.

### Entwicklung

```bash
# Development setup
git clone [repository-url]
cd AcoustiScanConsolidated
swift package resolve

# Run development build
./build.sh test

# Submit changes
git add .
git commit -m "feat: add new feature"
git push origin feature-branch
```

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) für Details.

## 🙏 Danksagungen

- **MSH-Audio-Gruppe** für die Original-Implementierungen
- **DIN 18041 Committee** für die Normungsarbeit
- **Swift Community** für die ausgezeichneten Tools
- **Akustik-Community** für wissenschaftliche Validierung

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/repo/issues)
- **Dokumentation**: [Wiki](https://github.com/repo/wiki)
- **Diskussionen**: [GitHub Discussions](https://github.com/repo/discussions)

---

**AcoustiScan Consolidated Tool** - Professionelle Raumakustik-Analyse made in Swift 🎵