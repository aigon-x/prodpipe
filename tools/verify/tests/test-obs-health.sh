#!/usr/bin/env bash
# ============================================================================
# test-obs-health.sh — OBS-BASELINE — HEALTH ENDPOINTS GATE tests (OBS-10)
# ============================================================================
# Weryfikuje, że:
#   T1: web:false → moduł robi SKIP (rc=0, evidence N/A, brak FAIL)
#   T2: web:true + healthz/readyz zadeklarowane → PASS (rc=0)
#   T3: web:true + brak readyz → FAIL (rc != 0)
#
# Użycie: ./test-obs-health.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
OBS_CHECK="$VERIFY_DIR/obs-health-endpoints.sh"
OBSERVABILITY_SRC="$(cd "$VERIFY_DIR/../.." && pwd)/config/canonical/observability.yaml"

# --- Kolory (z lib.sh) -----------------------------------------------------
# shellcheck source=core/lib.sh
. "$VERIFY_DIR/core/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Helper: buduje izolowane repo git z .skeleton.yaml + observability.yaml
# Argumenty: <katalog_docelowy> <web_flag> <obs_yaml>
make_isolated_repo() {
  local dir="$1" web="$2" obs="$3"
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "OBS Test" )
  cat > "$dir/.skeleton.yaml" <<EOF
web: $web
events: false
tier: 3
service_id: "template"
EOF
  cp "$obs" "$dir/config/canonical/observability.yaml"
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add skeleton" )
}

echo "=== OBS-BASELINE — HEALTH ENDPOINTS GATE TESTS ==="

# ── T1: web:false → SKIP ───────────────────────────────────────────────────
echo ""
echo "--- T1: web:false → moduł robi SKIP (rc=0, brak FAIL) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR"' EXIT
make_isolated_repo "$T1_DIR/repo" "false" "$OBSERVABILITY_SRC"
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "SKIP" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "web:false → SKIP bez FAIL (rc=$T1_RC)"
else
  t_fail "web:false NIE zrobił SKIP (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -15
fi

# ── T2: web:true + healthz/readyz → PASS ───────────────────────────────────
echo ""
echo "--- T2: web:true + healthz/readyz zadeklarowane → PASS (rc=0) ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR/repo" "true" "$OBSERVABILITY_SRC"
T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -eq 0 ] \
   && printf '%s' "$T2_OUT" | grep -q "OBS-10 Health endpoints" \
   && ! printf '%s' "$T2_OUT" | grep -q "\[FAIL\]"; then
  t_pass "web:true + healthz/readyz → PASS (rc=$T2_RC)"
else
  t_fail "web:true + healthz/readyz NIE przeszedł (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -15
fi

# ── T3: web:true + brak readyz → FAIL ──────────────────────────────────────
echo ""
echo "--- T3: web:true + brak readyz → FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
# Usuń sekcję health (readyz) z observability.yaml.
T3_OBS="$T3_DIR/obs-nohealth.yaml"
mkdir -p "$T3_DIR"
sed '/^health:/,/^deadman:/{/^health:/d; /^  liveness:/d; /^  readiness:/d;}' "$OBSERVABILITY_SRC" > "$T3_OBS"
make_isolated_repo "$T3_DIR/repo" "true" "$T3_OBS"
T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$OBS_CHECK" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] OBS-10"; then
  t_pass "web:true + brak readyz → FAIL (rc=$T3_RC)"
else
  t_fail "web:true + brak readyz NIE wykrył braku (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -15
fi

# ── Podsumowanie -----------------------------------------------------------
echo ""
echo "=== OBS-BASELINE — HEALTH ENDPOINTS GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
