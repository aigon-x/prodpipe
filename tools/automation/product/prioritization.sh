#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-004 — PRIORITIZATION (Requirement Prioritization / MoSCoW)
# Rodzina: PRODUCT | Klasa: FAST | Status: IMPLEMENTED
#
# Weryfikuje, że wymagania mają priorytet (np. MoSCoW: MUST/SHOULD/COULD/WONT
# lub P0/P1/P2/P3). Szybki check pre-commit.
#
# Wykrywa:
#   * REQ-NO-PRIORITY — wymaganie bez priorytetu
#   * REQ-BAD-PRIORITY — wymaganie z nieznanym priorytetem
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION (czy pipeline jest poprawnie zbudowany) vs REPOSITORY (czy repo spełnia kontrakt)
# ─────────────────────────────────────────────────────────────
set -u

# ── Wczytaj core ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

# ── DISCOVER ────────────────────────────────────────────────
p_say "=== P-004 PRIORITIZATION ==="
p_say "Weryfikacja priorytetyzacji wymagań (MoSCoW / P0-P3)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-004"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
TOTAL=0
NO_PRIORITY=0
BAD_PRIORITY=0
DB_OK=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_OK=1
  TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement;" 2>/dev/null || echo 0)
  # 1. Wymaganie bez priorytetu.
  NO_PRIORITY=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE priority IS NULL OR priority = '';" 2>/dev/null || echo 0)
  # 2. Wymaganie z nieznanym priorytetem (poza dozwolonym zbiorem).
  BAD_PRIORITY=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE priority IS NOT NULL AND priority != '' AND UPPER(priority) NOT IN ('P0','P1','P2','P3','MUST','SHOULD','COULD','WONT','MUST-HAVE','SHOULD-HAVE','COULD-HAVE','WONT-HAVE');" 2>/dev/null || echo 0)
else
  p_info "PRIORITIZATION-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  p_info "PRIORITIZATION-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
elif [ "$TOTAL" -eq 0 ]; then
  p_info "PRIORITIZATION-EMPTY" "Brak wymagań w StateStore — repo_verdict NOT_APPLICABLE"
else
  if [ "$NO_PRIORITY" -eq 0 ]; then
    p_pass "PRIORITIZATION-ALL-PRIORITY" BLOCKING "Wszystkie wymagania mają priorytet"
  else
    p_fail "PRIORITIZATION-NO-PRIORITY" BLOCKING "Znaleziono $NO_PRIORITY wymagań bez priorytetu"
  fi
  if [ "$BAD_PRIORITY" -eq 0 ]; then
    p_pass "PRIORITIZATION-ALL-VALID" BLOCKING "Wszystkie priorytety są z dozwolonego zbioru (P0-P3 / MoSCoW)"
  else
    p_fail "PRIORITIZATION-BAD-PRIORITY" BLOCKING "Znaleziono $BAD_PRIORITY wymagań z nieznanym priorytetem"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-004:prioritization TOTAL=$TOTAL NO_PRIORITY=$NO_PRIORITY BAD_PRIORITY=$BAD_PRIORITY" "pipeline" "product/prioritization.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ] || [ "$TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$NO_PRIORITY" -gt 0 ] || [ "$BAD_PRIORITY" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-004" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-004" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "FAST" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
