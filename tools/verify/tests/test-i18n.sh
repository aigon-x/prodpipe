#!/usr/bin/env bash
# ============================================================================
# test-i18n.sh — I18N (INTERNACJONALIZACJA) module tests (i18n.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/i18n/i18n.sh:
#   T1: moduł działa na repo z poprawnym i18n/policy.yaml i i18n/locales.yaml
#       (rc=0, INT-01/02 PASS)
#   T2: fail-closed — brak i18n/policy.yaml → INT-01 FAIL (rc != 0)
#   T3: fail-closed — brak i18n/locales.yaml → INT-02 FAIL (rc != 0)
#   T4: locales z językiem RTL (ar) bez flagi rtl: true → INT-04 WARN
#       (rc=0, bo WARNING nie blokuje)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), tworzą pliki i18n/, więc nie dotykają
# prawdziwego repo ani równoległej pracy innych subagentów. Ustawiamy
# VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record nie psuł wyniku.
#
# Użycie: ./test-i18n.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
I18N_SH="$VERIFY_DIR/i18n/i18n.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== I18N (INTERNACJONALIZACJA) TESTS ==="

# ── Helper: buduje izolowane repo git z plikami i18n/ ─────────────────────
# Argumenty: <katalog_docelowy> [--no-policy] [--no-locales] [--no-rtl]
# Tworzy git repo, tworzy i18n/policy.yaml i i18n/locales.yaml (lub warianty),
# zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_policy=0
  local no_locales=0
  local no_rtl=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-policy) no_policy=1 ;;
      --no-locales) no_locales=1 ;;
      --no-rtl) no_rtl=1 ;;
    esac
    shift
  done
  mkdir -p "$dir/i18n"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "I18N Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_policy" -eq 0 ]; then
    cat > "$dir/i18n/policy.yaml" <<'EOF'
# Polityka internacjonalizacji
default_locale: en
strategy: externalized
EOF
  fi
  if [ "$no_locales" -eq 0 ]; then
    if [ "$no_rtl" -eq 0 ]; then
      cat > "$dir/i18n/locales.yaml" <<'EOF'
locales:
  - en
  - pl
  - ar
rtl: true
EOF
    else
      cat > "$dir/i18n/locales.yaml" <<'EOF'
locales:
  - en
  - pl
  - ar
EOF
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na repo z poprawnymi plikami i18n/ ────────────────────
echo ""
echo "--- T1: moduł działa na repo z poprawnym i18n/policy.yaml i i18n/locales.yaml (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$I18N_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] INT-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] INT-02"; then
  t_pass "moduł działa na poprawnym repo (rc=$T1_RC, INT-01/02 PASS)"
else
  t_fail "moduł NIE działa poprawnie na poprawnym repo (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak i18n/policy.yaml → INT-01 FAIL ──────────────────
echo ""
echo "--- T2: fail-closed — brak i18n/policy.yaml → INT-01 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-policy >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$I18N_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] INT-01"; then
  t_pass "brak i18n/policy.yaml → INT-01 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak i18n/policy.yaml NIE dał INT-01 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — brak i18n/locales.yaml → INT-02 FAIL ─────────────────
echo ""
echo "--- T3: fail-closed — brak i18n/locales.yaml → INT-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-locales >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$I18N_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] INT-02"; then
  t_pass "brak i18n/locales.yaml → INT-02 FAIL (fail-closed, rc=$T3_RC)"
else
  t_fail "brak i18n/locales.yaml NIE dał INT-02 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: locales z językiem RTL (ar) bez flagi rtl: true → INT-04 WARN ──────
echo ""
echo "--- T4: locales z językiem RTL (ar) bez flagi rtl: true → INT-04 WARN ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-rtl >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$I18N_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -eq 0 ] \
   && printf '%s' "$T4_OUT" | grep -q "\[WARN\] INT-04" \
   && printf '%s' "$T4_OUT" | grep -q "\[PASS\] INT-01" \
   && printf '%s' "$T4_OUT" | grep -q "\[PASS\] INT-02"; then
  t_pass "locale RTL bez rtl: true → INT-04 WARN, rc=0 (WARNING nie blokuje)"
else
  t_fail "locale RTL bez rtl: true NIE dał INT-04 WARN (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== I18N (INTERNACJONALIZACJA) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
