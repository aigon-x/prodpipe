#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-023 — E2E TESTS (Testy end-to-end)
# Rodzina: CODE | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium zawiera testy end-to-end (pełny przepływ
# przez system). Wykrywa:
#   * NO-E2E-TESTS — brak testów E2E
#   * E2E-ORPHAN   — testy E2E bez runnera
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION (czy pipeline jest poprawnie zbudowany) vs REPOSITORY (czy repo spełnia kontrakt)
# ─────────────────────────────────────────────────────────────
set -u

# ── Wczytaj core ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── DISCOVER ────────────────────────────────────────────────
p_say "=== P-023 E2E TESTS ==="
p_say "Weryfikacja obecności testów end-to-end"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-023"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykryj testy E2E: katalog tests/e2e/, e2e/, pliki *.e2e.test.*,
# konfiguracja Playwright (playwright.config.*).
E2E_FILES="$(p_repo_files --name '(^tests/e2e/|^e2e/|\.e2e\.test\.|playwright\.config\.)')"
E2E_COUNT=$(printf '%s\n' "$E2E_FILES" | grep -c . || true)

# Wykryj runner testów E2E.
RUNNER_FILES="$(p_repo_files --name '(run_tests|test_runner|testforge|playwright|cypress|puppeteer)')"
RUNNER_COUNT=$(printf '%s\n' "$RUNNER_FILES" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$E2E_COUNT" -gt 0 ]; then
  p_pass "E2E-TESTS-PRESENT" BLOCKING "Znaleziono $E2E_COUNT plików testów E2E"
else
  p_fail "E2E-TESTS-MISSING" BLOCKING "Brak testów E2E w repozytorium"
fi
if [ "$RUNNER_COUNT" -gt 0 ]; then
  p_pass "E2E-TESTS-RUNNABLE" BLOCKING "Znaleziono $RUNNER_COUNT runnerów testów E2E"
else
  p_warn "E2E-TESTS-ORPHAN" "Testy E2E bez wykrytego runnera — mogą nie być uruchamiane"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-023:e2e-tests E2E_FILES=$E2E_COUNT RUNNERS=$RUNNER_COUNT" "pipeline" "code/e2e-tests.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$E2E_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-023" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-023" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
