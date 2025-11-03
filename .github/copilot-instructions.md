# GitHub Copilot Instructions - AcoustiScan RT60

Diese Datei enthält projektspezifische Anweisungen für GitHub Copilot, um konsistenten und qualitativ hochwertigen Code zu generieren.

## Projekt-Kontext

AcoustiScan ist eine professionelle iPad-App für akustische Raumanalyse mit:
- **RT60-Messung**: Frequenzabhängige Nachhallzeitmessung (125 Hz - 4 kHz)
- **DIN 18041 Konformität**: Deutsche Norm für Raumakustik
- **LiDAR-Integration**: 3D-Raumerfassung mit RoomPlan API
- **PDF-Export**: Professionelle Gutachten-Reports
- **Material-Datenbank**: 500+ akustische Materialien

## Code-Stil und Konventionen

### Swift Code Style

1. **Naming Conventions**
   - Verwende **camelCase** für alle Properties und Variablen (NICHT snake_case)
   - Verwende **PascalCase** für Typen (Struct, Class, Enum, Protocol)
   - Verwende beschreibende Namen: `calculateRT60` statt `calc` oder `c`

   ```swift
   // ✅ RICHTIG
   public let frequencyHz: Int
   public let targetRT60Seconds: Double

   // ❌ FALSCH
   public let freq_hz: Int
   public let target_rt60: Double
   ```

2. **Error Handling**
   - Verwende **immer** explizite Error Handling mit `throws`
   - NIEMALS silent failures mit `return 0.0` oder `guard ... else { return nil }`
   - Definiere spezifische Error-Enums für Module

   ```swift
   // ✅ RICHTIG
   public enum AcoustiScanError: LocalizedError {
       case invalidVolume(Double)
       case invalidAbsorptionArea(Double)
   }

   public static func calculateRT60(volume: Double, absorptionArea: Double) throws -> Double {
       guard volume > 0 else { throw AcoustiScanError.invalidVolume(volume) }
       guard absorptionArea > 0 else { throw AcoustiScanError.invalidAbsorptionArea(absorptionArea) }
       return 0.161 * volume / absorptionArea
   }

   // ❌ FALSCH
   public static func calculateRT60(volume: Double, absorptionArea: Double) -> Double {
       guard volume > 0 else { return 0.0 }  // Silent failure!
       guard absorptionArea > 0 else { return 0.0 }
       return 0.161 * volume / absorptionArea
   }
   ```

3. **Type Safety**
   - Verwende **strongly-typed Models** statt Dictionaries
   - Verwende `Codable` für JSON-Serialisierung
   - Vermeide `[String: Any]` oder `[[String: Double?]]`

   ```swift
   // ✅ RICHTIG
   public struct RT60Band: Codable {
       public let frequencyHz: Int
       public let t20Seconds: Double
   }
   public let rt60Bands: [RT60Band]

   // ❌ FALSCH
   public let rt60_bands: [[String: Double?]]  // Type-unsafe!
   ```

4. **Dokumentation**
   - Verwende **`///` DocC-Comments** für alle public APIs
   - Dokumentiere Parameter, Return-Werte, Throws und Examples

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
   public static func calculateRT60(volume: Double, absorptionArea: Double) throws -> Double
   ```

5. **SwiftLint Compliance**
   - Max line length: **120 characters**
   - Max type body length: **400 lines**
   - Max file length: **1000 lines**
   - Cyclomatic complexity: **15**

### Architektur-Patterns

1. **Single Responsibility Principle**
   - Klassen sollten EINE klare Verantwortung haben
   - Wenn eine Klasse > 400 Zeilen hat, splitten in kleinere Klassen
   - Beispiel: `ImpulseResponseAnalyzer` (248 LOC) sollte aufgeteilt werden in:
     - `EnergyDecayCalculator`
     - `SpectrogramAnalyzer`
     - `RT60Detector`

2. **Dependency Injection**
   - Verwende Protokolle für Abhängigkeiten
   - Inject Dependencies über Initializer

   ```swift
   // ✅ RICHTIG
   protocol ReportRenderer {
       func render(_ model: ReportModel) -> Data
   }

   class ExportService {
       private let renderer: ReportRenderer
       init(renderer: ReportRenderer) {
           self.renderer = renderer
       }
   }
   ```

3. **Vermeide Code-Duplikation**
   - KRITISCH: Es existieren mehrere duplizierte Renderer-Implementierungen
   - Verwende EINE gemeinsame Implementierung für HTML/PDF Rendering
   - Vermeide copy-paste zwischen `AcoustiScanConsolidated` und `Modules/Export`

### Testing

1. **Test Coverage**
   - Alle public APIs müssen getestet werden
   - Target: **80% Code Coverage**
   - Verwende **XCTest** (nicht Swift Testing)

2. **Test-Naming**
   ```swift
   func testCalculateRT60WithValidInputs() throws
   func testCalculateRT60ThrowsErrorForNegativeVolume() throws
   ```

3. **Test-Organisation**
   - Arrange: Setup test data
   - Act: Execute function
   - Assert: Verify results

   ```swift
   func testRT60CalculationForClassroom() throws {
       // Arrange
       let volume = 150.0  // m³
       let absorptionArea = 25.0  // m²

       // Act
       let rt60 = try RT60Calculator.calculateRT60(volume: volume, absorptionArea: absorptionArea)

       // Assert
       XCTAssertEqual(rt60, 0.966, accuracy: 0.01)
   }
   ```

## Domain-Spezifisches Wissen

### Akustik-Konstanten

```swift
// Sabine-Konstante für RT60-Berechnung
let sabineConstant = 0.161  // für Luft bei 20°C, 50% rel. Luftfeuchte

// DIN 18041 Frequenzbänder (Hz)
let dinFrequencies = [125, 250, 500, 1000, 2000, 4000]

// Raumtypen nach DIN 18041
enum RoomType {
    case a1Sprache         // Sprache klein (V < 250 m³)
    case a2SpracheMittel   // Sprache mittel (250 < V < 5000 m³)
    case a3SpracheLaut     // Sprache groß (V > 5000 m³)
    case b                 // Musik/Darbietung
    case c                 // Inklusiver Unterricht
    case d                 // Sport/Schwimmen
    case e                 // Verkehrsflächen
}
```

### RT60-Berechnung

```swift
// Sabine-Formel: RT60 = 0.161 × V / A
// V = Raumvolumen (m³)
// A = Äquivalente Absorptionsfläche (m²)
//
// Absorptionsfläche: A = Σ(S_i × α_i)
// S_i = Fläche der Oberfläche i (m²)
// α_i = Absorptionskoeffizient (0-1, frequenzabhängig)
```

### DIN 18041 Toleranzen

```swift
// Raumtyp A1: ±20% Toleranz
// Raumtyp A2: ±15% Toleranz
// Raumtyp B: ±25% Toleranz
// Raumtyp C: ±30% Toleranz
```

## Projektstruktur

```
AcoustiScanApp/                 # iOS UI Layer (SwiftUI)
    ├── Views/RT60/             # RT60-Messung UI
    ├── Views/Scanner/          # LiDAR-Scanner UI
    ├── Views/Export/           # PDF-Export UI
    └── Views/Material/         # Material-Datenbank UI

AcoustiScanConsolidated/        # Backend Logic (Swift Package)
    ├── Models/                 # Datenmodelle (RT60Measurement, etc.)
    ├── DIN18041/              # Evaluator & Database
    ├── Acoustics/             # Audio-Analyse (ImpulseResponseAnalyzer)
    ├── Export/                # PDF/HTML Renderer
    └── Material/              # Material-Datenbank

Modules/Export/                # LEGACY - Sollte konsolidiert werden ⚠️
    └── ReportExport/          # Duplizierte Renderer (DEPRECATED)
```

## Wichtige Regeln

### DO ✅

- **Verwende camelCase** für alle Swift Properties
- **Verwende throws** für Error Handling
- **Dokumentiere** alle public APIs mit `///`
- **Teste** alle neuen Funktionen (80% Coverage)
- **Verwende strongly-typed Models** statt Dictionaries
- **Folge DIN 18041** für akustische Berechnungen
- **Verwende bestehende Renderer** (keine Duplikation)

### DON'T ❌

- **NIEMALS snake_case** für Swift Code
- **NIEMALS silent failures** (return 0.0 bei Errors)
- **NIEMALS Code duplizieren** (besonders Renderer!)
- **NIEMALS `[String: Any]`** verwenden
- **NIEMALS undokumentierte public APIs**
- **NIEMALS XSS-Vulnerabilities** (HTML-Escape benutzen!)
- **NIEMALS > 400 Zeilen** pro Klasse (SRP beachten)

## Security

### HTML Rendering

```swift
// ✅ RICHTIG - Escape HTML
private func escapeHTML(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
}

// ❌ FALSCH - XSS Vulnerability!
private func renderMetadata(_ metadata: [String: String]) -> String {
    return "<div>\(metadata["key"])</div>"  // KEINE Escape!
}
```

## Beispiel-Code

### Model Definition

```swift
/// Represents an RT60 measurement at a specific frequency.
public struct RT60Measurement: Codable, Equatable {
    /// The frequency in Hz (typically 125, 250, 500, 1000, 2000, or 4000)
    public let frequencyHz: Int

    /// The measured RT60 reverberation time in seconds
    public let rt60Seconds: Double

    /// Creates a new RT60 measurement.
    /// - Parameter frequency: The frequency in Hz (must be > 0)
    /// - Parameter rt60: The RT60 time in seconds (must be > 0)
    /// - Throws: `AcoustiScanError.invalidFrequency` if frequency ≤ 0
    /// - Throws: `AcoustiScanError.invalidRT60` if rt60 ≤ 0
    public init(frequency: Int, rt60: Double) throws {
        guard frequency > 0 else { throw AcoustiScanError.invalidFrequency(frequency) }
        guard rt60 > 0 else { throw AcoustiScanError.invalidRT60(rt60) }
        self.frequencyHz = frequency
        self.rt60Seconds = rt60
    }
}
```

### Service Implementation

```swift
/// Service for calculating room acoustics based on DIN 18041.
public final class RT60Calculator {

    /// Calculates RT60 using Sabine's formula.
    ///
    /// - Parameter volume: Room volume in m³
    /// - Parameter absorptionArea: Equivalent absorption area in m²
    /// - Returns: RT60 in seconds
    /// - Throws: `AcoustiScanError` if parameters are invalid
    public static func calculateRT60(
        volume: Double,
        absorptionArea: Double
    ) throws -> Double {
        guard volume > 0 else { throw AcoustiScanError.invalidVolume(volume) }
        guard absorptionArea > 0 else {
            throw AcoustiScanError.invalidAbsorptionArea(absorptionArea)
        }

        let sabineConstant = 0.161
        return sabineConstant * volume / absorptionArea
    }
}
```

## Bekannte Probleme zu vermeiden

1. **Renderer-Duplikation** ⚠️
   - Es existieren 3 verschiedene HTML-Renderer
   - Es existieren 3 verschiedene PDF-Renderer
   - Verwende NUR die Version in `AcoustiScanConsolidated/Export/`

2. **Report-Model Inkonsistenzen** ⚠️
   - `ReportData` vs. `ReportModel` sind inkompatibel
   - Verwende `ReportModel` für neue Features
   - `ReportData` ist DEPRECATED

3. **Test-Framework** ⚠️
   - Verwende **XCTest** (nicht Swift Testing)
   - Die Codebase wurde von Testing zu XCTest migriert

4. **iOS Version** ⚠️
   - App: iOS 17.0+
   - Consolidated Package: iOS 15.0+
   - Verwende iOS 15.0+ APIs im Package

## CI/CD

- **Build-Workflow**: `.github/workflows/build-test.yml`
- **Auto-Retry**: `.github/workflows/auto-retry.yml`
- **Linting**: SwiftLint (strict mode)
- **Formatting**: SwiftFormat (automatisch)

## Hilfreiche Links

- **DIN 18041**: Deutsche Norm für Raumakustik
- **Sabine Formula**: RT60 = 0.161 × V / A
- **ISO 3382-1**: Internationale Standard für RT60-Messung
- **Apple RoomPlan**: LiDAR-basierte Raumerfassung
- **PDFKit**: PDF-Generierung (iOS/macOS)

---

**Version**: 1.0
**Letztes Update**: 2025-11-03
**Maintainer**: Marc Schneider-Handrup
