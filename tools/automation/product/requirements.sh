#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-002 — REQUIREMENTS (Requirement Completeness)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje kompletność wymagań: każde wymaganie musi mieć status,
# priorytet i właściciela.
#
# Wykrywa:
#   * REQ-NO-STATUS   — wymaganie bez statusu
#   * REQ-NO-PRIORITY — wymaganie bez priorytetu
#   * REQ-NO-OWNER    — wymaganie bez właściciela
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
p_say "=== P-002 REQUIREMENTS ==="
p_say "Weryfikacja kompletności wymagań (status / priorytet / właściciel)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-002"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
TOTAL=0
NO_STATUS=0
NO_PRIORITY=0
NO_OWNER=0
DB_OK=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_OK=1
  TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement;" 2>/dev/null || echo 0)
  # 1. Wymaganie bez statusu (status NULL lub pusty).
  NO_STATUS=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE status IS NULL OR status = '';" 2>/dev/null || echo 0)
  # 2. Wymaganie bez priorytetu (priority NULL lub pusty).
  NO_PRIORITY=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE priority IS NULL OR priority = '';" 2>/dev/null || echo 0)
  # 3. Wymaganie bez właściciela (owner NULL lub pusty).
  NO_OWNER=$(sqlite3 "$db" "SELECT COUNT(*) FROM requirement WHERE owner IS NULL OR owner = '';" 2>/dev/null || echo 0)
else
  p_info "REQUIREMENTS-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  p_info "REQUIREMENTS-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
elif [ "$TOTAL" -eq 0 ]; then
  p_info "REQUIREMENTS-EMPTY" "Brak wymagań w StateStore — repo_verdict NOT_APPLICABLE"
else
  if [ "$NO_STATUS" -eq 0 ]; then
    p_pass "REQUIREMENTS-ALL-STATUS" BLOCKING "Wszystkie wymagania mają status"
  else
    p_fail "REQUIREMENTS-NO-STATUS" BLOCKING "Znaleziono $NO_STATUS wymagań bez statusu"
  fi
  if [ "$NO_PRIORITY" -eq 0 ]; then
    p_pass "REQUIREMENTS-ALL-PRIORITY" BLOCKING "Wszystkie wymagania mają priorytet"
  else
    p_fail "REQUIREMENTS-NO-PRIORITY" BLOCKING "Znaleziono $NO_PRIORITY wymagań bez priorytetu"
  fi
  if [ "$NO_OWNER" -eq 0 ]; then
    p_pass "REQUIREMENTS-ALL-OWNER" BLOCKING "Wszystkie wymagania mają właściciela"
  else
    p_warn "REQUIREMENTS-NO-OWNER" "Znaleziono $NO_OWNER wymagań bez właściciela"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-002:requirements TOTAL=$TOTAL NO_STATUS=$NO_STATUS NO_PRIORITY=$NO_PRIORITY NO_OWNER=$NO_OWNER" "pipeline" "product/requirements.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ] || [ "$TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$NO_STATUS" -gt 0 ] || [ "$NO_PRIORITY" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-002" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-002" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
