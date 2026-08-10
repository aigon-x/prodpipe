#!/usr/bin/env bash
# ============================================================================
# lib.sh — TESTFORGE core library
# ============================================================================
# AIGON Production Platform — Test System Foundation.
#
# TESTFORGE buduje "system, który automatycznie testuje każdy kolejny system".
# Ten plik to rdzeń: definiuje kontrakt pipeline'u (PASS/FAIL/ERROR/SKIPPED),
# wymusza NO FALSE GREEN i agreguje wyniki do maszynowo-czytelnego JSON.
#
# Zasady (NO FALSE GREEN):
#   * Każdy test MUSI zwrócić jawny status: PASS | FAIL | ERROR | SKIPPED.
#   * ZABRONIONE: `|| true`, `set +e`, `continue-on-error`, ignorowany exit
#     code, pusty suite testowy, silent skip.
#   * SKIPPED jest JAWNY (wypisany + zarejestrowany) — nigdy cichy.
#   * ERROR = test nie mógł się wykonać (brak zależności, błąd runnera).
#   * FAIL  = test wykonał się i nie przeszedł.
#   * Każdy test ma jawny exit code propagowany do runnera.
# ============================================================================

set -euo pipefail

# ── Ścieżki ────────────────────────────────────────────────────────────────
TESTFORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$TESTFORGE_DIR")"
REPO_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"
RESULTS_DIR="${TESTFORGE_RESULTS_DIR:-$REPO_ROOT/.testforge-results}"

# ── Kolory (jeśli TTY) ─────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_BOLD=""; C_RESET=""
fi

# ── Globalny stan wyników ──────────────────────────────────────────────────
TF_PASS=0
TF_FAIL=0
TF_ERROR=0
TF_SKIPPED=0
TF_TOTAL=0
TF_RESULTS_JSON="[]"   # akumulator wyników (JSON array)

# ── Wyjście ────────────────────────────────────────────────────────────────
tf_say()  { printf '%s\n' "$*"; }
tf_sayc() { printf '%s%s%s\n' "$2" "$1" "$C_RESET"; }

# ── Rejestracja wyniku testu ───────────────────────────────────────────────
# Użycie: tf_result <STATUS> <NAME> [DETAIL]
#   STATUS: PASS | FAIL | ERROR | SKIPPED
# Rejestruje wynik, inkrementuje licznik i dopisuje do JSON.
# Zwraca 0 dla PASS/SKIPPED, 1 dla FAIL/ERROR (do propagacji exit code).
tf_result() {
  local status="$1" name="$2" detail="${3:-}"
  TF_TOTAL=$((TF_TOTAL + 1))
  local rc=0
  case "$status" in
    PASS)
      TF_PASS=$((TF_PASS + 1))
      tf_sayc "[PASS] $name" "$C_GREEN"
      ;;
    FAIL)
      TF_FAIL=$((TF_FAIL + 1)); rc=1
      tf_sayc "[FAIL] $name" "$C_RED"
      ;;
    ERROR)
      TF_ERROR=$((TF_ERROR + 1)); rc=1
      tf_sayc "[ERROR] $name" "$C_RED"
      ;;
    SKIPPED)
      TF_SKIPPED=$((TF_SKIPPED + 1))
      tf_sayc "[SKIPPED] $name" "$C_YELLOW"
      ;;
    *)
      # Nieznany status = ERROR (nigdy nie cichy).
      TF_ERROR=$((TF_ERROR + 1)); rc=1
      tf_sayc "[ERROR] $name (nieznany status '$status')" "$C_RED"
      ;;
  esac
  [ -n "$detail" ] && printf '       %s\n' "$detail"
  # Dopisz do JSON (bezpiecznie — JSON-escape).
  local esc_name esc_detail
  esc_name=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
  esc_detail=$(printf '%s' "$detail" | sed 's/\\/\\\\/g; s/"/\\"/g')
  TF_RESULTS_JSON="$TF_RESULTS_JSON,{"
  TF_RESULTS_JSON="$TF_RESULTS_JSON\"status\":\"$status\","
  TF_RESULTS_JSON="$TF_RESULTS_JSON\"name\":\"$esc_name\","
  TF_RESULTS_JSON="$TF_RESULTS_JSON\"detail\":\"$esc_detail\""
  TF_RESULTS_JSON="$TF_RESULTS_JSON}"
  return $rc
}

# ── Skróty ─────────────────────────────────────────────────────────────────
tf_pass()    { tf_result PASS "$1" "${2:-}"; }
tf_fail()    { tf_result FAIL "$1" "${2:-}"; }
tf_error()   { tf_result ERROR "$1" "${2:-}"; }
tf_skip()    { tf_result SKIPPED "$1" "${2:-}"; }

# ── Asercje ────────────────────────────────────────────────────────────────
# Użycie: tf_assert_eq <NAME> <ACTUAL> <EXPECTED>
tf_assert_eq() {
  local name="$1" actual="$2" expected="$3"
  if [ "$actual" = "$expected" ]; then
    tf_pass "$name" "actual == expected == '$expected'"
  else
    tf_fail "$name" "actual='$actual' expected='$expected'"
  fi
}

# Użycie: tf_assert_rc <NAME> <RC> <EXPECTED_RC>
tf_assert_rc() {
  local name="$1" rc="$2" expected="${3:-0}"
  if [ "$rc" -eq "$expected" ]; then
    tf_pass "$name" "exit code == $expected"
  else
    tf_fail "$name" "exit code=$rc (oczekiwano $expected)"
  fi
}

# Użycie: tf_assert_file <NAME> <PATH>
tf_assert_file() {
  local name="$1" path="$2"
  if [ -f "$path" ]; then
    tf_pass "$name" "plik istnieje: $path"
  else
    tf_fail "$name" "brak pliku: $path"
  fi
}

# Użycie: tf_assert_dir <NAME> <PATH>
tf_assert_dir() {
  local name="$1" path="$2"
  if [ -d "$path" ]; then
    tf_pass "$name" "katalog istnieje: $path"
  else
    tf_fail "$name" "brak katalogu: $path"
  fi
}

# Użycie: tf_assert_contains <NAME> <FILE> <PATTERN>
tf_assert_contains() {
  local name="$1" file="$2" pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    tf_pass "$name" "wzorzec znaleziony w $file"
  else
    tf_fail "$name" "brak wzorca '$pattern' w $file"
  fi
}

# ── NO FALSE GREEN guard ───────────────────────────────────────────────────
# Wykrywa zakazane wzorce w pliku: `|| true`, `set +e`, `continue-on-error`,
# puste suite'y, silent skip. Zwraca 0 jeśli czysto, 1 jeśli znaleziono.
# Uwaga: usuwa komentarze i literały stringowe przed grep, aby nie łapać
# fałszywych trafień (np. komentarze/komunikaty zawierające '|| true').
tf_no_false_green() {
  local file="$1"
  local bad=0
  if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$file" | grep -nE '\|\|\s*true\b' >/dev/null 2>&1; then
    tf_fail "NO-FALSE-GREEN $file" "znaleziono '|| true'"
    bad=1
  fi
  if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$file" | grep -nE '^\s*set\s+\+e\b' >/dev/null 2>&1; then
    tf_fail "NO-FALSE-GREEN $file" "znaleziono 'set +e'"
    bad=1
  fi
  if sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' "$file" | grep -nE 'continue-on-error' >/dev/null 2>&1; then
    tf_fail "NO-FALSE-GREEN $file" "znaleziono 'continue-on-error'"
    bad=1
  fi
  if grep -nE 'exit\s+0\s*(#.*)?$' "$file" >/dev/null 2>&1; then
    # exit 0 na końcu bez warunku — potencjalny false green (jeśli nie ma
    # żadnego tf_result/check). To jest WARN, nie FAIL — zbyt agresywne.
    :
  fi
  [ "$bad" -eq 0 ] && tf_pass "NO-FALSE-GREEN $file" "brak zakazanych wzorców"
  return $bad
}

# ── Podsumowanie ───────────────────────────────────────────────────────────
# Użycie: tf_summary <SUITE_NAME>
# Wypisuje podsumowanie i zapisuje test-results.json.
# Zwraca 0 jeśli PASS (brak FAIL/ERROR), 1 w przeciwnym razie.
tf_summary() {
  local suite="${1:-testforge}"
  tf_say ""
  tf_say "=== TESTFORGE RESULT: $suite ==="
  tf_say "Total: $TF_TOTAL  PASS: $TF_PASS  FAIL: $TF_FAIL  ERROR: $TF_ERROR  SKIPPED: $TF_SKIPPED"
  # Zapis JSON (maszynowo-czytelny output).
  mkdir -p "$RESULTS_DIR"
  local json
  json="{\"suite\":\"$suite\",\"total\":$TF_TOTAL,\"pass\":$TF_PASS,\"fail\":$TF_FAIL,\"error\":$TF_ERROR,\"skipped\":$TF_SKIPPED,\"results\":["
  # Usuń wiodący przecinek z akumulatora.
  json="$json${TF_RESULTS_JSON#,}"
  json="$json]}"
  printf '%s\n' "$json" > "$RESULTS_DIR/test-results.json"
  if [ "$TF_FAIL" -gt 0 ] || [ "$TF_ERROR" -gt 0 ]; then
    tf_sayc "SUITE: FAIL" "$C_RED"
    return 1
  else
    tf_sayc "SUITE: PASS" "$C_GREEN"
    return 0
  fi
}

# ── Zakończenie suite (subprocesu) ─────────────────────────────────────────
# Każdy plik testowy kończy się tym wywołaniem — propaguje status przez
# exit code, dzięki czemu runner może agregować. Bez tego liczniki giną
# w subprocesie → FALSE GATE.
tf_exit() {
  local suite="${1:-testforge}"
  tf_summary "$suite"
  exit $?
}

# ── Wykrywanie root repo ───────────────────────────────────────────────────
tf_root() {
  git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null || { tf_say "FATAL: not a git repository"; exit 2; }
}
