#!/usr/bin/env bash
# ============================================================================
# test-sec-web-check.sh — SEC-BASELINE web security
# ============================================================================
# Weryfikuje moduł tools/verify/security/sec-web-check.sh:
#   T1: moduł działa na prawdziwej definicji (rc=0, SEC-WEB-01..02 PASS)
#   T2: fail-closed — brak definicji → SEC-WEB-01 FAIL (rc != 0)
#   T3: fail-closed — brak nagłówków → SEC-WEB-01 FAIL (rc != 0)
#   T4: fail-closed — TLS nie wymagany → SEC-WEB-02 FAIL (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują definicję, więc nie dotykają prawdziwego
# repo. Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-sec-web-check.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
MODULE="$VERIFY_DIR/security/sec-web-check.sh"

# ROOT repo (worktree) — źródło prawdziwej definicji.
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
WEB_SRC="$ROOT/config/canonical/web-security.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-BASELINE WEB SECURITY (SEC-WEB) TESTS ==="

# ── Helper: buduje izolowane repo git z definicją ──────────────────────────
# Argumenty: <katalog_docelowy> [--no-web] [--no-headers] [--no-tls]
make_isolated_repo() {
  local dir="$1"; shift
  local no_web=0
  local no_headers=0
  local no_tls=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-web) no_web=1 ;;
      --no-headers) no_headers=1 ;;
      --no-tls) no_tls=1 ;;
    esac
    shift
  done
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-WEB Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_web" -eq 0 ]; then
    cp "$WEB_SRC" "$dir/config/canonical/web-security.yaml"
    if [ "$no_headers" -eq 1 ]; then
      # Wyłącz nagłówki (enabled: false).
      sed -i '/^security_headers:/,/^tls:/{s/^  enabled:.*/  enabled: false/}' "$dir/config/canonical/web-security.yaml"
    fi
    if [ "$no_tls" -eq 1 ]; then
      # Wyłącz wymóg TLS.
      sed -i '/^tls:/,/^  min_version:/{s/^  required:.*/  required: false/}' "$dir/config/canonical/web-security.yaml"
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
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-WEB-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-WEB-02"; then
  t_pass "moduł działa na prawdziwej definicji (rc=$T1_RC, SEC-WEB-01..02 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwej definicji (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak definicji → SEC-WEB-01 FAIL ──────────────────────
echo ""
echo "--- T2: fail-closed — brak definicji → SEC-WEB-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-web >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-WEB-01"; then
  t_pass "brak definicji → SEC-WEB-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak definicji NIE dał SEC-WEB-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — brak nagłówków → SEC-WEB-01 FAIL ──────────────────────
echo ""
echo "--- T3: fail-closed — brak nagłówków → SEC-WEB-01 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-headers >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-WEB-01"; then
  t_pass "brak nagłówków → SEC-WEB-01 FAIL (rc=$T3_RC)"
else
  t_fail "brak nagłówków NIE dał SEC-WEB-01 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — TLS nie wymagany → SEC-WEB-02 FAIL ────────────────────
echo ""
echo "--- T4: fail-closed — TLS nie wymagany → SEC-WEB-02 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-tls >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$MODULE" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] SEC-WEB-02"; then
  t_pass "TLS nie wymagany → SEC-WEB-02 FAIL (rc=$T4_RC)"
else
  t_fail "TLS nie wymagany NIE dał SEC-WEB-02 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-BASELINE WEB SECURITY — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
