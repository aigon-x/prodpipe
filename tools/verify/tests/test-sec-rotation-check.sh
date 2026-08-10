#!/usr/bin/env bash
# ============================================================================
# test-sec-rotation-check.sh — SEC-BASELINE credential rotation
# ============================================================================
# Weryfikuje moduł tools/verify/security/sec-rotation-check.sh:
#   T1: moduł działa na prawdziwym rejestrze (rc=0, SEC-ROT-01..02 PASS)
#   T2: fail-closed — brak rejestru → SEC-ROT-01 FAIL (rc != 0)
#   T3: fail-closed — przeterminowana data rotacji bez statusu rotating
#       → SEC-ROT-02 FAIL (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują rejestr, więc nie dotykają prawdziwego
# repo. Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-sec-rotation-check.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
MODULE="$VERIFY_DIR/security/sec-rotation-check.sh"

# ROOT repo (worktree) — źródło prawdziwego rejestru.
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
REGISTRY_SRC="$ROOT/config/canonical/credentials.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-BASELINE CREDENTIAL ROTATION (SEC-ROT) TESTS ==="

# ── Helper: buduje izolowane repo git z rejestrem ──────────────────────────
# Argumenty: <katalog_docelowy> [--no-registry] [--expired-active <name>]
#            [--expired-date <name> <data>]
make_isolated_repo() {
  local dir="$1"; shift
  local no_registry=0
  local expired_active=""
  local expired_date=""
  local expired_date_val=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-registry) no_registry=1 ;;
      --expired-active) expired_active="$2"; shift ;;
      --expired-date) expired_date="$2"; expired_date_val="$3"; shift 2 ;;
    esac
    shift
  done
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-ROT Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_registry" -eq 0 ]; then
    cp "$REGISTRY_SRC" "$dir/config/canonical/credentials.yaml"
    # Wariant: przeterminowana data rotacji, ale status "active" (nie rotating).
    if [ -n "$expired_active" ]; then
      sed -i "/^  - name: $expired_active\$/,/^  - name:/{s/^    rotation_date:.*/    rotation_date: \"2000-01-01\"/;s/^    status:.*/    status: active/}" "$dir/config/canonical/credentials.yaml"
    fi
    # Wariant: wymuś konkretną datę rotacji dla wpisu.
    if [ -n "$expired_date" ]; then
      sed -i "/^  - name: $expired_date\$/,/^  - name:/{s/^    rotation_date:.*/    rotation_date: \"$expired_date_val\"/}" "$dir/config/canonical/credentials.yaml"
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na prawdziwym rejestrze ────────────────────────────────
echo ""
echo "--- T1: moduł działa na prawdziwym rejestrze (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-ROT-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-ROT-02"; then
  t_pass "moduł działa na prawdziwym rejestrze (rc=$T1_RC, SEC-ROT-01..02 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwym rejestrze (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak rejestru → SEC-ROT-01 FAIL ───────────────────────
echo ""
echo "--- T2: fail-closed — brak rejestru → SEC-ROT-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-registry >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-ROT-01"; then
  t_pass "brak rejestru → SEC-ROT-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak rejestru NIE dał SEC-ROT-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — przeterminowana data bez statusu rotating → SEC-ROT-02 FAIL ──
echo ""
echo "--- T3: fail-closed — przeterminowana data bez statusu rotating → SEC-ROT-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --expired-active db-primary-app >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-ROT-02"; then
  t_pass "przeterminowana data bez statusu rotating → SEC-ROT-02 FAIL (rc=$T3_RC)"
else
  t_fail "przeterminowana data bez statusu rotating NIE dała SEC-ROT-02 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-BASELINE CREDENTIAL ROTATION — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
