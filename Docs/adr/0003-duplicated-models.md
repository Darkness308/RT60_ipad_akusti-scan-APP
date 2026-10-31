# ADR-0003 — Doppelte Datenmodelle App ↔ Paket (bewusste, dokumentierte Schuld)

**Status:** Akzeptiert als technische Schuld (Konsolidierung geplant)
**Datum:** 2026

## Kontext

Die App führt eigene Typen (`AcousticMaterial`, `SurfaceStore`, teils eigene Exporter) **parallel**
zu den Paket-Typen in `AcoustiScanConsolidated`/`Modules/Export`. Beim Verdrahten des PDF-Reports
musste der Paket-Typ qualifiziert werden (`AcoustiScanConsolidated.AcousticMaterial`), um den
Namenskonflikt mit dem App-Modell zu umgehen.

## Entscheidung

Die Dopplung wird **vorerst akzeptiert** (beide Seiten in sich konsistent), statt sie unter Zeitdruck
zu verschmelzen. Eine Konsolidierung ist ein eigener, CI-verifizierter Refactor.

## Konsequenzen

- ➕ Kurzfristig stabil; kein riskanter Big-Bang-Refactor.
- ➖ Zwei Wahrheiten für Material/Flächen → Drift-Risiko, doppelte Strings/Lokalisierung.
- 🎯 **Trigger zur Auflösung:** sobald ein Feature beide Seiten ändern müsste, oder vor M5 (Release).
  Konsolidierung bevorzugt **Richtung Paket** (die getestete Seite).
