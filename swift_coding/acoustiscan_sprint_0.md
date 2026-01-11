# AcoustiScan - Sprint 0-2 Artefakte (Finalisiert)

## Repository-Struktur
```
repo/
├─ App/
│  └─ AppEntry.swift
├─ Modules/
│  ├─ UI/TabRootView.swift
│  ├─ Scanner/
│  │   ├─ ARCoordinator.swift
│  │   ├─ LiDARScanView.swift
│  │   ├─ RoomScanView.swift
│  │   ├─ SurfaceStore.swift
│  │   └─ RoomDimensionView.swift
│  ├─ Acoustics/RT60/
│  │   ├─ RT60Calculation.swift
│  │   ├─ RT60ChartView.swift
│  │   ├─ RT60View.swift
│  │   └─ ImpulseResponseAnalyzer.swift
│  ├─ DIN18041/
│  │   ├─ RoomType.swift
│  │   ├─ DIN18041Database.swift
│  │   ├─ DIN18041Target.swift
│  │   ├─ RT60Evaluator.swift
│  │   ├─ RT60Deviation.swift
│  │   ├─ RT60Measurement.swift
│  │   └─ RT60ClassificationView.swift
│  ├─ Material/
│  │   ├─ MaterialDatabase.swift
│  │   ├─ MaterialManager.swift
│  │   ├─ MaterialEditorView.swift
│  │   └─ MaterialCSVImporter.swift
│  ├─ Export/
│  │   ├─ PDFExportView.swift
│  │   ├─ ExportView.swift
│  │   └─ ShareSheet.swift
│  └─ AbsorberCalculation/
│      ├─ AbsorberCalculator.swift
│      ├─ AbsorberPlanner.swift
│      ├─ AbsorberProduct.swift
│      ├─ AbsorberRecommendation.swift
│      └─ AbsorptionRequirement.swift
├─ Docs/
│  ├─ README.md
│  ├─ Messleitfaden.md
│  ├─ CHANGELOG.md
│  ├─ backlog.md
│  └─ risks.md
└─ Tests/
   ├─ Unit/
   │  ├─ RT60Tests.swift
   │  ├─ RT60EvaluatorTests.swift
   │  ├─ RT60ChartViewTests.swift
   │  ├─ AbsorberCalculatorTests.swift
   │  ├─ MockMaterialDatabase.swift
   │  └─ MockSurfaceStore.swift
   └─ Integration/
```

---

## Docs

### README.md
Beschreibt Ziel, Umfang und Aufbau der App **AcoustiScan** (iPad‑App zur orientierenden Raumakustikmessung). Enthält Überblick zu Modulen, genutzten Frameworks (RoomPlan, ARKit, SwiftUI, AVFoundation, PDFKit) sowie Scope-Hinweis (keine Abnahmemessung).

### Messleitfaden.md
Enthält praxisnahe Anleitung für Nutzer:
- Vorbereitungen (Mikrofon, Raum frei räumen, Störquellen reduzieren)
- Ablauf: Scannen → Material zuordnen → Messung (T20/T30) → DIN‑Vergleich → PDF‑Export
- Kalibrierhinweise und Transparenz gemäß EU AI Act.

### CHANGELOG.md
- **0.1.0 Sprint 0:** Repo‑Skeleton, AppEntry, TabRootView, Docs erstellt
- **0.2.0 Sprint 1:** RT60‑Pipeline (Schroeder‑Methode), DIN18041‑Formeln, dynamische Klassifikation, neuer RoomType `musicRoom`
- **0.3.0 Sprint 2:** RoomPlan‑Skeleton (`RoomScanView`), CSV‑Import/Export (`MaterialCSVImporter`), Erweiterungen `MaterialManager`

### backlog.md
User Stories (US‑1 bis US‑5) mit Sprintzuordnung und EKS‑Priorität. Nach Sprint 2 sind US‑1 und US‑2 "in Arbeit" markiert, US‑3/4 abgeschlossen.

### risks.md
Liste erkannter Risiken mit Bewertung und Gegenmaßnahmen: Mikrofon‑Kalibrierung, Störgeräusche, Messdauer, Speicher/Performance, EU‑AI‑Act Compliance.

---

## Kernmodule (Auszug)

### AppEntry.swift
```swift
@main
struct AppEntry: App {
    var body: some Scene {
        WindowGroup {
            TabRootView()
        }
    }
}
```

### TabRootView.swift
SwiftUI‑TabView mit 5 Bereichen: **Scan | Material | RT60 | DIN | Report**.

### ImpulseResponseAnalyzer.swift
Implementiert Schroeder‑Integration, berechnet Energiezerfallskurve, T20/T30 und leitet RT60 ab.

### DIN18041Database.swift
Berechnet Tsoll nach Normformeln abhängig vom `RoomType` und Raumvolumen; Toleranz = max(0.2s; 10% Tsoll).

### RT60Evaluator.swift
Stellt `classifyRT60` bereit, um gemessene Werte in `withinRange`, `tooHigh`, `tooLow` einzuordnen.

### RoomScanView.swift
Skeleton für RoomPlan‑Integration. Nutzt `RoomCaptureSession` (nur auf Device), speichert Flächeninformationen im `SurfaceStore`.

### MaterialCSVImporter.swift
Hilfsklasse für Import/Export von CSV‑Materiallisten (`name;125;250;...`).

### MaterialManager.swift
Erweitert um CSV‑Import/Export‑Funktionen (Datei + String).

---

## Nächste Schritte (Sprint 3)
- PDF‑Export ausbauen (Charts, Ampel, Maßnahmenblock)
- UX‑Flows: Mess‑Wizard, Fehlerführung, Accessibility
- Golden‑File‑Tests für PDF
- Erweiterung der Report‑Metadaten

---

📦 **Finale Artefakte Sprint 0-2** sind jetzt vollständig in Klartext (Markdown) und Swift‑Code strukturiert und einsatzbereit.

