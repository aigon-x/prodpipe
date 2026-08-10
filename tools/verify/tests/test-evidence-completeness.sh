#!/usr/bin/env bash
# ============================================================================
# test-evidence-completeness.sh — SELF-001 + Evidence Bridge tests
# ============================================================================
# Weryfikuje, że:
#   T1: SELF-001 wykrywa ghost moduły (zadeklarowane, a nieistniejące) → FAIL
#   T2: Evidence bridge zapisuje wynik SELF-001 do StateStore (P0#1)
#   T3: Moduł realny (git) przechodzi SELF-001 (istnieje)
#   T4: Meta-gate VERIFY-EVIDENCE-COMPLETE przechodzi, gdy evidence jest kompletne
#
# Użycie: ./test-evidence-completeness.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"

# --- Kolory (z lib.sh; załaduj wcześnie, żeby t_pass/t_fail działały) ------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Izolacja: tymczasowa baza StateStore ----------------------------------
TEST_DATA_DIR="$(mktemp -d)"
STATE_DATA_DIR="$TEST_DATA_DIR"
STATE_DB="$TEST_DATA_DIR/canonical-state.db"
export STATE_DATA_DIR STATE_DB

cleanup() { rm -rf "$TEST_DATA_DIR"; }
trap cleanup EXIT

echo "=== SELF-001 + EVIDENCE BRIDGE TESTS ==="
echo "Test DB: $STATE_DB"

# --- Przygotowanie: zainicjalizuj izolowaną bazę ---------------------------
# Uwaga: NIE używamy `state.sh init` — state/lib.sh twardo nadpisuje
# STATE_DATA_DIR/STATE_DB, więc izolacja przez override nie zadziała.
# Zamiast tego tworzymy bazę ręcznie z migracji (0001 + 0002).
MIGRATIONS_DIR="$SCRIPT_DIR/../../../system/control-plane/state/migrations"
if ! sqlite3 "$STATE_DB" < "$MIGRATIONS_DIR/0001_initial.sql" 2>/dev/null; then
    echo "FATAL: nie udało się utworzyć bazy z 0001_initial.sql"
    exit 1
fi
if ! sqlite3 "$STATE_DB" < "$MIGRATIONS_DIR/0002_history_hash.sql" 2>/dev/null; then
    echo "FATAL: nie udało się zastosować 0002_history_hash.sql"
    exit 1
fi

# --- T1: SELF-001 wykrywa ghost moduły → FAIL ------------------------------
echo ""
echo "--- T1: SELF-001 ghost detection (moduł zadeklarowany, a nieistniejący) ---"
# Uruchom SELF-001 z izolowaną bazą. Ghost moduły (architecture, dependencies,
# reproducibility, deployment, contracts, migration, recovery) są zadeklarowane
# w VERIFY_MODULES, ale ich skrypty NIE istnieją → muszą dać FAIL (BLOCKING).
VERIFY_STATE_DB="$STATE_DB" bash "$VERIFY_DIR/self-profile-integrity.sh" >/dev/null 2>&1
rc=$?
if [ "$rc" -ne 0 ]; then
    t_pass "SELF-001 zwrócił exit $rc (ghost moduły → FAIL, fail-closed)"
else
    t_fail "SELF-001 zwrócił exit 0 (ghost moduły NIE wykryte — FALSE GATE)"
fi

# --- T2: Evidence bridge zapisuje wynik do StateStore ----------------------
echo ""
echo "--- T2: Evidence bridge (P0#1) — wynik SELF-001 w StateStore ---"
ev=$(sqlite3 "$STATE_DB" "SELECT claim FROM evidence WHERE source_ref='self-profile-integrity.sh' ORDER BY recorded_at DESC LIMIT 1;" 2>/dev/null)
if [ -n "$ev" ] && [[ "$ev" == *"self-profile-integrity:FAIL"* ]] && [[ "$ev" == *"missing="* ]]; then
    t_pass "Evidence zapisane: $ev"
else
    t_fail "Evidence NIE zapisane lub błędne: '$ev'"
fi

# --- T3: Moduł realny (git) przechodzi SELF-001 ----------------------------
echo ""
echo "--- T3: Moduł realny (git) istnieje → PASS ---"
# SELF-001 iteruje po VERIFY_MODULES. Moduł 'git' jest zadeklarowany i jego
# skrypt (git/integrity.sh) istnieje → musi być PASS (nie FAIL).
# Weryfikujemy przez bezpośrednie sprawdzenie, że skrypt istnieje.
if [ -f "$VERIFY_DIR/git/integrity.sh" ]; then
    t_pass "Skrypt git/integrity.sh istnieje (moduł realny)"
else
    t_fail "Skrypt git/integrity.sh NIE istnieje"
fi

# --- T4: Meta-gate VERIFY-EVIDENCE-COMPLETE --------------------------------
echo ""
echo "--- T4: Meta-gate VERIFY-EVIDENCE-COMPLETE (gate bez evidence = 0 pkt) ---"
# Symulacja: zapisz 2 evidence, oczekuj PASS przy expected=2.
VERIFY_STATE_DB="$STATE_DB"
VERIFY_EVIDENCE_COUNT=0
evidence_record "test:meta-gate:1" "verify" "test.sh" >/dev/null 2>&1
evidence_record "test:meta-gate:2" "verify" "test.sh" >/dev/null 2>&1
if verify_evidence_complete 2 >/dev/null 2>&1; then
    t_pass "VERIFY-EVIDENCE-COMPLETE przechodzi przy kompletnej evidence"
else
    t_fail "VERIFY-EVIDENCE-COMPLETE NIE przeszedł przy kompletnej evidence"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== SELF-001 + EVIDENCE BRIDGE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
