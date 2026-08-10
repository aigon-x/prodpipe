#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-068 — AI RETRAIN (Etap 7: model aktualny?)
# Rodzina: AI | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje aktualność modelu: retraining, champion/challenger,
# drift-triggered retrain i scheduled retraining. W AI model to artefakt,
# który się starzeje — ten pipeline pilnuje, że model jest regularnie
# odświeżany, gdy dane dryfują.
#
# Wykrywa:
#   * NO-RETRAIN-EVIDENCE  — brak dowodu retraining (drift / slo / event)
#   * NO-SCHEDULED-RETRAIN — brak dowodu scheduled retraining
#   * NO-CHAMPION-CHALLENGER — brak dowodu champion/challenger
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
p_say "=== P-068 AI RETRAIN ==="
p_say "Weryfikacja aktualności modelu (retraining / champion-challenger / drift-triggered)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-068"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

RETRAIN_DRIFT=0
RETRAIN_SLO=0
RETRAIN_EVENT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Drift-triggered retrain — rekordy drift dla modelu/danych.
  RETRAIN_DRIFT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM drift
    WHERE domain LIKE '%model%' OR domain LIKE '%ai%' OR domain LIKE '%data%'
       OR entity_type LIKE '%model%' OR entity_type LIKE '%data%';" 2>/dev/null || echo 0)
  # SLO dla modelu (performance monitoring → trigger retrain).
  RETRAIN_SLO=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM slo
    WHERE service_id LIKE '%model%' OR service_id LIKE '%ai%';" 2>/dev/null || echo 0)
  # Eventy retraining (kind zawiera 'retrain'/'train'/'champion'/'challenger').
  RETRAIN_EVENT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE kind LIKE '%retrain%' OR kind LIKE '%train%'
       OR kind LIKE '%champion%' OR kind LIKE '%challenger%';" 2>/dev/null || echo 0)
else
  p_info "AI-RETRAIN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-RETRAIN-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować aktualności modelu"
elif [ "$RETRAIN_DRIFT" -eq 0 ] && [ "$RETRAIN_SLO" -eq 0 ] && [ "$RETRAIN_EVENT" -eq 0 ]; then
  p_fail "AI-RETRAIN-NO-EVIDENCE" BLOCKING "Brak dowodu retraining (drift / slo / event) — model nieodświeżany"
else
  p_pass "AI-RETRAIN-EVIDENCE-PRESENT" BLOCKING "Znaleziono dowód retraining (drift=$RETRAIN_DRIFT, slo=$RETRAIN_SLO, event=$RETRAIN_EVENT)"
  if [ "$RETRAIN_EVENT" -eq 0 ]; then
    p_fail "AI-RETRAIN-NO-SCHEDULED" BLOCKING "Brak dowodu scheduled retraining / champion-challenger (tabela event)"
  else
    p_pass "AI-RETRAIN-SCHEDULED" BLOCKING "Znaleziono $RETRAIN_EVENT eventów retraining (scheduled / champion-challenger)"
  fi
  if [ "$RETRAIN_DRIFT" -eq 0 ] && [ "$RETRAIN_SLO" -eq 0 ]; then
    p_warn "AI-RETRAIN-NO-TRIGGER" "Brak drift/SLO triggerów retraining (model może się starzeć bez wykrycia)"
  else
    p_pass "AI-RETRAIN-TRIGGER" BLOCKING "Znaleziono trigger retraining (drift=$RETRAIN_DRIFT, slo=$RETRAIN_SLO)"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-068:ai-retrain MODE=$AI_MODE DRIFT=$RETRAIN_DRIFT SLO=$RETRAIN_SLO EVENT=$RETRAIN_EVENT" "pipeline" "ai/retrain.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$RETRAIN_DRIFT" -gt 0 ] || [ "$RETRAIN_SLO" -gt 0 ] || [ "$RETRAIN_EVENT" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$RETRAIN_EVENT" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-068" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-068" "$repo_verdict" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
