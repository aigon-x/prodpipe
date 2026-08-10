#!/usr/bin/env bash
# ============================================================================
# test-obs-dashboards.sh — OBS-BASELINE — DASHBOARDS GATE tests (OBS-15)
# ============================================================================
# Weryfikuje, że:
#   T1: tier 3 (świeży projekt) → dashboardy nieobowiązkowe, PASS (rc=0)
#   T2: tier 1 + zadeklarowany dashboard → PASS (rc=0)
#   T3: tier 1 + brak dashboardu → FAIL (rc != 0)
#
# Użycie: ./test-obs-dashboards.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-dashboards-check.sh"
DASHBOARDS_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/dashboards.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z .skeleton.yaml + dashboards.yaml --
# Argumenty: <katalog_docelowy> <tier> <dashboards_yaml>
make_isolated_repo() {
  local dir="$1" tier="$2" dash="$3"
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
  cp "$dash" "$dir/config/canonical/dashboards.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add dashboards" )
}

echo "=== OBS-BASELINE — DASHBOARDS GATE TESTS ==="

# ── T1: tier 3 → dashboardy nieobowiązkowe, PASS ───────────────────────────
echo ""
echo "--- T1: tier 3 → dashboardy nieobowiązkowe (rc=0, brak FAIL) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "3" "$DASHBOARDS_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "tier 3 → dashboardy nieobowiązkowe (rc=$T1_RC)"
else
  t_fail "tier 3 NIE przeszedł (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -15
fi

# ── T2: tier 1 + zadeklarowany dashboard → PASS ────────────────────────────
echo ""
echo "--- T2: tier 1 + zadeklarowany dashboard → PASS (rc=0) ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR/repo" "1" "$DASHBOARDS_SRC"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -eq 0 ] \
   && printf '%s' "$T2_OUT" | grep -q "OBS-15 Dashboards" \
   && ! printf '%s' "$T2_OUT" | grep -q "\[FAIL\]"; then
  t_pass "tier 1 + dashboard → PASS (rc=$T2_RC)"
else
  t_fail "tier 1 + dashboard NIE przeszedł (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: tier 1 + brak dashboardu → FAIL ────────────────────────────────────
echo ""
echo "--- T3: tier 1 + brak dashboardu → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Pusty manifest dashboardów (bez path).
T3_DASH="$T3_DIR/dash-empty.yaml"
mkdir -p "$T3_DIR"
cat > "$T3_DASH" <<'EOF'
schema_version: 1
dashboards: []
EOF
make_isolated_repo "$T3_DIR/repo" "1" "$T3_DASH"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-15"; then
  t_pass "tier 1 + brak dashboardu → FAIL (rc=$T3_RC)"
else
  t_fail "tier 1 + brak dashboardu NIE wykrył braku (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — DASHBOARDS GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
