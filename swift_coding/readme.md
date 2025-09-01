# AcoustiScan – iPad Raumakustik‑App (MVP)

Dieses Repository enthält den Quellcode für **AcoustiScan**, einen
experimentellen Prototyp zur orientierenden Messung der Raumakustik
auf dem iPad.  Die App nutzt LiDAR‑Scans, Audiosignalanalyse und
Normenvergleiche, um die Nachhallzeit (RT60) zu bestimmen und mit
den Zielwerten der DIN 18041 zu vergleichen.  Die Ergebnisse können
anschließend in einem PDF‑Bericht exportiert werden.

---

## Zielgruppe
* Planer, Architekten, Akustiker
* Anwender in Bildungseinrichtungen, Büros, Musikräumen
* Forschung/Lehre: orientierende Messung für Didaktik und Studien

---

## Scope
Die App dient ausschließlich der **orientierenden Messung**. Sie ersetzt keine abnahmerelevante Messung nach DIN EN ISO 3382.

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

