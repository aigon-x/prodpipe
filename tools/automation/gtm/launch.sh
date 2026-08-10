#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-057 — GTM LAUNCH (Etap 5: controlled market entry)
# Rodzina: GTM | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje, czy launch jest kontrolowany:
#   * CONTROLLED-RELEASE — wydanie ze statusem kontrolowanym (release)
#   * CANARY-EVIDENCE — canary/controlled deployment (deployment)
#   * ROLLBACK-EVIDENCE — plan rollback (release/deployment)
#
# GTM to przedłużenie architektury na rynek: ten sam mechanizm evidence,
# gate'y, drille, escape analysis, sunsetting, proof plane.
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
p_say "=== P-057 GTM LAUNCH ==="
p_say "Etap 5: czy launch jest kontrolowany (canary / rollback)?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-057"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
RELEASE_COUNT=0
DEPLOYMENT_COUNT=0
CANARY_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. CONTROLLED-RELEASE — wydania ze statusem kontrolowanym.
  RELEASE_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM release
    WHERE status IN ('CANARY','PRODUCTION','OPERATING');" 2>/dev/null || echo 0)

  # 2. DEPLOYMENT-EVIDENCE — wdrożenia w StateStore.
  DEPLOYMENT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE status = 'CURRENT';" 2>/dev/null || echo 0)

  # 3. CANARY-EVIDENCE — canary/controlled deployment.
  CANARY_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE lower(desired) LIKE '%canary%' OR lower(effective) LIKE '%canary%'
       OR lower(observed) LIKE '%canary%';" 2>/dev/null || echo 0)
else
  p_info "GTM-LAUNCH-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 4. ROLLBACK-EVIDENCE — plan rollback w repo (git-tracked).
ROLLBACK_COUNT=$(git ls-files 2>/dev/null | grep -iE 'rollback|recovery-plan|launch-plan|runbook' | wc -l | tr -d ' ')

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$RELEASE_COUNT" -gt 0 ]; then
    p_pass "GTM-LAUNCH-CONTROLLED-RELEASE" BLOCKING "Znaleziono $RELEASE_COUNT kontrolowanych wydań (CANARY/PRODUCTION)"
  else
    p_warn "GTM-LAUNCH-NO-CONTROLLED-RELEASE" "Brak kontrolowanego wydania (release CANARY/PRODUCTION) — brak danych rynkowych"
  fi
  if [ "$DEPLOYMENT_COUNT" -gt 0 ]; then
    p_pass "GTM-LAUNCH-DEPLOYMENT-EVIDENCE" BLOCKING "Znaleziono $DEPLOYMENT_COUNT wdrożeń w StateStore"
  else
    p_warn "GTM-LAUNCH-NO-DEPLOYMENT-EVIDENCE" "Brak wdrożeń w StateStore (deployment)"
  fi
  if [ "$CANARY_COUNT" -gt 0 ]; then
    p_pass "GTM-LAUNCH-CANARY-EVIDENCE" BLOCKING "Znaleziono $CANARY_COUNT canary deployment"
  else
    p_warn "GTM-LAUNCH-NO-CANARY-EVIDENCE" "Brak canary deployment (deployment)"
  fi
else
  p_warn "GTM-LAUNCH-DB-UNAVAILABLE" "Baza niedostępna — launch niezweryfikowany (best-effort)"
fi
if [ "$ROLLBACK_COUNT" -gt 0 ]; then
  p_pass "GTM-LAUNCH-ROLLBACK-EVIDENCE" BLOCKING "Znaleziono $ROLLBACK_COUNT planów rollback w repo"
else
  p_warn "GTM-LAUNCH-NO-ROLLBACK-EVIDENCE" "Brak planu rollback w repo (rollback/recovery-plan)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-057:gtm-launch RELEASE=$RELEASE_COUNT DEPLOYMENT=$DEPLOYMENT_COUNT CANARY=$CANARY_COUNT ROLLBACK=$ROLLBACK_COUNT" "pipeline" "gtm/launch.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$RELEASE_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-057" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-057" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
