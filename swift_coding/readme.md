# AcoustiScan - iPad Raumakustik‑App (MVP)

Dieses Repository enthält den Quellcode für **AcoustiScan**, einen
experimentellen Prototyp zur orientierenden Messung der Raumakustik
auf dem iPad.  Die App nutzt LiDAR‑Scans, Audiosignalanalyse und
Normenvergleiche, um die Nachhallzeit (RT60) zu bestimmen und mit
den Zielwerten der DIN 18041 zu vergleichen.  Die Ergebnisse können
anschließend in einem PDF‑Bericht exportiert werden.

## Archive-Status

[STATS] **Siehe [ZIP_ANALYSIS_REPORT.md](../ZIP_ANALYSIS_REPORT.md)** für detaillierte Analyse der 5 ZIP-Archive in diesem Ordner.

**Zusammenfassung:**
- [DONE] **4 wertvolle Archive** + 1 Duplikat (entfernbar)
- [DONE] **150 Swift-Dateien** dokumentieren Entwicklungshistorie
- [DONE] **Ergänzen das Hauptsystem** (machen es nicht komplizierter)
- [DONE] **Backup + Test-Ressourcen** für das konsolidierte System

---

## Zielgruppe
* Planer, Architekten, Akustiker
* Anwender in Bildungseinrichtungen, Büros, Musikräumen
* Forschung/Lehre: orientierende Messung für Didaktik und Studien

---

## Scope
Die App dient ausschließlich der **orientierenden Messung**. Sie ersetzt keine abnahmerelevante Messung nach DIN EN ISO 3382.

---

## Features (MVP)
- LiDAR‑Raumscan via RoomPlan
- RT60‑Ermittlung (T20/T30) per Impulsantwortanalyse
- DIN‑18041‑Vergleich mit Ampellogik
- Materialdatenbank (Absorptionskoeffizienten)
- PDF‑Export, CSV/XLSX‑Import/Export, JSON‑Audit‑Trail

---

## Architektur
- **App/**: Einstiegspunkt und Ressourcen
- **Modules/**: Scanner, Acoustics/RT60, DIN18041, Material, Export, AbsorberCalculation, UI
- **Docs/**: Dokumentation
- **Tests/**: Unit- und Integrationstests

---

## Frameworks
- Apple: RoomPlan, RealityKit, SwiftUI, AVFoundation, Accelerate/vDSP, PDFKit, Swift Charts
- Optional: AudioKit, KissFFT
- Daten: SwiftXLSX, CSVEncoder/Decoder

---

## Compliance
- EU AI Act Transparenz: Alle Berechnungen und Annahmen dokumentiert
- Keine Verarbeitung sensibler personenbezogener Daten

