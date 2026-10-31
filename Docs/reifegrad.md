# Reifegrad — Messinstrument statt Behauptung

> **Zweck:** Qualität **und** Quantität messbar machen. Die *zählbaren* Kennzahlen liefert das Skript
> [`Tools/maturity/reifegrad.sh`](../Tools/maturity/reifegrad.sh) (auf Linux/CI ausführbar, ohne
> Swift). Die *Reifegrad-Stufe* (0–5) je Ebene ist **menschliches Urteil** und muss durch die
> Kennzahlen + Nachweise belegt sein — sie wird hier nicht als „gemessen" ausgegeben.

Skala (CMMI-artig): **0** nicht vorhanden · **1** ad hoc · **2** wiederholbar · **3** definiert ·
**4** gemessen/beherrscht · **5** optimierend.

## Ebenen-Scorecard (Stand 2026-10-31)

Die Ebenen-Daten (Reife 0–5, Evidenz, Verifizierbarkeit) stehen **maschinenlesbar und single-sourced**
in [`../governance.json`](../governance.json) → `layers` (dazu `milestones` und `bottlenecks`); hier
**nicht** dupliziert (SSOT-Disziplin). Konsistenz-Check: `python3 Tools/maturity/index_check.py`.

> Diese Stufen sind **Einschätzungen**, keine Messwerte; die *gemessenen* KPIs liefert `reifegrad.sh`.
> Belegpflicht: wer eine Stufe in `governance.json` anhebt, nennt dort die Kennzahl/den Nachweis.

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
