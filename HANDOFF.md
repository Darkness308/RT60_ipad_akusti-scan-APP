# Übergabe / Handoff — Projektstand & Weiterführung auf macOS

> **Zweck:** Diese Datei ist der **Startpunkt für jede neue Person und jede Claude-/Copilot-Instanz**,
> die das Projekt auf macOS übernimmt. Sie beschreibt den *ehrlich überprüfbaren* Stand —
> nicht ein Wunschbild. Wenn etwas hier im Widerspruch zu vollmundigen Aussagen anderswo steht,
> gilt **diese Datei + der tatsächliche Code/CI-Lauf**.

---

## TL;DR

- **Rechenkern** (`AcoustiScanConsolidated`, `Modules/Export`): solide, getestet, baut via `swift test`. **Übernahmefähig.**
- **DIN 18041**: normtreu nach DIN 18041:2016-03 (Gruppen A1–A5, `T_soll = a·lg(V)+b`, Bild-2-Toleranzband), mit Tests.
- **iOS-App** (`AcoustiScanApp`): **kompiliert** (CI via `xcodebuild`), 5-Tab-Navigation verdrahtet — aber **App-Tests und Geräte-Laufzeit sind NICHT automatisch verifiziert** (siehe §2).
- **CI**: `ci-honest.yml` ist die **einzige aktive, ehrliche** Pipeline. Alle anderen Workflows sind stillgelegt.
- **Wichtigster nächster Schritt**: App-Tests in eine echte CI-Loop bringen (§5).

---

## 1. Was funktioniert / verifiziert ist

| Bereich | Status | Wodurch belegt |
|---|---|---|
| `AcoustiScanConsolidated` | ✅ baut + Tests grün | `swift build && swift test` in `ci-honest.yml` |
| `Modules/Export` (ReportExport) | ✅ baut + Tests grün | `swift build && swift test` in `ci-honest.yml` |
| DIN 18041 Engine (A1–A5) | ✅ implementiert + getestet | `DIN18041Tests.swift`, `AcoustiScanConsolidatedTests.swift` |
| iOS-App **Build** | ✅ kompiliert | `xcodebuild build` (Simulator-SDK) in `ci-honest.yml` |
| App `ContentView` | ✅ echte `TabView` (RT60/Scan/Maße/Material/Export) | Code + CI-Build |

---

## 2. Was (noch) NICHT verifiziert ist — ehrlich

- **App-Tests laufen in KEINER CI.** Das Test-Target `AcoustiScanAppTests` ist **nicht** im Xcode-Projekt
  (`AcoustiScanApp.xcodeproj/project.pbxproj` referenziert es 0×). Die Testdateien existieren nur auf der Platte
  und im SPM-Manifest `AcoustiScanApp/Package.swift`, das die CI **nicht** baut. → Brüche in App-Tests bleiben unbemerkt.
- **Geräte-Laufzeit** (LiDAR/RoomPlan, Mikrofon, ARKit) wurde **nie automatisiert** getestet — nur auf echtem iPad sinnvoll.
- **PDF-Export der App ist ein Platzhalter.** Seine Compliance-/Toleranzprüfung (`PDFPageRenderer`/`PDFTableRenderer`)
  ist **symmetrisch** (`abs(measured − target) ≤ tolerance`) statt des normtreuen **asymmetrischen** Bild-2-Bands.
  Derzeit ohne Aufrufer/ohne erzeugte `dinTargets` → produziert aktuell keine falschen Zahlen, **muss aber** beim
  Verdrahten auf die Package-Bänder (`DIN18041Database`) umgestellt werden.

> **Konsequenz:** „bugfrei" ist **nicht belegbar**, solange §5/Schritt 1 nicht erledigt ist. Bitte nicht so nennen.

---

## 3. Echte Verifikation auf macOS (Befehle)

```bash
# 1) Packages (laufen sicher auf jedem Mac mit Xcode/Swift)
cd AcoustiScanConsolidated && swift build && swift test && cd ..
cd Modules/Export         && swift build && swift test && cd ..

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

1. **Echte App-Verifikation herstellen** *(höchster Wert)*:
   in Xcode ein **Unit-Test-Target** anlegen (GUI: *File → New → Target → Unit Testing Bundle*),
   die vorhandenen Dateien in `AcoustiScanApp/AcoustiScanAppTests/` zuordnen, dann **`xcodebuild test`**
   in `ci-honest.yml` ergänzen. → erstes automatisches Rot/Grün für die App.
   *(Die `.pbxproj` bitte über Xcode ändern, nicht von Hand — danach `swift`/`xcodebuild test` lokal prüfen.)*
2. **Danach wählen** (je ein eigenes, CI-verifiziertes Vorhaben):
   - Modelle App→Package konsolidieren, **oder**
   - PDF-Export verdrahten **und dabei** die normtreuen DIN-Bänder (`DIN18041Database`) nutzen (§2).
3. **Branch-Hygiene** (§9).

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
- **Stillgelegt** (nur `workflow_dispatch`): `build-test.yml`, `swift.yml`, `self-healing.yml`,
  `auto-retry.yml`, `autofix-agent.yml`. **Nicht ohne Grund reaktivieren** — sie haben früher Fehler maskiert.

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

---

*Letzte Aktualisierung dieses Dokuments: 2026-05-30. Bei Abweichungen zwischen diesem Dokument und dem Code
gilt der Code — bitte diese Datei dann aktualisieren.*
