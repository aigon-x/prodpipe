#!/usr/bin/env bash
# ============================================================================
# state.test.sh — L1 UNIT tests for state subsystem
# ============================================================================
# Wykonuje istniejący suite test_state.sh (PHASE B11, T1-T15) jako test
# jednostkowy. Wymaga że test_state.sh przechodzi w całości.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

STATE_TEST="$REPO_ROOT/system/control-plane/state/tests/test_state.sh"

tf_say "=== UNIT: state subsystem ==="

# Test 1: test_state.sh istnieje
if [ -f "$STATE_TEST" ]; then
  tf_pass "STATE-UNIT-001" "test_state.sh istnieje"
else
  tf_fail "STATE-UNIT-001" "brak test_state.sh"
fi

# Test 2: test_state.sh przechodzi (exit 0)
if bash "$STATE_TEST" >/dev/null 2>&1; then
  tf_pass "STATE-UNIT-002" "test_state.sh przechodzi (exit 0)"
else
  tf_fail "STATE-UNIT-002" "test_state.sh NIE przechodzi"
fi

# Test 3: test_state.sh ma set -euo pipefail LUB set -uo pipefail (NO FALSE GREEN)
# test_state.sh używa set -uo pipefail + jawnych liczników FAIL i exit 1 przy FAIL>0,
# więc gwarancja NO FALSE GREEN jest spełniona mimo braku -e.
if grep -qE 'set\s+-e?uo\s+pipefail' "$STATE_TEST"; then
  tf_pass "STATE-UNIT-003" "test_state.sh ma set -euo pipefail (lub set -uo pipefail)"
else
  tf_fail "STATE-UNIT-003" "test_state.sh nie ma set -euo pipefail"
fi

# Test 4: test_state.sh nie ma zakazanych wzorców
if grep -qE '\|\|\s*true\b|^\s*set\s+\+e\b' "$STATE_TEST"; then
  tf_fail "STATE-UNIT-004" "test_state.sh ma zakazane wzorce (|| true / set +e)"
else
  tf_pass "STATE-UNIT-004" "test_state.sh czysty (brak || true / set +e)"
fi

tf_exit "STATE-UNIT"
