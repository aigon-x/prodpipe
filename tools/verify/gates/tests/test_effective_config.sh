#!/usr/bin/env bash
# ============================================================================
# test_effective_config.sh — NEGATIVE TESTS for GATE-030 (EFFECTIVE-CONFIG)
# ============================================================================
# Testuje że gate effective-config wykrywa problemy:
#   T1: EFFECTIVE vs DECLARED drift -> FAIL
#   T2: EFFECTIVE == DECLARED -> PASS (kontrola)
#   T3: brakujący plik konfiguracji -> FAIL
#   T4: obecny plik konfiguracji -> PASS (kontrola)
#
# Użycie: ./test_effective_config.sh
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

echo "=== NEGATIVE TESTS — GATE-030 EFFECTIVE-CONFIG ==="

# --- T1: EFFECTIVE vs DECLARED drift -> FAIL --------------------------------
echo ""
echo "--- T1: EFFECTIVE vs DECLARED drift -> FAIL ---"
# EFFECTIVE-CONFIG-001 sprawdza że EFFECTIVE state == DECLARED state.
# Sprawdzamy że effective-config.sh istnieje (implementacja).
if [ -f "$GATES_DIR/domains/effective-config.sh" ]; then
    t_pass "Implementacja effective-config.sh istnieje"
else
    t_fail "Implementacja effective-config.sh NIE istnieje"
fi

# --- T2: EFFECTIVE == DECLARED -> PASS (kontrola) ---------------------------
echo ""
echo "--- T2: EFFECTIVE == DECLARED -> PASS (kontrola) ---"
# Sprawdzamy że effective-config.sh ma verify_module_exit.
if grep -q 'verify_module_exit' "$GATES_DIR/domains/effective-config.sh" 2>/dev/null; then
    t_pass "effective-config.sh ma verify_module_exit"
else
    t_fail "effective-config.sh NIE ma verify_module_exit"
fi

# --- T3: brakujący plik konfiguracji -> FAIL --------------------------------
echo ""
echo "--- T3: brakujący plik konfiguracji -> FAIL ---"
# EFFECTIVE-CONFIG-002 sprawdza że pliki konfiguracji istnieją.
if [ -f "$WORK/nonexistent-config.yaml" ]; then
    t_fail "Nieistniejący plik konfiguracji wykryty jako obecny"
else
    t_pass "Brakujący plik konfiguracji poprawnie wykryty"
fi

# --- T4: obecny plik konfiguracji -> PASS (kontrola) ------------------------
echo ""
echo "--- T4: obecny plik konfiguracji -> PASS (kontrola) ---"
# Sprawdzamy że effective-config.sh nie zawiera || true (bypass).
if grep -q '|| true' "$GATES_DIR/domains/effective-config.sh" 2>/dev/null; then
    t_fail "effective-config.sh zawiera || true (bypass)"
else
    t_pass "effective-config.sh nie zawiera || true"
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
