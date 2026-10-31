# Changelog

Alle nennenswerten Änderungen an diesem Projekt. Format nach
[Keep a Changelog](https://keepachangelog.com/de/1.1.0/); Versionierung nach
[SemVer](https://semver.org/lang/de/).

> **Hinweis:** Es existiert noch **kein Release-Tag**. Bis zum ersten getaggten Release
> (`v1.0.0`, Meilenstein **M5** in [ROADMAP.md](ROADMAP.md)) sammelt sich alles unter *Unreleased*.
> Freigabe-Vorbehalt: „Messung" im Produkt erst ab Validierungsstufe S4
> ([Docs/measurement-validation.md](Docs/measurement-validation.md)).

## [Unreleased]

### Added
- Mess-/Belegketten-Validierungsprotokoll (L4/L5) mit DoD, ISO-3382-1-Bezug und GUM-Unsicherheitsbudget (`Docs/measurement-validation.md`).
- Roadmap mit Meilensteinen M0–M5 (`ROADMAP.md`), Reifegrad-Instrument (`Docs/reifegrad.md` + `Tools/maturity/reifegrad.sh`), ADR-Verzeichnis (`Docs/adr/`), dieses Changelog.
- Maschinenlesbarer Governance-Index/SSOT (`governance.json`) + Drift-Validator (`Tools/maturity/index_check.py`): Doku-Landkarte, Autoritätsregel, Ebenen-Reifegrad, Meilensteine, offene Engpässe — single-sourced.
- RT60-Messsystem mit USB-Mikrofon + FFT-Analyse (`AudioManager`), ISO-3382-1-Bezug, AbsorberCalculator inkl. 8000-Hz-Band (#299).
- Echter PDF-Report über den normtreuen `ConsolidatedPDFExporter` (#296); DIN-18041-Bewertung in der App verdrahtet (RoomType A1–A5, asymmetrisches Bild-2-Band) (#295).
- Audio-Messpfad: getestetes `ImpulseCaptureProcessing` + `AudioImpulseRecorder` + Mess-UI (#289/#290).
- App-Unit-Tests in der CI sichtbar (`AcoustiScanAppTests` via `xcodebuild test`, iPad-Simulator) (#291).

### Changed
- Docs auf den ehrlich überprüfbaren Stand gebracht (HANDOFF, FORK_READINESS); Status „Juni 2026" → Oktober 2026.
- CI: iOS-Job von `build` auf `clean test` (iPad-Destination) umgestellt (#291).

### Fixed
- Fehlendes `CFBundleExecutable`/`CFBundlePackageType` → App war nicht installierbar (von der CI-Test-Loop aufgedeckt) (#291).
- Lokalisierung (`Localizable.strings` de/en) war nie ins App-Bundle eingebunden → rohe Keys zur Laufzeit (#291).

### Removed
- Toter, duplizierter App-PDF-Renderer-Cluster inkl. symmetrischer Toleranz-Platzhalter (#292).
- Verwaiste `Tools/LogParser/RT60LogParserTests.swift` (lief in keiner Pipeline).

### Baseline (vor diesem Zyklus, gemergt)
`#248` ehrliche CI + App-Fix · `#259` Concurrency-Fix · `#263` ContentView→TabView ·
`#264` DIN normtreu · `#265` Tech-Debt-Doku · `#266`/`#267` Faktenkorrekturen · `#268` App-Test-Fix ·
`#269` HANDOFF · `#283/#287` Fork-Cleanup + DoD · `#297` ehrliche Docs · `#298` PDF-Export-Binding.

[Unreleased]: https://github.com/Darkness308/RT60_ipad_akusti-scan-APP/commits/main
