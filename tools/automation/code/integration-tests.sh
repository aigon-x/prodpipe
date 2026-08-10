#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-022 — INTEGRATION TESTS (Testy integracyjne)
# Rodzina: CODE | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium zawiera testy integracyjne (współpraca
# komponentów). Wykrywa:
#   * NO-INTEGRATION-TESTS — brak testów integracyjnych
#   * INTEGRATION-ORPHAN   — testy integracyjne bez runnera
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
p_say "=== P-022 INTEGRATION TESTS ==="
p_say "Weryfikacja obecności testów integracyjnych"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-022"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykryj testy integracyjne: katalog tests/integration/, integration/,
# pliki *.integration.test.*, *_integration_test.*.
INTEGRATION_FILES="$(p_repo_files --name '(^tests/integration/|^integration/|\.integration\.test\.|_integration_test\.)')"
INTEGRATION_COUNT=$(printf '%s\n' "$INTEGRATION_FILES" | grep -c . || true)

# Wykryj runner testów integracyjnych.
RUNNER_FILES="$(p_repo_files --name '(run_tests|test_runner|testforge|pytest|jest|go test|make test)')"
RUNNER_COUNT=$(printf '%s\n' "$RUNNER_FILES" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$INTEGRATION_COUNT" -gt 0 ]; then
  p_pass "INTEGRATION-TESTS-PRESENT" BLOCKING "Znaleziono $INTEGRATION_COUNT plików testów integracyjnych"
else
  p_fail "INTEGRATION-TESTS-MISSING" BLOCKING "Brak testów integracyjnych w repozytorium"
fi
if [ "$RUNNER_COUNT" -gt 0 ]; then
  p_pass "INTEGRATION-TESTS-RUNNABLE" BLOCKING "Znaleziono $RUNNER_COUNT runnerów testów"
else
  p_warn "INTEGRATION-TESTS-ORPHAN" "Testy integracyjne bez wykrytego runnera — mogą nie być uruchamiane"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-022:integration-tests INTEGRATION_FILES=$INTEGRATION_COUNT RUNNERS=$RUNNER_COUNT" "pipeline" "code/integration-tests.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$INTEGRATION_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-022" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-022" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
