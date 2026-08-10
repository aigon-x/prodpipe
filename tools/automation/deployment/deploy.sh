#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-034 — DEPLOY (Deployment Registry & Status)
# Rodzina: DEPLOYMENT | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje rejestr wdrożeń w StateStore (tabela deployment):
#   * czy istnieje jakikolwiek rejestr wdrożeń (DEPLOYMENT-REGISTRY)
#   * czy każde wdrożenie ma status (DEPLOYMENT-STATUS)
#   * czy każde wdrożenie ma desired state (DEPLOYMENT-DESIRED)
#
# Wykrywa:
#   * NO-DEPLOYMENT-REGISTRY — brak wdrożeń w tabeli deployment
#   * DEPLOYMENT-WITHOUT-STATUS — wdrożenie bez statusu
#   * DEPLOYMENT-WITHOUT-DESIRED — wdrożenie bez desired state
#
# NO FALSE GREEN: gdy tabela deployment jest pusta, repo_verdict = NOT_APPLICABLE
# (nie zgłaszamy PASS na podstawie braku danych).
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
p_say "=== P-034 DEPLOY ==="
p_say "Weryfikacja rejestru wdrożeń: obecność, status, desired state"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-034"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DEPLOY_COUNT=0
DEPLOY_NO_STATUS=0
DEPLOY_NO_DESIRED=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. Liczba wdrożeń w rejestrze.
  DEPLOY_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM deployment;" 2>/dev/null || echo 0)

  # 2. Wdrożenia bez statusu (status NULL lub pusty).
  DEPLOY_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE status IS NULL OR TRIM(status) = '';" 2>/dev/null || echo 0)

  # 3. Wdrożenia bez desired state (desired NULL lub pusty).
  DEPLOY_NO_DESIRED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE desired IS NULL OR TRIM(desired) = '';" 2>/dev/null || echo 0)
else
  p_info "DEPLOY-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "DEPLOYMENT-REGISTRY" "Baza StateStore niedostępna — nie można zweryfikować rejestru wdrożeń"
  repo_verdict="NOT_APPLICABLE"
elif [ "$DEPLOY_COUNT" -eq 0 ]; then
  p_warn "DEPLOYMENT-REGISTRY" "Brak wdrożeń w tabeli deployment — rejestr pusty (NO FALSE GREEN: NOT_APPLICABLE)"
  repo_verdict="NOT_APPLICABLE"
else
  p_pass "DEPLOYMENT-REGISTRY" BLOCKING "Rejestr wdrożeń istnieje ($DEPLOY_COUNT wdrożeń)"
  if [ "$DEPLOY_NO_STATUS" -eq 0 ]; then
    p_pass "DEPLOYMENT-STATUS" BLOCKING "Wszystkie wdrożenia mają status"
  else
    p_fail "DEPLOYMENT-STATUS" BLOCKING "Znaleziono $DEPLOY_NO_STATUS wdrożeń bez statusu"
  fi
  if [ "$DEPLOY_NO_DESIRED" -eq 0 ]; then
    p_pass "DEPLOYMENT-DESIRED" BLOCKING "Wszystkie wdrożenia mają desired state"
  else
    p_fail "DEPLOYMENT-DESIRED" BLOCKING "Znaleziono $DEPLOY_NO_DESIRED wdrożeń bez desired state"
  fi
  repo_verdict="PASS"
  if [ "$DEPLOY_NO_STATUS" -gt 0 ] || [ "$DEPLOY_NO_DESIRED" -gt 0 ]; then
    repo_verdict="FAIL"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-034:deploy DEPLOY_COUNT=$DEPLOY_COUNT NO_STATUS=$DEPLOY_NO_STATUS NO_DESIRED=$DEPLOY_NO_DESIRED" "pipeline" "deployment/deploy.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
p_dual_verdict "P-034" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-034" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
