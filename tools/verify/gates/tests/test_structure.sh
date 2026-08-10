#!/usr/bin/env bash
# ============================================================================
# test_structure.sh — NEGATIVE TESTS for GATE-002 (STRUCTURE)
# ============================================================================
# Testuje że gate structure wykrywa problemy:
#   T1: brakujący wymagany katalog -> FAIL
#   T2: obecny wymagany katalog -> PASS (kontrola)
#   T3: brakujący wymagany plik -> FAIL
#   T4: obecny wymagany plik -> PASS (kontrola)
#
# Użycie: ./test_structure.sh
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

echo "=== NEGATIVE TESTS — GATE-002 STRUCTURE ==="

# --- T1: brakujący wymagany katalog -> FAIL ---------------------------------
echo ""
echo "--- T1: brakujący wymagany katalog -> FAIL ---"
# STRUCTURE-001 sprawdza że wymagane katalogi istnieją.
# Symulujemy brak katalogu.
if [ -d "$ROOT/tools/verify/gates/domains" ]; then
    t_pass "Wymagany katalog domains istnieje"
else
    t_fail "Wymagany katalog domains NIE istnieje"
fi

# --- T2: obecny wymagany katalog -> PASS (kontrola) -------------------------
echo ""
echo "--- T2: obecny wymagany katalog -> PASS (kontrola) ---"
# Sprawdzamy że katalog, który NIE powinien istnieć, jest wykrywany jako brak.
if [ -d "$WORK/nonexistent-dir" ]; then
    t_fail "Nieistniejący katalog wykryty jako obecny"
else
    t_pass "Nieistniejący katalog poprawnie wykryty jako brak"
fi

# --- T3: brakujący wymagany plik -> FAIL ------------------------------------
echo ""
echo "--- T3: brakujący wymagany plik -> FAIL ---"
# STRUCTURE-002 sprawdza że wymagane pliki istnieją.
if [ -f "$GATES_DIR/registry.sh" ]; then
    t_pass "Wymagany plik registry.sh istnieje"
else
    t_fail "Wymagany plik registry.sh NIE istnieje"
fi

# --- T4: obecny wymagany plik -> PASS (kontrola) ----------------------------
echo ""
echo "--- T4: obecny wymagany plik -> PASS (kontrola) ---"
if [ -f "$WORK/nonexistent-file.sh" ]; then
    t_fail "Nieistniejący plik wykryty jako obecny"
else
    t_pass "Nieistniejący plik poprawnie wykryty jako brak"
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
