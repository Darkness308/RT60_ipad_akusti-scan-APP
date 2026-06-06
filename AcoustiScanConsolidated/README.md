# AcoustiScanConsolidated

Swift-Package mit dem **Rechenkern** für Raumakustik: RT60 (Sabine),
DIN-18041:2016-03-Bewertung (Nutzungsgruppen A1–A5), Datenmodelle und
Report-Rendering (PDF/HTML). Baut und testet plattformunabhängig auf macOS via SwiftPM.

> **Lizenz:** **proprietär** — siehe [`../LICENSE`](../LICENSE). (Nicht MIT.)

## Build & Test (macOS, Xcode 15.4 / Swift 5.9)

```bash
swift build
swift test
```

Das ist exakt, was die **einzige aktive CI** (`.github/workflows/ci-honest.yml`)
ausführt. Es gibt **kein** `build.sh` und keine Auto-Fix-/Retry-Skripte mehr — das
frühere „Green-Washing" (Fehler-Maskierung durch Retry/Auto-Commit) wurde vor dem
Fork entfernt.

## Struktur

```
AcoustiScanConsolidated/
├── Sources/
│   ├── AcoustiScanConsolidated/
│   │   ├── RT60Calculator.swift          # RT60 nach Sabine (0.161·V/A), Frequenzspektrum
│   │   ├── DIN18041/                      # RT60Evaluator, DIN18041Database (normtreu)
│   │   ├── Models/                        # RoomType (A1–A5), DIN18041Target, RT60Measurement, …
│   │   ├── Acoustics/                     # ImpulseResponseAnalyzer (Schroeder/Oktavband)
│   │   ├── ConsolidatedPDFExporter.swift  # PDF-Report
│   │   └── ReportHTMLRenderer.swift       # HTML-Report
│   └── AcoustiScanTool/                   # CLI (AcoustiScanTool)
├── Tests/AcoustiScanConsolidatedTests/    # Unit-Tests — laufen in ci-honest.yml
└── Package.swift
```

## API-Einstieg

Maßgeblich sind **Quellcode und Tests** (keine erfundene API hier):

- **RT60:** `RT60Calculator` — Beispiele/Erwartungswerte in
  `Tests/AcoustiScanConsolidatedTests/AcousticsTests.swift` und
  `AcoustiScanConsolidatedTests.swift`.
- **DIN-Bewertung:** `RT60Evaluator` + `Models/RoomType.swift` (Gruppen A1–A5,
  `T_soll = a·lg(V)+b`, gültige Volumenbereiche, asymmetrisches Toleranzband) —
  normtreue Beispielwerte in `Tests/AcoustiScanConsolidatedTests/DIN18041Tests.swift`.

## Hinweise (harte Regeln)

- **DIN-Logik ist normtreu — so halten.** Keine erfundenen Raumtypen
  (classroom/office/…) und keine symmetrischen Toleranzen wieder einführen.
- `ImpulseResponseAnalyzer` ist der **echte** Messpfad (Impulsantwort →
  Schroeder-Integration). Die iOS-App ruft ihn derzeit **nicht** auf; sie
  *prognostiziert* RT60 via Sabine aus Materialdaten. Vor „Messung"-Wortlaut: HANDOFF §10.1.
- **„verifiziert" = gebaut/gelaufen.** Diese (Linux-)Umgebung hat kein `swift`;
  echte Verifikation nur auf macOS.
