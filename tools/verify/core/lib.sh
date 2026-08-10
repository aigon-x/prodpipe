#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib.sh — AIGON Production Platform — Repository Certification Engine
# Wspólne funkcje dla wszystkich modułów tools/verify.
#
# Każdy check ma klasę:
#   BLOCKING      — FAIL blokuje commit/push/certyfikację
#   WARNING       — nie blokuje, ale wymaga świadomej decyzji
#   INFORMATIONAL — tylko informacja, nie wpływa na wynik
#
# Każdy check odpowiada na:
#   WHAT / WHY / SOURCE / EVIDENCE / EXPECTED / ACTUAL / SEVERITY / REMEDIATION
# ─────────────────────────────────────────────────────────────
set -u

# ── Globalny stan wyników ────────────────────────────────────
VERIFY_FAIL=0
VERIFY_WARN=0
VERIFY_INFO=0
VERIFY_PASS=0
VERIFY_CHECKS=0

# ── Kolory (jeśli TTY) ───────────────────────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_CYAN=""; C_BOLD=""; C_RESET=""
fi

# ── Podstawowe wyjście ───────────────────────────────────────
say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$2" "$1" "$C_RESET"; }

# ── Rejestracja wyniku checka ────────────────────────────────
# Użycie: check_result <SEVERITY> <STATUS> <NAME> [DETAIL]
#   SEVERITY: BLOCKING | WARNING | INFORMATIONAL
#   STATUS:   PASS | FAIL | WARN | INFO
check_result() {
  local severity="$1" status="$2" name="$3" detail="${4:-}"
  VERIFY_CHECKS=$((VERIFY_CHECKS+1))
  case "$status" in
    PASS) VERIFY_PASS=$((VERIFY_PASS+1)); sayc "[PASS] $name" "$C_GREEN" ;;
    FAIL)
      case "$severity" in
        BLOCKING) VERIFY_FAIL=$((VERIFY_FAIL+1)); sayc "[FAIL] $name" "$C_RED" ;;
        WARNING)  VERIFY_WARN=$((VERIFY_WARN+1)); sayc "[WARN] $name" "$C_YELLOW" ;;
        *)        VERIFY_INFO=$((VERIFY_INFO+1)); sayc "[INFO] $name" "$C_CYAN" ;;
      esac
      ;;
    WARN) VERIFY_WARN=$((VERIFY_WARN+1)); sayc "[WARN] $name" "$C_YELLOW" ;;
    INFO) VERIFY_INFO=$((VERIFY_INFO+1)); sayc "[INFO] $name" "$C_CYAN" ;;
    *)    VERIFY_INFO=$((VERIFY_INFO+1)); sayc "[INFO] $name" "$C_CYAN" ;;
  esac
  [ -n "$detail" ] && printf '       %s\n' "$detail"
}

# ── Skróty dla typowych przypadków ───────────────────────────
pass() { check_result "${2:-BLOCKING}" PASS "$1" "${3:-}"; }
fail() { check_result "${2:-BLOCKING}" FAIL "$1" "${3:-}"; }
warn() { check_result WARNING WARN "$1" "${2:-}"; }
info() { check_result INFORMATIONAL INFO "$1" "${2:-}"; }

# ── Blokada na FAIL (BLOCKING) ───────────────────────────────
# Zwraca 1 jeśli są FAIL-y BLOCKING, 0 w przeciwnym razie.
verify_blocked() {
  [ "$VERIFY_FAIL" -gt 0 ]
}

# ── Podsumowanie ─────────────────────────────────────────────
verify_summary() {
  say ""
  say "=== RESULT ==="
  say "Checks: $VERIFY_CHECKS  PASS: $VERIFY_PASS  FAIL: $VERIFY_FAIL  WARN: $VERIFY_WARN  INFO: $VERIFY_INFO"
  if verify_blocked; then
    sayc "CERTIFICATION: FAIL" "$C_RED"
    return 1
  else
    sayc "CERTIFICATION: PASS" "$C_GREEN"
    return 0
  fi
}

# ── Wykrywanie root repo ─────────────────────────────────────
verify_root() {
  git rev-parse --show-toplevel 2>/dev/null || { say "FATAL: not a git repository"; exit 2; }
}

# ── Sprawdzenie czy plik istnieje w repo ─────────────────────
repo_file() { [ -f "$1" ]; }

# ── Sprawdzenie czy katalog istnieje w repo ──────────────────
repo_dir() { [ -d "$1" ]; }
