# Reifegrad — Messinstrument statt Behauptung

> **Zweck:** Qualität **und** Quantität messbar machen. Die *zählbaren* Kennzahlen liefert das Skript
> [`Tools/maturity/reifegrad.sh`](../Tools/maturity/reifegrad.sh) (auf Linux/CI ausführbar, ohne
> Swift). Die *Reifegrad-Stufe* (0–5) je Ebene ist **menschliches Urteil** und muss durch die
> Kennzahlen + Nachweise belegt sein — sie wird hier nicht als „gemessen" ausgegeben.

Skala (CMMI-artig): **0** nicht vorhanden · **1** ad hoc · **2** wiederholbar · **3** definiert ·
**4** gemessen/beherrscht · **5** optimierend.

## Ebenen-Scorecard (Stand 2026-10-31)

| Ebene | Reife | Belegt durch (Kennzahl/Nachweis) | Fehlt für die nächste Stufe |
|---|---|---|---|
| **L1 Rechenkern** | 4 | ~89 Tests, `swift test` grün in CI | Coverage-Messung + Schwelle |
| **L2 Report/Export** | 4 | 14 Tests, `swift test` grün | Schema-Contract-Test (report.schema.json) als Gate |
| **L3 App-Logik** | 3 | 177 App-Tests via `xcodebuild test` grün | Dedup (ADR-0003), UI-Tests verifizieren, Coverage |
| **L4 Geräte-Laufzeit** | 1 | nur compile-checked (Simulator) | L4-DoD am iPad abhaken (measurement-validation §6) |
| **L5 Metrologie** | 0–1 | nur Checkliste, keine Referenzmessung | kalibriertes Messmikro, Referenz, Unsicherheitsbudget |
| **L6 Enforcement** | 2 | ehrliche CI läuft (1 Workflow) | Branch-Protection + Lint-/Coverage-Gate (M2) |
| **L7 Steuerung** | 2–3 | DoD, Roadmap, ADRs, Changelog, dieses Instrument | regelmäßige Pflege + Gate-Kopplung |

> Diese Stufen sind **Einschätzungen**, keine Messwerte. Belegpflicht: wer eine Stufe anhebt, nennt
> die Kennzahl/den Nachweis in der Tabelle.

## Fortschritts-Metriken (vom Skript gezählt)

Das Skript gibt objektiv aus: Testanzahl je Ebene + gesamt, verwaiste Tests, Skips, Anzahl Workflows,
ob ein **Lint-Gate** und ein **Coverage-Gate** in der CI vorhanden sind, Anzahl ADRs. So lässt sich
Quantität (Testmenge) **und** ein Teil der Qualität (laufen Gates?) über die Zeit verfolgen.

```bash
bash Tools/maturity/reifegrad.sh
```

## Was dieses Instrument NICHT kann (ehrlich)

- Es misst **nicht**, ob Tests *gut* sind (nur wie viele). Qualität der Asserts bleibt Review.
- Es kann Branch-Protection **nicht** prüfen (kein API-Zugriff) → im GitHub-UI verifizieren.
- Es ersetzt **nicht** die Geräte-/Metrologie-Validierung (L4/L5) — die ist hardware-gebunden.

> **Kopplung an die Durchsetzung:** Das Instrument entfaltet erst mit **M2** (Lint-/Coverage-Gate,
> Branch-Protection) volle Wirkung — sonst bleibt es Beobachtung ohne Hebel.
