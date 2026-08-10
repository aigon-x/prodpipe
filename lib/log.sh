#!/usr/bin/env bash
# ============================================================================
# lib/log.sh — AIGON Production Platform — OBS-BASELINE
# JEDYNY dozwolony kanał logowania (OBS-01).
# ============================================================================
# OBS-BASELINE: szablon rodzi obserwowalne projekty. Ten plik jest jedynym
# miejscem, w którym wolno emitować logi (OBS-01). Bezpośrednie echo/printf
# poza lib/log.sh w kodzie szkieletu = FAIL (egzekwowane przez
# obs-logging-check.sh).
#
# Funkcje:
#   log_info  <msg>   — poziom info
#   log_warn  <msg>   — poziom warn
#   log_error <msg>   — poziom error
#
# Każda emisja to JSON line na stderr:
#   {"ts":"<ISO8601>","level":"info","msg":"...","service":"...","run_id":"...","trace_id":"..."}
#
# SCRUBBING (OBS-02): przed emisją maskowane są wzorce PII/sekrety:
#   * adresy email
#   * PESEL (11 cyfr)
#   * numery kart (13-19 cyfr, Luhn-kształt)
#   * bearer tokeny (Authorization: Bearer ...)
#   * pola *password* | *secret* | *token* (wartość po '=')
#   * klucze API (sk-..., AKIA..., ghp_..., xox...)
#
# run_id / trace_id propagowane z env (VERIFY_RUN_ID, TRACE_ID) — umożliwia
# korelację request→log→trace (OBS-04/08).
#
# ZAKAZ: bezpośrednie echo/printf poza tym plikiem w kodzie szkieletu.
# ============================================================================
set -u

# ── Konfiguracja ────────────────────────────────────────────────────────────
LOG_SERVICE="${LOG_SERVICE:-template}"
LOG_LEVEL="${LOG_LEVEL:-info}"   # debug | info | warn | error

# ── Scrubber: maskuje wzorce PII/sekrety ────────────────────────────────────
# Użycie: log_scrub <string> → wypisuje zamaskowaną wersję na stdout.
# Maskowanie jest deterministyczne (ten sam input → ten sam output), co
# umożliwia test kanarkowy (OBS-02): kanarek NIGDY nie pojawia się w czystej
# postaci w outputcie.
log_scrub() {
  local input="$1"
  # Bearer tokeny: Authorization: Bearer <token>
  input="$(printf '%s' "$input" | sed -E 's/([Bb]earer[[:space:]]+)[A-Za-z0-9._~+\/-]+=*/\1[REDACTED]/g')"
  # Adresy email
  input="$(printf '%s' "$input" | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[EMAIL]/g')"
  # PESEL (11 cyfr)
  input="$(printf '%s' "$input" | sed -E 's/\b[0-9]{11}\b/[PESEL]/g')"
  # Numery kart (13-19 cyfr)
  input="$(printf '%s' "$input" | sed -E 's/\b[0-9]{13,19}\b/[CARD]/g')"
  # Klucze API (sk-, AKIA, ghp_, xox, glpat, AIza)
  input="$(printf '%s' "$input" | sed -E 's/\b(sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9]{10,}|glpat-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35})\b/[API_KEY]/g')"
  # Pola *password* | *secret* | *token*: wartość po '='
  input="$(printf '%s' "$input" | sed -E 's/([Pp]assword|[Ss]ecret|[Tt]oken)[[:space:]]*=[[:space:]]*[^[:space:]"'"'"']+/\1=[REDACTED]/g')"
  printf '%s' "$input"
}

# ── Emisja JSON line na stderr ──────────────────────────────────────────────
# Użycie: log_emit <level> <msg>
log_emit() {
  local level="$1" msg="$2"
  # Poziom: filtrujemy (debug tylko gdy LOG_LEVEL=debug).
  case "$LOG_LEVEL" in
    debug) ;;
    info)  [ "$level" = "debug" ] && return ;;
    warn)  [ "$level" = "debug" ] || [ "$level" = "info" ] && return ;;
    error) [ "$level" != "error" ] && return ;;
  esac
  local ts run_id trace_id
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  run_id="${VERIFY_RUN_ID:-}"
  trace_id="${TRACE_ID:-}"
  # Scrubbing przed emisją (OBS-02).
  local scrubbed
  scrubbed="$(log_scrub "$msg")"
  # JSON line na stderr (logi nie mieszają się z stdout — stdout to dane).
  printf '{"ts":"%s","level":"%s","msg":"%s","service":"%s","run_id":"%s","trace_id":"%s"}\n' \
    "$ts" "$level" "$scrubbed" "$LOG_SERVICE" "$run_id" "$trace_id" >&2
}

# ── Publiczne funkcje ───────────────────────────────────────────────────────
log_info()  { log_emit "info"  "$1"; }
log_warn()  { log_emit "warn"  "$1"; }
log_error() { log_emit "error" "$1"; }
