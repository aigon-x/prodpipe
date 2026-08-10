#!/usr/bin/env bash
# ============================================================================
# test-sec-auth-check.sh — SEC-BASELINE authorization
# ============================================================================
# Weryfikuje moduł tools/verify/security/sec-auth-check.sh:
#   T1: moduł działa na prawdziwej definicji (rc=0, SEC-AUTH-01..03 PASS)
#   T2: fail-closed — brak definicji → SEC-AUTH-01 FAIL (rc != 0)
#   T3: fail-closed — brak ról → SEC-AUTH-02 FAIL (rc != 0)
#   T4: fail-closed — brak SoD → SEC-AUTH-03 FAIL (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują definicję, więc nie dotykają prawdziwego
# repo. Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-sec-auth-check.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
MODULE="$VERIFY_DIR/security/sec-auth-check.sh"

# ROOT repo (worktree) — źródło prawdziwej definicji.
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
AUTH_SRC="$ROOT/config/canonical/auth.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-BASELINE AUTHORIZATION (SEC-AUTH) TESTS ==="

# ── Helper: buduje izolowane repo git z definicją ──────────────────────────
# Argumenty: <katalog_docelowy> [--no-auth] [--no-roles] [--no-sod]
make_isolated_repo() {
  local dir="$1"; shift
  local no_auth=0
  local no_roles=0
  local no_sod=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-auth) no_auth=1 ;;
      --no-roles) no_roles=1 ;;
      --no-sod) no_sod=1 ;;
    esac
    shift
  done
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-AUTH Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_auth" -eq 0 ]; then
    cp "$AUTH_SRC" "$dir/config/canonical/auth.yaml"
    if [ "$no_roles" -eq 1 ]; then
      # Usuń sekcję roles (od nagłówka roles: do separation_of_duties:).
      sed -i '/^roles:/,/^separation_of_duties:/{/^roles:/d; /^separation_of_duties:/!d}' "$dir/config/canonical/auth.yaml"
    fi
    if [ "$no_sod" -eq 1 ]; then
      # Wyłącz SoD (enabled: false).
      sed -i '/^separation_of_duties:/,/^  rules:/{s/^  enabled:.*/  enabled: false/}' "$dir/config/canonical/auth.yaml"
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na prawdziwej definicji ────────────────────────────────
echo ""
echo "--- T1: moduł działa na prawdziwej definicji (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-AUTH-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-AUTH-02" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-AUTH-03"; then
  t_pass "moduł działa na prawdziwej definicji (rc=$T1_RC, SEC-AUTH-01..03 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwej definicji (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak definicji → SEC-AUTH-01 FAIL ─────────────────────
echo ""
echo "--- T2: fail-closed — brak definicji → SEC-AUTH-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-auth >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-AUTH-01"; then
  t_pass "brak definicji → SEC-AUTH-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak definicji NIE dał SEC-AUTH-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — brak ról → SEC-AUTH-02 FAIL ───────────────────────────
echo ""
echo "--- T3: fail-closed — brak ról → SEC-AUTH-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-roles >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-AUTH-02"; then
  t_pass "brak ról → SEC-AUTH-02 FAIL (rc=$T3_RC)"
else
  t_fail "brak ról NIE dał SEC-AUTH-02 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — brak SoD → SEC-AUTH-03 FAIL ───────────────────────────
echo ""
echo "--- T4: fail-closed — brak SoD → SEC-AUTH-03 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-sod >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] SEC-AUTH-03"; then
  t_pass "brak SoD → SEC-AUTH-03 FAIL (rc=$T4_RC)"
else
  t_fail "brak SoD NIE dał SEC-AUTH-03 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-BASELINE AUTHORIZATION — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
