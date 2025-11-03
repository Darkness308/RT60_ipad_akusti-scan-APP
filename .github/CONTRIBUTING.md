# Contributing to AcoustiScan RT60

Vielen Dank für dein Interesse an der Mitarbeit am AcoustiScan RT60 Projekt! Dieses Dokument enthält Richtlinien und Best Practices für Beiträge.

## Inhaltsverzeichnis

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Issue Reporting](#issue-reporting)

## Code of Conduct

Dieses Projekt folgt einem Code of Conduct, um eine einladende und inklusive Community zu schaffen. Wir erwarten von allen Mitwirkenden:

- Respektvoller und konstruktiver Umgang
- Fokus auf das beste Ergebnis für das Projekt
- Akzeptanz konstruktiver Kritik
- Empathie gegenüber anderen Community-Mitgliedern

## Getting Started

### Prerequisites

- **Xcode** 15.0 oder neuer
- **Swift** 5.9 oder neuer
- **macOS** 12.0+ für Entwicklung
- **iPadOS 17.0+** für App-Testing (LiDAR-fähiges iPad empfohlen)

### Repository Setup

```bash
# Clone the repository
git clone https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
cd RT60_ipad_akusti-scan-APP

# Build the backend package
cd AcoustiScanConsolidated
swift build
swift test

# Open the iOS app in Xcode
cd ../AcoustiScanApp
open AcoustiScanApp.xcodeproj
```

### Branch Structure

- **`main`**: Production-ready code
- **`develop`**: Development branch (wenn vorhanden)
- **`feature/*`**: Feature-Entwicklung
- **`fix/*`**: Bug-Fixes
- **`copilot/*`**: GitHub Copilot generierte Branches
- **`claude/*`**: Claude AI generierte Branches

## Development Workflow

### 1. Create a Branch

```bash
# Feature branch
git checkout -b feature/din18041-extended-frequencies

# Bug fix branch
git checkout -b fix/rt60-calculation-edge-case
```

### 2. Make Changes

- Folge den [Code Style Guidelines](#code-style)
- Schreibe Tests für neue Funktionen
- Dokumentiere public APIs mit DocC-Comments (`///`)
- Halte Commits klein und fokussiert

### 3. Run Tests

```bash
# Backend tests
cd AcoustiScanConsolidated
swift test

# App tests (in Xcode)
# Product > Test (⌘U)
```

### 4. Run Linters

```bash
# SwiftLint
swiftlint --strict

# SwiftFormat
swiftformat --lint .
```

### 5. Commit Changes

Siehe [Commit Message Guidelines](#commit-message-guidelines)

### 6. Push and Create PR

```bash
git push -u origin feature/your-feature-name
```

Erstelle dann einen Pull Request über GitHub.

## Code Style

Wir folgen den Swift API Design Guidelines mit projektspezifischen Erweiterungen:

### Naming Conventions

```swift
// ✅ RICHTIG: camelCase für Properties
public let frequencyHz: Int
public let targetRT60Seconds: Double

// ❌ FALSCH: snake_case
public let freq_hz: Int
public let target_rt60: Double
```

### Error Handling

```swift
// ✅ RICHTIG: Explizite Errors mit throws
public static func calculateRT60(volume: Double, absorptionArea: Double) throws -> Double {
    guard volume > 0 else { throw AcoustiScanError.invalidVolume(volume) }
    guard absorptionArea > 0 else { throw AcoustiScanError.invalidAbsorptionArea(absorptionArea) }
    return 0.161 * volume / absorptionArea
}

// ❌ FALSCH: Silent failures
public static func calculateRT60(volume: Double, absorptionArea: Double) -> Double {
    guard volume > 0 else { return 0.0 }  // Silent failure!
    return 0.161 * volume / absorptionArea
}
```

### Type Safety

```swift
// ✅ RICHTIG: Strongly-typed models
public struct RT60Band: Codable {
    public let frequencyHz: Int
    public let t20Seconds: Double
}

// ❌ FALSCH: Dictionary-based
public let rt60_bands: [[String: Double?]]  // Type-unsafe!
```

### Documentation

Alle public APIs müssen dokumentiert werden:

```swift
/// Calculates room reverberation time using Sabine's formula.
///
/// Sabine's formula: RT60 = 0.161 × V / A
///
/// - Parameter volume: Room volume in cubic meters (must be > 0)
/// - Parameter absorptionArea: Equivalent absorption area in m² (must be > 0)
/// - Returns: Reverberation time in seconds
/// - Throws: `AcoustiScanError.invalidVolume` if volume ≤ 0
/// - Throws: `AcoustiScanError.invalidAbsorptionArea` if absorptionArea ≤ 0
///
/// - Example:
/// ```swift
/// let rt60 = try RT60Calculator.calculateRT60(volume: 150.0, absorptionArea: 25.0)
/// print("RT60: \(rt60) seconds")
/// ```
public static func calculateRT60(volume: Double, absorptionArea: Double) throws -> Double
```

### SwiftLint Rules

- **Line length**: 120 Zeichen max
- **Type body length**: 400 Zeilen max
- **File length**: 1000 Zeilen max
- **Cyclomatic complexity**: 15 max

Siehe `.swiftlint.yml` für vollständige Konfiguration.

## Testing

### Test Coverage

- **Target**: 80% Code Coverage
- Alle public APIs müssen getestet werden
- Tests für Edge Cases und Error-Handling

### Test Organization

```swift
final class RT60CalculatorTests: XCTestCase {

    // MARK: - Happy Path Tests

    func testCalculateRT60WithValidInputs() throws {
        // Arrange
        let volume = 150.0  // m³
        let absorptionArea = 25.0  // m²

        // Act
        let rt60 = try RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)

        // Assert
        XCTAssertEqual(rt60, 0.966, accuracy: 0.01)
    }

    // MARK: - Error Handling Tests

    func testCalculateRT60ThrowsErrorForNegativeVolume() throws {
        // Arrange
        let volume = -100.0
        let absorptionArea = 25.0

        // Act & Assert
        XCTAssertThrowsError(
            try RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)
        ) { error in
            guard case AcoustiScanError.invalidVolume(let vol) = error else {
                XCTFail("Expected invalidVolume error")
                return
            }
            XCTAssertEqual(vol, -100.0)
        }
    }

    // MARK: - Edge Cases

    func testCalculateRT60WithVerySmallAbsorptionArea() throws {
        let volume = 150.0
        let absorptionArea = 0.001  // Very small

        let rt60 = try RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)

        XCTAssertGreaterThan(rt60, 24000)  // Very high RT60
    }
}
```

### Running Tests

```bash
# Swift Package Tests
cd AcoustiScanConsolidated
swift test

# With verbose output
swift test -v

# Specific test
swift test --filter RT60CalculatorTests

# App Tests (Xcode)
# Product > Test (⌘U)
```

## Pull Request Process

### PR Template

Wir verwenden ein PR-Template (`.github/PULL_REQUEST_TEMPLATE.md`). Bitte fülle alle Abschnitte aus:

1. **Problem**: Kurzbeschreibung + Issue-Referenz
2. **Lösung**: Kernänderungen, Architekturhinweise
3. **Tests**: Welche Tests wurden hinzugefügt?
4. **Risiken**: Edge-Cases, Performance, Migration
5. **Normbezug**: DIN 18041 / ISO 3382-1 (falls relevant)
6. **Artefakte**: Audit-JSON, PDF-Preview, Coverage

### Review Process

1. **CI/CD Checks**: Alle GitHub Actions müssen grün sein
   - Build und Tests (Swift Package)
   - SwiftLint (strict mode)
   - SwiftFormat Check
   - Export Module Tests

2. **Code Review**: Mindestens ein Reviewer muss zustimmen
   - Code-Qualität
   - Test-Abdeckung
   - Dokumentation
   - DIN 18041 Konformität (falls relevant)

3. **Approval**: Nach erfolgreichem Review wird der PR gemerged

### Merge Strategy

- **Squash and Merge** für Feature-Branches
- **Merge Commit** für wichtige Releases
- **Rebase and Merge** für Hotfixes

## Commit Message Guidelines

Wir folgen der [Conventional Commits](https://www.conventionalcommits.org/) Spezifikation:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: Neue Funktion
- **fix**: Bug-Fix
- **docs**: Dokumentation
- **style**: Code-Formatierung (keine Logik-Änderung)
- **refactor**: Code-Refactoring
- **test**: Tests hinzufügen oder korrigieren
- **chore**: Build, CI/CD, Dependencies
- **perf**: Performance-Verbesserung

### Scopes

- **rt60**: RT60-Berechnungen
- **din18041**: DIN 18041 Evaluator
- **export**: PDF/HTML Export
- **scanner**: LiDAR Scanner
- **material**: Material-Datenbank
- **ui**: SwiftUI Views
- **acoustics**: Audio-Analyse
- **ci**: CI/CD Workflows

### Examples

```bash
# Feature
feat(din18041): add support for room type E (traffic areas)

# Bug fix
fix(rt60): correct Sabine formula constant for high humidity

# Documentation
docs(contributing): add testing guidelines

# Refactoring
refactor(export): consolidate duplicate HTML renderers

# Test
test(acoustics): add edge case tests for ImpulseResponseAnalyzer

# CI/CD
chore(ci): upgrade Xcode version to 15.2
```

### Breaking Changes

Bei Breaking Changes füge `BREAKING CHANGE:` im Footer hinzu:

```
feat(export)!: replace ReportData with unified ReportModel

BREAKING CHANGE: ReportData model is now deprecated. Use ReportModel instead.
Migration guide: ...
```

## Issue Reporting

### Bug Reports

Verwende das Bug-Report-Template (`.github/ISSUE_TEMPLATE/bug_report.md`):

1. **Beschreibung**: Was ist das Problem?
2. **Zu reproduzieren**: Schritte zur Reproduktion
3. **Erwartetes Verhalten**: Was sollte passieren?
4. **Tatsächliches Verhalten**: Was passiert stattdessen?
5. **Screenshots**: Falls relevant
6. **Umgebung**: iOS-Version, Xcode-Version, etc.

### Feature Requests

Verwende das Feature-Request-Template (`.github/ISSUE_TEMPLATE/feature_request.md`):

1. **Beschreibung**: Was ist die neue Funktion?
2. **Problem**: Welches Problem löst sie?
3. **Lösung**: Wie sollte sie implementiert werden?
4. **Alternativen**: Welche Alternativen gibt es?
5. **Zusätzlicher Kontext**: Weitere Informationen

### Normbezogene Issues

Für DIN 18041 oder ISO 3382-1 bezogene Issues, verwende das Engpass-Template (`.github/ISSUE_TEMPLATE/engpass_issue.md`).

## Domain-Spezifische Guidelines

### Akustik-Berechnungen

Alle akustischen Berechnungen müssen normkonform sein:

- **DIN 18041**: Hörsamkeit in Räumen
- **ISO 3382-1**: Measurement of room acoustic parameters
- **IEC 61260-1**: Electroacoustics - Octave-band filters

```swift
// Sabine-Formel
// RT60 = 0.161 × V / A
// Konstante 0.161 ist für 20°C, 50% rel. Luftfeuchte

// DIN 18041 Frequenzen
let frequencies = [125, 250, 500, 1000, 2000, 4000]  // Hz

// Toleranzen nach Raumtyp
let toleranceA1 = 0.20  // ±20%
let toleranceA2 = 0.15  // ±15%
```

### PDF-Export

PDF-Reports müssen folgende Struktur haben:

1. **Seite 1**: Deckblatt (Projekt-Info, Datum, Gutachter)
2. **Seite 2**: Raum-Übersicht (3D-Visualisierung, Dimensionen)
3. **Seite 3**: RT60-Frequenzgrafiken (alle 6 Bänder)
4. **Seite 4**: DIN 18041 Klassifizierung (Soll/Ist-Vergleich)
5. **Seite 5**: Material-Übersicht (Absorptionskoeffizienten)
6. **Seite 6**: Absorber-Empfehlungen (Berechnung erforderlicher Flächen)

### Security

- **HTML-Escape**: Alle User-Inputs in HTML müssen escaped werden
- **PDF-Validation**: PDFs müssen valide sein (Magic Bytes: `%PDF`)
- **No SQL Injection**: (Noch nicht relevant, aber für Zukunft)

```swift
// ✅ RICHTIG: HTML Escape
private func escapeHTML(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}
```

## Architecture Guidelines

### Projektstruktur

```
AcoustiScanApp/                 # iOS UI Layer
    └── Views/                  # SwiftUI Views
        ├── RT60/               # RT60 Measurement
        ├── Scanner/            # LiDAR Scanner
        ├── Export/             # PDF Export
        └── Material/           # Material Database

AcoustiScanConsolidated/        # Backend Logic
    ├── Models/                 # Data Models
    ├── DIN18041/              # Evaluator & Database
    ├── Acoustics/             # Audio Analysis
    ├── Export/                # Renderers (HTML/PDF)
    └── Material/              # Material Database

Modules/Export/                # DEPRECATED - zu konsolidieren
```

### Dependency Rules

1. **UI Layer** darf **Backend Layer** nutzen
2. **Backend Layer** darf **KEINE** UI-Imports haben
3. **Models** sind in **Backend Layer**
4. **Renderer** sind in **Backend Layer** (NICHT in Modules/Export)

### Known Issues

Vermeide diese bekannten Probleme:

1. **Renderer-Duplikation**: Verwende NUR `AcoustiScanConsolidated/Export/`
2. **Report-Model**: Verwende `ReportModel` (NICHT `ReportData`)
3. **snake_case**: Verwende camelCase für Swift Code
4. **Silent Failures**: Verwende `throws` für Error Handling

## Helpful Resources

- **Apple Developer Docs**: https://developer.apple.com/documentation/
- **Swift API Design Guidelines**: https://swift.org/documentation/api-design-guidelines/
- **DIN 18041**: Deutsche Norm für Raumakustik
- **ISO 3382-1**: International standard for RT60 measurement
- **RoomPlan API**: https://developer.apple.com/documentation/roomplan

## Questions?

Bei Fragen kannst du:

1. **Issue erstellen** mit Label `question`
2. **GitHub Discussions** nutzen (falls aktiviert)
3. **Code Owner kontaktieren**: @Darkness308

---

**Vielen Dank für deine Mitarbeit!** 🎉

Jeder Beitrag, egal wie klein, ist wertvoll für das Projekt. Wir freuen uns auf deine Pull Requests!
