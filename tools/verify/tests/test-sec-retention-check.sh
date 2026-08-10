#!/usr/bin/env bash
# ============================================================================
# test-sec-retention-check.sh — SEC-BASELINE retention policy
# ============================================================================
# Weryfikuje moduł tools/verify/security/sec-retention-check.sh:
#   T1: moduł działa na prawdziwej polityce (rc=0, SEC-RET-01..02 PASS)
#   T2: fail-closed — brak polityki → SEC-RET-01 FAIL (rc != 0)
#   T3: fail-closed — logi < 90 dni → SEC-RET-02 FAIL (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują politykę, więc nie dotykają prawdziwego
# repo. Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-sec-retention-check.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
MODULE="$VERIFY_DIR/security/sec-retention-check.sh"

# ROOT repo (worktree) — źródło prawdziwej polityki.
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
POLICY_SRC="$ROOT/config/canonical/retention.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-BASELINE RETENTION POLICY (SEC-RET) TESTS ==="

# ── Helper: buduje izolowane repo git z polityką ───────────────────────────
# Argumenty: <katalog_docelowy> [--no-policy] [--short-logs]
make_isolated_repo() {
  local dir="$1"; shift
  local no_policy=0
  local short_logs=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-policy) no_policy=1 ;;
      --short-logs) short_logs=1 ;;
    esac
    shift
  done
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-RET Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_policy" -eq 0 ]; then
    cp "$POLICY_SRC" "$dir/config/canonical/retention.yaml"
    if [ "$short_logs" -eq 1 ]; then
      # Zmniejsz retencję logów aplikacyjnych poniżej 90 dni.
      sed -i '/^  - name: application_logs$/,/^  - name:/{s/^    retention_days:.*/    retention_days: 30/}' "$dir/config/canonical/retention.yaml"
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na prawdziwej polityce ─────────────────────────────────
echo ""
echo "--- T1: moduł działa na prawdziwej polityce (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-RET-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-RET-02"; then
  t_pass "moduł działa na prawdziwej polityce (rc=$T1_RC, SEC-RET-01..02 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwej polityce (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak polityki → SEC-RET-01 FAIL ───────────────────────
echo ""
echo "--- T2: fail-closed — brak polityki → SEC-RET-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-policy >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-RET-01"; then
  t_pass "brak polityki → SEC-RET-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak polityki NIE dał SEC-RET-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — logi < 90 dni → SEC-RET-02 FAIL ───────────────────────
echo ""
echo "--- T3: fail-closed — logi < 90 dni → SEC-RET-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --short-logs >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-RET-02"; then
  t_pass "logi < 90 dni → SEC-RET-02 FAIL (rc=$T3_RC)"
else
  t_fail "logi < 90 dni NIE dały SEC-RET-02 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-BASELINE RETENTION POLICY — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
