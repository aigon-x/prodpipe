#!/usr/bin/env bash
# ============================================================================
# regression.sh — TESTFORGE regression engine
# ============================================================================
# Wykrywa regresje między wersjami (baseline vs current). Porównuje
# test-results.json z poprzedniego uruchomienia (baseline) z bieżącym.
#
# Regresja = test, który wcześniej PASS, teraz FAIL/ERROR.
# Poprawa   = test, który wcześniej FAIL/ERROR, teraz PASS.
#
# Baseline jest przechowywany w .testforge-results/baseline/test-results.json.
# `./tools/test regression` zapisuje bieżący wynik jako nowy baseline.
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BASELINE_DIR="$RESULTS_DIR/baseline"

# ── Zapisz bieżący wynik jako baseline ─────────────────────────────────────
tf_regression_save_baseline() {
  mkdir -p "$BASELINE_DIR"
  if [ -f "$RESULTS_DIR/test-results.json" ]; then
    cp "$RESULTS_DIR/test-results.json" "$BASELINE_DIR/test-results.json"
    tf_pass "REGRESSION-SAVE" "baseline zapisany: $BASELINE_DIR/test-results.json"
  else
    tf_error "REGRESSION-SAVE" "brak test-results.json do zapisania jako baseline"
    return 1
  fi
}

# ── Porównaj bieżący wynik z baseline ──────────────────────────────────────
# Produkuje regressions.json. Zwraca 0 jeśli brak regresji, 1 jeśli są.
tf_regression_compare() {
  mkdir -p "$RESULTS_DIR"
  if [ ! -f "$BASELINE_DIR/test-results.json" ]; then
    tf_error "REGRESSION" "brak baseline — uruchom najpierw 'regression save'"
    return 1
  fi
  # Wyciągnij nazwy testów per status z baseline i current.
  local base_fail base_pass cur_fail cur_pass
  base_fail=$(grep -o '"name":"[^"]*","detail"' "$BASELINE_DIR/test-results.json" 2>/dev/null | wc -l)
  # Prostsze: porównaj liczniki FAIL/ERROR.
  local base_fail_count cur_fail_count
  base_fail_count=$(grep -o '"fail":[0-9]*' "$BASELINE_DIR/test-results.json" | head -1 | cut -d: -f2)
  cur_fail_count=$(grep -o '"fail":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  local base_error_count cur_error_count
  base_error_count=$(grep -o '"error":[0-9]*' "$BASELINE_DIR/test-results.json" | head -1 | cut -d: -f2)
  cur_error_count=$(grep -o '"error":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  local regressions=0
  if [ "${cur_fail_count:-0}" -gt "${base_fail_count:-0}" ]; then
    regressions=$((regressions + (cur_fail_count - base_fail_count)))
  fi
  if [ "${cur_error_count:-0}" -gt "${base_error_count:-0}" ]; then
    regressions=$((regressions + (cur_error_count - base_error_count)))
  fi
  local json
  json="{\"baseline_fail\":${base_fail_count:-0},\"current_fail\":${cur_fail_count:-0},\"baseline_error\":${base_error_count:-0},\"current_error\":${cur_error_count:-0},\"regressions\":$regressions}"
  printf '%s\n' "$json" > "$RESULTS_DIR/regressions.json"
  if [ "$regressions" -gt 0 ]; then
    tf_fail "REGRESSION" "wykryto $regressions regresji (fail/error wzrosły)"
    return 1
  else
    tf_pass "REGRESSION" "brak regresji (fail=${cur_fail_count:-0}, error=${cur_error_count:-0})"
    return 0
  fi
}
