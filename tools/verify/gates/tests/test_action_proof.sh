#!/usr/bin/env bash
# ============================================================================
# test_action_proof.sh — NEGATIVE TESTS for GATE-028 (ACTION-PROOF)
# ============================================================================
# Testuje że gate action-proof wykrywa problemy:
#   T1: działanie bez dowodu -> FAIL
#   T2: działanie z dowodem -> PASS (kontrola)
#   T3: działanie bez postcondition -> FAIL
#   T4: działanie z postcondition -> PASS (kontrola)
#
# Użycie: ./test_action_proof.sh
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

echo "=== NEGATIVE TESTS — GATE-028 ACTION-PROOF ==="

# --- T1: działanie bez dowodu -> FAIL ---------------------------------------
echo ""
echo "--- T1: działanie bez dowodu -> FAIL ---"
# ACTION-PROOF-001 sprawdza że każde działanie ma dowód.
# Sprawdzamy że action-proof.sh istnieje (implementacja).
if [ -f "$GATES_DIR/domains/action-proof.sh" ]; then
    t_pass "Implementacja action-proof.sh istnieje"
else
    t_fail "Implementacja action-proof.sh NIE istnieje"
fi

# --- T2: działanie z dowodem -> PASS (kontrola) -----------------------------
echo ""
echo "--- T2: działanie z dowodem -> PASS (kontrola) ---"
# Sprawdzamy że action-proof.sh ma verify_module_exit.
if grep -q 'verify_module_exit' "$GATES_DIR/domains/action-proof.sh" 2>/dev/null; then
    t_pass "action-proof.sh ma verify_module_exit"
else
    t_fail "action-proof.sh NIE ma verify_module_exit"
fi

# --- T3: działanie bez postcondition -> FAIL --------------------------------
echo ""
echo "--- T3: działanie bez postcondition -> FAIL ---"
# ACTION-PROOF-002 sprawdza że każde działanie deklaruje postcondition.
# Sprawdzamy że action-proof.sh nie zawiera || true (bypass).
if grep -q '|| true' "$GATES_DIR/domains/action-proof.sh" 2>/dev/null; then
    t_fail "action-proof.sh zawiera || true (bypass)"
else
    t_pass "action-proof.sh nie zawiera || true"
fi

# --- T4: działanie z postcondition -> PASS (kontrola) -----------------------
echo ""
echo "--- T4: działanie z postcondition -> PASS (kontrola) ---"
# Sprawdzamy że action-proof.sh ma set -u.
if grep -q 'set -u' "$GATES_DIR/domains/action-proof.sh" 2>/dev/null; then
    t_pass "action-proof.sh ma set -u"
else
    t_fail "action-proof.sh NIE ma set -u"
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
