# ADR-0005 — Messmethode: Impulsantwort (ISO 3382-1); Sabine = Prognose/Verifikation

**Status:** Akzeptiert (Messpfad verdrahtet in #289/#290 und #299)
**Datum:** 2026

## Kontext

Ursprünglich *prognostizierte* die App RT60 nur über die Sabine-Formel (`0,161·V/A`) aus
Materialkoeffizienten; die echte DSP-Engine (`ImpulseResponseAnalyzer`, Schroeder-Integration) wurde
von der UI nie aufgerufen, obwohl das PDF „Messung" druckte (historischer Befund HANDOFF §10.1).

## Entscheidung

- **Messung** = Impulsantwort-Methode nach ISO 3382-1: Anregung (Klatsch/Ballon bzw. USB-Audio),
  Onset/Pre-Roll, Oktavband-Schroeder-RT60 (`ImpulseCaptureProcessing` → `ImpulseResponseAnalyzer`).
  Der Messpfad ist in der App verdrahtet (`AudioManager`, `RT60MeasurementView`).
- **Sabine** bleibt als **Prognose** und als **Verifikation** der Messung (`compare(measured:predicted:)`),
  nicht als „Messung" etikettiert.
- Report-Wortlaut wird an die erreichte **Verifikationsstufe** gekoppelt (S3/S4/S5, siehe
  [measurement-validation.md §2](../measurement-validation.md)).

## Konsequenzen

- ➕ Ehrliche Trennung Messung vs. Prognose; Sabine dient als Plausibilitätsanker.
- ➖ Echte **Mess-Gültigkeit** ist hardware-/kalibrierungsgebunden → L4/L5, nicht in CI (ADR-übergreifend
  dokumentiert in `Docs/measurement-validation.md`).
- 🔒 Regel: Kein uneingeschränktes „Messung nach ISO 3382-1" im Report unterhalb Stufe S4.
