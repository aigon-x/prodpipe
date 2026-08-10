#!/usr/bin/env bash
# ============================================================================
# report.sh — TESTFORGE reporting
# ============================================================================
# Produkuje raporty maszynowo-czytelne (quality.json) i ludzkie podsumowania.
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Wygeneruj quality.json ─────────────────────────────────────────────────
# Agreguje wyniki z test-results.json do quality.json z oceną jakości.
tf_report_quality() {
  mkdir -p "$RESULTS_DIR"
  if [ ! -f "$RESULTS_DIR/test-results.json" ]; then
    tf_error "REPORT" "brak test-results.json — uruchom testy najpierw"
    return 1
  fi
  local total pass fail error skipped
  total=$(grep -o '"total":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  pass=$(grep -o '"pass":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  fail=$(grep -o '"fail":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  error=$(grep -o '"error":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  skipped=$(grep -o '"skipped":[0-9]*' "$RESULTS_DIR/test-results.json" | head -1 | cut -d: -f2)
  local pass_rate=0
  if [ "${total:-0}" -gt 0 ]; then
    pass_rate=$((pass * 100 / total))
  fi
  local grade="F"
  if [ "$pass_rate" -ge 90 ]; then grade="A"; elif [ "$pass_rate" -ge 75 ]; then grade="B"; elif [ "$pass_rate" -ge 50 ]; then grade="C"; elif [ "$pass_rate" -ge 25 ]; then grade="D"; fi
  local json
  json="{\"total\":${total:-0},\"pass\":${pass:-0},\"fail\":${fail:-0},\"error\":${error:-0},\"skipped\":${skipped:-0},\"pass_rate\":$pass_rate,\"grade\":\"$grade\"}"
  printf '%s\n' "$json" > "$RESULTS_DIR/quality.json"
  tf_pass "REPORT-QUALITY" "quality.json: pass_rate=$pass_rate% grade=$grade"
  return 0
}

# ── Podsumowanie ludzkie ───────────────────────────────────────────────────
tf_report_summary() {
  tf_say ""
  tf_say "=== TESTFORGE SUMMARY ==="
  if [ -f "$RESULTS_DIR/quality.json" ]; then
    cat "$RESULTS_DIR/quality.json"
    tf_say ""
  fi
  if [ -f "$RESULTS_DIR/coverage.json" ]; then
    tf_say "Coverage: $RESULTS_DIR/coverage.json"
  fi
  if [ -f "$RESULTS_DIR/regressions.json" ]; then
    tf_say "Regressions: $RESULTS_DIR/regressions.json"
  fi
  tf_say "Results: $RESULTS_DIR/test-results.json"
}
