#!/usr/bin/env bash
# ============================================================================
# test-waiver-sweeper.sh — Waiver Sweeper tests
# ============================================================================
# Weryfikuje, że:
#   T1: Wygasły waiver (expires_at w przeszłości) zostaje USUNIĘTY
#   T2: Aktywny waiver (expires_at w przyszłości) zostaje
#   T3: Waiver bez expires_at (pusty string) zostaje zgłoszony jako FAIL (BLOCKING)
#   T4: Sweeper kończy się exit 0, gdy nie ma wygasłych/nielegalnych
#
# Użycie: ./test-waiver-sweeper.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"

# --- Kolory (z lib.sh) ------------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Izolacja: tymczasowa baza StateStore ----------------------------------
TEST_DATA_DIR="$(mktemp -d)"
STATE_DB="$TEST_DATA_DIR/canonical-state.db"

cleanup() { rm -rf "$TEST_DATA_DIR"; }
trap cleanup EXIT

echo "=== WAIVER SWEEPER TESTS ==="
echo "Test DB: $STATE_DB"

# --- Przygotowanie: baza z migracji 0001 + 0002 + 0003 ----------------------
MIGRATIONS_DIR="$SCRIPT_DIR/../../../system/control-plane/state/migrations"
for m in 0001_initial.sql 0002_history_hash.sql 0003_gate_runs_waivers.sql; do
    if ! sqlite3 "$STATE_DB" < "$MIGRATIONS_DIR/$m" 2>/dev/null; then
        echo "FATAL: nie udało się zastosować migracji $m"
        exit 1
    fi
done

# --- Wstaw testowe waivery --------------------------------------------------
# 1 wygasły (przeszłość), 1 aktywny (przyszłość), 1 bez expires_at (pusty string).
# Uwaga: kolumna expires_at ma NOT NULL, więc NULL jest odrzucany przez schema.
# Nielegalny waiver = pusty string '' (przechodzi przez NOT NULL, ale łamie
# zasadę "wyjątki wygasają" — sweeper musi go wykryć jako FAIL/BLOCKING).
sqlite3 "$STATE_DB" "INSERT INTO waivers (check_id, scope, justification, approved_by, expires_at) VALUES
    ('test:expired',   'module:test', 'wygasły', 'tester', datetime('now', '-1 day')),
    ('test:active',    'module:test', 'aktywny', 'tester', datetime('now', '+1 day')),
    ('test:noexpiry',  'module:test', 'bez wygaśnięcia', 'tester', '');" 2>/dev/null

# --- T1: Wygasły waiver zostaje usunięty ------------------------------------
echo ""
echo "--- T1: Wygasły waiver (przeszłość) zostaje USUNIĘTY ---"
VERIFY_STATE_DB="$STATE_DB" bash "$VERIFY_DIR/waivers/sweeper.sh" >/dev/null 2>&1
rc=$?
expired=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM waivers WHERE check_id='test:expired';" 2>/dev/null)
if [ "$expired" -eq 0 ]; then
    t_pass "Wygasły waiver usunięty (count=$expired)"
else
    t_fail "Wygasły waiver NIE usunięty (count=$expired)"
fi

# --- T2: Aktywny waiver zostaje ---------------------------------------------
echo ""
echo "--- T2: Aktywny waiver (przyszłość) zostaje ---"
active=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM waivers WHERE check_id='test:active';" 2>/dev/null)
if [ "$active" -eq 1 ]; then
    t_pass "Aktywny waiver pozostał (count=$active)"
else
    t_fail "Aktywny waiver NIE pozostał (count=$active)"
fi

# --- T3: Waiver bez expires_at → FAIL (BLOCKING) ----------------------------
echo ""
echo "--- T3: Waiver bez expires_at (pusty string) → FAIL (BLOCKING) ---"
# Sweeper musi zwrócić exit != 0, bo waiver bez expires_at jest NIELEGALNY.
if [ "$rc" -ne 0 ]; then
    t_pass "Sweeper zwrócił exit $rc (waiver bez expires_at → FAIL, BLOCKING)"
else
    t_fail "Sweeper zwrócił exit 0 (waiver bez expires_at NIE wykryty — FALSE GATE)"
fi

# --- T4: Sweeper bez wygasłych/nielegalnych → exit 0 -------------------------
echo ""
echo "--- T4: Sweeper bez wygasłych/nielegalnych → exit 0 ---"
# Usuń nielegalny waiver, żeby baza była czysta.
sqlite3 "$STATE_DB" "DELETE FROM waivers WHERE check_id='test:noexpiry';" 2>/dev/null
VERIFY_STATE_DB="$STATE_DB" bash "$VERIFY_DIR/waivers/sweeper.sh" >/dev/null 2>&1
rc2=$?
if [ "$rc2" -eq 0 ]; then
    t_pass "Sweeper zwrócił exit 0 przy czystej bazie"
else
    t_fail "Sweeper zwrócił exit $rc2 przy czystej bazie (oczekiwano 0)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== WAIVER SWEEPER — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
