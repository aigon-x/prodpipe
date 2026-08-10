#!/usr/bin/env bash
# ============================================================================
# test-sec-credential-registry.sh — SEC-BASELINE credential registry
# ============================================================================
# Weryfikuje moduł tools/verify/security/sec-credential-registry.sh:
#   T1: moduł działa na prawdziwym rejestrze (rc=0, SEC-CR-01..04 PASS)
#   T2: fail-closed — brak rejestru → SEC-CR-01 FAIL (rc != 0)
#   T3: fail-closed — wpis bez właściciela → SEC-CR-02 FAIL (rc != 0)
#   T4: fail-closed — wpis bez daty rotacji → SEC-CR-03 FAIL (rc != 0)
#   T5: fail-closed — wpis z niepoprawnym statusem → SEC-CR-04 FAIL (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują rejestr, więc nie dotykają prawdziwego
# repo ani równoległej pracy innych subagentów. Ustawiamy VERIFY_STATE_DB na
# nieistniejącą bazę, żeby evidence_record nie psuł wyniku.
#
# Użycie: ./test-sec-credential-registry.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
MODULE="$VERIFY_DIR/security/sec-credential-registry.sh"

# ROOT repo (worktree) — źródło prawdziwego rejestru.
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
REGISTRY_SRC="$ROOT/config/canonical/credentials.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-BASELINE CREDENTIAL REGISTRY (SEC-CR) TESTS ==="

# ── Helper: buduje izolowane repo git z rejestrem ──────────────────────────
# Argumenty: <katalog_docelowy> [--no-registry] [--no-owner <name>]
#            [--no-rotation <name>] [--bad-status <name>]
make_isolated_repo() {
  local dir="$1"; shift
  local no_registry=0
  local no_owner=""
  local no_rotation=""
  local bad_status=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-registry) no_registry=1 ;;
      --no-owner) no_owner="$2"; shift ;;
      --no-rotation) no_rotation="$2"; shift ;;
      --bad-status) bad_status="$2"; shift ;;
    esac
    shift
  done
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-CR Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_registry" -eq 0 ]; then
    cp "$REGISTRY_SRC" "$dir/config/canonical/credentials.yaml"
    # Warianty: usuń pole lub zepsuj status.
    if [ -n "$no_owner" ]; then
      sed -i "/^  - name: $no_owner\$/,/^  - name:/{/^    owner:/d}" "$dir/config/canonical/credentials.yaml"
    fi
    if [ -n "$no_rotation" ]; then
      sed -i "/^  - name: $no_rotation\$/,/^  - name:/{/^    rotation_date:/d}" "$dir/config/canonical/credentials.yaml"
    fi
    if [ -n "$bad_status" ]; then
      sed -i "/^  - name: $bad_status\$/,/^  - name:/{s/^    status:.*/    status: invalid/}" "$dir/config/canonical/credentials.yaml"
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na prawdziwym rejestrze ────────────────────────────────
echo ""
echo "--- T1: moduł działa na prawdziwym rejestrze (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-CR-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-CR-02" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-CR-03" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-CR-04"; then
  t_pass "moduł działa na prawdziwym rejestrze (rc=$T1_RC, SEC-CR-01..04 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwym rejestrze (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak rejestru → SEC-CR-01 FAIL ───────────────────────
echo ""
echo "--- T2: fail-closed — brak rejestru → SEC-CR-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-registry >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-CR-01"; then
  t_pass "brak rejestru → SEC-CR-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak rejestru NIE dał SEC-CR-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — wpis bez właściciela → SEC-CR-02 FAIL ─────────────────
echo ""
echo "--- T3: fail-closed — wpis bez właściciela → SEC-CR-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-owner db-primary-app >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-CR-02"; then
  t_pass "wpis bez właściciela → SEC-CR-02 FAIL (rc=$T3_RC)"
else
  t_fail "wpis bez właściciela NIE dał SEC-CR-02 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — wpis bez daty rotacji → SEC-CR-03 FAIL ────────────────
echo ""
echo "--- T4: fail-closed — wpis bez daty rotacji → SEC-CR-03 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-rotation db-primary-app >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] SEC-CR-03"; then
  t_pass "wpis bez daty rotacji → SEC-CR-03 FAIL (rc=$T4_RC)"
else
  t_fail "wpis bez daty rotacji NIE dał SEC-CR-03 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── T5: fail-closed — wpis z niepoprawnym statusem → SEC-CR-04 FAIL ─────────
echo ""
echo "--- T5: fail-closed — wpis z niepoprawnym statusem → SEC-CR-04 FAIL ---"
T5_DIR="$(mktemp -d)"
make_isolated_repo "$T5_DIR" --bad-status db-primary-app >/dev/null

T5_OUT="$(cd "$T5_DIR" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "\[FAIL\] SEC-CR-04"; then
  t_pass "wpis z niepoprawnym statusem → SEC-CR-04 FAIL (rc=$T5_RC)"
else
  t_fail "wpis z niepoprawnym statusem NIE dał SEC-CR-04 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-BASELINE CREDENTIAL REGISTRY — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
