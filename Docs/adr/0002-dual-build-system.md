# ADR-0002 — Dual-Build: `.xcodeproj` maßgeblich, SPM-Pakete für den Kern

**Status:** Akzeptiert
**Datum:** 2026

## Kontext

Es existieren zwei Build-Wege: die SwiftPM-Pakete (`AcoustiScanConsolidated`, `Modules/Export`) und
die iOS-App. Zusätzlich liegt ein `AcoustiScanApp/Package.swift` **parallel** zum
`AcoustiScanApp.xcodeproj`. Zwei App-Build-Definitionen können auseinanderlaufen.

## Entscheidung

- Der **`AcoustiScanApp.xcodeproj` ist maßgeblich** für die App; die CI baut/testet die App
  ausschließlich darüber (`xcodebuild`).
- Der **Rechenkern** bleibt in SwiftPM-Paketen (plattformunabhängig, schnell via `swift test`).
- Das parallele `AcoustiScanApp/Package.swift` wird von der CI **nicht** gebaut; nicht darauf verlassen.

## Konsequenzen

- ➕ Klare Autorität; CI testet exakt, was ausgeliefert wird.
- ➕ Kern-Logik bleibt plattformunabhängig testbar.
- ➖ `AcoustiScanApp/Package.swift` kann stillschweigend driften → Kandidat zum **Entfernen** oder
  bewusst als Nur-IDE-Hilfe markieren (offene Aufgabe).
