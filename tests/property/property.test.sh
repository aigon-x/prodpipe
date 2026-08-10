#!/usr/bin/env bash
# ============================================================================
# property.test.sh — L1 PROPERTY tests
# ============================================================================
# Testuje właściwości (property-based): dla wielu przypadków wejściowych
# system zachowuje niezmienniki. Weryfikuje że asercje są poprawne dla
# różnych wartości (nie tylko jednego przypadku).
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== PROPERTY: property-based tests ==="

# Test 1: tf_assert_eq jest poprawny dla wielu wartości (właściwość: równość
# jest zwrotna — x == x dla dowolnego x)
ok=1
for i in 1 2 3 4 5 42 100 abc xyz "a b c"; do
  if ! tf_assert_eq "PROP-001 x==x dla '$i'" "$i" "$i" >/dev/null 2>&1; then
    tf_fail "PROP-001" "tf_assert_eq zawiódł dla x==x, x='$i'"
    ok=0
  fi
done
[ "$ok" -eq 1 ] && tf_pass "PROP-001" "tf_assert_eq zachowuje zwrotność dla wielu wartości"

# Test 2: tf_assert_rc jest poprawny dla wielu rc (właściwość: rc==rc)
ok2=1
for i in 0 1 2 3 42 127 255; do
  if ! tf_assert_rc "PROP-002 rc==rc dla $i" "$i" "$i" >/dev/null 2>&1; then
    tf_fail "PROP-002" "tf_assert_rc zawiódł dla rc==rc, rc=$i"
    ok2=0
  fi
done
[ "$ok2" -eq 1 ] && tf_pass "PROP-002" "tf_assert_rc zachowuje poprawność dla wielu rc"

# Test 3: NO FALSE GREEN — property nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/property/property.test.sh"

tf_exit "PROPERTY"
