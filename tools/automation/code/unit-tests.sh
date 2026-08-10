#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-021 — UNIT TESTS (Testy jednostkowe)
# Rodzina: CODE | Klasa: FAST | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium zawiera testy jednostkowe i że są one
# wykonywalne. Wykrywa:
#   * NO-UNIT-TESTS      — brak jakichkolwiek testów jednostkowych
#   * UNIT-TESTS-ORPHAN  — testy jednostkowe bez uruchomienia (brak runnera)
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
p_say "=== P-021 UNIT TESTS ==="
p_say "Weryfikacja obecności i wykonywalności testów jednostkowych"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-021"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykryj testy jednostkowe: katalog tests/unit/, pliki test_*.sh,
# *_test.py, *.test.ts, *.test.js, *_test.go, *_test.rs.
UNIT_FILES="$(p_repo_files --name '(^tests/unit/|/test_|_test\.(py|go|rs)$|\.test\.(sh|ts|js)$)')"
UNIT_COUNT=$(printf '%s\n' "$UNIT_FILES" | grep -c . || true)

# Wykryj runner testów jednostkowych (skrypt, który je uruchamia).
RUNNER_FILES="$(p_repo_files --name '(run_tests|test_runner|testforge|pytest|jest|go test|make test)')"
RUNNER_COUNT=$(printf '%s\n' "$RUNNER_FILES" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$UNIT_COUNT" -gt 0 ]; then
  p_pass "UNIT-TESTS-PRESENT" BLOCKING "Znaleziono $UNIT_COUNT plików testów jednostkowych"
else
  p_fail "UNIT-TESTS-MISSING" BLOCKING "Brak testów jednostkowych w repozytorium"
fi
if [ "$RUNNER_COUNT" -gt 0 ]; then
  p_pass "UNIT-TESTS-RUNNABLE" BLOCKING "Znaleziono $RUNNER_COUNT runnerów testów jednostkowych"
else
  p_warn "UNIT-TESTS-ORPHAN" "Testy jednostkowe bez wykrytego runnera — mogą nie być uruchamiane"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-021:unit-tests UNIT_FILES=$UNIT_COUNT RUNNERS=$RUNNER_COUNT" "pipeline" "code/unit-tests.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$UNIT_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-021" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-021" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "FAST" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
