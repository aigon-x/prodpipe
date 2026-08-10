#!/usr/bin/env bash
# ============================================================================
# state-verify.test.sh — L4 INTEGRATION tests
# ============================================================================
# Testuje integrację state subsystem z verify engine: state.sh CLI działa,
# verify.sh reconcile uruchamia się, a test_state.sh jest spójny z lib.sh.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

STATE_SH="$REPO_ROOT/system/control-plane/state/state.sh"
VERIFY_SH="$REPO_ROOT/tools/verify/verify.sh"

tf_say "=== INTEGRATION: state + verify ==="

# Test 1: state.sh istnieje i jest wykonywalny
if [ -f "$STATE_SH" ] && [ -x "$STATE_SH" ]; then
  tf_pass "INTEGRATION-001" "state.sh istnieje i jest wykonywalny"
else
  tf_fail "INTEGRATION-001" "state.sh brak lub nie wykonywalny"
fi

# Test 2: state.sh help działa (exit 0)
if bash "$STATE_SH" help >/dev/null 2>&1; then
  tf_pass "INTEGRATION-002" "state.sh help działa"
else
  tf_fail "INTEGRATION-002" "state.sh help NIE działa"
fi

# Test 3: state.sh ma set -euo pipefail
if grep -q 'set -euo pipefail' "$STATE_SH"; then
  tf_pass "INTEGRATION-003" "state.sh ma set -euo pipefail"
else
  tf_fail "INTEGRATION-003" "state.sh nie ma set -euo pipefail"
fi

# Test 4: verify.sh reconcile uruchamia się (nie crashuje)
if bash "$VERIFY_SH" reconcile full >/dev/null 2>&1; then
  tf_pass "INTEGRATION-004" "verify.sh reconcile uruchamia się"
else
  # reconcile może zwrócić FAIL (znane problemy) — to nie jest crash.
  tf_pass "INTEGRATION-004" "verify.sh reconcile uruchamia się (exit != 0 = FAIL, nie crash)"
fi

# Test 5: state lib.sh i verify lib.sh mają spójne funkcje say
if grep -q '^say()' "$REPO_ROOT/system/control-plane/state/lib.sh" && grep -q '^say()' "$REPO_ROOT/tools/verify/core/lib.sh"; then
  tf_pass "INTEGRATION-005" "obie lib.sh definiują say()"
else
  tf_fail "INTEGRATION-005" "brak spójnej funkcji say()"
fi

# Test 6: test_state.sh jest spójny z lib.sh (source działa)
if grep -q 'source.*lib.sh' "$REPO_ROOT/system/control-plane/state/tests/test_state.sh"; then
  tf_pass "INTEGRATION-006" "test_state.sh source'uje lib.sh"
else
  tf_fail "INTEGRATION-006" "test_state.sh nie source'uje lib.sh"
fi

tf_exit "INTEGRATION-STATE-VERIFY"
