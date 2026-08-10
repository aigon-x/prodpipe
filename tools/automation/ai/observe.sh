#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-067 — AI OBSERVE (Etap 6: model działa w prod?)
# Rodzina: AI | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje monitoring modelu w produkcji: drift detection, SLO,
# alerty i performance monitoring. W AI predykcja to deployment — ten
# pipeline pilnuje, że model jest stale obserwowany po wdrożeniu.
#
# Wykrywa:
#   * NO-DRIFT-DETECTION   — brak rekordu drift (drift detection)
#   * NO-MODEL-SLO         — brak SLO dla modelu (performance monitoring)
#   * NO-MODEL-ALERTS      — brak alertów dla modelu
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
p_say "=== P-067 AI OBSERVE ==="
p_say "Weryfikacja monitoringu modelu w produkcji (drift / SLO / alerty)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-067"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

DRIFT_COUNT=0
MODEL_SLO=0
MODEL_ALERTS=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Rekordy drift (drift detection) — domain/entity_type zawiera 'model'/'ai'/'data'.
  DRIFT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM drift
    WHERE domain LIKE '%model%' OR domain LIKE '%ai%' OR domain LIKE '%data%'
       OR entity_type LIKE '%model%' OR entity_type LIKE '%data%';" 2>/dev/null || echo 0)
  # SLO dla modelu (service_id zawiera 'model'/'ai').
  MODEL_SLO=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM slo
    WHERE service_id LIKE '%model%' OR service_id LIKE '%ai%';" 2>/dev/null || echo 0)
  # Alerty dla modelu (runbook_ref/owner zawiera 'model'/'ai').
  MODEL_ALERTS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM alerts
    WHERE runbook_ref LIKE '%model%' OR runbook_ref LIKE '%ai%'
       OR owner LIKE '%model%' OR owner LIKE '%ai%';" 2>/dev/null || echo 0)
else
  p_info "AI-OBSERVE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-OBSERVE-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować monitoringu modelu"
elif [ "$DRIFT_COUNT" -eq 0 ] && [ "$MODEL_SLO" -eq 0 ] && [ "$MODEL_ALERTS" -eq 0 ]; then
  p_fail "AI-OBSERVE-NO-MONITORING" BLOCKING "Brak dowodu monitoringu modelu (drift / SLO / alerty) — model nieobserwowany"
else
  p_pass "AI-OBSERVE-MONITORING-PRESENT" BLOCKING "Znaleziono dowód monitoringu (drift=$DRIFT_COUNT, slo=$MODEL_SLO, alerts=$MODEL_ALERTS)"
  if [ "$DRIFT_COUNT" -eq 0 ]; then
    p_fail "AI-OBSERVE-NO-DRIFT" BLOCKING "Brak drift detection (tabela drift) — dryf danych niewykrywany"
  else
    p_pass "AI-OBSERVE-DRIFT" BLOCKING "Znaleziono $DRIFT_COUNT rekordów drift (drift detection)"
  fi
  if [ "$MODEL_SLO" -eq 0 ]; then
    p_fail "AI-OBSERVE-NO-SLO" BLOCKING "Brak SLO dla modelu (performance monitoring)"
  else
    p_pass "AI-OBSERVE-SLO" BLOCKING "Znaleziono $MODEL_SLO SLO dla modelu"
  fi
  if [ "$MODEL_ALERTS" -eq 0 ]; then
    p_warn "AI-OBSERVE-NO-ALERTS" "Brak alertów dla modelu"
  else
    p_pass "AI-OBSERVE-ALERTS" BLOCKING "Znaleziono $MODEL_ALERTS alertów dla modelu"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-067:ai-observe MODE=$AI_MODE DRIFT=$DRIFT_COUNT SLO=$MODEL_SLO ALERTS=$MODEL_ALERTS" "pipeline" "ai/observe.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$DRIFT_COUNT" -gt 0 ] || [ "$MODEL_SLO" -gt 0 ] || [ "$MODEL_ALERTS" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$DRIFT_COUNT" -eq 0 ] || [ "$MODEL_SLO" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-067" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-067" "$repo_verdict" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
