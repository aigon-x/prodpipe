#!/usr/bin/env bash
# ============================================================================
# test-security-drills.sh — SEC-DEPLOY fire drills security (drills.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/security/drills.sh:
#   T1: moduł działa bez błędu na prawdziwym katalogu drills/ (rc=0,
#       SEC-D-00..SEC-C-01 PASS)
#   T2: fail-closed — brak katalogu drills/ → SEC-D-00 FAIL (rc != 0)
#   T3: fail-closed — domena bez README.md → odpowiedni check FAIL (rc != 0)
#   T4: fail-closed — README.md bez sekcji DESTROY → odpowiedni check FAIL
#       (rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), kopiują katalog drills/, więc nie dotykają
# prawdziwego repo ani równoległej pracy innych subagentów. Ustawiamy
# VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record nie psuł wyniku.
#
# Użycie: ./test-security-drills.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
DRILLS_SH="$VERIFY_DIR/security/drills.sh"
DRILLS_SRC="$VERIFY_DIR/security/drills"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== SEC-DEPLOY FIRE DRILLS (SECURITY-DRILLS) TESTS ==="

# ── Helper: buduje izolowane repo git z katalogiem drills/ ────────────────
# Argumenty: <katalog_docelowy> [--no-drills] [--no-readme <domena>]
#            [--no-destroy <domena>]
# Tworzy git repo, kopiuje katalog drills/ (lub jego wariant), zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_drills=0
  local no_readme=""
  local no_destroy=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-drills) no_drills=1 ;;
      --no-readme) no_readme="$2"; shift ;;
      --no-destroy) no_destroy="$2"; shift ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "SEC-DEPLOY Test" )
  echo "# test" > "$dir/README.md"
  if [ "$no_drills" -eq 0 ]; then
    cp -r "$DRILLS_SRC" "$dir/tools/verify/security/drills" 2>/dev/null \
      || { mkdir -p "$dir/tools/verify/security"; cp -r "$DRILLS_SRC" "$dir/tools/verify/security/drills"; }
    # Warianty: usuń README domeny lub sekcję DESTROY.
    if [ -n "$no_readme" ]; then
      rm -f "$dir/tools/verify/security/drills/$no_readme/README.md"
    fi
    if [ -n "$no_destroy" ]; then
      local f="$dir/tools/verify/security/drills/$no_destroy/README.md"
      if [ -f "$f" ]; then
        # Usuń sekcję DESTROY (wszystko od nagłówka DESTROY do końca pliku).
        sed -i '/^## DESTROY/,$d' "$f"
      fi
    fi
  fi
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na prawdziwym katalogu drills/ ────────────────────────
echo ""
echo "--- T1: moduł działa na prawdziwym katalogu drills/ (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$DRILLS_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "SEC-D-00 Pipeline integrity" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-D-00" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-D-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-A-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-R-01" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] SEC-C-01"; then
  t_pass "moduł działa na prawdziwym katalogu drills/ (rc=$T1_RC, SEC-D-00..SEC-C-01 PASS)"
else
  t_fail "moduł NIE działa poprawnie na prawdziwym katalogu drills/ (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak katalogu drills/ → SEC-D-00 FAIL ────────────────
echo ""
echo "--- T2: fail-closed — brak katalogu drills/ → SEC-D-00 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-drills >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$DRILLS_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] SEC-D-00"; then
  t_pass "brak katalogu drills/ → SEC-D-00 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak katalogu drills/ NIE dał SEC-D-00 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — domena bez README.md → odpowiedni check FAIL ─────────
echo ""
echo "--- T3: fail-closed — domena bez README.md → odpowiedni check FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-readme detection >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$DRILLS_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] \
   && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-D-00" \
   && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] SEC-D-01"; then
  t_pass "domena detection bez README.md → SEC-D-00 + SEC-D-01 FAIL (rc=$T3_RC)"
else
  t_fail "domena detection bez README.md NIE dała FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — README.md bez sekcji DESTROY → odpowiedni check FAIL ─
echo ""
echo "--- T4: fail-closed — README.md bez sekcji DESTROY → odpowiedni check FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-destroy recovery >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$DRILLS_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] \
   && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] SEC-D-00" \
   && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] SEC-R-01"; then
  t_pass "README recovery bez sekcji DESTROY → SEC-D-00 + SEC-R-01 FAIL (rc=$T4_RC)"
else
  t_fail "README recovery bez sekcji DESTROY NIE dał FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== SEC-DEPLOY FIRE DRILLS — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
