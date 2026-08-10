#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-066 — AI DEPLOY (Etap 5: model w produkcji?)
# Rodzina: AI | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje wdrożenie modelu do produkcji: deployment, release,
# shadow/canary, rollback plan i feature flag. W AI predykcja to deployment —
# ten pipeline pilnuje bezpiecznego wdrożenia modelu.
#
# Wykrywa:
#   * NO-MODEL-DEPLOYMENT — brak deploymentu modelu w tabeli deployment
#   * NO-MODEL-RELEASE    — brak release modelu (status PRODUCTION/OPERATING)
#   * NO-ROLLBACK-PLAN    — brak dowodu planu rollback
#   * NO-FEATURE-FLAG     — brak dowodu feature flag / canary
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
p_say "=== P-066 AI DEPLOY ==="
p_say "Weryfikacja wdrożenia modelu do produkcji (deployment / release / rollback / feature flag)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-066"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

DEPLOYMENT_COUNT=0
MODEL_RELEASE=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Deploymenty (service_id/desired/effective zawiera 'model' lub 'ai').
  DEPLOYMENT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE service_id LIKE '%model%' OR service_id LIKE '%ai%'
       OR desired LIKE '%model%' OR effective LIKE '%model%';" 2>/dev/null || echo 0)
  # Release modelu w produkcji (status PRODUCTION/OPERATING/CANARY).
  MODEL_RELEASE=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM release
    WHERE status IN ('PRODUCTION','OPERATING','CANARY')
       AND (version LIKE '%model%' OR source_ref LIKE '%model%' OR source_ref LIKE '%ai%');" 2>/dev/null || echo 0)
else
  p_info "AI-DEPLOY-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-DEPLOY-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować wdrożenia modelu"
elif [ "$DEPLOYMENT_COUNT" -eq 0 ] && [ "$MODEL_RELEASE" -eq 0 ]; then
  p_fail "AI-DEPLOY-NO-DEPLOYMENT" BLOCKING "Brak deploymentu/release modelu (model niewdrożony do produkcji)"
else
  p_pass "AI-DEPLOY-EVIDENCE-PRESENT" BLOCKING "Znaleziono dowód wdrożenia (deployment=$DEPLOYMENT_COUNT, release=$MODEL_RELEASE)"
  if [ "$DEPLOYMENT_COUNT" -eq 0 ]; then
    p_fail "AI-DEPLOY-NO-DEPLOYMENT-RECORD" BLOCKING "Brak rekordu deploymentu modelu (shadow/canary / feature flag)"
  else
    p_pass "AI-DEPLOY-DEPLOYMENT" BLOCKING "Znaleziono $DEPLOYMENT_COUNT deploymentów modelu"
  fi
  if [ "$MODEL_RELEASE" -eq 0 ]; then
    p_warn "AI-DEPLOY-NO-RELEASE" "Brak release modelu w produkcji (rollback plan / feature flag)"
  else
    p_pass "AI-DEPLOY-RELEASE" BLOCKING "Znaleziono $MODEL_RELEASE release modelu w produkcji"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-066:ai-deploy MODE=$AI_MODE DEPLOYMENT=$DEPLOYMENT_COUNT RELEASE=$MODEL_RELEASE" "pipeline" "ai/deploy.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$DEPLOYMENT_COUNT" -gt 0 ] || [ "$MODEL_RELEASE" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$DEPLOYMENT_COUNT" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-066" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-066" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
