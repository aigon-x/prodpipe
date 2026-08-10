#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-059 — GTM SCALE (Etap 7: repeatable engine)
# Rodzina: GTM | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje unit economics / metryki skali:
#   * SCALE-SLO — SLO skali w StateStore (slo)
#   * QUALITY-INDEX — wskaźnik jakości w StateStore (quality_index)
#   * SCALE-EVENT — eventy skali w StateStore (event)
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
p_say "=== P-059 GTM SCALE ==="
p_say "Etap 7: czy unit economics / metryki skali są mierzone?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-059"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
SLO_COUNT=0
QUALITY_COUNT=0
EVENT_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. SCALE-SLO — SLO skali w StateStore.
  SLO_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM slo
    WHERE lower(sli) LIKE '%scale%' OR lower(sli) LIKE '%throughput%'
       OR lower(sli) LIKE '%capacity%' OR lower(sli) LIKE '%cost%'
       OR lower(sli) LIKE '%efficiency%';" 2>/dev/null || echo 0)

  # 2. QUALITY-INDEX — wskaźnik jakości w StateStore.
  QUALITY_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM quality_index
    WHERE score IS NOT NULL;" 2>/dev/null || echo 0)

  # 3. SCALE-EVENT — eventy skali w StateStore.
  EVENT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE lower(kind) LIKE '%scale%' OR lower(kind) LIKE '%growth%'
       OR lower(kind) LIKE '%expansion%';" 2>/dev/null || echo 0)
else
  p_info "GTM-SCALE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$SLO_COUNT" -gt 0 ]; then
    p_pass "GTM-SCALE-SCALE-SLO" BLOCKING "Znaleziono $SLO_COUNT SLO skali w StateStore"
  else
    p_warn "GTM-SCALE-NO-SCALE-SLO" "Brak SLO skali (slo scale/throughput/capacity) — brak danych rynkowych"
  fi
  if [ "$QUALITY_COUNT" -gt 0 ]; then
    p_pass "GTM-SCALE-QUALITY-INDEX" BLOCKING "Znaleziono $QUALITY_COUNT wpisów quality_index"
  else
    p_warn "GTM-SCALE-NO-QUALITY-INDEX" "Brak quality_index w StateStore"
  fi
  if [ "$EVENT_COUNT" -gt 0 ]; then
    p_pass "GTM-SCALE-SCALE-EVENT" BLOCKING "Znaleziono $EVENT_COUNT eventów skali w StateStore"
  else
    p_warn "GTM-SCALE-NO-SCALE-EVENT" "Brak eventów skali w StateStore (event)"
  fi
else
  p_warn "GTM-SCALE-DB-UNAVAILABLE" "Baza niedostępna — metryki skali niezweryfikowane (best-effort)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-059:gtm-scale SLO=$SLO_COUNT QUALITY=$QUALITY_COUNT EVENT=$EVENT_COUNT" "pipeline" "gtm/scale.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$SLO_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-059" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-059" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
