#!/usr/bin/env bash
# ============================================================================
# test-obs-deadman.sh — OBS-BASELINE — DEADMAN SWITCH GATE tests (OBS-13)
# ============================================================================
# Weryfikuje, że:
#   T1: tier 3 (świeży projekt) → deadman nieobowiązkowy, PASS (rc=0)
#   T2: tier 1 + kompletny deadman → PASS (rc=0)
#   T3: tier 1 + brak deadman → FAIL (rc != 0)
#   T4: tier 1 + niekompletny deadman (brak alert_ref) → FAIL (rc != 0)
#
# Użycie: ./test-obs-deadman.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-deadman-check.sh"
OBSERVABILITY_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/observability.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z .skeleton.yaml + observability.yaml
# Argumenty: <katalog_docelowy> <tier> <obs_yaml>
make_isolated_repo() {
  local dir="$1" tier="$2" obs="$3"
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
  cp "$obs" "$dir/config/canonical/observability.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add skeleton" )
}

echo "=== OBS-BASELINE — DEADMAN SWITCH GATE TESTS ==="

# ── T1: tier 3 → deadman nieobowiązkowy, PASS ──────────────────────────────
echo ""
echo "--- T1: tier 3 → deadman nieobowiązkowy (rc=0, brak FAIL) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "3" "$OBSERVABILITY_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "tier 3 → deadman nieobowiązkowy (rc=$T1_RC)"
else
  t_fail "tier 3 NIE przeszedł (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -15
fi

# ── T2: tier 1 + kompletny deadman → PASS ──────────────────────────────────
echo ""
echo "--- T2: tier 1 + kompletny deadman → PASS (rc=0) ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR/repo" "1" "$OBSERVABILITY_SRC"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -eq 0 ] \
   && printf '%s' "$T2_OUT" | grep -q "OBS-13 Deadman switch" \
   && ! printf '%s' "$T2_OUT" | grep -q "\[FAIL\]"; then
  t_pass "tier 1 + kompletny deadman → PASS (rc=$T2_RC)"
else
  t_fail "tier 1 + kompletny deadman NIE przeszedł (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: tier 1 + brak deadman → FAIL ───────────────────────────────────────
echo ""
echo "--- T3: tier 1 + brak deadman → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Usuń sekcję deadman z observability.yaml.
T3_OBS="$T3_DIR/obs-nodeadman.yaml"
mkdir -p "$T3_DIR"
sed '/^deadman:/,/^[a-z]/d' "$OBSERVABILITY_SRC" > "$T3_OBS"
make_isolated_repo "$T3_DIR/repo" "1" "$T3_OBS"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-13"; then
  t_pass "tier 1 + brak deadman → FAIL (rc=$T3_RC)"
else
  t_fail "tier 1 + brak deadman NIE wykrył braku (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── T4: tier 1 + niekompletny deadman (brak alert_ref) → FAIL ──────────────
echo ""
echo "--- T4: tier 1 + niekompletny deadman (brak alert_ref) → FAIL ---"
T4_DIR="$(mktemp -d)"
# Usuń alert_ref z sekcji deadman.
T4_OBS="$T4_DIR/obs-incomplete-deadman.yaml"
mkdir -p "$T4_DIR"
sed '0,/^  alert_ref:/{/^  alert_ref:/d}' "$OBSERVABILITY_SRC" > "$T4_OBS"
make_isolated_repo "$T4_DIR/repo" "1" "$T4_OBS"
T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] OBS-13"; then
  t_pass "tier 1 + niekompletny deadman → FAIL (rc=$T4_RC)"
else
  t_fail "tier 1 + niekompletny deadman NIE wykrył braku (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — DEADMAN SWITCH GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
