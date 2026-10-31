# ADR-0004 — DIN 18041 normtreu: asymmetrisches Bild-2-Band, keine erfundenen Raumtypen

**Status:** Akzeptiert (umgesetzt in PR #264; Exporter-Verdrahtung #296)
**Datum:** 2026

## Kontext

Eine frühere Fassung erfand eigene Raumtypen (classroom/office/…) und nutzte eine **symmetrische**
Toleranz `|T − T_soll| ≤ tol`. DIN 18041:2016-03 kennt die Nutzungsgruppen **A1–A5** mit
`T_soll = a·lg(V) + b` und ein **asymmetrisches** Toleranzband (Bild 2), das an den Rändern (125 Hz,
4000 Hz) unterschiedlich aufweitet.

## Entscheidung

Nur die normativen Gruppen **A1–A5** und das **asymmetrische Bild-2-Band** (in `Models/RoomType.swift`
+ `DIN18041/`). Erfundene Raumtypen und symmetrische Toleranzen sind entfernt und dürfen nicht
zurückkehren. Der tote App-Exporter mit symmetrischer Toleranz wurde gelöscht (#292).

## Konsequenzen

- ➕ Bewertung entspricht der Norm (zu tief ≠ zu hoch).
- ➕ Durch Tests gedeckt (`DIN18041Tests`, `RT60EvaluatorTests`).
- ⚠️ **Offen/zu prüfen gegen die gedruckte Norm** (HANDOFF §10.5): exakte Bild-2-Koordinaten,
  A1-Obergrenze (1000 vs. 5000 m³), A4 `b = −0,14`. Nicht raten — gegen DIN 18041:2016-03 Bild 2 verifizieren.
