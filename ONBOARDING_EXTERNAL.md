# Onboarding für externe Mitwirkende

Willkommen! Dieses Dokument erklärt, **wie** du an AcoustiScan mitarbeitest und
**unter welchen Bedingungen**. Bitte zuerst vollständig lesen.

---

## 1. Rechtliches zuerst (wichtig)

- Der Code ist **proprietär** — siehe [LICENSE](LICENSE). **Alle Rechte vorbehalten.**
- Dass du dieses Repo sehen/forken kannst, gibt dir **noch keine** Rechte am Code.
  Maßgeblich ist die **gesonderte schriftliche Vereinbarung** mit dem Rechteinhaber
  (Entwicklungs-/Contributor-Vertrag). Ohne diese Vereinbarung bitte **nicht** mit
  der Arbeit beginnen und nichts veröffentlichen/weitergeben.
- **Vertraulichkeit**: Code, Reports, Daten und Zugangsdaten nicht außerhalb des
  Projekts teilen, nicht in öffentlichen Repos/Gists/Foren posten.
- **Keine Geheimnisse committen** (API-Keys, Tokens, Apple-Team-IDs, Profile,
  personenbezogene Daten). Falls versehentlich passiert: sofort melden.

---

## 2. Voraussetzungen (Build/Run)

- **macOS** + **Xcode 15.4** (die CI ist bewusst auf 15.4 gepinnt — bitte lokal
  dieselbe Major-Version nutzen, sonst weichen Ergebnisse ab).
- Optional **iPad mit LiDAR** (iPad Pro 2020+) für RoomPlan/ARKit-Laufzeittests.
- Details & echter Projektstand: **[HANDOFF.md](HANDOFF.md)** ist die ehrliche
  Quelle der Wahrheit (was verifiziert ist und was nicht).

---

## 3. Mitarbeits-Workflow (Fork → Pull Request)

```bash
# 1) Repo über die GitHub-Oberfläche forken (Button "Fork").
# 2) Deinen Fork klonen:
git clone https://github.com/<dein-user>/RT60_ipad_akusti-scan-APP.git
cd RT60_ipad_akusti-scan-APP

# 3) Das Original als "upstream" hinzufügen, um aktuell zu bleiben:
git remote add upstream https://github.com/Darkness308/RT60_ipad_akusti-scan-APP.git
git fetch upstream

# 4) Branch von aktuellem main:
git checkout -b feat/meine-aenderung upstream/main

# 5) Vor jeder Arbeit lokal verifizieren (siehe HANDOFF.md §3):
(cd AcoustiScanConsolidated && swift build && swift test)
(cd Modules/Export         && swift build && swift test)
xcodebuild build -project AcoustiScanApp/AcoustiScanApp.xcodeproj \
  -scheme AcoustiScanApp -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO

# 6) Commit + Push in DEINEN Fork, dann Pull Request gegen Darkness308:main.
```

- Bitte **kleine, fokussierte PRs** und die Konventionen aus
  [CONTRIBUTING.md](CONTRIBUTING.md) einhalten.
- Die einzige verbindliche CI ist **`ci-honest.yml`** — sie muss grün sein.
  Andere Workflows sind stillgelegt und dürfen **nicht** reaktiviert werden.

---

## 4. Womit anfangen

Die priorisierten nächsten Schritte stehen in **[HANDOFF.md](HANDOFF.md) §5** —
der wertvollste erste Beitrag ist, die **App-Tests in eine echte CI-Loop** zu
bringen (Unit-Test-Target in Xcode anlegen + `xcodebuild test` in der CI).

---

## 5. Fragen

Über GitHub-Issues im Repository oder direkt beim Rechteinhaber
(Account: https://github.com/Darkness308).
