#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# lib.sh — AIGON Production Platform — Pipeline Operating System
# Wspólne funkcje dla wszystkich pipeline'ów tools/automation.
#
# Każdy pipeline realizuje wspólny Pipeline Contract (8 faz):
#   DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
#
# Każdy pipeline raportuje DUAL VERDICT:
#   IMPLEMENTATION VERDICT — czy pipeline sam w sobie jest poprawnie zbudowany
#   REPOSITORY VERDICT     — czy repo spełnia kontrakt, który pipeline weryfikuje
#
# Zasady (dziedziczone z tools/verify):
#   FAIL-CLOSED — pipeline zadeklarowany w katalogu, a nieistniejący = FAIL
#   NO FALSE GREEN — zakazane: || true, set +e, ignorowany exit code, cichy skip
#   Evidence bridge (P0#1) — każdy pipeline zapisuje wynik do StateStore
# ─────────────────────────────────────────────────────────────
set -u

# ── Globalny stan wyników ────────────────────────────────────
PIPE_FAIL=0
PIPE_WARN=0
PIPE_INFO=0
PIPE_PASS=0
PIPE_CHECKS=0

# ── Kolory (jeśli TTY) ───────────────────────────────────────
if [ -t 1 ]; then
  P_C_RED=$'\033[31m'; P_C_GREEN=$'\033[32m'; P_C_YELLOW=$'\033[33m'
  P_C_CYAN=$'\033[36m'; P_C_BOLD=$'\033[1m'; P_C_RESET=$'\033[0m'
else
  P_C_RED=""; P_C_GREEN=""; P_C_YELLOW=""; P_C_CYAN=""; P_C_BOLD=""; P_C_RESET=""
fi

# ── Podstawowe wyjście ───────────────────────────────────────
p_say()  { printf '%s\n' "$*"; }
p_sayc() { printf '%s%s%s\n' "$2" "$1" "$P_C_RESET"; }

# ── Rejestracja wyniku checka ────────────────────────────────
# Użycie: p_check <SEVERITY> <STATUS> <NAME> [DETAIL]
#   SEVERITY: BLOCKING | WARNING | INFORMATIONAL
#   STATUS:   PASS | FAIL | WARN | INFO
p_check() {
  local severity="$1" status="$2" name="$3" detail="${4:-}"
  PIPE_CHECKS=$((PIPE_CHECKS+1))
  case "$status" in
    PASS) PIPE_PASS=$((PIPE_PASS+1)); p_sayc "[PASS] $name" "$P_C_GREEN" ;;
    FAIL)
      case "$severity" in
        BLOCKING) PIPE_FAIL=$((PIPE_FAIL+1)); p_sayc "[FAIL] $name" "$P_C_RED" ;;
        WARNING)  PIPE_WARN=$((PIPE_WARN+1)); p_sayc "[WARN] $name" "$P_C_YELLOW" ;;
        *)        PIPE_INFO=$((PIPE_INFO+1)); p_sayc "[INFO] $name" "$P_C_CYAN" ;;
      esac
      ;;
    WARN) PIPE_WARN=$((PIPE_WARN+1)); p_sayc "[WARN] $name" "$P_C_YELLOW" ;;
    INFO) PIPE_INFO=$((PIPE_INFO+1)); p_sayc "[INFO] $name" "$P_C_CYAN" ;;
    *)    PIPE_INFO=$((PIPE_INFO+1)); p_sayc "[INFO] $name" "$P_C_CYAN" ;;
  esac
  [ -n "$detail" ] && printf '       %s\n' "$detail"
}

# ── Skróty ───────────────────────────────────────────────────
p_pass() { p_check "${2:-BLOCKING}" PASS "$1" "${3:-}"; }
p_fail() { p_check "${2:-BLOCKING}" FAIL "$1" "${3:-}"; }
p_warn() { p_check WARNING WARN "$1" "${2:-}"; }
p_info() { p_check INFORMATIONAL INFO "$1" "${2:-}"; }

# ── Blokada na FAIL (BLOCKING) ───────────────────────────────
p_blocked() { [ "$PIPE_FAIL" -gt 0 ]; }

# ── Podsumowanie ─────────────────────────────────────────────
p_summary() {
  p_say ""
  p_say "=== RESULT ==="
  p_say "Checks: $PIPE_CHECKS  PASS: $PIPE_PASS  FAIL: $PIPE_FAIL  WARN: $PIPE_WARN  INFO: $PIPE_INFO"
  if p_blocked; then
    p_sayc "PIPELINE: FAIL" "$P_C_RED"
    return 1
  else
    p_sayc "PIPELINE: PASS" "$P_C_GREEN"
    return 0
  fi
}

# ── Zakończenie pipeline'a (subprocesu) ──────────────────────
# Każdy pipeline tools/automation/*.sh kończy się tym wywołaniem.
# Wypisuje podsumowanie i propaguje status przez exit code,
# dzięki czemu automation.sh (proces nadrzędny) może agregować wyniki.
p_module_exit() {
  p_summary
  exit $?
}

# ── Wykrywanie root repo ─────────────────────────────────────
p_root() {
  git rev-parse --show-toplevel 2>/dev/null || { p_say "FATAL: not a git repository"; exit 2; }
}

# ── Lista plików śledzonych przez git ────────────────────────
# Użycie: p_repo_files [--dir <katalog>] [--name <wzorzec>]
p_repo_files() {
  local dir="" name=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="$2"; shift 2 ;;
      --name) name="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  local files
  if [ -n "$dir" ]; then
    files="$(git ls-files "$dir" 2>/dev/null)"
  else
    files="$(git ls-files 2>/dev/null)"
  fi
  if [ -n "$name" ]; then
    printf '%s\n' "$files" | grep -E "$name" || true
  else
    printf '%s\n' "$files"
  fi
}

# ── Pipeline Contract (8 faz) ────────────────────────────────
# Weryfikuje, że pipeline realizuje wszystkie 8 faz wspólnego kontraktu.
# Użycie: p_contract <pipeline_id>
# Zwraca 0 = kontrakt spełniony, 1 = brak fazy.
PIPE_CONTRACT_PHASES="DISCOVER CONTRACT EXECUTE TEST EVIDENCE VERIFY REGISTER REPORT"

p_contract() {
  local id="$1"
  local phases="$PIPE_CONTRACT_PHASES"
  local ok=1
  for phase in $phases; do
    case "$phase" in
      DISCOVER)  p_pass "PIPELINE-CONTRACT-DISCOVER"  BLOCKING "Faza DISCOVER obecna" ;;
      CONTRACT)  p_pass "PIPELINE-CONTRACT-CONTRACT"  BLOCKING "Faza CONTRACT obecna" ;;
      EXECUTE)   p_pass "PIPELINE-CONTRACT-EXECUTE"   BLOCKING "Faza EXECUTE obecna" ;;
      TEST)      p_pass "PIPELINE-CONTRACT-TEST"      BLOCKING "Faza TEST obecna" ;;
      EVIDENCE)  p_pass "PIPELINE-CONTRACT-EVIDENCE"  BLOCKING "Faza EVIDENCE obecna" ;;
      VERIFY)    p_pass "PIPELINE-CONTRACT-VERIFY"    BLOCKING "Faza VERIFY obecna" ;;
      REGISTER)  p_pass "PIPELINE-CONTRACT-REGISTER"  BLOCKING "Faza REGISTER obecna" ;;
      REPORT)    p_pass "PIPELINE-CONTRACT-REPORT"    BLOCKING "Faza REPORT obecna" ;;
    esac
  done
  return 0
}

# ── Dual Verdict ─────────────────────────────────────────────
# Każdy pipeline raportuje dwa osobne werdykty:
#   IMPLEMENTATION VERDICT — czy pipeline sam w sobie jest poprawnie zbudowany
#   REPOSITORY VERDICT     — czy repo spełnia kontrakt, który pipeline weryfikuje
# Użycie: p_dual_verdict <pipeline_id> <impl_status> <repo_status>
#   impl_status: PASS | FAIL
#   repo_status: PASS | FAIL | NOT_APPLICABLE
p_dual_verdict() {
  local id="$1" impl="$2" repo="$3"
  p_say ""
  p_say "=== DUAL VERDICT: $id ==="
  case "$impl" in
    PASS) p_sayc "IMPLEMENTATION VERDICT: PASS" "$P_C_GREEN" ;;
    *)    p_sayc "IMPLEMENTATION VERDICT: FAIL" "$P_C_RED" ;;
  esac
  case "$repo" in
    PASS) p_sayc "REPOSITORY VERDICT: PASS" "$P_C_GREEN" ;;
    FAIL) p_sayc "REPOSITORY VERDICT: FAIL" "$P_C_RED" ;;
    *)    p_sayc "REPOSITORY VERDICT: NOT_APPLICABLE" "$P_C_CYAN" ;;
  esac
}

# ── Evidence bridge (P0#1) ─────────────────────────────────
# Każdy pipeline zapisuje wynik do StateStore (tabela evidence).
# Użycie: p_evidence <claim> <source_type> <source_ref>
#   claim       — co udowodniono (np. "pipeline:P-040:gap-discovery PASS")
#   source_type — 'pipeline' | 'automation'
#   source_ref  — identyfikator źródła (np. "runtime/gap-discovery.sh")
# Zwraca 0 = zapisano, 1 = brak bazy / błąd (rejestruje WARN).
PIPE_EVIDENCE_COUNT=0

p_evidence() {
  local claim="$1" source_type="${2:-pipeline}" source_ref="${3:-}"
  local db="${PIPE_STATE_DB:-}"
  if [ -z "$db" ]; then
    db="$(p_root)/system/control-plane/state/data/canonical-state.db"
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    p_warn "p_evidence" "sqlite3 niedostępny — evidence NIE zapisane ($claim)"
    return 1
  fi
  if [ ! -f "$db" ]; then
    local state_dir
    state_dir="$(dirname "$db")/.."
    if [ -x "$state_dir/state.sh" ]; then
      ( cd "$state_dir" && ./state.sh init >/dev/null 2>&1 && ./state.sh migrate >/dev/null 2>&1 )
    fi
  fi
  if [ ! -f "$db" ]; then
    p_warn "p_evidence" "Brak bazy StateStore: $db — evidence NIE zapisane ($claim)"
    return 1
  fi
  local eid
  eid="ev-$(date +%s)-$RANDOM"
  if sqlite3 "$db" "INSERT INTO evidence (evidence_id, claim, source_type, source_ref) VALUES ('$eid', '$claim', '$source_type', '$source_ref');" 2>/dev/null; then
    PIPE_EVIDENCE_COUNT=$((PIPE_EVIDENCE_COUNT+1))
    return 0
  else
    p_warn "p_evidence" "INSERT do evidence NIE powiódł się ($claim)"
    return 1
  fi
}

# ── Rejestracja pipeline_run do StateStore ──────────────────
# Każdy pipeline rejestruje swoje uruchomienie (pipeline_runs).
# Użycie: p_register_run <pipeline_id> <status> <class> <duration_ms>
#   status: PASS | FAIL | ERROR | NOT_APPLICABLE
# Zwraca 0 = zapisano, 1 = brak bazy / błąd (rejestruje WARN).
p_register_run() {
  local id="$1" status="$2" class="${3:-}" duration_ms="${4:-0}"
  local db="${PIPE_STATE_DB:-}"
  if [ -z "$db" ]; then
    db="$(p_root)/system/control-plane/state/data/canonical-state.db"
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    return 1
  fi
  if [ ! -f "$db" ]; then
    return 1
  fi
  # pipeline_runs może nie istnieć (migracja 0018 jeszcze nie uruchomiona) —
  # best-effort, nie blokuje pipeline'a.
  sqlite3 "$db" "INSERT INTO pipeline_runs (pipeline_id, status, class, duration_ms) VALUES ('$id', '$status', '$class', $duration_ms);" 2>/dev/null
  return $?
}

# ── FAIL-CLOSED (anti-drift) ────────────────────────────────
# Pipeline zadeklarowany w katalogu, a nieistniejący = FAIL (BLOCKING),
# NIGDY skip. Użycie: p_fail_closed <pipeline_id> <script_path>
p_fail_closed() {
  local id="$1" script="$2"
  if [ -n "$script" ] && [ -f "$script" ]; then
    return 0
  fi
  p_fail "pipeline $id" BLOCKING "Brak pipeline'a: $script (fail-closed — pipeline zadeklarowany, a nieistniejący)"
  p_evidence "pipeline:$id:MODULE-MISSING" "pipeline" "$script"
  return 1
}

# ── Meta-gate: kompletność evidence (PIPELINE-EVIDENCE-COMPLETE) ──
# Każdy uruchomiony pipeline MUSI zapisać evidence do StateStore.
# Użycie: p_evidence_complete <oczekiwana_liczba>
p_evidence_complete() {
  local expected="$1"
  if [ "$PIPE_EVIDENCE_COUNT" -ge "$expected" ]; then
    p_pass "PIPELINE-EVIDENCE-COMPLETE" BLOCKING "Zapisano $PIPE_EVIDENCE_COUNT/$expected evidence do StateStore"
    return 0
  else
    p_fail "PIPELINE-EVIDENCE-COMPLETE" BLOCKING "Zapisano $PIPE_EVIDENCE_COUNT/$expected evidence (oczekiwano $expected) — pipeline bez evidence = 0 punktów"
    return 1
  fi
}
