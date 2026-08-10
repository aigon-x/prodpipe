#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-060 — GTM LEARN (Etap 8: continuous validation)
# Rodzina: GTM | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje feedback loop / continuous validation:
#   * LOST-DEAL-EVIDENCE — analiza utraconych deali (event/decision)
#   * FEEDBACK-EVIDENCE — eventy feedback w StateStore (event)
#   * ALERT-EVIDENCE — alerty w StateStore (alerts)
#   * DECISION-EVIDENCE — decyzje w StateStore (decision)
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
p_say "=== P-060 GTM LEARN ==="
p_say "Etap 8: czy feedback loop / continuous validation działa?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-060"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
LOST_DEAL_COUNT=0
FEEDBACK_COUNT=0
ALERT_COUNT=0
DECISION_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. LOST-DEAL-EVIDENCE — analiza utraconych deali (event/decision).
  LOST_DEAL_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE lower(kind) LIKE '%lost%' OR lower(kind) LIKE '%churn%'
       OR lower(kind) LIKE '%win-loss%' OR lower(kind) LIKE '%deal%';" 2>/dev/null || echo 0)

  # 2. FEEDBACK-EVIDENCE — eventy feedback w StateStore.
  FEEDBACK_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE lower(kind) LIKE '%feedback%' OR lower(kind) LIKE '%learn%'
       OR lower(kind) LIKE '%retro%' OR lower(kind) LIKE '%lesson%';" 2>/dev/null || echo 0)

  # 3. ALERT-EVIDENCE — alerty w StateStore.
  ALERT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM alerts
    WHERE status IN ('ACTIVE','ACKNOWLEDGED','RESOLVED');" 2>/dev/null || echo 0)

  # 4. DECISION-EVIDENCE — decyzje w StateStore.
  DECISION_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM decision
    WHERE status = 'CURRENT';" 2>/dev/null || echo 0)
else
  p_info "GTM-LEARN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$LOST_DEAL_COUNT" -gt 0 ]; then
    p_pass "GTM-LEARN-LOST-DEAL-EVIDENCE" BLOCKING "Znaleziono $LOST_DEAL_COUNT eventów lost-deal w StateStore"
  else
    p_warn "GTM-LEARN-NO-LOST-DEAL-EVIDENCE" "Brak analizy utraconych deali (event lost/churn) — brak danych rynkowych"
  fi
  if [ "$FEEDBACK_COUNT" -gt 0 ]; then
    p_pass "GTM-LEARN-FEEDBACK-EVIDENCE" BLOCKING "Znaleziono $FEEDBACK_COUNT eventów feedback w StateStore"
  else
    p_warn "GTM-LEARN-NO-FEEDBACK-EVIDENCE" "Brak eventów feedback w StateStore (event)"
  fi
  if [ "$ALERT_COUNT" -gt 0 ]; then
    p_pass "GTM-LEARN-ALERT-EVIDENCE" BLOCKING "Znaleziono $ALERT_COUNT alertów w StateStore"
  else
    p_warn "GTM-LEARN-NO-ALERT-EVIDENCE" "Brak alertów w StateStore (alerts)"
  fi
  if [ "$DECISION_COUNT" -gt 0 ]; then
    p_pass "GTM-LEARN-DECISION-EVIDENCE" BLOCKING "Znaleziono $DECISION_COUNT decyzji w StateStore"
  else
    p_warn "GTM-LEARN-NO-DECISION-EVIDENCE" "Brak decyzji w StateStore (decision)"
  fi
else
  p_warn "GTM-LEARN-DB-UNAVAILABLE" "Baza niedostępna — feedback loop niezweryfikowany (best-effort)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-060:gtm-learn LOST=$LOST_DEAL_COUNT FEEDBACK=$FEEDBACK_COUNT ALERT=$ALERT_COUNT DECISION=$DECISION_COUNT" "pipeline" "gtm/learn.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$LOST_DEAL_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-060" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-060" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
