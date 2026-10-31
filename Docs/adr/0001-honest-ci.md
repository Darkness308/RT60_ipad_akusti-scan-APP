# ADR-0001 — Ehrliche CI ohne Maskierung; Legacy-Automation gelöscht

**Status:** Akzeptiert (umgesetzt in PR #248; Bereinigung vor dem Fork)
**Datum:** 2026 (Sanierungsphase)

## Kontext

Das Repo war zuvor „grün-gewaschen": Workflows (`build-test.yml`, `swift.yml`, `self-healing.yml`,
`auto-retry.yml`, `autofix-agent.yml`), ein `build.sh`-Auto-Fix-Wrapper und `.github/heal-attempts.json`
verschluckten Fehler mit `|| true`, Retries und Auto-Fix. Grüne Checks bedeuteten nicht, dass etwas
funktionierte.

## Entscheidung

Eine **einzige** Pipeline `ci-honest.yml` als Quelle der Wahrheit: `set -o pipefail`, keine Retries,
keine Auto-Fixes, keine Fehler-Maskierung. Schlägt etwas fehl, ist der Job rot. Alle maskierenden
Workflows + Wrapper wurden **gelöscht** und dürfen nicht wieder eingeführt werden.

## Konsequenzen

- ➕ „Grün" ist wieder ein belastbares Signal.
- ➕ Reale Fehler werden sichtbar (der Build-/Test-Tail wird bei Fehlern an den PR gepostet).
- ➖ Mehr rote Läufe sichtbar — gewollt (Realität statt Fassade).
- 🔒 Regel: keine Retry-/Self-Healing-/Auto-Fix-Automation (vgl. CLAUDE.md Regel 1 & 6).
