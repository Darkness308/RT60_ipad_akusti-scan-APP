# CLAUDE.md

Guidance for Claude Code instances working in this repository. Read this first,
then **[HANDOFF.md](HANDOFF.md)** for the honest, verifiable project state.

## What this project is

**AcoustiScan** — a SwiftUI/iPadOS app for room-acoustics analysis: LiDAR room
capture (RoomPlan/ARKit), RT60 reverberation measurement, and DIN 18041:2016-03
evaluation, with PDF/XLSX report export. It is **not** a learning tool; it measures
and evaluates acoustics. The repo is **proprietary** (see `LICENSE`).

## Repository layout

- `AcoustiScanConsolidated/` — Swift package, the computation core (RT60, DIN 18041,
  models, report rendering). Builds & tests on macOS via `swift build` / `swift test`.
- `Modules/Export/` — `ReportExport` package (PDF/HTML/XLSX rendering). Builds & tests on macOS via `swift build` / `swift test`.
- `AcoustiScanApp/` — the iOS app (SwiftUI). Built via **`AcoustiScanApp.xcodeproj`**
  (authoritative). A parallel `AcoustiScanApp/Package.swift` exists but is **not**
  built by CI — don't rely on it.
- `Docs/`, `Schemas/`, `Tools/` — supporting material.

## Build & test (requires macOS + Xcode 15.4)

```bash
(cd AcoustiScanConsolidated && swift build && swift test)
(cd Modules/Export         && swift build && swift test)
xcodebuild build -project AcoustiScanApp/AcoustiScanApp.xcodeproj \
  -scheme AcoustiScanApp -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

> ⚠️ The Linux web/sandbox environment has **no `swift`/`xcodebuild`** — it can only
> do static work (read, edit, search). Anything requiring compile/run/test must
> happen on macOS. Do **not** claim something is "verified" unless it was actually
> built or run.

## Hard rules (learned the hard way)

1. **Honesty over polish.** This repo was previously "green-washed" by bots that
   masked failures. The single source of CI truth is **`.github/workflows/ci-honest.yml`**
   — and now the *only* workflow. The legacy masking workflows (`build-test.yml`,
   `swift.yml`, `self-healing.yml`, `auto-retry.yml`, `autofix-agent.yml`), the
   `build.sh` auto-fix wrapper and `.github/heal-attempts.json` were **deleted**
   before the fork. Do not reintroduce retry/auto-fix/self-healing automation.
2. **The word "verified" means built/ran.** Reading code is review, not verification.
3. **App tests are NOT in CI.** `AcoustiScanAppTests` isn't in the Xcode project yet,
   so its breakage is invisible to CI. Run app tests locally; wiring them into CI is
   the highest-value next step (see HANDOFF §5).
4. **DIN logic is norm-faithful — keep it that way.** Targets are
   `T_soll = a·lg(V)+b` for Groups A1–A5 with the asymmetric Bild-2 tolerance band
   (lives in `Models/RoomType.swift` + `DIN18041/`). Do not reintroduce the old
   invented room types (classroom/office/…) or symmetric tolerances.
5. **Known tech debt (documented, deliberately deferred):** duplicated models
   (app vs. package), the dual build system, the app PDF exporter's still-symmetric
   tolerance placeholder. See HANDOFF §2/§4.
6. **Agents/automation only with enforcement + tests.** Any agent or automation
   (CI bot, Git hook, "agent system", RAG/tooling) may live in this repo only if it
   is actually enforced (Git hooks / GitHub Actions) **and** covered by executable
   tests across the relevant layers. No aspirational prose/architecture — the
   fictional `Docs/agents.md` was deleted for exactly this reason.

## Workflow conventions

- Small, focused PRs; create them as **draft**. CI (`ci-honest.yml`) must be green.
- Commit/PR language in this repo is mostly German; match the surrounding style.
- Don't commit secrets (API keys, Apple Team IDs, provisioning profiles).
- External contributors: see `ONBOARDING_EXTERNAL.md` (fork → PR).

## Where to start a task

`HANDOFF.md` §5 has the prioritized next steps. For acoustics correctness, the core
is `AcoustiScanConsolidated/Sources/AcoustiScanConsolidated/` (`RT60Calculator.swift`,
`DIN18041/`, `Models/RoomType.swift`).
