# Übergabe / Handoff — Projektstand & Weiterführung auf macOS

> **Zweck:** Diese Datei ist der **Startpunkt für jede neue Person und jede Claude-/Copilot-Instanz**,
> die das Projekt auf macOS übernimmt. Sie beschreibt den *ehrlich überprüfbaren* Stand —
> nicht ein Wunschbild. Wenn etwas hier im Widerspruch zu vollmundigen Aussagen anderswo steht,
> gilt **diese Datei + der tatsächliche Code/CI-Lauf**.

---

## Stand Juni 2026 — Update (gilt bei Konflikt vor den älteren Abschnitten unten)

Seit 2026-05-30 wurden die meisten unten als „offen" markierten Engpässe **geschlossen**
(alle via `ci-honest.yml` grün gemergt):

- ✅ **App-Tests laufen jetzt in der CI.** Unit-Test-Target `AcoustiScanAppTests` ist im
  Xcode-Projekt; `ci-honest.yml` führt für die App `xcodebuild test` aus (iPad-Simulator).
  → §2 / §4 / §5 / §10.2 sind **erledigt**.
- ✅ **Reale App-Bugs gefixt** (erst durch die Test-/Run-Loop sichtbar): fehlendes
  `CFBundleExecutable` (App war **nicht installierbar**), Lokalisierung jetzt im Target
  gebündelt (§10.4).
- ✅ **DIN-18041-Bewertung in der App verdrahtet:** RoomType-Auswahl A1–A5 → norm-treue
  **asymmetrische** Bewertung → Anzeige. (§10.1 a erledigt; Wortlaut ehrlich „Sabine/Prognose".)
- ✅ **Mess-Pfad vorbereitet** (§10.1 b): `AudioImpulseRecorder` (AVAudioEngine) + getestetes
  `ImpulseCaptureProcessing` + Mess-UI; **Geräte-Lauf** steht noch aus.
- ✅ **Toter, duplizierter App-PDF-Renderer-Cluster entfernt** (enthielt die symmetrische
  Toleranz) → §2 / §10.5 gegenstandslos.
- ✅ **Echter PDF-Report** über den norm-treuen `ConsolidatedPDFExporter` (PR #296):
  asymmetrisches DIN-Band + ehrlicher Sabine-Hinweis; ersetzt den Platzhalter.

**Noch offen:** Geräte-Laufzeit (LiDAR/Mikrofon, §10.6) · Dedup doppelter Modelle/Strings (§4) ·
Lint-/Coverage-Gates (§10.3/§10.4) · **Branch-Protection als Durchsetzung** (§11, nur Owner/Admin).

---

## TL;DR

- **Rechenkern** (`AcoustiScanConsolidated`, `Modules/Export`): solide, getestet, baut via `swift test`. **Übernahmefähig.**
- **DIN 18041**: normtreu nach DIN 18041:2016-03 (Gruppen A1–A5, `T_soll = a·lg(V)+b`, Bild-2-Toleranzband), mit Tests.
- **iOS-App** (`AcoustiScanApp`): kompiliert **und App-Tests laufen jetzt in der CI** (`xcodebuild test`, iPad-Simulator); **Geräte-Laufzeit** (LiDAR/Mikrofon/ARKit) bleibt nicht automatisiert (siehe „Stand Juni 2026" oben / §2).
- **CI**: `ci-honest.yml` ist die **einzige** Pipeline (ehrlich, ohne Maskierung). Die früheren maskierenden Workflows wurden vor dem Fork **gelöscht**.
- **Erledigt** (war der wichtigste Schritt): App-Tests in einer echten CI-Loop (siehe „Stand Juni 2026" oben). **Jetzt offen:** Geräte-Lauf, Dedup, Branch-Protection-Durchsetzung (§11).

---

## 1. Was funktioniert / verifiziert ist

| Bereich | Status | Wodurch belegt |
|---|---|---|
| `AcoustiScanConsolidated` | ✅ baut + Tests grün | `swift build && swift test` in `ci-honest.yml` |
| `Modules/Export` (ReportExport) | ✅ baut + Tests grün | `swift build && swift test` in `ci-honest.yml` |
| DIN 18041 Engine (A1–A5) | ✅ implementiert + getestet | `DIN18041Tests.swift`, `AcoustiScanConsolidatedTests.swift` |
| iOS-App **Build + App-Tests** | ✅ kompiliert + Tests grün | `xcodebuild test` (iPad-Simulator) in `ci-honest.yml` |
| App `ContentView` | ✅ echte `TabView` (RT60/Scan/Maße/Material/Export) | Code + CI-Build |

---

## 2. Was (noch) NICHT verifiziert ist — ehrlich

- **Geräte-Laufzeit** (LiDAR/RoomPlan, Mikrofon, ARKit) ist **nicht automatisiert** getestet — nur auf echtem iPad sinnvoll. Das ist der verbleibende Hauptpunkt.
- **App-PDF am Gerät:** Der PDF-Report wird erzeugt (`ConsolidatedPDFExporter`, normtreues asymmetrisches DIN-Band) und im CI-Build kompiliert, aber der **tatsächliche Share-/Layout-Lauf am Gerät** ist nicht auto-getestet.
- **Release-/Archive-Build, Lint-Gate, Code-Coverage** laufen (noch) nicht in der CI (siehe §10.3/§10.4).

> **Erledigt seit 2026-05-30** (siehe „Stand Juni 2026"-Block oben): App-Tests laufen jetzt in der CI
> (`xcodebuild test`); der frühere **tote** PDF-Platzhalter samt symmetrischer Toleranz wurde **entfernt**;
> DIN-Bewertung + echter PDF-Report sind verdrahtet.
>
> **Konsequenz:** „bugfrei" bleibt nur so weit belegbar, wie CI + Tests reichen — die **Geräte-Laufzeit** ist der offene Rest.

---

## 3. Echte Verifikation auf macOS (Befehle)

```bash
# 1) Packages (laufen sicher auf jedem Mac mit Xcode/Swift)
(cd AcoustiScanConsolidated && swift build && swift test)
(cd Modules/Export         && swift build && swift test)

# 2) iOS-App bauen (Simulator-SDK, ohne Signing)
xcodebuild build \
  -project AcoustiScanApp/AcoustiScanApp.xcodeproj \
  -scheme AcoustiScanApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO

# 3) App-Tests — ERST möglich, nachdem das Test-Target im Xcode-Projekt existiert (siehe §5).
#    Danach z. B. (konkreten Simulator via `xcrun simctl list devices` wählen):
# xcodebuild test \
#   -project AcoustiScanApp/AcoustiScanApp.xcodeproj \
#   -scheme AcoustiScanApp \
#   -destination 'platform=iOS Simulator,name=iPad Pro (11-inch) (4th generation)' \
#   CODE_SIGNING_ALLOWED=NO
```

---

## 4. Bekannte technische Schulden (Risiken, bewusst zurückgestellt)

1. **Doppelte Datenmodelle App ↔ Package**: Die App führt eigene `AcousticMaterial`, `SurfaceStore`,
   PDF/XLSX-Exporter parallel zum Package. Beide in sich konsistent; Konsolidierung = großer Refactor.
2. **Dual-Build-System**: Die CI baut die App über das **`.xcodeproj`** (maßgeblich). Das parallele
   `AcoustiScanApp/Package.swift` wird von der CI **nicht** gebaut.
3. **App-Tests nicht im CI-Gate** (siehe §2) — größte Verifikationslücke.

---

## 5. Empfohlene nächste Schritte (Priorität)

1. ✅ **Erledigt:** App-Verifikation in der CI (Unit-Test-Target `AcoustiScanAppTests` + `xcodebuild test`)
   sowie PDF-Export mit normtreuen DIN-Bändern. War der höchste Hebel — siehe „Stand Juni 2026"-Block oben.
2. **Jetzt offen** (je ein eigenes, CI-verifiziertes Vorhaben):
   - Modelle/Strings App↔Package **konsolidieren** (Dedup), **oder**
   - **i18n**: neue App-Views (DIN/Messung/Export) auf `LocalizationKeys` umstellen, **oder**
   - **Geräte-Lauf** (Mikrofon-Capture, LiDAR) auf echtem iPad verifizieren.
3. **Branch-Hygiene** (§9) · **Branch-Protection** als Durchsetzung (§11).

---

## 6. Arbeitsteilung — Mensch / Claude / Copilot

- **Claude Code auf dem Mac**: echtes Build/Test/Debug (hat dort `swift` + `xcodebuild`).
- **Copilot**: IDE-Assistent + Coding-Agent lokal; **PR-Reviewer** auf GitHub (kalter Diff-Blick — hat reale
  Doku-Inkonsistenzen gefunden, die der Autor übersah). Empfehlenswert als zweite Instanz.
- **Regel**: Das Wort **„verifiziert" nur verwenden, wenn wirklich gebaut/gelaufen** — nicht für „sieht gut aus".

---

## 7. CI & Workflows

- **Aktiv**: `ci-honest.yml` — baut & testet `AcoustiScanConsolidated` und `Modules/Export` (`swift test`)
  und baut die App via `xcodebuild`; bei Fehlern wird der echte Build-/Test-Tail an den PR gepostet.
  Xcode ist bewusst auf **15.4 gepinnt** (Reproduzierbarkeit).
- **Gelöscht** (vor dem Fork): die früheren maskierenden Workflows `build-test.yml`, `swift.yml`,
  `self-healing.yml`, `auto-retry.yml`, `autofix-agent.yml` sowie `AcoustiScanConsolidated/build.sh`
  (Auto-Fix/Retry-Wrapper) und `.github/heal-attempts.json`. Sie maskierten früher Fehler.
  Retry-/Auto-Fix-/Self-Healing-Automation **nicht** wieder einführen (CLAUDE.md-Regel 6:
  Agenten/Automation nur mit Durchsetzung + Tests).

---

## 8. Sanierungs-Historie (gemergte PRs)

Gemergt: `#248` ehrliche CI + App-Fix · `#259` Concurrency-Fix · `#263` ContentView→TabView ·
`#264` DIN normtreu · `#265` Cleanup/Tech-Debt-Doku · `#266` README-Faktenfehler ·
`#267` CONTRIBUTING-Korrekturen · `#268` kaputter App-Test gefixt.
`#269` = dieses HANDOFF-Dokument.

---

## 9. Branch-Hygiene

Es existieren ~40 Alt-Branches aus der früheren Bot-Ära (`copilot/remove-*-characters`, `copilot/fix-<nr/uuid>`
sowie diverse bereits gemergte). Sie sollten gelöscht werden. Die Sandbox durfte das nicht (Git-Proxy: 403);
auf dem Mac mit Schreibrechten:

```bash
# Beispiel — alle bereits in main gemergten + offensichtlichen Bot-Müll-Branches löschen.
# Liste vorher prüfen mit:  git branch -r --merged origin/main
git push origin --delete <branchname> [<branchname> ...]
```
Behalten: `main`, aktive Feature-Branches, `claude/*`-Branches mit evtl. nützlicher Arbeit
(z. B. `consolidate-duplicate-renderers`) und beschreibende WIP-Branches (`fix-pdf-export-issues` etc.).

## 10. Verifizierungs-Engpässe & blinde Flecken (Audit 2026-05-30 — historisch; viele Punkte erledigt, siehe „Stand Juni 2026" oben)

Ergebnis einer systematischen EKS-Engpassanalyse (CI/Test-Coverage + Fake-Funktions-Jagd).
Reihenfolge bewusst nach **Risiko × Schließbarkeit**. Mac-gebundene Punkte sind markiert
(🖥 = braucht swift/xcodebuild; in der Linux-Sandbox nicht verifizierbar).

### 10.1 ⚠️ CRITICAL — Befund, der eine Produktentscheidung erfordert
**Die App *misst* RT60 nicht, sie *prognostiziert* es.** `RT60View` → `SurfaceStore.calculateRT60`
ist reine Sabine-Formel (`0.161·V/A`) aus den vom Nutzer zugewiesenen Material­koeffizienten.
Es gibt **keinen** Mikrofon-/Audio-Capture-Pfad im App-Code (`AVAudioEngine`/`installTap` etc.
kommen nicht vor). Die echte, korrekte Audio-Engine `ImpulseResponseAnalyzer` (Schroeder-
Integration, Oktavband-Filter) wird von der App **nie aufgerufen**. Gleichzeitig druckt das
PDF-Boilerplate „Diese **Messung** wurde nach DIN 18041 durchgeführt".
→ Entscheidung nötig: entweder (a) Wortlaut/Doku ehrlich auf „Prognose nach Sabine" umstellen,
oder (b) echten Messpfad (`ImpulseResponseAnalyzer`) an die UI anbinden. **Nicht** stillschweigend lassen.

### 10.2 ✅ ERLEDIGT (war: App-Tests laufen in KEINER CI)
**Seit Juni 2026 behoben:** Das Unit-Test-Target `AcoustiScanAppTests` ist im Xcode-Projekt, und
`ci-honest.yml` führt `xcodebuild test` (iPad-Simulator) aus. Die App-Tests (`MaterialManagerXLSXTests`,
`SurfaceStore`-RT60, `MaterialManager`, …) laufen jetzt real in CI — die App besteht CI nicht mehr
allein durchs Kompilieren.

### 10.3 🟠 Schnelle, risikoarme Gates (fehlen in der CI)
- **Lint/Format nicht erzwungen:** `.swiftlint.yml` + `.swiftformat` existieren, werden aber
  von `ci-honest.yml` **nicht** ausgeführt (Enforcement lag nur im inzwischen gelöschten `build-test.yml`).
  → 🖥 `swiftlint --strict` + `swiftformat --lint` als CI-Schritt. (Vorher lokal laufen lassen —
  kann anfangs viele Funde liefern.)
- **JSON-Schemas ungenutzt:** `Schemas/report.schema.json` + `audit.schema.json` werden nirgends
  zur Validierung herangezogen. → Report-Modell gegen Schema prüfen (Contract-Test).

### 10.4 🟡 Methodik-Lücken
- Nur **Debug**, ein SDK, **kein `archive`/Release-Build** → Optimizer-/Packaging-/Signing-Fehler
  werden nie gefangen.
- **Keine Code-Coverage-Messung** (kein `-enableCodeCoverage`, kein Threshold-Gate).
- **Lokalisierung:** `.strings`/`.lproj` sind **nicht in der `.pbxproj`** → die App könnte rohe
  Keys rendern; bestehende Tests fangen das wegen des NSLocalizedString-Fallbacks **nicht**.
  → Key↔`.strings`-Vollständigkeitscheck + Dateien ins Projekt aufnehmen.

### 10.5 🟡 Weitere bestätigte Code-Funde (eigene kleine PRs)
- **App-PDF-Exporter nutzt symmetrische Toleranz** (`PDFTableRenderer`/`PDFPageRenderer`,
  `abs(measured−target) ≤ tol`) statt des asymmetrischen Bild-2-Bands. Derzeit **unerreichbar**
  (ExportView ist Platzhalter), würde aber falsch bewerten, sobald verdrahtet. (Auch in §2/§4.)
- **Paket-`AcousticMaterial` erfindet α = 0.1** für fehlende Koeffizienten
  (`Models/AcousticMaterial.swift`, `?? 0.1`) → ändert RT60 still; besser fehlende Daten kennzeichnen.
- ⚠️ **DIN-Bild-2-Toleranz bei 4000 Hz**: Recherche legt nahe, dass die Aufweitung **asymmetrisch**
  ist (125 Hz weitet oben, 4000 Hz lockert v. a. unten) — unsere Implementierung nutzt an **beiden**
  Rändern `(0.65, 1.45)`. Exakte Figur-Koordinaten waren **nicht** verbatim belegbar.
  → 🖥 Gegen die **gedruckte** DIN 18041:2016-03 (Bild 2) prüfen, **nicht** raten. Ebenso offen:
  A1-Obergrenze (1000 vs. 5000 m³) und A4 `b = −0.14` (nur indirekt belegt).

### 10.6 ⚪ Bewusst NICHT automatisiert (gerätegebunden — als untested dokumentieren)
LiDAR/RoomPlan/ARKit-Scan, Live-Audio-Capture, PDF-Visual-Layout, Persistenz auf echtem Gerät.
RoomPlan schätzt zudem Deckenfläche = Bodenfläche und Wandhöhe 2.5 m (Default); der LiDAR-Raycast-
Fallback liefert 2.0 m² — vernünftige, **dokumentierte** Schätzungen, die aber in die RT60-Geometrie
einfließen.

### 10.7 Bereinigte Green-Washing-Tests
`XCTAssertEqual(h,h)` (PDF-Snapshot), zwei `XCTAssertTrue(true)`-No-ops → durch echte Assertions
ersetzt. Die immer-skippenden `TimeoutConfigurationTests` (Datei-Existenz-Skip → 0 Assertions in CI)
wurden vor dem Fork **gelöscht**.

## 11. Governance / Systemdurchsetzung (vor dem Fork einzurichten)

Die ehrliche CI **läuft** automatisch (push/PR), aber „laufen" ≠ „erzwungen". Drei Dinge
entscheiden, ob roter/ungeprüfter Code blockiert wird — zwei davon kann **nur der Repo-Owner**
im GitHub-UI setzen (nicht im Code, nicht von einer Sandbox):

1. **Branch-Protection auf `main`** (Settings → Branches → Add rule):
   - ☑ Require a pull request before merging
   - ☑ Require status checks to pass → **`Swift packages (build + test)`** und **`iOS app (xcodebuild)`** als *required* markieren
   - ☑ Require review from Code Owners
   - ☑ Require branches up to date before merging
   Ohne dies kann (auch der externe Dev) **rot mergen** oder direkt auf `main` pushen.
   - Optional „as code“ (einmalig durch Admin ausführen): `Tools/setup-branch-protection.sh --repo Darkness308/RT60_ipad_akusti-scan-APP --apply`
2. **Actions-Berechtigungen für Forks** (Settings → Actions → General): Workflow-Permissions auf
   *read-only* + „Require approval for all outside collaborators" (Security-Review-Gate, vgl. LICENSE und ONBOARDING_EXTERNAL.md).
3. **CODEOWNERS** ist jetzt real (`@Darkness308` statt nicht-existenter `@your-org/*`-Teams);
   greift aber erst mit „Require review from Code Owners" aus Punkt 1. Sobald echte Teams
   existieren, dort eintragen.

> Status dieser drei Punkte ist **von der Sandbox aus nicht prüfbar** (kein Branch-Protection-API-Zugriff).
> Bitte im UI verifizieren — das ist die eigentliche Durchsetzung hinter der „ehrlichen CI".

---

*Letzte Aktualisierung dieses Dokuments: 2026-06-06 (Stand-Update Juni 2026 + Konsistenzabgleich der älteren
Abschnitte). Bei Abweichungen zwischen diesem Dokument und dem Code gilt der Code — bitte diese Datei dann aktualisieren.*
