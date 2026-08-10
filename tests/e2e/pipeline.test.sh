#!/usr/bin/env bash
# ============================================================================
# pipeline.test.sh — L5 E2E tests
# ============================================================================
# Testuje cały pipeline end-to-end: tools/test discover → unit → contract →
# integration → quality → coverage. Weryfikuje że wszystkie subkomendy
# działają i produkują maszynowy output.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

TEST_BIN="$REPO_ROOT/tools/test"

tf_say "=== E2E: full pipeline ==="

# Test 1: tools/test discover znajduje testy
discover_out=$(bash "$TEST_BIN" discover 2>&1)
if echo "$discover_out" | grep -q 'Znaleziono'; then
  tf_pass "E2E-001" "discover znajduje testy"
else
  tf_fail "E2E-001" "discover nie znalazł testów"
fi

# Test 2: tools/test unit działa (produkuje test-results.json)
tmp_results=$(mktemp -d)
if TESTFORGE_RESULTS_DIR="$tmp_results" bash "$TEST_BIN" unit >/dev/null 2>&1; then
  tf_pass "E2E-002" "unit suite działa"
else
  tf_fail "E2E-002" "unit suite NIE działa"
fi
rm -rf "$tmp_results"

# Test 3: tools/test contract działa
tmp_results=$(mktemp -d)
if TESTFORGE_RESULTS_DIR="$tmp_results" bash "$TEST_BIN" contract >/dev/null 2>&1; then
  tf_pass "E2E-003" "contract suite działa"
else
  tf_fail "E2E-003" "contract suite NIE działa"
fi
rm -rf "$tmp_results"

# Test 4: tools/test quality produkuje quality.json
tmp_results=$(mktemp -d)
if TESTFORGE_RESULTS_DIR="$tmp_results" bash "$TEST_BIN" quality >/dev/null 2>&1; then
  if [ -f "$tmp_results/quality.json" ]; then
    tf_pass "E2E-004" "quality produkuje quality.json"
  else
    tf_fail "E2E-004" "quality nie wyprodukował quality.json"
  fi
else
  tf_fail "E2E-004" "quality suite NIE działa"
fi
rm -rf "$tmp_results"

# Test 5: tools/test coverage produkuje coverage.json
tmp_results=$(mktemp -d)
if TESTFORGE_RESULTS_DIR="$tmp_results" bash "$TEST_BIN" coverage >/dev/null 2>&1; then
  if [ -f "$tmp_results/coverage.json" ]; then
    tf_pass "E2E-005" "coverage produkuje coverage.json"
  else
    tf_fail "E2E-005" "coverage nie wyprodukował coverage.json"
  fi
else
  tf_fail "E2E-005" "coverage suite NIE działa"
fi
rm -rf "$tmp_results"

# Test 6: tools/test help działa
if bash "$TEST_BIN" help >/dev/null 2>&1; then
  tf_pass "E2E-006" "help działa"
else
  tf_fail "E2E-006" "help NIE działa"
fi

# Test 7: nieznana subkomenda zwraca 2
if bash "$TEST_BIN" nonexistent >/dev/null 2>&1; then
  tf_fail "E2E-007" "nieznana subkomenda zwróciła 0"
else
  tf_pass "E2E-007" "nieznana subkomenda zwraca != 0"
fi

tf_exit "E2E-PIPELINE"
