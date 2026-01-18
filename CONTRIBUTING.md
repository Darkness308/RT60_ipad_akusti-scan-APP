# Beitragen zu AcoustiScan

Dieses Dokument erklärt, wie du als Auszubildende/r oder neue/r Entwickler/in zum Projekt beitragen kannst.

---

## Inhaltsverzeichnis

1. [Voraussetzungen](#voraussetzungen)
2. [Entwicklungsumgebung einrichten](#entwicklungsumgebung-einrichten)
3. [Projektstruktur verstehen](#projektstruktur-verstehen)
4. [Code-Konventionen](#code-konventionen)
5. [Workflow: Änderungen einreichen](#workflow-änderungen-einreichen)
6. [Merge-Gate für `main`](#merge-gate-für-main)
7. [Tests schreiben und ausführen](#tests-schreiben-und-ausführen)
8. [Häufige Aufgaben](#häufige-aufgaben)
9. [Fehlerbehebung](#fehlerbehebung)

---

## Voraussetzungen

### Hardware

- **Mac** mit Apple Silicon (M1/M2/M3) oder Intel-Prozessor
- **iPad mit LiDAR** (iPad Pro 2020+) - optional für Tests

### Software

| Software | Version | Installation |
|----------|---------|--------------|
| macOS | 14.0+ (Sonoma) | - |
| Xcode | 15.4+ | App Store |
| Swift | 5.9+ | Mit Xcode |
| Git | 2.39+ | `xcode-select --install` |
| SwiftLint | 0.54+ | `brew install swiftlint` |
| SwiftFormat | 0.53+ | `brew install swiftformat` |

### Installation der Tools

```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Developer Tools installieren
xcode-select --install

# Linting-Tools installieren
brew install swiftlint swiftformat
```

---

## Entwicklungsumgebung einrichten

### 1. Repository klonen

```bash
# Repository klonen
git clone https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
cd RT60_ipad_akusti-scan-APP
```

### 2. Swift Package bauen

```bash
# Backend-Package testen
cd AcoustiScanConsolidated
swift build
swift test

# Export-Modul testen
cd ../Modules/Export
swift build
swift test
cd ../..
```

### 3. Xcode-Projekt öffnen

```bash
# Xcode-Projekt öffnen
open AcoustiScanApp/AcoustiScanApp.xcodeproj
```

### 4. Konfiguration prüfen

In Xcode:
1. **Signing & Capabilities**: Wähle dein Development Team
2. **Deployment Target**: iPadOS 17.0
3. **Device**: Wähle dein iPad oder Simulator

---

## Projektstruktur verstehen

```
RT60_ipad_akusti-scan-APP/
│
├── AcoustiScanApp/                 # iOS App (SwiftUI)
│   ├── AcoustiScanApp.xcodeproj    # Xcode-Projekt
│   └── AcoustiScanApp/
│       ├── App/                    # App-Einstiegspunkt
│       │   ├── AcoustiScanApp.swift    # @main App
│       │   └── ContentView.swift       # Root View
│       ├── Views/                  # UI-Komponenten
│       │   ├── Scanner/           # LiDAR-Scanner Views
│       │   ├── RT60/              # Messungs-Views
│       │   ├── Material/          # Material-Editor
│       │   ├── Room/              # Raumeingabe
│       │   └── Export/            # PDF-Export
│       └── Resources/
│           ├── Info.plist         # App-Konfiguration
│           └── Assets.xcassets/   # Icons & Farben
│
├── AcoustiScanConsolidated/        # Backend Swift Package
│   ├── Package.swift              # Package-Definition
│   ├── Sources/
│   │   └── AcoustiScanConsolidated/
│   │       ├── RT60Calculator.swift    # Sabine-Formel
│   │       ├── RT60Evaluator.swift     # DIN 18041 Bewertung
│   │       ├── MaterialDatabase.swift  # 500+ Materialien
│   │       └── AcousticFramework.swift # 48 Akustik-Parameter
│   └── Tests/                     # Unit Tests
│
├── Modules/Export/                 # Separates Export-Modul
│   ├── Sources/ReportExport/      # PDF/XLSX-Export
│   └── Tests/                     # Export-Tests
│
└── .github/workflows/             # CI/CD Pipelines
    ├── build-test.yml             # Haupt-Build
    ├── swift.yml                  # Swift Tests
    └── self-healing.yml           # Auto-Fix
```

### Architektur-Muster

Das Projekt verwendet **MVVM** (Model-View-ViewModel):

```
┌─────────────────────────────────────────────────────┐
│                    View (SwiftUI)                   │
│  RoomScanView, RT60View, MaterialEditorView, etc.   │
└─────────────────────┬───────────────────────────────┘
                      │ @StateObject / @ObservedObject
┌─────────────────────▼───────────────────────────────┐
│                    ViewModel                        │
│  SurfaceStore, MaterialStore, RT60ViewModel         │
│  - Geschäftslogik                                   │
│  - @Published Properties                            │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                    Model                            │
│  Surface, Material, RT60Measurement, RoomType       │
│  - Reine Datenstrukturen                            │
│  - Codable für Persistenz                           │
└─────────────────────────────────────────────────────┘
```

---

## Code-Konventionen

### Swift-Stil

Wir folgen den [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

```swift
// RICHTIG: Klare, beschreibende Namen
func calculateRT60(volume: Double, absorptionArea: Double) -> Double

// FALSCH: Kryptische Abkürzungen
func calcRT(v: Double, a: Double) -> Double
```

### Formatierung

```swift
// Einrückung: 4 Spaces (kein Tab)
// Zeilenlänge: max. 120 Zeichen
// Leerzeilen zwischen logischen Blöcken

class RT60Calculator {

    // MARK: - Properties

    private let sabineConstant = 0.161

    // MARK: - Public Methods

    public func calculate(volume: Double, area: Double) -> Double {
        guard area > 0 else { return 0.0 }
        return sabineConstant * volume / area
    }
}
```

### SwiftLint-Regeln

Vor jedem Commit ausführen:

```bash
# Lint-Fehler anzeigen
swiftlint

# Auto-Fix wo möglich
swiftlint --fix
swiftformat .
```

### Lokalisierung

Alle User-facing Strings müssen lokalisiert werden:

```swift
// RICHTIG: Lokalisierter String
Text(NSLocalizedString(LocalizationKeys.scanning, comment: "Scanning"))

// FALSCH: Hardcoded String
Text("Scanning")
```

### Memory Management

Immer `[weak self]` in Closures verwenden:

```swift
// RICHTIG: Vermeidet Retain Cycles
DispatchQueue.main.async { [weak self] in
    guard let self = self else { return }
    self.updateUI()
}

// FALSCH: Potentieller Memory Leak
DispatchQueue.main.async {
    self.updateUI()
}
```

---

## Workflow: Änderungen einreichen

### 1. Branch erstellen

```bash
# Aktuellen Stand holen
git checkout main
git pull origin main

# Feature-Branch erstellen
git checkout -b feature/meine-aenderung

# Oder für Bugfixes
git checkout -b fix/bug-beschreibung
```

### 2. Änderungen machen

- Kleine, fokussierte Commits
- Aussagekräftige Commit-Messages

```bash
# Änderungen stagen
git add .

# Commit mit Conventional Commits Format
git commit -m "feat: Add new material category filter"
git commit -m "fix: Correct RT60 calculation for large rooms"
git commit -m "docs: Update README with new features"
```

### Commit-Message-Format

```
<type>: <kurze Beschreibung>

[optionaler Body mit Details]

[optionale Footer mit Issue-Referenz]
```

| Type | Verwendung |
|------|------------|
| `feat` | Neues Feature |
| `fix` | Bugfix |
| `docs` | Dokumentation |
| `style` | Formatierung |
| `refactor` | Code-Umstrukturierung |
| `test` | Tests hinzufügen/ändern |
| `chore` | Build/Tools |

### 3. Tests ausführen

```bash
# Alle Tests lokal ausführen
cd AcoustiScanConsolidated && swift test && cd ..
cd Modules/Export && swift test && cd ../..

# Linting
swiftlint
swiftformat --lint .
```

### 4. Push und Pull Request

```bash
# Branch pushen
git push -u origin feature/meine-aenderung
```

Dann auf GitHub:
1. "Compare & Pull Request" klicken
2. Beschreibung ausfüllen
3. Reviewer zuweisen
4. Auf CI-Status warten

---

## Merge-Gate für `main`

**Ziel:** Änderungen dürfen nur nachweisbar wertvoll, risiko-bewertet und sauber geprüft in `main` landen. Dieses Gate ist verbindlich.

### Kriterienkatalog (verbindlich)

**Business Value**
- Der PR liefert messbaren Nutzen (z. B. Feature, Bugfix, Performance, Compliance).
- Nutzen ist im PR-Text klar beschrieben und für Stakeholder verständlich.

**Keine neue technische Schuld**
- Keine neuen TODOs ohne Ticket/Issue-Referenz.
- Keine absichtlichen Code-Smells (Duplikate, Dead Code, unverwendete Abhängigkeiten).
- Architektur- oder API-Änderungen wurden dokumentiert (README/Docs) falls erforderlich.

**Risikoabschätzung**
- Risiken (z. B. Datenverlust, API-Bruch, UX-Regression) sind identifiziert.
- Minderung/Abfang (Fallback, Feature-Flag, Tests, Monitoring) ist beschrieben.

### Required Checks (müssen grün sein)
- CI-Workflow **build-test.yml** erfolgreich.
- CI-Workflow **swift.yml** erfolgreich.
- Linting/Formatting (SwiftLint/SwiftFormat) ohne Fehler.
- Relevante Unit/Integration/UI-Tests vorhanden und grün.

### Required Reviews (müssen vor Merge erfüllt sein)
- Mindestens **1 fachlicher Review** (Produkt/QA/Domain) für Business Value.
- Mindestens **1 technischer Review** (Code Owner/Lead/Senior).
- Bei Risiko **hoch**: zusätzlicher Review durch Tech Lead oder Maintainer.

---

## Tests schreiben und ausführen

### Unit Tests

```swift
import XCTest
@testable import AcoustiScanConsolidated

final class RT60CalculatorTests: XCTestCase {

    func testSabineFormula() {
        // Given
        let volume: Double = 100.0  // m³
        let absorptionArea: Double = 20.0  // m²

        // When
        let rt60 = RT60Calculator.calculateRT60(
            volume: volume,
            absorptionArea: absorptionArea
        )

        // Then
        // RT60 = 0.161 * 100 / 20 = 0.805
        XCTAssertEqual(rt60, 0.805, accuracy: 0.001)
    }

    func testZeroAbsorptionReturnsZero() {
        let rt60 = RT60Calculator.calculateRT60(volume: 100, absorptionArea: 0)
        XCTAssertEqual(rt60, 0.0)
    }
}
```

### Tests ausführen

```bash
# Alle Package-Tests
swift test

# Mit Verbose Output
swift test -v

# Einzelnen Test ausführen
swift test --filter RT60CalculatorTests.testSabineFormula

# In Xcode
# ⌘U = Alle Tests
# ⌘⌥U = Test an Cursor-Position
```

### UI Tests (in Xcode)

```swift
import XCTest

final class ScannerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testScanButtonExists() throws {
        let scanButton = app.buttons["scanToggleButton"]
        XCTAssertTrue(scanButton.exists)
        XCTAssertTrue(scanButton.isEnabled)
    }
}
```

---

## Häufige Aufgaben

### Neues Material hinzufügen

```swift
// In MaterialDatabase.swift
static let materials: [Material] = [
    // ... existierende Materialien
    Material(
        id: UUID(),
        name: "Neues Material",
        category: .absorber,
        absorptionCoefficients: [
            125: 0.10,
            250: 0.25,
            500: 0.50,
            1000: 0.70,
            2000: 0.80,
            4000: 0.85
        ]
    )
]
```

### Neue View hinzufügen

1. View-Datei erstellen in `AcoustiScanApp/Views/`
2. ViewModel erstellen (falls nötig)
3. In Navigation einbinden
4. Lokalisierungs-Keys hinzufügen

```swift
// NeueView.swift
import SwiftUI

struct NeueView: View {
    @StateObject private var viewModel = NeueViewModel()

    var body: some View {
        VStack {
            // UI hier
        }
        .navigationTitle(NSLocalizedString("neue_view_title", comment: ""))
    }
}
```

### Lokalisierung hinzufügen

1. Key in `LocalizationKeys.swift` hinzufügen:

```swift
public static let neuerKey = "neuer_key"
```

2. Übersetzungen in `Localizable.strings`:

```
// de.lproj/Localizable.strings
"neuer_key" = "Deutsche Übersetzung";

// en.lproj/Localizable.strings
"neuer_key" = "English Translation";
```

---

## Fehlerbehebung

### Build-Fehler

**Problem**: "Missing package product 'AcoustiScanConsolidated'"

```bash
# Lösung: Package neu bauen
cd AcoustiScanConsolidated
swift package clean
swift build
# Xcode: File > Packages > Reset Package Caches
```

**Problem**: SwiftLint-Fehler blockieren Build

```bash
# Lösung: Auto-Fix ausführen
swiftlint --fix
swiftformat .
git add . && git commit -m "style: Fix lint errors"
```

### LiDAR-Probleme

**Problem**: "RoomPlan not available"

- **Simulator** unterstützt kein LiDAR - verwende physisches iPad
- **iPad muss LiDAR haben**: iPad Pro 2020+, iPad Pro 2021+

### Test-Fehler

**Problem**: Tests schlagen auf CI fehl, lokal aber nicht

```bash
# Lösung: Gleiche Umgebung wie CI verwenden
cd AcoustiScanConsolidated
swift package clean
swift build
swift test
```

---

## Hilfe bekommen

- **Code Review**: Erstelle einen Draft PR für frühes Feedback
- **Fragen**: Kommentiere im Issue oder PR
- **Dokumentation**: Siehe README.md und Code-Kommentare
- **DIN 18041**: [Norm-Dokument](https://www.din.de/de/mitwirken/normenausschuesse/nabau/veroeffentlichungen/wdc-beuth:din21:305553385)

---

## Checkliste vor dem PR

- [ ] Code kompiliert ohne Fehler
- [ ] Alle Tests bestehen (`swift test`)
- [ ] SwiftLint zeigt keine Fehler (`swiftlint`)
- [ ] SwiftFormat zeigt keine Änderungen (`swiftformat --lint .`)
- [ ] Commit-Messages folgen Conventional Commits
- [ ] PR-Beschreibung erklärt die Änderungen
- [ ] Neue Features haben Tests
- [ ] User-facing Strings sind lokalisiert

---

## Merge-Gate Checkliste (Go/No-Go)

**Go nur, wenn alle Punkte erfüllt sind:**
- [ ] **Business Value** ist klar beschrieben und nachvollziehbar.
- [ ] **Keine neue technische Schuld** (keine neuen TODOs ohne Ticket, keine Code-Smells).
- [ ] **Risikoabschätzung** ist dokumentiert inkl. Mitigation.
- [ ] **Required Checks** sind grün (build-test.yml, swift.yml, Linting, relevante Tests).
- [ ] **Required Reviews** sind erfüllt (fachlich + technisch, bei hohem Risiko zusätzlicher Lead).

**No-Go, wenn einer der folgenden Punkte zutrifft:**
- [ ] Business Value unklar oder nicht messbar.
- [ ] Neue technische Schuld ohne Plan/Ticket.
- [ ] Risiko nicht bewertet oder keine Mitigation.
- [ ] Mindestens ein Required Check ist rot/fehlt.
- [ ] Required Reviews fehlen.

---

Viel Erfolg beim Entwickeln!
