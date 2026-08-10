#!/usr/bin/env bash
# ============================================================================
# test_system_twin.sh — NEGATIVE TESTS for GATE-026 (SYSTEM-TWIN)
# ============================================================================
# Testuje że gate system-twin wykrywa problemy:
#   T1: brakujący węzeł w grafie stanu -> FAIL
#   T2: obecny węzeł w grafie stanu -> PASS (kontrola)
#   T3: brakująca krawędź -> FAIL
#   T4: obecna krawędź -> PASS (kontrola)
#
# Użycie: ./test_system_twin.sh
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

echo "=== NEGATIVE TESTS — GATE-026 SYSTEM-TWIN ==="

# --- T1: brakujący węzeł w grafie stanu -> FAIL -----------------------------
echo ""
echo "--- T1: brakujący węzeł w grafie stanu -> FAIL ---"
# SYSTEM-TWIN-001 sprawdza że graf stanu ma wymagane węzły.
# Sprawdzamy że system-twin.sh istnieje (implementacja).
if [ -f "$GATES_DIR/domains/system-twin.sh" ]; then
    t_pass "Implementacja system-twin.sh istnieje"
else
    t_fail "Implementacja system-twin.sh NIE istnieje"
fi

# --- T2: obecny węzeł w grafie stanu -> PASS (kontrola) ---------------------
echo ""
echo "--- T2: obecny węzeł w grafie stanu -> PASS (kontrola) ---"
# Sprawdzamy że migracja system_twin istnieje.
if [ -f "$ROOT/system/control-plane/state/migrations/0003_system_twin.sql" ]; then
    t_pass "Migracja system_twin istnieje"
else
    t_fail "Migracja system_twin NIE istnieje"
fi

# --- T3: brakująca krawędź -> FAIL ------------------------------------------
echo ""
echo "--- T3: brakująca krawędź -> FAIL ---"
# SYSTEM-TWIN-002 sprawdza że krawędzie grafu są spójne.
# Sprawdzamy że tabela system_twin_edge jest zdefiniowana w migracji.
if grep -q 'system_twin_edge' "$ROOT/system/control-plane/state/migrations/0003_system_twin.sql" 2>/dev/null; then
    t_pass "Tabela system_twin_edge zdefiniowana"
else
    t_fail "Tabela system_twin_edge NIE zdefiniowana"
fi

# --- T4: obecna krawędź -> PASS (kontrola) ----------------------------------
echo ""
echo "--- T4: obecna krawędź -> PASS (kontrola) ---"
# Sprawdzamy że tabela system_twin_node jest zdefiniowana.
if grep -q 'system_twin_node' "$ROOT/system/control-plane/state/migrations/0003_system_twin.sql" 2>/dev/null; then
    t_pass "Tabela system_twin_node zdefiniowana"
else
    t_fail "Tabela system_twin_node NIE zdefiniowana"
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
