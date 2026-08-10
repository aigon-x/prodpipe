#!/usr/bin/env bash
# ============================================================================
# test-obs-metrics.sh — OBS-BASELINE — METRICS GATE tests (OBS-03, OBS-06)
# ============================================================================
# Weryfikuje, że:
#   T1: obs-metrics-check.sh przechodzi na świeżym projekcie (PASS, rc=0)
#   T2: OBS-06 wykrywa metrykę bez definicji (brak unit) → FAIL
#   T3: OBS-03 wykrywa zabronioną etykietę o wysokiej kardynalności → FAIL
#   T4: OBS-03 wykrywa złą konwencję nazw (metryka bez unit) → FAIL
#
# Użycie: ./test-obs-metrics.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-metrics-check.sh"
OBSERVABILITY_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/observability.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z observability.yaml ----------------
# Argumenty: <katalog_docelowy> <plik_observability>
make_isolated_repo() {
  local dir="$1" obs="$2"
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "OBS Test" )
  cp "$obs" "$dir/config/canonical/observability.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add observability" )
}

echo "=== OBS-BASELINE — METRICS GATE TESTS ==="

# ── T1: moduł przechodzi na świeżym projekcie ──────────────────────────────
echo ""
echo "--- T1: obs-metrics-check.sh PASS na świeżym projekcie (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "$OBSERVABILITY_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "OBS-03 Metric naming" \
   && printf '%s' "$T1_OUT" | grep -q "OBS-06 Metric definitions" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał OBS-03/06 bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -20
fi

# ── T2: OBS-06 wykrywa metrykę bez definicji (brak unit) ───────────────────
echo ""
echo "--- T2: OBS-06 wykrywa metrykę bez unit → FAIL (rc != 0) ---"
T2_DIR="$(mktemp -d)"
# Usuń 'unit' z pierwszej metryki.
T2_OBS="$T2_DIR/obs-nounit.yaml"
mkdir -p "$T2_DIR"
sed '0,/^    unit:/{/^    unit:/d}' "$OBSERVABILITY_SRC" > "$T2_OBS"
make_isolated_repo "$T2_DIR/repo" "$T2_OBS"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] OBS-06"; then
  t_pass "OBS-06 wykrył metrykę bez unit (rc=$T2_RC)"
else
  t_fail "OBS-06 NIE wykrył metryki bez unit (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: OBS-03 wykrywa zabronioną etykietę o wysokiej kardynalności ────────
echo ""
echo "--- T3: OBS-03 wykrywa zabronioną etykietę (user_id) → FAIL ---"
T3_DIR="$(mktemp -d)"
# Dodaj user_id do labels pierwszej metryki.
T3_OBS="$T3_DIR/obs-highcard.yaml"
mkdir -p "$T3_DIR"
sed '0,/labels: \["method", "status", "endpoint"\]/s//labels: ["method", "status", "endpoint", "user_id"]/' "$OBSERVABILITY_SRC" > "$T3_OBS"
make_isolated_repo "$T3_DIR/repo" "$T3_OBS"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-03"; then
  t_pass "OBS-03 wykrył zabronioną etykietę user_id (rc=$T3_RC)"
else
  t_fail "OBS-03 NIE wykrył zabronionej etykiety user_id (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── T4: OBS-03 wykrywa złą konwencję nazw ──────────────────────────────────
echo ""
echo "--- T4: OBS-03 wykrywa metrykę bez unit w nazwie → FAIL ---"
T4_DIR="$(mktemp -d)"
# Zmień nazwę pierwszej metryki na 'template_requests' (bez _total).
T4_OBS="$T4_DIR/obs-badname.yaml"
mkdir -p "$T4_DIR"
sed '0,/name: "template_requests_total"/s//name: "template_requests"/' "$OBSERVABILITY_SRC" > "$T4_OBS"
make_isolated_repo "$T4_DIR/repo" "$T4_OBS"
T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] OBS-03"; then
  t_pass "OBS-03 wykrył złą konwencję nazw (rc=$T4_RC)"
else
  t_fail "OBS-03 NIE wykrył złej konwencji nazw (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — METRICS GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
