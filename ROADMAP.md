# Roadmap — AcoustiScan

> **Zweck:** Ein einziger, ehrlicher Fahrplan vom heutigen Stand zum auslieferbaren Produkt.
> Meilensteine sind an die **Ebenen (L1–L7)** und die **Definition of Done** gekoppelt
> ([FORK_READINESS.md](FORK_READINESS.md), [Docs/measurement-validation.md](Docs/measurement-validation.md)).
> „Grün = echte Funktion" — rote/offene Punkte bleiben sichtbar rot.
>
> Stand: **2026-10-31**. Begleitend: [HANDOFF.md](HANDOFF.md) · [CHANGELOG.md](CHANGELOG.md) ·
> [Docs/reifegrad.md](Docs/reifegrad.md) · ADRs: [Docs/adr/](Docs/adr/).

---

## Vision

iPadOS-App, die Raumakustik **misst** (RT60 via Impulsantwort/ISO 3382-1), nach **DIN 18041:2016-03**
bewertet und einen **belegbaren** PDF-Bericht erzeugt — mit nachvollziehbarer Mess- und Belegkette.

## Nicht-Ziele (bewusst)

- Kein Lern-/Trainingstool, kein Android, kein Web-Client.
- Keine Retry-/Auto-Fix-/Self-Healing-Automation (siehe [ADR-0001](Docs/adr/0001-honest-ci.md)).
- Keine „grün-gewaschene" CI; kein Wort *„Messung"* im Report oberhalb der real erreichten Stufe.

---

## Meilensteine

| MS | Ziel | Ebenen | Status | Verifizierbar wo |
|---|---|---|---|---|
| **M0** | Ehrliche Baseline (CI ohne Maskierung, Rechenkern getestet) | L1–L2, L6(CI) | ✅ erreicht | CI |
| **M1** | Rechnerisch fork-ready (App baut+testet in CI, DIN+PDF+Messpfad verdrahtet) | L1–L3 | ✅ erreicht | CI |
| **M2** | **Durchsetzung** (Branch-Protection, Lint-/Coverage-Gate) | L6 | 🟡 teilweise (Gates verdrahtet; Branch-Protection offen) | GitHub + CI |
| **M3** | **Geräte-Validierung** (S3/S4: iPad, Mikro, LiDAR-Volumen, E2E am Gerät) | L4 | 🔴 offen | iPad |
| **M4** | **Metrologie/Feld** (S5: kalibriertes Messmikro, Referenz, Unsicherheitsbudget) | L5 | 🔴 offen | Labor/Ringversuch |
| **M5** | **Release** (Archive/Signing, App-Store-Build, Tag `v1.0.0`) | L3, L6 | 🔴 offen | macOS + App Store Connect |

### Entry/Exit-Kriterien

- **M0 ✅** — `ci-honest.yml` einzige Pipeline, `swift test` grün für beide Pakete. *(erreicht)*
- **M1 ✅** — `xcodebuild test` (App-Tests) grün; RT60→DIN→PDF + Messpfad (`AudioManager`/`RT60MeasurementView`) im Code. *(erreicht; Geräte-Lauf = M3)*
- **M2** — *Entry:* M1. *Status:* Index-Gate (`Governance index (SSOT)`, Linux) **blockierend + grün**; `SwiftLint` (Linux) **report-only** (`--lenient`, Baseline 204 Verstöße/4 serious) — Ratchet auf blockierend nach Bereinigung; Coverage **report-only** (läuft bei zurückgekehrten macOS-Runnern). *Exit:* `main` protected mit allen vier Checks als *required* (Owner, [HANDOFF §11](HANDOFF.md)); Lint- + Coverage-Gate scharfgeschaltet nach Schuld-Bereinigung.
- **M3** — *Entry:* M1. *Exit:* L4-Checkliste in [measurement-validation.md §6](Docs/measurement-validation.md) abgehakt (iPad).
- **M4** — *Entry:* M3. *Exit:* L5-Checkliste abgehakt; Unsicherheitsbudget dokumentiert.
- **M5** — *Entry:* M2+M3 (Minimum). *Exit:* Release-Build signiert/archiviert, Version getaggt, Store-Einreichung.

---

## Reihenfolge-Logik (EKS/Engpass)

Der **nächste Hebel** ist **M2 (Durchsetzung)** — ohne sie sind alle grünen Checks beratend, nicht
blockierend; erst sie macht M1 belastbar. **M3/M4** sind hardware-gebunden und können parallel von
echten Entwicklern mit Gerät/Labor laufen. **M5** erst, wenn M2 greift und M3 am Gerät trägt.

> Dieses Dokument wird bei jedem abgeschlossenen Meilenstein aktualisiert. Weicht es vom Code/CI ab,
> **gilt Code/CI** — dann diese Datei nachziehen (gleiche Regel wie HANDOFF).
