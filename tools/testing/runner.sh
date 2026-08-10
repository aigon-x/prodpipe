#!/usr/bin/env bash
# ============================================================================
# runner.sh — TESTFORGE test runner
# ============================================================================
# Wykonuje testy, agreguje wyniki, wymusza NO FALSE GREEN i produkuje
# maszynowo-czytelny output (test-results.json, coverage.json, quality.json,
# regressions.json).
#
# Runner jest LOCAL-FIRST: `./tools/test full` działa lokalnie identycznie
# jak w CI. Nie ma osobnej ścieżki CI — CI wywołuje ten sam runner.
#
# Zasady:
#   * Każdy test uruchamiany w subprocesie (bash "$file").
#   * Exit code testu MUSI być jawny (0=PASS, 1=FAIL/ERROR).
#   * Test, który nie istnieje w manifest = ERROR (nie cichy skip).
#   * Test, który nie kończy się tf_exit = ERROR (wykrywane po braku
#     pliku test-results.json w subprocesie).
# ============================================================================

set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# shellcheck source=manifest.sh
. "$(dirname "${BASH_SOURCE[0]}")/manifest.sh"
# shellcheck source=discovery.sh
. "$(dirname "${BASH_SOURCE[0]}")/discovery.sh"

# ── Uruchom pojedynczy test ────────────────────────────────────────────────
# Użycie: tf_run_test <PATH>
# Wykonuje test w subprocesie. Zwraca 0 jeśli PASS, 1 jeśli FAIL/ERROR.
tf_run_test() {
  local path="$1"
  local abs="$REPO_ROOT/$path"
  if [ ! -f "$abs" ]; then
    tf_error "RUN $path" "brak pliku testu"
    return 1
  fi
  if [ ! -x "$abs" ] && ! head -1 "$abs" | grep -q '^#!/'; then
    tf_error "RUN $path" "test nie jest wykonywalny ani nie ma shebang"
    return 1
  fi
  tf_say ""
  tf_say "────────────────────────────────────────────────────────────"
  tf_say "TEST: $path"
  tf_say "────────────────────────────────────────────────────────────"
  # Uruchom w subprocesie z izolowanym RESULTS_DIR (żeby nie mieszać JSON).
  local sub_results
  sub_results=$(mktemp -d)
  local rc=0
  if TESTFORGE_RESULTS_DIR="$sub_results" bash "$abs"; then
    rc=0
  else
    rc=$?
  fi
  # Sprawdź czy test wyprodukował test-results.json (dowód że zakończył się
  # przez tf_exit, nie przez cichy exit 0).
  if [ ! -f "$sub_results/test-results.json" ]; then
    tf_error "RUN $path" "test nie wyprodukował test-results.json (nie zakończył się przez tf_exit) — FALSE GATE"
    rm -rf "$sub_results"
    return 1
  fi
  # Odczytaj status z JSON subprocesu.
  local sub_status
  sub_status=$(grep -o '"fail":[0-9]*' "$sub_results/test-results.json" | head -1 | cut -d: -f2)
  local sub_error
  sub_error=$(grep -o '"error":[0-9]*' "$sub_results/test-results.json" | head -1 | cut -d: -f2)
  rm -rf "$sub_results"
  if [ "$rc" -eq 0 ] && [ "${sub_status:-0}" = "0" ] && [ "${sub_error:-0}" = "0" ]; then
    tf_pass "RUN $path" "test przeszedł (exit=0)"
    return 0
  else
    tf_fail "RUN $path" "test NIE przeszedł (exit=$rc, fail=${sub_status:-?}, error=${sub_error:-?})"
    return 1
  fi
}

# ── Uruchom suite testów ───────────────────────────────────────────────────
# Użycie: tf_run_suite <SUITE_NAME> <LEVEL> [PATHS...]
#   SUITE_NAME — nazwa do raportu
#   LEVEL      — poziom testów (L0-L6) lub "all"
#   PATHS      — ścieżki testów do uruchomienia (jeśli puste, z manifestu)
tf_run_suite() {
  local suite="$1" level="$2"
  shift 2
  local paths=("$@")
  tf_say ""
  tf_say "╔══════════════════════════════════════════════════════════╗"
  tf_say "║  TESTFORGE SUITE: $suite (level $level)  ║"
  tf_say "╚══════════════════════════════════════════════════════════╝"
  if [ "${#paths[@]}" -eq 0 ]; then
    # Brak jawnych ścieżek — weź z manifestu dla poziomu.
    local manifest_paths
    manifest_paths=$(tf_manifest_level "$level" 2>/dev/null || rc=$?)
    if [ -z "$manifest_paths" ]; then
      tf_error "SUITE $suite" "brak testów dla poziomu $level w manifest"
      tf_exit "$suite"
    fi
    # shellcheck disable=SC2206
    paths=($manifest_paths)
  fi
  local p
  for p in "${paths[@]}"; do
    tf_run_test "$p" || rc=$?
  done
  tf_exit "$suite"
}

# ── Uruchom suite z discovery (bez manifestu) ──────────────────────────────
# Użycie: tf_run_discovered <SUITE_NAME> <CATEGORY>
tf_run_discovered() {
  local suite="$1" category="$2"
  local files
  files=$(tf_discover "$category" 2>/dev/null || rc=$?)
  if [ -z "$files" ]; then
    tf_error "SUITE $suite" "brak testów w kategorii $category"
    tf_exit "$suite"
  fi
  local f
  for f in $files; do
    tf_run_test "$f" || rc=$?
  done
  tf_exit "$suite"
}
