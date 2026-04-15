# RT60_ipad_akusti-scan-APP

## AcoustiScan - Professional Acoustic Analysis for iPad

AcoustiScan ist eine professionelle iOS-App für akustische Raumanalyse mit LiDAR-Scanner-Integration und RT60-Nachhallzeitmessungen nach DIN 18041.

### Features

- [TARGET] **LiDAR-Raumscan**: Automatische 3D-Raumerfassung mit RoomPlan API
- [SOUND] **RT60-Messung**: Frequenzabhängige Nachhallzeitmessung (125 Hz - 4 kHz)
- [STATS] **DIN 18041 Klassifizierung**: Automatische Bewertung nach deutscher Norm
- [DOC] **PDF-Export**: 6-seitiger Gutachten-Report mit Frequenzgrafiken
- [STYLE] **Material-Datenbank**: 500+ akustische Materialien mit Absorptionskoeffizienten
- [CONSTRUCT]️ **Absorber-Planer**: Automatische Berechnung erforderlicher Absorptionsflächen

---

## 📱 iPad App

### Voraussetzungen

- **Xcode** 15.0+
- **iPadOS** 17.0+
- **iPad mit LiDAR-Sensor** (iPad Pro 2020+)

### Installation

1. Öffne `AcoustiScanApp/AcoustiScanApp.xcodeproj` in Xcode
2. Wähle dein iPad als Target (Device oder Simulator)
3. Build & Run (⌘R)

```bash
# Clone Repository
git clone https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
cd RT60_ipad_akusti-scan-APP

# Öffne in Xcode
open AcoustiScanApp/AcoustiScanApp.xcodeproj
```

### App-Architektur

```
AcoustiScanApp (SwiftUI UI Layer)
    │
    ├── Views/
    │   ├── Scanner/     # LiDAR + RoomPlan Integration
    │   ├── RT60/        # Impulsmessung + Frequenzanalyse
    │   ├── Material/    # Material-Datenbank Editor
    │   ├── Room/        # Manuelle Raumeingabe
    │   └── Export/      # PDF-Generation + Sharing
    │
    └── Dependencies:
        └── AcoustiScanConsolidated (Swift Package)
            ├── RT60 Calculation Engine
            ├── DIN 18041 Evaluator
            ├── PDF Report Generator
            └── Material Database
```

### Tab-Navigation

1. **Scanner-Tab**: LiDAR-basierte Raumerfassung mit ARKit
2. **RT60-Tab**: Nachhallzeitmessung mit Frequenzgrafiken
3. **Results-Tab**: DIN 18041 Klassifizierung und Bewertung
4. **Export-Tab**: PDF-Report-Generierung und Share Sheet
5. **Materials-Tab**: Material-Datenbank mit Suchfunktion

### Berechtigungen

Die App benötigt folgende iOS-Berechtigungen (in Info.plist konfiguriert):

- **Kamera**: Für LiDAR-Scanner (`NSCameraUsageDescription`)
- **Mikrofon**: Für RT60-Impulsmessungen (`NSMicrophoneUsageDescription`)
- **LiDAR**: Hardware-Anforderung (`UIRequiredDeviceCapabilities`)

---

## [TOOLS]️ Entwicklung

### Backend (Swift Package)

Das Backend ist als Swift Package strukturiert:

```bash
cd AcoustiScanConsolidated
swift build
swift test
```

### Tests ausführen

```bash
# Package Tests
cd AcoustiScanConsolidated
swift test

# App Tests (in Xcode)
# Product > Test (⌘U)
```

### Projektstruktur

```
RT60_ipad_akusti-scan-APP/
│
├── AcoustiScanApp/                 # iOS App (SwiftUI)
│   ├── AcoustiScanApp.xcodeproj    # Xcode-Projekt
│   ├── Package.swift               # SPM Integration
│   ├── AcoustiScanApp/
│   │   ├── App/                    # App Entry Point
│   │   │   ├── AcoustiScanApp.swift
│   │   │   └── ContentView.swift
│   │   ├── Views/                  # UI Layer (13 Views)
│   │   │   ├── RT60/               # RT60View, ChartView, ClassificationView
│   │   │   ├── Scanner/            # LiDAR, RoomScan, ARCoordinator
│   │   │   ├── Material/           # MaterialEditorView
│   │   │   ├── Room/               # RoomDimensionView
│   │   │   └── Export/             # ExportView, ShareSheet
│   │   └── Resources/
│   │       ├── Info.plist          # App Configuration
│   │       └── Assets.xcassets/    # App Icon, AccentColor
│   └── AcoustiScanAppTests/        # UI Tests
│
└── AcoustiScanConsolidated/        # Backend (Swift Package)
    ├── Package.swift
    ├── Sources/
    │   └── AcoustiScanConsolidated/
    │       ├── RT60/               # RT60 Calculation Engine
    │       ├── DIN18041/           # Evaluator + Classification
    │       ├── Export/             # PDF Report Generator
    │       ├── Material/           # Material Database
    │       └── Room/               # Room Model + Calculations
    └── Tests/
```

---

## [STATS] Features im Detail

### 1. LiDAR-Scanner (RoomPlan)

- Automatische Raumerkennung mit Apple RoomPlan API
- Erkennung von Wänden, Türen, Fenstern
- Export als USDZ 3D-Modell
- Oberflächenklassifizierung (Beton, Holz, Glas, etc.)

### 2. RT60-Messung

- Impulsantwort-Messung mit USB-Mikrofon-Support
- Frequenzanalyse: 125 Hz, 250 Hz, 500 Hz, 1 kHz, 2 kHz, 4 kHz
- Live-FFT-Visualisierung
- Automatische Kalibration (EQ-Kompensation)

### 3. DIN 18041 Evaluator

- Raumtyp-Klassifizierung (A1, A2, A3, B, C, D, E)
- Soll-/Ist-Vergleich der Nachhallzeit
- Abweichungsanalyse nach Norm
- Farbcodierte Bewertung (Grün/Gelb/Rot)

### 4. PDF-Report

6-seitiger professioneller Gutachten-Report:

- **Seite 1**: Deckblatt mit Projekt-Infos
- **Seite 2**: Raum-Übersicht mit 3D-Visualisierung
- **Seite 3**: RT60-Frequenzgrafiken
- **Seite 4**: DIN 18041 Klassifizierung
- **Seite 5**: Material-Übersicht
- **Seite 6**: Absorber-Empfehlungen

### 5. Material-Datenbank

- 500+ vordefinierte Materialien
- Absorptionskoeffizienten für alle Oktavbänder
- Kategorisierung (Absorber, Diffusoren, Reflektoren)
- Suchfunktion + Filter

---

## [LAUNCH] Deployment

### TestFlight (Beta)

```bash
# Archive erstellen
# Xcode > Product > Archive

# Upload zu App Store Connect
# Xcode Organizer > Distribute App > App Store Connect
```

### App Store

Erforderliche Assets:

- App Icon (1024x1024)
- Screenshots (iPad Pro 12.9" + 11")
- Beschreibung (DE + EN)
- Keywords: Akustik, RT60, LiDAR, DIN 18041, Nachhallzeit

---

## [READ] Dokumentation

### RT60-Berechnung

Nach Sabine-Formel:
```
RT60 = 0.161 × V / A
```

- **V**: Raumvolumen in m3
- **A**: Äquivalente Absorptionsfläche in m² (frequenzabhängig)

### DIN 18041 Grenzwerte

| Raumtyp | Volumen | Soll-RT60 | Toleranz |
|---------|---------|-----------|----------|
| A1      | < 250 m3 | 0.6 s    | ±20%     |
| A2      | < 5000 m3 | 0.8 s   | ±15%     |
| B       | Sprache  | 1.0 s    | ±25%     |
| C       | Musik    | 1.5 s    | ±30%     |

---

## [FIX] Troubleshooting

### Build-Fehler

**Problem**: `AcoustiScanConsolidated` Package nicht gefunden

**Lösung**:
```bash
cd AcoustiScanConsolidated
swift build
# Dann Xcode neu starten
```

**Problem**: LiDAR-Funktionen nicht verfügbar

**Lösung**:
- Simulator unterstützt kein LiDAR → Physisches iPad verwenden
- iPad muss LiDAR-Sensor haben (iPad Pro 2020+)

**Problem**: Kamera/Mikrofon-Berechtigungen fehlen

**Lösung**:
- In iOS Settings > AcoustiScan > Berechtigungen aktivieren
- App neu starten

---

## 🎓 Für Auszubildende / Einsteiger

Dieser Abschnitt hilft dir, das Projekt zu verstehen und eigene Beiträge zu leisten.

### Erste Schritte

1. **Repository klonen und bauen**:
   ```bash
   git clone https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
   cd RT60_ipad_akusti-scan-APP

   # Backend testen
   cd AcoustiScanConsolidated
   swift build && swift test
   cd ..

   # Xcode öffnen
   open AcoustiScanApp/AcoustiScanApp.xcodeproj
   ```

2. **Lies CONTRIBUTING.md** - Dort findest du alle Entwicklungsrichtlinien.

3. **Verstehe die Architektur** (siehe Diagramm unten).

### Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────────┐
│                        AcoustiScan App                          │
│                     (SwiftUI / iPadOS)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Scanner   │  │    RT60     │  │   Export    │             │
│  │    Tab      │  │    Tab      │  │    Tab      │             │
│  │  (LiDAR)    │  │  (Messung)  │  │   (PDF)     │             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
│         │                │                │                     │
│         └────────────────┼────────────────┘                     │
│                          │                                      │
│                    ┌─────▼─────┐                                │
│                    │ViewModel  │  @StateObject / @Published    │
│                    │  Layer    │                                │
│                    └─────┬─────┘                                │
│                          │                                      │
├──────────────────────────┼──────────────────────────────────────┤
│                          │                                      │
│  ┌───────────────────────▼────────────────────────────────────┐ │
│  │            AcoustiScanConsolidated (Swift Package)         │ │
│  │                                                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │ RT60         │  │ DIN 18041    │  │ Material     │     │ │
│  │  │ Calculator   │  │ Evaluator    │  │ Database     │     │ │
│  │  │              │  │              │  │              │     │ │
│  │  │ Sabine-      │  │ Raumtyp-     │  │ 500+         │     │ │
│  │  │ Formel       │  │ Klassierung  │  │ Materialien  │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  │                                                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │ Measurement  │  │ Acoustic     │  │ PDF Report   │     │ │
│  │  │ Quality      │  │ Framework    │  │ Generator    │     │ │
│  │  │              │  │              │  │              │     │ │
│  │  │ ISO 3382-1   │  │ 48 Parameter │  │ 6-Seiten     │     │ │
│  │  │ Konformität  │  │ Klangfarbe+  │  │ Gutachten    │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Wichtige Konzepte

| Konzept | Erklärung | Datei(en) |
|---------|-----------|-----------|
| **RT60** | Nachhallzeit - Zeit bis Schall um 60 dB abfällt | `RT60Calculator.swift` |
| **Sabine-Formel** | RT60 = 0.161 × V / A (V=Volumen, A=Absorption) | `RT60Calculator.swift:10-14` |
| **DIN 18041** | Deutsche Norm für Raumakustik | `RT60Evaluator.swift`, `RoomType.swift` |
| **LiDAR** | Laser-Entfernungsmessung für 3D-Raumscan | `LiDARScanView.swift` |
| **RoomPlan** | Apple API für automatische Raumerkennung | `RoomScanView.swift` |
| **ARKit** | Augmented Reality Framework | `LiDARScanView.swift` |
| **SwiftUI** | Deklaratives UI-Framework | `Views/*.swift` |
| **MVVM** | Model-View-ViewModel Architekturmuster | Gesamtprojekt |

### Lernpfad

**Woche 1-2: Grundlagen**
- [ ] Swift-Syntax lernen ([Swift Tour](https://docs.swift.org/swift-book/GuidedTour/GuidedTour.html))
- [ ] SwiftUI-Basics ([Apple Tutorial](https://developer.apple.com/tutorials/swiftui))
- [ ] Git-Grundlagen (clone, commit, push, pull request)

**Woche 3-4: Projekt verstehen**
- [ ] README.md und CONTRIBUTING.md lesen
- [ ] Projektstruktur erkunden
- [ ] Erste kleine Änderung machen (z.B. Typo fixen)

**Woche 5-6: Akustik-Grundlagen**
- [ ] Was ist RT60? (YouTube: "Reverberation Time Explained")
- [ ] DIN 18041 verstehen (Zusammenfassung lesen)
- [ ] `RT60Calculator.swift` durchlesen

**Woche 7-8: Eigene Features**
- [ ] Issue auswählen und bearbeiten
- [ ] Pull Request erstellen
- [ ] Code Review durchlaufen

### Häufige Aufgaben für Anfänger

1. **Lokalisierung hinzufügen**
   - Neue Strings in `LocalizationKeys.swift` eintragen
   - Übersetzungen in `Localizable.strings` (de/en)

2. **UI-Test schreiben**
   - Beispiel in `AcoustiScanAppTests/` ansehen
   - `XCTAssert` für Assertions verwenden

3. **Material zur Datenbank hinzufügen**
   - `MaterialDatabase.swift` bearbeiten
   - Absorptionskoeffizienten recherchieren

4. **Bug fixen**
   - Issue-Liste durchsuchen
   - `[good first issue]` Label suchen

### Hilfe bekommen

- **Im Code**: Kommentare lesen, `// MARK:` Abschnitte beachten
- **Dokumentation**: Apple Developer Documentation
- **Fragen**: Issue im Repository erstellen
- **Pair Programming**: Mentor um Session bitten

### Wichtige Dateien zum Studieren

| Priorität | Datei | Warum wichtig |
|-----------|-------|---------------|
| 1 | `RT60Calculator.swift` | Kernalgorithmus |
| 2 | `ContentView.swift` | App-Einstiegspunkt |
| 3 | `RoomScanView.swift` | LiDAR-Integration |
| 4 | `Surface.swift` | Datenmodell |
| 5 | `MeasurementQuality.swift` | ISO-Konformität |

---

## [SCROLL] Lizenz

Proprietary - Alle Rechte vorbehalten

---

## 👥 Kontakt

**Entwickler**: Marc Schneider-Handrup
**Repository**: https://github.com/Darkness308/RT60_ipad_akusti-scan-APP

---

## [NOTE] Changelog

### Version 1.0 (2025-11-02)

[DONE] **App Structure**
- Created complete Xcode project for iPadOS 17.0+
- Integrated 13 SwiftUI views from source archives
- Linked AcoustiScanConsolidated Swift Package

[DONE] **Features**
- Tab 1: LiDAR Scanner (RoomPlan + ARKit)
- Tab 2: RT60 Measurement (frequency analysis)
- Tab 3: DIN 18041 Classification (evaluation)
- Tab 4: PDF Export (6-page reports)
- Tab 5: Material Database (500+ materials)

[DONE] **Backend Integration**
- RT60 Calculation Engine (consolidated)
- DIN 18041 Evaluator (production-ready)
- PDF Report Generator (6-page template)
- Material Database (500+ entries)

[TARGET] **Production Status**: Ready for QA Testing

---

**Relates-to**: Commits 046245c (Merge cleanup), e15c8c8 (Consolidation)
**Completes**: Backend + UI integration (production-ready)
