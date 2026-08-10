#!/usr/bin/env bash
# ============================================================================
# quality.sh — TESTFORGE quality gates
# ============================================================================
# Bramki jakości TEST-001..012. Weryfikują że system testowy sam spełnia
# wymagania NO FALSE GREEN, ma pokrycie, manifest, maszynowy output itd.
#
# Bramki:
#   TEST-001  tools/test istnieje i jest wykonywalny
#   TEST-002  tools/test ma set -euo pipefail
#   TEST-003  manifest.yaml istnieje
#   TEST-004  coverage-matrix.yaml istnieje
#   TEST-005  brak zakazanych wzorców (|| true, set +e, continue-on-error)
#   TEST-006  każdy test kończy się tf_exit (nie cichy exit)
#   TEST-007  test-results.json produkowany
#   TEST-008  coverage.json produkowany
#   TEST-009  quality.json produkowany
#   TEST-010  regressions.json produkowany
#   TEST-011  brak pustych suite'ów (każda kategoria ma testy)
#   TEST-012  local == CI (ten sam runner)
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ── Uruchom bramki jakości ─────────────────────────────────────────────────
tf_quality_gates() {
  # TEST-001
  if [ -f "$TOOLS_DIR/test" ] && [ -x "$TOOLS_DIR/test" ]; then
    tf_pass "TEST-001" "tools/test istnieje i jest wykonywalny"
  else
    tf_fail "TEST-001" "tools/test brak lub nie wykonywalny"
  fi

  # TEST-002
  if grep -q 'set -euo pipefail' "$TOOLS_DIR/test" 2>/dev/null; then
    tf_pass "TEST-002" "tools/test ma set -euo pipefail"
  else
    tf_fail "TEST-002" "tools/test nie ma set -euo pipefail"
  fi

  # TEST-003
  if [ -f "$TESTS_DIR/manifest.yaml" ]; then
    tf_pass "TEST-003" "manifest.yaml istnieje"
  else
    tf_fail "TEST-003" "brak manifest.yaml"
  fi

  # TEST-004
  if [ -f "$TESTS_DIR/coverage-matrix.yaml" ]; then
    tf_pass "TEST-004" "coverage-matrix.yaml istnieje"
  else
    tf_fail "TEST-004" "brak coverage-matrix.yaml"
  fi

  # TEST-005 — NO FALSE GREEN w systemie testowym
  # Uwaga: usuń komentarze i literały stringowe przed grep, aby nie łapać
  # fałszywych trafień (np. komentarze/komunikaty zawierające '|| true').
  local bad=0
  local f
  for f in "$TOOLS_DIR/test" "$TESTFORGE_DIR"/*.sh; do
    if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$f" | grep -nE '\|\|\s*true\b' >/dev/null 2>&1; then
      tf_fail "TEST-005" "znaleziono '|| true' w $f"
      bad=1
    fi
    if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$f" | grep -nE '^\s*set\s+\+e\b' >/dev/null 2>&1; then
      tf_fail "TEST-005" "znaleziono 'set +e' w $f"
      bad=1
    fi
    if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$f" | grep -nE 'continue-on-error' >/dev/null 2>&1; then
      tf_fail "TEST-005" "znaleziono 'continue-on-error' w $f"
      bad=1
    fi
  done
  [ "$bad" -eq 0 ] && tf_pass "TEST-005" "brak zakazanych wzorców w systemie testowym"

  # TEST-006 — każdy test kończy się tf_exit
  local no_exit=0
  for f in $(find "$TESTS_DIR" -name '*.test.sh' 2>/dev/null); do
    if ! grep -q 'tf_exit' "$f"; then
      tf_fail "TEST-006" "test nie kończy się tf_exit: $f"
      no_exit=1
    fi
  done
  [ "$no_exit" -eq 0 ] && tf_pass "TEST-006" "wszystkie testy kończą się tf_exit"

  # TEST-007..010 — maszynowy output
  # Uwaga: użyj if/else zamiast `&& ... || ...`, aby `set -e` nie przerywał
  # pozostałych bramek po pierwszym braku pliku (maskowanie kolejnych FAIL).
  if [ -f "$RESULTS_DIR/test-results.json" ]; then
    tf_pass "TEST-007" "test-results.json istnieje"
  else
    tf_fail "TEST-007" "brak test-results.json"
  fi
  if [ -f "$RESULTS_DIR/coverage.json" ]; then
    tf_pass "TEST-008" "coverage.json istnieje"
  else
    tf_fail "TEST-008" "brak coverage.json"
  fi
  if [ -f "$RESULTS_DIR/quality.json" ]; then
    tf_pass "TEST-009" "quality.json istnieje"
  else
    tf_fail "TEST-009" "brak quality.json"
  fi
  # TEST-010 — regressions.json. Dopuszczalny brak gdy nie skonfigurowano
  # baseline (regression to osobna, opt-in funkcja). Jeśli baseline istnieje,
  # regressions.json MUSI istnieć.
  if [ -f "$RESULTS_DIR/regressions.json" ]; then
    tf_pass "TEST-010" "regressions.json istnieje"
  elif [ ! -f "$RESULTS_DIR/baseline/test-results.json" ]; then
    tf_pass "TEST-010" "regressions.json brak (baseline nie skonfigurowany — OK)"
  else
    tf_fail "TEST-010" "brak regressions.json (baseline istnieje)"
  fi

  # TEST-011 — brak pustych suite'ów
  local empty=0
  local cat
  for cat in unit integration e2e security drift recovery reproducibility clean-room fault-injection negative golden snapshot property migration performance meta mutation contract; do
    if [ -d "$TESTS_DIR/$cat" ] && [ -z "$(find "$TESTS_DIR/$cat" -name '*.test.sh' 2>/dev/null)" ]; then
      tf_fail "TEST-011" "pusty suite: $cat (brak *.test.sh)"
      empty=1
    fi
  done
  [ "$empty" -eq 0 ] && tf_pass "TEST-011" "brak pustych suite'ów"

  # TEST-012 — local == CI (ten sam runner, brak osobnej ścieżki CI)
  if [ -f "$TOOLS_DIR/test" ] && grep -q 'runner.sh' "$TOOLS_DIR/test"; then
    tf_pass "TEST-012" "local == CI (ten sam runner)"
  else
    tf_fail "TEST-012" "tools/test nie używa runner.sh"
  fi
}
