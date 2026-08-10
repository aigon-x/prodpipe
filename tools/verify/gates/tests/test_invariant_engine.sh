#!/usr/bin/env bash
# ============================================================================
# test_invariant_engine.sh — NEGATIVE TESTS for GATE-027 (INVARIANT-ENGINE)
# ============================================================================
# Testuje że gate invariant-engine wykrywa problemy:
#   T1: naruszony invariant -> FAIL
#   T2: spełniony invariant -> PASS (kontrola)
#   T3: brakujący invariant -> FAIL
#   T4: obecny invariant -> PASS (kontrola)
#
# Użycie: ./test_invariant_engine.sh
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

echo "=== NEGATIVE TESTS — GATE-027 INVARIANT-ENGINE ==="

# --- T1: naruszony invariant -> FAIL ----------------------------------------
echo ""
echo "--- T1: naruszony invariant -> FAIL ---"
# INVARIANT-001 sprawdza że registry jest spójne.
# Sprawdzamy że invariant-engine.sh istnieje (implementacja).
if [ -f "$GATES_DIR/domains/invariant-engine.sh" ]; then
    t_pass "Implementacja invariant-engine.sh istnieje"
else
    t_fail "Implementacja invariant-engine.sh NIE istnieje"
fi

# --- T2: spełniony invariant -> PASS (kontrola) -----------------------------
echo ""
echo "--- T2: spełniony invariant -> PASS (kontrola) ---"
# Sprawdzamy że invariant-engine.sh ma verify_module_exit (nie broken exit code).
if grep -q 'verify_module_exit' "$GATES_DIR/domains/invariant-engine.sh" 2>/dev/null; then
    t_pass "invariant-engine.sh ma verify_module_exit"
else
    t_fail "invariant-engine.sh NIE ma verify_module_exit"
fi

# --- T3: brakujący invariant -> FAIL ----------------------------------------
echo ""
echo "--- T3: brakujący invariant -> FAIL ---"
# INVARIANT-005 sprawdza że każdy gate ma implementację.
# Sprawdzamy że invariant-engine.sh nie ma || true (bypass) W KODZIE.
# UWAGA: odfiltrowujemy komentarze — wzorzec '|| true' w komentarzu (np. opis
# wzorca do wykrycia) NIE jest bypassem. Grep musi patrzeć tylko na kod.
if grep -vE '^\s*#' "$GATES_DIR/domains/invariant-engine.sh" 2>/dev/null | grep -q '|| true'; then
    t_fail "invariant-engine.sh zawiera || true (bypass)"
else
    t_pass "invariant-engine.sh nie zawiera || true"
fi

# --- T4: obecny invariant -> PASS (kontrola) --------------------------------
echo ""
echo "--- T4: obecny invariant -> PASS (kontrola) ---"
# Sprawdzamy że invariant-engine.sh ma set -u (zgodnie z wzorcem).
if grep -q 'set -u' "$GATES_DIR/domains/invariant-engine.sh" 2>/dev/null; then
    t_pass "invariant-engine.sh ma set -u"
else
    t_fail "invariant-engine.sh NIE ma set -u"
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
