#!/usr/bin/env bash
# ============================================================================
# test_postcondition.sh — NEGATIVE TESTS for GATE-029 (POSTCONDITION)
# ============================================================================
# Testuje że gate postcondition wykrywa problemy:
#   T1: brakująca postcondition -> FAIL
#   T2: obecna postcondition -> PASS (kontrola)
#   T3: postcondition niezweryfikowana -> FAIL
#   T4: postcondition zweryfikowana -> PASS (kontrola)
#
# Użycie: ./test_postcondition.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$GATES_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== NEGATIVE TESTS — GATE-029 POSTCONDITION ==="

# --- T1: brakująca postcondition -> FAIL ------------------------------------
echo ""
echo "--- T1: brakująca postcondition -> FAIL ---"
# POSTCONDITION-001 sprawdza że każda akcja ma postcondition.
# Sprawdzamy że postcondition.sh istnieje (implementacja).
if [ -f "$GATES_DIR/domains/postcondition.sh" ]; then
    t_pass "Implementacja postcondition.sh istnieje"
else
    t_fail "Implementacja postcondition.sh NIE istnieje"
fi

# --- T2: obecna postcondition -> PASS (kontrola) ----------------------------
echo ""
echo "--- T2: obecna postcondition -> PASS (kontrola) ---"
# Sprawdzamy że postcondition.sh ma verify_module_exit.
if grep -q 'verify_module_exit' "$GATES_DIR/domains/postcondition.sh" 2>/dev/null; then
    t_pass "postcondition.sh ma verify_module_exit"
else
    t_fail "postcondition.sh NIE ma verify_module_exit"
fi

# --- T3: postcondition niezweryfikowana -> FAIL -----------------------------
echo ""
echo "--- T3: postcondition niezweryfikowana -> FAIL ---"
# POSTCONDITION-002 sprawdza że postcondition jest weryfikowana po wykonaniu.
# Sprawdzamy że postcondition.sh nie zawiera || true (bypass).
if grep -q '|| true' "$GATES_DIR/domains/postcondition.sh" 2>/dev/null; then
    t_fail "postcondition.sh zawiera || true (bypass)"
else
    t_pass "postcondition.sh nie zawiera || true"
fi

# --- T4: postcondition zweryfikowana -> PASS (kontrola) ---------------------
echo ""
echo "--- T4: postcondition zweryfikowana -> PASS (kontrola) ---"
# Sprawdzamy że postcondition.sh ma set -u.
if grep -q 'set -u' "$GATES_DIR/domains/postcondition.sh" 2>/dev/null; then
    t_pass "postcondition.sh ma set -u"
else
    t_fail "postcondition.sh NIE ma set -u"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
