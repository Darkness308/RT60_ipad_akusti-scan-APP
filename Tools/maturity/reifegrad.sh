#!/usr/bin/env bash
# reifegrad.sh — misst die ZÄHLBAREN Reifegrad-Kennzahlen des Repos.
# Läuft ohne Swift/Xcode (reines Datei-Parsing), also auch auf Linux/CI.
# Die Reifegrad-STUFEN (0-5) stehen in Docs/reifegrad.md (menschliches Urteil),
# NICHT hier — dieses Skript gibt nur objektive Zahlen/Flags aus.
#
# Bewusst OHNE `set -e`/`pipefail`: grep mit null Treffern (z. B. keine
# verwaisten Tests = Erfolgsfall) darf das Skript nicht abbrechen.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

count_tests() { # $1 = Verzeichnis -> Anzahl "func test..."
  local n
  n=$(grep -rhE 'func[[:space:]]+test' "$1" --include=*.swift 2>/dev/null | wc -l)
  echo "$((n + 0))"
}

L1=$(count_tests AcoustiScanConsolidated/Tests)
L2=$(count_tests Modules/Export/Tests)
L3=$(count_tests AcoustiScanApp/AcoustiScanAppTests)
ORPH=$(count_tests Tools)
TOTAL=$(( L1 + L2 + L3 + ORPH ))

SKIPS=$(grep -rhE 'XCTSkip' --include=*.swift . 2>/dev/null | wc -l); SKIPS=$((SKIPS + 0))
WORKFLOWS=$(find .github/workflows -maxdepth 1 -name '*.yml' 2>/dev/null | wc -l); WORKFLOWS=$((WORKFLOWS + 0))
ADRS=$(find Docs/adr -maxdepth 1 -name '[0-9]*.md' 2>/dev/null | wc -l); ADRS=$((ADRS + 0))

# Ehrlich: "vorhanden" ist noch kein GATE. Ein Lint-Job mit --lenient bzw. ein
# Coverage-Schritt ohne fehlschlagende Schwelle ist REPORT-ONLY, nicht erzwingend.
lint_status() {
  grep -rqiE 'swiftlint|swiftformat' .github/workflows/ 2>/dev/null || { echo "fehlt"; return; }
  if grep -rqiE 'lenient' .github/workflows/ 2>/dev/null; then echo "report-only"; else echo "ENFORCING"; fi
}
coverage_status() {
  grep -rqiE 'enableCodeCoverage|codecov|xccov' .github/workflows/ 2>/dev/null || { echo "fehlt"; return; }
  if grep -rqiE 'coverage.*(threshold|minimum|fail)|--minimum-coverage|xccov.*--check' .github/workflows/ 2>/dev/null; then echo "ENFORCING"; else echo "report-only"; fi
}
LINT_GATE=$(lint_status)
COVERAGE_GATE=$(coverage_status)

BRANCHES="n/v"
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCHES=$(git branch -r 2>/dev/null | grep -v 'HEAD ->' | wc -l)
  BRANCHES=$((BRANCHES + 0))
fi

printf '\n=== AcoustiScan — Reifegrad-Kennzahlen (%s) ===\n\n' "$(date +%Y-%m-%d)"
printf 'Tests L1 Rechenkern (AcoustiScanConsolidated): %s\n' "$L1"
printf 'Tests L2 Report/Export (Modules/Export):       %s\n' "$L2"
printf 'Tests L3 App (AcoustiScanAppTests):             %s\n' "$L3"
printf 'Tests VERWAIST (Tools/, laufen nirgends):       %s\n' "$ORPH"
printf 'Tests GESAMT:                                   %s\n' "$TOTAL"
printf 'XCTSkip-Vorkommen:                              %s\n' "$SKIPS"
printf 'CI-Workflows:                                   %s\n' "$WORKFLOWS"
printf 'Lint in CI (swiftlint/-format):                 %s\n' "$LINT_GATE"
printf 'Coverage in CI:                                 %s\n' "$COVERAGE_GATE"
printf 'ADRs:                                           %s\n' "$ADRS"
printf 'Remote-Branches (lokal bekannt):                %s\n' "$BRANCHES"

printf '\nHinweise:\n'
[ "$ORPH" -gt 0 ] && printf '  ! %s verwaiste Test(s) — in keiner Pipeline.\n' "$ORPH"
[ "$LINT_GATE" != "ENFORCING" ] && printf '  ! Lint ist kein blockierendes Gate (%s) — M2-Ratchet offen.\n' "$LINT_GATE"
[ "$COVERAGE_GATE" != "ENFORCING" ] && printf '  ! Coverage ist kein blockierendes Gate (%s) — M2-Ratchet offen.\n' "$COVERAGE_GATE"
printf '  i Branch-Protection ist hier NICHT prüfbar — im GitHub-UI verifizieren.\n'
printf '  i Stufen (0-5) je Ebene: siehe Docs/reifegrad.md.\n\n'
exit 0
