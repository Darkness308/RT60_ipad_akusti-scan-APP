# Fork-Readiness — Definition of Done (DoD) & Scope-Grenzen

Eine **einzige, überprüfbare** Definition von „fork-ready" für AcoustiScan.
Sie ersetzt vage „ready"-Aussagen und trennt klar: **was in der Linux-Web-Umgebung
verifizierbar ist**, **was zwingend auf macOS/an echte Entwickler übergeht**, und
**was „grün" bedeuten muss**.

> Begleitend: [HANDOFF.md](HANDOFF.md) (Projektstand), [CLAUDE.md](CLAUDE.md) (Regeln),
> [ONBOARDING_EXTERNAL.md](ONBOARDING_EXTERNAL.md) (Fork→PR).

---

## 1. Grundprinzipien (der „Vertrag")

1. **Grün = echte Funktion.** Ein grüner Test/Check bedeutet: die zugehörige Funktion
   tut nachweislich, was sie soll. **Keine** Skips-als-grün, leeren Asserts oder
   maskierten Fehler.
2. **Rot ist erlaubt, wenn es die Realität abbildet.** Ein Test, der rot ist, weil
   etwas (noch) nicht funktioniert oder hier nicht baubar ist, bleibt **rot/markiert** —
   er wird **nicht** künstlich grün gemacht.
3. **„Verifiziert" = gebaut/gelaufen.** Code lesen ist Review, nicht Verifikation.
4. **Diese Umgebung (Linux) kann Swift/iOS nicht bauen/testen.** Verifiziert ist
   `swift`/`xcodebuild` **FEHLT**; Plattform = Ubuntu 24.04 (kein macOS). Jede
   Swift-Verifikation gehört auf macOS/CI. Das ist eine **Scope-Grenze, kein Bug.**

---

## 2. Scope-Grenzen — wo etwas verifizierbar ist

| Aufgabe | Hier (Linux) machbar? | Verifizierbar wo |
|---|---|---|
| Markdown / Docs / JSON / Schemas | ✅ ja | hier |
| Statische Code-Analyse, Inventare, Greps | ✅ ja (= Review) | hier |
| Git / GitHub (Labels, Issues, PRs, Branch-Protection-Doku) | ✅ ja | hier / GitHub |
| Reiner Nicht-Swift-Content editieren | ✅ ja | hier |
| **Swift Packages bauen + testen** | ❌ nein | macOS-CI (`ci-honest.yml`) ✓ vorhanden |
| **iOS-App `xcodebuild`** | ❌ nein | macOS-CI ✓ vorhanden |
| **App-Tests (`AcoustiScanAppTests`) ausführen** | ❌ nein **und** nicht in CI | macOS, **nach** Wiring (P2) |
| **App im Simulator/Gerät, RoomPlan/LiDAR** | ❌ nein | macOS + echtes iPad |

---

## 3. Offene Pakete für echte Entwickler (Handoff) — je mit eigener DoD

> Diese Pakete sind **hier nicht abschließend verifizierbar.** Claude bereitet sie
> (Spec, Inventar, statische Vorarbeit, PRs) vor; die **Verifikation** macht macOS/CI/Dev.

- **P1 — macOS/Xcode-Migration (Voraussetzung, ausstehend).**
  *DoD:* Repo baut/testet auf **macOS + Xcode 15.4** mit den drei Befehlen aus
  `CLAUDE.md`; `ci-honest.yml` grün. → **Explizit im Scope** als anstehende Migration.
- **P2 — Test-Integrität & App-Tests in CI.**
  *DoD:* (a) `AcoustiScanAppTests` im Xcode-Projekt **und** in `ci-honest.yml`;
  (b) kein Test, der auf sauberem Checkout nur *skippt*; (c) **Nachweis:** ein
  absichtlich gebrochener Funktionswert macht **genau einen** Test rot.
- **P3 — Funktionslücken.**
  *DoD je Punkt:* RT60-Messpfad (`ImpulseResponseAnalyzer`) **entweder** verdrahtet +
  getestet **oder** klar als „nicht aktiv" markiert; Exporter-Toleranz **asymmetrisch**
  (DIN-Bild-2) statt Platzhalter; doppelte Modelle/Strings konsolidiert **oder**
  bewusst dupliziert + synchron getestet.
- **P4 — Repo-Hygiene.** Git-Labels-Taxonomie; Branch-Protection (#284);
  Wording/Labeling (#285); verwaiste Branches.
- **P5 — Ehrliches Statusdokument.** Dieses DoD + `HANDOFF.md` konsistent halten.

---

## 4. „Fork-ready"-Checkliste (maschinell prüfbar, wo möglich)

Ein Fork ist **„ready für Entwickler"**, wenn:

- [ ] `git clone` + die drei Build-Befehle (`CLAUDE.md`) laufen auf **macOS** grün. *(macOS — P1)*
- [ ] `ci-honest.yml` ist grün auf dem Head-Commit. *(GitHub — prüfbar)*
- [ ] App-Tests sind in CI eingebunden **und** grün. *(macOS — P2)*
- [ ] Kein skip-only/leerer Test (Audit bestanden). *(P2)*
- [ ] `README`/`HANDOFF`/dieses DoD beschreiben den **realen** Stand inkl. Grenzen. *(hier)*
- [ ] Bekannte Lücken (P1/P3) sind als Issues **mit DoD** erfasst. *(hier / GitHub)*
- [ ] Branch-Protection auf `main` aktiv. *(Admin — #284)*

> Punkte mit *(macOS)* sind **hier nicht abhakbar** — das ist die ehrliche Grenze,
> kein offener Mangel an dieser Stelle.

---

## 5. Arbeitsteilung — was Claude hier leistet, was nicht

**Claude (in dieser Linux-Umgebung) leistet:**
Docs/Spec/Inventare, Git-/GitHub-Hygiene, statische Fixes an reinem Nicht-Swift-Content,
PRs vorbereiten — **immer ehrlich als Review markiert**.

**Claude leistet hier NICHT** (und behauptet es nicht):
„verifiziert" für Swift/iOS, Testläufe, App-Verhalten. Das ist **macOS/CI/Entwickler**.

**Bewusst kein** „alles selbst groß autonom erledigen". Lieferform: **überprüfbare
Artefakte + klare Grenzen**, mit denen Maintainer und Entwickler weiterarbeiten.
