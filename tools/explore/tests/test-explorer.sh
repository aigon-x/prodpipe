#!/usr/bin/env bash
# ============================================================================
# test-explorer.sh — NEGATIVE/POSITIVE TESTS for explore.sh CLI
# ============================================================================
# Testuje że explore.sh CLI ma wymagane komendy i zachowania:
#   T1: explore.sh help działa (exit 0) -> PASS
#   T2: explore.sh z nieznaną komendą zwraca exit 2 -> PASS
#   T3: explore.sh ma komendę all (GŁÓWNA KOMENDA) -> PASS
#   T4: explore.sh ma komendę scan -> PASS
#   T5: explore.sh ma komendę build -> PASS
#   T6: explore.sh ma komendę docs -> PASS
#   T7: explore.sh ma komendę graphs -> PASS
#   T8: explore.sh ma komendę html -> PASS
#   T9: explore.sh ma komendę validate -> PASS
#   T10: explore.sh ma komendę status -> PASS
#
# Użycie: ./test-explorer.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== TESTS — explore.sh CLI ==="

EXPLORE_SH="$ROOT/tools/explore/explore.sh"

# --- T1: explore.sh help działa (exit 0) ------------------------------------
echo ""
echo "--- T1: explore.sh help działa (exit 0) ---"
if [ -f "$EXPLORE_SH" ]; then
    if bash "$EXPLORE_SH" help >/dev/null 2>&1; then
        t_pass "explore.sh help zwraca exit 0"
    else
        t_fail "explore.sh help nie zwraca exit 0"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T2: explore.sh z nieznaną komendą zwraca exit 2 -------------------------
echo ""
echo "--- T2: explore.sh z nieznaną komendą zwraca exit 2 ---"
if [ -f "$EXPLORE_SH" ]; then
    bash "$EXPLORE_SH" nieznana-komenda >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 2 ]; then
        t_pass "explore.sh nieznana-komenda zwraca exit 2"
    else
        t_fail "explore.sh nieznana-komenda zwraca exit $rc (oczekiwano 2)"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T3: explore.sh ma komendę all (GŁÓWNA KOMENDA) --------------------------
echo ""
echo "--- T3: explore.sh ma komendę all (GŁÓWNA KOMENDA) ---"
if [ -f "$EXPLORE_SH" ]; then
    if grep -qE 'explore_all\(\)' "$EXPLORE_SH" 2>/dev/null \
       && grep -qE 'all\)' "$EXPLORE_SH" 2>/dev/null; then
        t_pass "explore.sh ma komendę all"
    else
        t_fail "explore.sh bez komendy all"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T4-T10: explore.sh ma pozostałe komendy ---------------------------------
echo ""
echo "--- T4-T10: explore.sh ma komendy scan/build/docs/graphs/html/validate/status ---"
if [ -f "$EXPLORE_SH" ]; then
    MISSING=0
    for cmd in scan build docs graphs html validate status; do
        if ! grep -qE "^[[:space:]]*$cmd\)" "$EXPLORE_SH" 2>/dev/null; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak komendy %s\n' "$cmd"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "explore.sh ma komendy scan/build/docs/graphs/html/validate/status"
    else
        t_fail "Brak $MISSING komend w explore.sh"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
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
