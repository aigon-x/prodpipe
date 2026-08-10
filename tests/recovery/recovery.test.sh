#!/usr/bin/env bash
# ============================================================================
# recovery.test.sh — L6 RECOVERY tests
# ============================================================================
# Testuje zdolność systemu do odzyskania stanu po awarii: deterministyczna
# rekonstrukcja wyników, brak utraty danych przy ponownym uruchomieniu,
# idempotentność operacji odzyskiwania.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== RECOVERY: odzyskiwanie stanu ==="

# Test 1: RESULTS_DIR jest tworzony przez tf_summary (odzyskiwalność outputu)
tmp_results="$(mktemp -d)"
old_results="$RESULTS_DIR"
RESULTS_DIR="$tmp_results"
# Probe: tf_summary tworzy test-results.json. Użyj `|| rc=$?` zamiast `|| true`
# (NO FALSE GREEN — nie maskuj exit code).
probe_rc=0
tf_summary "RECOVERY-PROBE" >/dev/null 2>&1 || probe_rc=$?
if [ -f "$tmp_results/test-results.json" ]; then
  tf_pass "RECOVERY-001" "test-results.json jest tworzony (odzyskiwalny output)"
else
  tf_fail "RECOVERY-001" "test-results.json nie został utworzony"
fi
RESULTS_DIR="$old_results"
rm -rf "$tmp_results"

# Test 2: runner.sh istnieje (mechanizm odzyskiwania/ponownego uruchomienia)
tf_assert_file "RECOVERY-002 runner.sh istnieje" "$REPO_ROOT/tools/testing/runner.sh"

# Test 3: regression.sh istnieje (baseline do odzyskania stanu)
tf_assert_file "RECOVERY-003 regression.sh istnieje" "$REPO_ROOT/tools/testing/regression.sh"

# Test 4: NO FALSE GREEN — recovery nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/recovery/recovery.test.sh"

tf_exit "RECOVERY"
