#!/usr/bin/env bash
# ============================================================================
# test-obs-alerts.sh — OBS-BASELINE — ALERTS GATE tests (OBS-05, OBS-11, OBS-12)
# ============================================================================
# Weryfikuje, że:
#   T1: obs-alerts-check.sh przechodzi na świeżym projekcie (PASS, rc=0)
#   T2: OBS-05 wykrywa alert bez runbook_ref → FAIL
#   T3: OBS-11 wykrywa alert bez owner → FAIL
#   T4: OBS-12 wykrywa alert z niedozwoloną severity → FAIL
#
# Użycie: ./test-obs-alerts.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-alerts-check.sh"
ALERTS_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/alerts/_template.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z plikiem alertów -------------------
# Argumenty: <katalog_docelowy> <plik_alertów>
make_isolated_repo() {
  local dir="$1" alerts="$2"
  mkdir -p "$dir/config/canonical/alerts"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "OBS Test" )
  cp "$alerts" "$dir/config/canonical/alerts/alerts.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add alerts" )
}

echo "=== OBS-BASELINE — ALERTS GATE TESTS ==="

# ── T1: moduł przechodzi na świeżym projekcie ──────────────────────────────
echo ""
echo "--- T1: obs-alerts-check.sh PASS na świeżym projekcie (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "$ALERTS_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "OBS-05 Alerts have runbook" \
   && printf '%s' "$T1_OUT" | grep -q "OBS-11 Alerts have owner" \
   && printf '%s' "$T1_OUT" | grep -q "OBS-12 Alerts have severity" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał OBS-05/11/12 bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -20
fi

# ── T2: OBS-05 wykrywa alert bez runbook_ref ───────────────────────────────
echo ""
echo "--- T2: OBS-05 wykrywa alert bez runbook_ref → FAIL (rc != 0) ---"
T2_DIR="$(mktemp -d)"
# Usuń runbook_ref z pierwszego alertu.
T2_ALERTS="$T2_DIR/alerts-norunbook.yaml"
mkdir -p "$T2_DIR"
sed '0,/^    runbook_ref:/{/^    runbook_ref:/d}' "$ALERTS_SRC" > "$T2_ALERTS"
make_isolated_repo "$T2_DIR/repo" "$T2_ALERTS"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] OBS-05"; then
  t_pass "OBS-05 wykrył alert bez runbook_ref (rc=$T2_RC)"
else
  t_fail "OBS-05 NIE wykrył alertu bez runbook_ref (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: OBS-11 wykrywa alert bez owner ─────────────────────────────────────
echo ""
echo "--- T3: OBS-11 wykrywa alert bez owner → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Usuń owner z pierwszego alertu.
T3_ALERTS="$T3_DIR/alerts-noowner.yaml"
mkdir -p "$T3_DIR"
sed '0,/^    owner:/{/^    owner:/d}' "$ALERTS_SRC" > "$T3_ALERTS"
make_isolated_repo "$T3_DIR/repo" "$T3_ALERTS"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-11"; then
  t_pass "OBS-11 wykrył alert bez owner (rc=$T3_RC)"
else
  t_fail "OBS-11 NIE wykrył alertu bez owner (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── T4: OBS-12 wykrywa niedozwoloną severity ───────────────────────────────
echo ""
echo "--- T4: OBS-12 wykrywa niedozwoloną severity → FAIL (rc != 0) ---"
T4_DIR="$(mktemp -d)"
# Zmień severity pierwszego alertu na niedozwolone.
T4_ALERTS="$T4_DIR/alerts-badseverity.yaml"
mkdir -p "$T4_DIR"
sed '0,/severity: "critical"/s//severity: "fatal"/' "$ALERTS_SRC" > "$T4_ALERTS"
make_isolated_repo "$T4_DIR/repo" "$T4_ALERTS"
T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] OBS-12"; then
  t_pass "OBS-12 wykrył niedozwoloną severity (rc=$T4_RC)"
else
  t_fail "OBS-12 NIE wykrył niedozwolonej severity (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — ALERTS GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
