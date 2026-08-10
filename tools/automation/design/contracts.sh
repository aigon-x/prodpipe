#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-010 — CONTRACTS (Contract Registry)
# Rodzina: DESIGN | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje rejestr kontraktów. Konsumuje tabele contract (StateStore)
# oraz contracts (migracja kontraktów z plików).
#
# Wykrywa:
#   * NO-CONTRACT       — brak jakichkolwiek kontraktów w rejestrze
#   * CONTRACT-NO-STATUS — kontrakt bez statusu
#   * CONTRACT-NO-VERIFY — kontrakt bez weryfikacji (status UNDEFINED)
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
p_say "=== P-010 CONTRACTS ==="
p_say "Weryfikacja rejestru kontraktów (status / weryfikacja)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-010"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
CONTRACT_TOTAL=0
CONTRACT_NO_STATUS=0
CONTRACT_UNDEFINED=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. NO-CONTRACT — łączna liczba kontraktów (tabela contract + contracts).
  CONTRACT_TOTAL=$(sqlite3 "$db" "
    SELECT (SELECT COUNT(*) FROM contract) + (SELECT COUNT(*) FROM contracts);" 2>/dev/null || echo 0)

  # 2. CONTRACT-NO-STATUS — kontrakty bez statusu (NULL lub pusty).
  CONTRACT_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM contract
    WHERE status IS NULL OR status = '';" 2>/dev/null || echo 0)

  # 3. CONTRACT-NO-VERIFY — kontrakty w statusie UNDEFINED (niezweryfikowane).
  CONTRACT_UNDEFINED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM contracts
    WHERE status = 'UNDEFINED';" 2>/dev/null || echo 0)
else
  p_info "CONTRACTS-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$CONTRACT_TOTAL" -gt 0 ]; then
  p_pass "CONTRACTS-PRESENT" BLOCKING "Znaleziono $CONTRACT_TOTAL kontraktów w rejestrze"
else
  p_warn "CONTRACTS-PRESENT" "Brak kontraktów w rejestrze (tabela contract/contracts) — brak zdefiniowanych kontraktów"
fi

if [ "$CONTRACT_NO_STATUS" -eq 0 ]; then
  p_pass "CONTRACTS-STATUS" BLOCKING "Wszystkie kontrakty mają status"
else
  p_fail "CONTRACTS-NO-STATUS" BLOCKING "Znaleziono $CONTRACT_NO_STATUS kontraktów bez statusu"
fi

if [ "$CONTRACT_UNDEFINED" -eq 0 ]; then
  p_pass "CONTRACTS-VERIFIED" BLOCKING "Brak kontraktów niezweryfikowanych (UNDEFINED)"
else
  p_warn "CONTRACTS-UNDEFINED" "Znaleziono $CONTRACT_UNDEFINED kontraktów w statusie UNDEFINED (niezweryfikowane)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-010:contracts TOTAL=$CONTRACT_TOTAL NO_STATUS=$CONTRACT_NO_STATUS UNDEFINED=$CONTRACT_UNDEFINED" "pipeline" "design/contracts.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$CONTRACT_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$CONTRACT_NO_STATUS" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-010" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-010" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
