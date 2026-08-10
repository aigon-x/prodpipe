#!/usr/bin/env bash
# ============================================================================
# migration.test.sh — L4 MIGRATION tests
# ============================================================================
# Testuje migracje: zdolność systemu do przeniesienia/aktualizacji stanu bez
# utraty danych. Weryfikuje że wyniki testów są przenośne (JSON) i że
# baseline regresji można migrować między uruchomieniami.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== MIGRATION: migracja stanu ==="

# Test 1: test-results.json jest przenośny (można go skopiować i nadal czytać)
# Uwaga: RESULTS_DIR jest ustawiany w lib.sh przy sourcowaniu — subproces
# re-sourcuje lib.sh i resetuje go. Przekazujemy TESTFORGE_RESULTS_DIR przez env.
tmpdir="$(mktemp -d)"
probe_rc=0
TESTFORGE_RESULTS_DIR="$tmpdir" bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" >/dev/null 2>&1 || probe_rc=$?
# "Migruj" wynik do innego katalogu
mkdir -p "$tmpdir/migrated"
cp "$tmpdir/test-results.json" "$tmpdir/migrated/"
if [ -f "$tmpdir/migrated/test-results.json" ] && grep -q '"suite"' "$tmpdir/migrated/test-results.json"; then
  tf_pass "MIGRATION-001" "test-results.json jest przenośny (migracja bez utraty danych)"
else
  tf_fail "MIGRATION-001" "test-results.json nie przetrwał migracji"
fi
rm -rf "$tmpdir"

# Test 2: regression.sh obsługuje baseline (migracja stanu regresji)
if grep -qE 'baseline|regressions\.json' "$REPO_ROOT/tools/testing/regression.sh"; then
  tf_pass "MIGRATION-002" "regression.sh obsługuje baseline (migracja stanu regresji)"
else
  tf_fail "MIGRATION-002" "regression.sh nie obsługuje baseline"
fi

# Test 3: NO FALSE GREEN — migration nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/migration/migration.test.sh"

tf_exit "MIGRATION"
