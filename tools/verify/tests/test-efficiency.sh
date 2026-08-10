#!/usr/bin/env bash
# ============================================================================
# test-efficiency.sh — ENGINEERING EFFICIENCY GATE (efficiency.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/efficiency/efficiency.sh (Change Intelligence /
# Engineering Efficiency Gate):
#   T1: moduł istnieje i jest wykonywalny
#   T2: moduł ma poprawną składnię (bash -n)
#   T3: moduł zawiera checki EFF-001..024
#   T4: moduł kończy się `evidence_record` i `verify_module_exit`
#   T5: moduł używa `repo_files` (nie `find .`)
#   T6: moduł ma nagłówek komentarza i `set -u`
#   T7: moduł ładuje `core/lib.sh`
#
# Testy są STRUKTURALNE i IZOLOWANE: NIE uruchamiają pełnego modułu (to
# wymagałoby prawdziwej bazy StateStore i pełnego repo). Weryfikują istnienie,
# składnię i strukturę modułu. Są fail-closed: jeśli moduł nie istnieje lub
# nie spełnia kontraktu strukturalnego, testy FAIL.
#
# Użycie: ./test-efficiency.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
EFFICIENCY_SH="$VERIFY_DIR/efficiency/efficiency.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== ENGINEERING EFFICIENCY GATE TESTS ==="

# ── T1: moduł istnieje i jest wykonywalny ──────────────────────────────────
echo ""
echo "--- T1: moduł istnieje i jest wykonywalny ---"
if [ -f "$EFFICIENCY_SH" ] && [ -x "$EFFICIENCY_SH" ]; then
  t_pass "moduł istnieje i jest wykonywalny: $EFFICIENCY_SH"
else
  t_fail "moduł NIE istnieje lub nie jest wykonywalny: $EFFICIENCY_SH"
fi

# ── T2: poprawna składnia (bash -n) ────────────────────────────────────────
echo ""
echo "--- T2: poprawna składnia (bash -n) ---"
if [ -f "$EFFICIENCY_SH" ] && bash -n "$EFFICIENCY_SH" 2>/dev/null; then
  t_pass "moduł ma poprawną składnię (bash -n)"
else
  t_fail "moduł ma błąd składni (bash -n) lub nie istnieje"
fi

# ── T3: moduł zawiera checki EFF-001..024 ──────────────────────────────────
echo ""
echo "--- T3: moduł zawiera checki EFF-001..024 ---"
if [ ! -f "$EFFICIENCY_SH" ]; then
  t_fail "moduł nie istnieje — nie można sprawdzić checków EFF-001..024"
else
  MISSING_EFF=""
  for i in $(seq 1 24); do
    EFF_ID="EFF-$(printf '%03d' "$i")"
    if ! grep -q "$EFF_ID" "$EFFICIENCY_SH"; then
      MISSING_EFF="$MISSING_EFF $EFF_ID"
    fi
  done
  if [ -z "$MISSING_EFF" ]; then
    t_pass "moduł zawiera wszystkie checki EFF-001..024"
  else
    t_fail "brakujące checki EFF:$MISSING_EFF"
  fi
fi

# ── T4: moduł kończy się `evidence_record` i `verify_module_exit` ──────────
echo ""
echo "--- T4: moduł kończy się evidence_record i verify_module_exit ---"
if [ ! -f "$EFFICIENCY_SH" ]; then
  t_fail "moduł nie istnieje — nie można sprawdzić zakończenia"
else
  if grep -q "evidence_record" "$EFFICIENCY_SH" && grep -q "verify_module_exit" "$EFFICIENCY_SH"; then
    t_pass "moduł używa evidence_record i verify_module_exit"
  else
    t_fail "moduł NIE używa evidence_record i/lub verify_module_exit"
  fi
fi

# ── T5: moduł używa `repo_files` (nie `find .`) ────────────────────────────
echo ""
echo "--- T5: moduł używa repo_files (nie find .) ---"
if [ ! -f "$EFFICIENCY_SH" ]; then
  t_fail "moduł nie istnieje — nie można sprawdzić repo_files"
else
  if grep -q "repo_files" "$EFFICIENCY_SH" && ! grep -qE "find \." "$EFFICIENCY_SH"; then
    t_pass "moduł używa repo_files i nie używa find ."
  else
    t_fail "moduł NIE używa repo_files lub używa find ."
  fi
fi

# ── T6: moduł ma nagłówek komentarza i `set -u` ────────────────────────────
echo ""
echo "--- T6: moduł ma nagłówek komentarza i set -u ---"
if [ ! -f "$EFFICIENCY_SH" ]; then
  t_fail "moduł nie istnieje — nie można sprawdzić nagłówka"
else
  # Nagłówek: pierwsza linia to shebang, a w pierwszych ~15 liniach jest
  # komentarz opisowy (linia zaczynająca się od '#').
  HEADER_OK=0
  if head -1 "$EFFICIENCY_SH" | grep -q '^#!'; then
    if head -15 "$EFFICIENCY_SH" | grep -qE '^#'; then
      HEADER_OK=1
    fi
  fi
  if [ "$HEADER_OK" -eq 1 ] && grep -q '^set -u' "$EFFICIENCY_SH"; then
    t_pass "moduł ma nagłówek komentarza i set -u"
  else
    t_fail "moduł NIE ma nagłówka komentarza i/lub set -u"
  fi
fi

# ── T7: moduł ładuje `core/lib.sh` ─────────────────────────────────────────
echo ""
echo "--- T7: moduł ładuje core/lib.sh ---"
if [ ! -f "$EFFICIENCY_SH" ]; then
  t_fail "moduł nie istnieje — nie można sprawdzić ładowania lib.sh"
else
  if grep -qE '\. .*core/lib\.sh|source .*core/lib\.sh' "$EFFICIENCY_SH"; then
    t_pass "moduł ładuje core/lib.sh"
  else
    t_fail "moduł NIE ładuje core/lib.sh"
  fi
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== ENGINEERING EFFICIENCY GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
