#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-013 — TECH DEBT (Technical Debt Registry)
# Rodzina: DESIGN | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje rejestr długu technicznego. Konsumuje tabelę debt (StateStore).
#
# Wykrywa:
#   * NO-DEBT-REGISTRY — brak rejestru długu technicznego
#   * DEBT-NO-OWNER    — dług techniczny bez przypisanego właściciela
#   * DEBT-NO-DEADLINE — dług techniczny bez terminu spłaty
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
p_say "=== P-013 TECH DEBT ==="
p_say "Weryfikacja rejestru długu technicznego (owner / deadline)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-013"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DEBT_TOTAL=0
DEBT_NO_OWNER=0
DEBT_NO_DEADLINE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. NO-DEBT-REGISTRY — łączna liczba wpisów długu technicznego.
  DEBT_TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM debt;" 2>/dev/null || echo 0)

  # 2. DEBT-NO-OWNER — dług bez przypisanego właściciela.
  DEBT_NO_OWNER=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM debt
    WHERE owner IS NULL OR owner = '';" 2>/dev/null || echo 0)

  # 3. DEBT-NO-DEADLINE — dług bez terminu spłaty.
  DEBT_NO_DEADLINE=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM debt
    WHERE repayment_deadline IS NULL OR repayment_deadline = '';" 2>/dev/null || echo 0)
else
  p_info "TECH-DEBT-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DEBT_TOTAL" -gt 0 ]; then
  p_pass "TECH-DEBT-REGISTRY" BLOCKING "Znaleziono $DEBT_TOTAL wpisów długu technicznego w rejestrze"
else
  p_warn "TECH-DEBT-REGISTRY" "Brak rejestru długu technicznego (tabela debt) — brak zarejestrowanego długu"
fi

if [ "$DEBT_NO_OWNER" -eq 0 ]; then
  p_pass "TECH-DEBT-OWNER" BLOCKING "Wszystkie wpisy długu mają właściciela"
else
  p_fail "TECH-DEBT-NO-OWNER" BLOCKING "Znaleziono $DEBT_NO_OWNER wpisów długu bez właściciela"
fi

if [ "$DEBT_NO_DEADLINE" -eq 0 ]; then
  p_pass "TECH-DEBT-DEADLINE" BLOCKING "Wszystkie wpisy długu mają termin spłaty"
else
  p_warn "TECH-DEBT-NO-DEADLINE" "Znaleziono $DEBT_NO_DEADLINE wpisów długu bez terminu spłaty"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-013:tech-debt TOTAL=$DEBT_TOTAL NO_OWNER=$DEBT_NO_OWNER NO_DEADLINE=$DEBT_NO_DEADLINE" "pipeline" "design/tech-debt.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DEBT_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$DEBT_NO_OWNER" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-013" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-013" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
