#!/usr/bin/env bash
# ============================================================================
# golden.test.sh — L1 GOLDEN tests
# ============================================================================
# Testuje golden files: porównanie wygenerowanego outputu z oczekiwanym
# (golden) wzorcem. Weryfikuje że deterministyczne outputy (np. nagłówki,
# struktura JSON) są stabilne i zgodne z wzorcem.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== GOLDEN: golden file tests ==="

# Test 1: test-results.json ma oczekiwaną strukturę (golden schema)
# Uruchom deterministyczny test i sprawdź klucze JSON.
# Uwaga: RESULTS_DIR jest ustawiany w lib.sh przy sourcowaniu — subproces
# re-sourcuje lib.sh i resetuje go. Dlatego przekazujemy TESTFORGE_RESULTS_DIR
# przez env, a nie modyfikujemy RESULTS_DIR w rodzicu.
tmp_results="$(mktemp -d)"
probe_rc=0
TESTFORGE_RESULTS_DIR="$tmp_results" bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" >/dev/null 2>&1 || probe_rc=$?
if [ -f "$tmp_results/test-results.json" ]; then
  json=$(cat "$tmp_results/test-results.json")
  # Golden: musi zawierać klucze suite, total, pass, fail, error, skipped, results
  ok=1
  for key in suite total pass fail error skipped results; do
    if ! printf '%s' "$json" | grep -q "\"$key\""; then
      tf_fail "GOLDEN-001" "brak klucza '$key' w test-results.json"
      ok=0
    fi
  done
  [ "$ok" -eq 1 ] && tf_pass "GOLDEN-001" "test-results.json ma pełną strukturę golden"
else
  tf_fail "GOLDEN-001" "test-results.json nie został wygenerowany"
fi
rm -rf "$tmp_results"

# Test 2: manifest.yaml ma oczekiwane klucze (golden schema)
ok2=1
for key in version tests; do
  if ! grep -q "^$key:" "$REPO_ROOT/tests/manifest.yaml"; then
    tf_fail "GOLDEN-002" "brak klucza '$key' w manifest.yaml"
    ok2=0
  fi
done
[ "$ok2" -eq 1 ] && tf_pass "GOLDEN-002" "manifest.yaml ma pełną strukturę golden"

# Test 3: NO FALSE GREEN — golden nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/golden/golden.test.sh"

tf_exit "GOLDEN"
