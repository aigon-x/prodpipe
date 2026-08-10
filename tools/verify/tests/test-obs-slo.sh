#!/usr/bin/env bash
# ============================================================================
# test-obs-slo.sh — OBS-BASELINE — SLO GATE tests (OBS-14)
# ============================================================================
# Weryfikuje, że:
#   T1: obs-slo-check.sh przechodzi na świeżym projekcie (PASS, rc=0)
#   T2: OBS-14 wykrywa SLO bez alert_ref → FAIL
#   T3: OBS-14 wykrywa target poza zakresem (>1) → FAIL
#   T4: OBS-14 wykrywa target poniżej floor tier → FAIL
#
# Użycie: ./test-obs-slo.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-slo-check.sh"
SLO_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/slo.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z .skeleton.yaml + slo.yaml ---------
# Argumenty: <katalog_docelowy> <tier> <slo_yaml>
make_isolated_repo() {
  local dir="$1" tier="$2" slo="$3"
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "OBS Test" )
  cat > "$dir/.skeleton.yaml" <<EOF
web: false
events: false
tier: $tier
service_id: "template"
EOF
  cp "$slo" "$dir/config/canonical/slo.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add slo" )
}

echo "=== OBS-BASELINE — SLO GATE TESTS ==="

# ── T1: moduł przechodzi na świeżym projekcie ──────────────────────────────
echo ""
echo "--- T1: obs-slo-check.sh PASS na świeżym projekcie (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "3" "$SLO_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "OBS-14 SLO targets" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał OBS-14 bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -20
fi

# ── T2: OBS-14 wykrywa SLO bez alert_ref ───────────────────────────────────
echo ""
echo "--- T2: OBS-14 wykrywa SLO bez alert_ref → FAIL (rc != 0) ---"
T2_DIR="$(mktemp -d)"
# Usuń alert_ref z pierwszego SLO.
T2_SLO="$T2_DIR/slo-noalert.yaml"
mkdir -p "$T2_DIR"
sed '0,/^    alert_ref:/{/^    alert_ref:/d}' "$SLO_SRC" > "$T2_SLO"
make_isolated_repo "$T2_DIR/repo" "3" "$T2_SLO"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] OBS-14"; then
  t_pass "OBS-14 wykrył SLO bez alert_ref (rc=$T2_RC)"
else
  t_fail "OBS-14 NIE wykrył SLO bez alert_ref (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: OBS-14 wykrywa target poza zakresem (>1) ───────────────────────────
echo ""
echo "--- T3: OBS-14 wykrywa target > 1 → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Zmień target pierwszego SLO na 1.5 (poza zakresem).
T3_SLO="$T3_DIR/slo-badtarget.yaml"
mkdir -p "$T3_DIR"
sed '0,/target: 0.99/s//target: 1.5/' "$SLO_SRC" > "$T3_SLO"
make_isolated_repo "$T3_DIR/repo" "3" "$T3_SLO"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-14"; then
  t_pass "OBS-14 wykrył target poza zakresem (rc=$T3_RC)"
else
  t_fail "OBS-14 NIE wykrył targetu poza zakresem (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── T4: OBS-14 wykrywa target poniżej floor tier ───────────────────────────
echo ""
echo "--- T4: OBS-14 wykrywa target poniżej floor tier 1 → FAIL ---"
T4_DIR="$(mktemp -d)"
# tier 1 → floor 0.99. Zmień target pierwszego SLO na 0.95 (poniżej floor).
T4_SLO="$T4_DIR/slo-belowfloor.yaml"
mkdir -p "$T4_DIR"
sed '0,/target: 0.99/s//target: 0.95/' "$SLO_SRC" > "$T4_SLO"
make_isolated_repo "$T4_DIR/repo" "1" "$T4_SLO"
T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] OBS-14"; then
  t_pass "OBS-14 wykrył target poniżej floor tier (rc=$T4_RC)"
else
  t_fail "OBS-14 NIE wykrył targetu poniżej floor tier (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — SLO GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
