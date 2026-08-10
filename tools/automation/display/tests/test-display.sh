#!/usr/bin/env bash
# ============================================================================
# test-display.sh — Visual Pipeline Display — testy
# ============================================================================
# Weryfikuje, że:
#   T1: Wszystkie pliki display istnieją (display.sh, colors.sh, display-pipeline.sh, display-html.sh, config/display.yaml)
#   T2: Wszystkie .sh mają poprawną składnię (bash -n)
#   T3: display-pipeline.sh help działa (exit 0)
#   T4: display-pipeline.sh families wypisuje 13 rodzin
#   T5: display-pipeline.sh stages wypisuje wszystkie pipeline'y P-001..P-098
#   T6: display-pipeline.sh deps wypisuje zależności (ASCII graph)
#   T7: display-pipeline.sh gates wypisuje pokrycie gate'ów (GATE-001..GATE-042)
#   T8: display-pipeline.sh status wypisuje status/evidence per pipeline
#   T9: display-pipeline.sh html generuje niepusty plik HTML
#   T10: display-pipeline.sh all kończy się sukcesem (exit 0) i generuje HTML
#   T11: NO FALSE GREEN — brak evidence = NOT_APPLICABLE, nigdy PASS
#   T12: FAIL-CLOSED — brak pipelines.sh = FAIL (BLOCKING)
#
# Użycie: ./test-display.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPLAY_DIR="$(dirname "$SCRIPT_DIR")"
AUTOMATION_DIR="$(dirname "$DISPLAY_DIR")"
REPO_ROOT="$(cd "$AUTOMATION_DIR/../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== VISUAL PIPELINE DISPLAY TESTS ==="

# --- T1: Wszystkie pliki display istnieją ----------------------------------
echo ""
echo "--- T1: Wszystkie pliki display istnieją ---"
FILES=(
  "$DISPLAY_DIR/lib/display.sh"
  "$DISPLAY_DIR/lib/colors.sh"
  "$DISPLAY_DIR/display-pipeline.sh"
  "$DISPLAY_DIR/display-html.sh"
  "$REPO_ROOT/config/display.yaml"
)
ALL_OK=1
for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    t_fail "Brak pliku: $f"
    ALL_OK=0
  fi
done
if [ "$ALL_OK" -eq 1 ]; then
  t_pass "Wszystkie pliki display istnieją"
fi

# --- T2: Wszystkie .sh mają poprawną składnię (bash -n) ---------------------
echo ""
echo "--- T2: Wszystkie .sh mają poprawną składnię (bash -n) ---"
SH_FILES=(
  "$DISPLAY_DIR/lib/display.sh"
  "$DISPLAY_DIR/lib/colors.sh"
  "$DISPLAY_DIR/display-pipeline.sh"
  "$DISPLAY_DIR/display-html.sh"
)
ALL_OK=1
for f in "${SH_FILES[@]}"; do
  if ! bash -n "$f" 2>/dev/null; then
    t_fail "Błąd składni: $f"
    ALL_OK=0
  fi
done
if [ "$ALL_OK" -eq 1 ]; then
  t_pass "Wszystkie .sh mają poprawną składnię"
fi

# --- T3: display-pipeline.sh help działa (exit 0) ---------------------------
echo ""
echo "--- T3: display-pipeline.sh help działa (exit 0) ---"
if bash "$DISPLAY_DIR/display-pipeline.sh" help >/dev/null 2>&1; then
  t_pass "help zwraca exit 0"
else
  t_fail "help nie zwraca exit 0"
fi

# --- T4: families wypisuje 13 rodzin ----------------------------------------
echo ""
echo "--- T4: families wypisuje 13 rodzin ---"
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" families 2>&1)"
FAMILY_COUNT="$(echo "$OUT" | grep -cE 'PRODUCT|DESIGN|SECURITY|CODE|BUILD|DEPLOYMENT|RUNTIME|RECOVERY|GTM|AI|OFFENSIVE-SECURITY|HUMAN-SIMULATION|SIMULATION')"
if [ "$FAMILY_COUNT" -ge 13 ]; then
  t_pass "families wypisuje ≥13 rodzin (znaleziono $FAMILY_COUNT)"
else
  t_fail "families wypisuje tylko $FAMILY_COUNT rodzin (oczekiwano ≥13)"
fi

# --- T5: stages wypisuje wszystkie pipeline'y P-001..P-098 ------------------
echo ""
echo "--- T5: stages wypisuje wszystkie pipeline'y P-001..P-098 ---"
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" stages 2>&1)"
PIPE_COUNT="$(echo "$OUT" | grep -cE 'P-[0-9]{3}')"
if [ "$PIPE_COUNT" -ge 98 ]; then
  t_pass "stages wypisuje ≥98 pipeline'ów (znaleziono $PIPE_COUNT)"
else
  t_fail "stages wypisuje tylko $PIPE_COUNT pipeline'ów (oczekiwano ≥98)"
fi

# --- T6: deps wypisuje zależności (ASCII graph) -----------------------------
echo ""
echo "--- T6: deps wypisuje zależności (ASCII graph) ---"
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" deps 2>&1)"
if echo "$OUT" | grep -qE '──▶'; then
  t_pass "deps wypisuje zależności (ASCII graph)"
else
  t_fail "deps nie wypisuje zależności (brak strzałek ──▶)"
fi

# --- T7: gates wypisuje pokrycie gate'ów (GATE-001..GATE-042) ---------------
echo ""
echo "--- T7: gates wypisuje pokrycie gate'ów (GATE-001..GATE-042) ---"
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" gates 2>&1)"
GATE_COUNT="$(echo "$OUT" | grep -cE 'GATE-[0-9]{3}')"
if [ "$GATE_COUNT" -ge 42 ]; then
  t_pass "gates wypisuje ≥42 gate'y (znaleziono $GATE_COUNT)"
else
  t_fail "gates wypisuje tylko $GATE_COUNT gate'ów (oczekiwano ≥42)"
fi

# --- T8: status wypisuje status/evidence per pipeline -----------------------
echo ""
echo "--- T8: status wypisuje status/evidence per pipeline ---"
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" status 2>&1)"
if echo "$OUT" | grep -qE 'IMPLEMENTED'; then
  t_pass "status wypisuje status pipeline'ów"
else
  t_fail "status nie wypisuje statusu pipeline'ów"
fi

# --- T9: html generuje niepusty plik HTML -----------------------------------
echo ""
echo "--- T9: html generuje niepusty plik HTML ---"
HTML_FILE="$REPO_ROOT/artifacts/display/pipeline-display.html"
rm -f "$HTML_FILE"
if bash "$DISPLAY_DIR/display-html.sh" >/dev/null 2>&1; then
  if [ -s "$HTML_FILE" ]; then
    t_pass "html generuje niepusty plik HTML ($(wc -c < "$HTML_FILE") bajtów)"
  else
    t_fail "html wygenerował pusty plik HTML"
  fi
else
  t_fail "html nie zakończył się sukcesem"
fi

# --- T10: all kończy się sukcesem (exit 0) i generuje HTML ------------------
echo ""
echo "--- T10: all kończy się sukcesem (exit 0) i generuje HTML ---"
HTML_FILE="$REPO_ROOT/artifacts/display/pipeline-display.html"
rm -f "$HTML_FILE"
if bash "$DISPLAY_DIR/display-pipeline.sh" all >/dev/null 2>&1; then
  if [ -s "$HTML_FILE" ]; then
    t_pass "all kończy się sukcesem i generuje HTML"
  else
    t_fail "all kończy się sukcesem, ale HTML jest pusty"
  fi
else
  t_fail "all nie zakończył się sukcesem (exit != 0)"
fi

# --- T11: NO FALSE GREEN — brak evidence = NOT_APPLICABLE, nigdy PASS -------
echo ""
echo "--- T11: NO FALSE GREEN — brak evidence = NOT_APPLICABLE, nigdy PASS ---"
# GATE-026 nie ma pliku evidence (brak w artifacts/evidence/gates/).
# Display musi raportować NOT_APPLICABLE, NIGDY PASS.
OUT="$(bash "$DISPLAY_DIR/display-pipeline.sh" gates 2>&1)"
GATE026_LINE="$(echo "$OUT" | grep -E '^  GATE-026 ' | head -n1)"
if echo "$GATE026_LINE" | grep -q 'NOT_APPLICABLE'; then
  t_pass "GATE-026 (brak evidence) raportuje NOT_APPLICABLE"
else
  t_fail "GATE-026 (brak evidence) nie raportuje NOT_APPLICABLE: '$GATE026_LINE'"
fi

# --- T12: FAIL-CLOSED — brak pipelines.sh = FAIL (BLOCKING) -----------------
echo ""
echo "--- T12: FAIL-CLOSED — brak pipelines.sh = FAIL (BLOCKING) ---"
PIPELINES_SH="$AUTOMATION_DIR/core/pipelines.sh"
if [ -f "$PIPELINES_SH" ]; then
  mv "$PIPELINES_SH" "$PIPELINES_SH.bak"
  if bash "$DISPLAY_DIR/display-pipeline.sh" stages >/dev/null 2>&1; then
    t_fail "Brak pipelines.sh nie powoduje FAIL (FAIL-CLOSED naruszony)"
  else
    t_pass "Brak pipelines.sh powoduje FAIL (FAIL-CLOSED)"
  fi
  mv "$PIPELINES_SH.bak" "$PIPELINES_SH"
else
  t_fail "Nie można przetestować FAIL-CLOSED — brak pipelines.sh"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== VISUAL PIPELINE DISPLAY — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
