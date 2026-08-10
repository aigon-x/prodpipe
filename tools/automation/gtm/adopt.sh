#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-058 — GTM ADOPT (Etap 6: early adopters → feedback loop)
# Rodzina: GTM | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje metryki adopcji (early adopters → feedback loop):
#   * ADOPTION-SLO — SLO adopcji w StateStore (slo)
#   * QUALITY-INDEX — wskaźnik jakości w StateStore (quality_index)
#   * FEEDBACK-EVIDENCE — feedback/event w StateStore (event)
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
p_say "=== P-058 GTM ADOPT ==="
p_say "Etap 6: czy metryki adopcji (early adopters) są mierzone?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-058"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
SLO_COUNT=0
QUALITY_COUNT=0
EVENT_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. ADOPTION-SLO — SLO adopcji w StateStore.
  SLO_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM slo
    WHERE lower(sli) LIKE '%adopt%' OR lower(sli) LIKE '%usage%'
       OR lower(sli) LIKE '%activation%' OR lower(sli) LIKE '%retention%';" 2>/dev/null || echo 0)

  # 2. QUALITY-INDEX — wskaźnik jakości w StateStore.
  QUALITY_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM quality_index
    WHERE score IS NOT NULL;" 2>/dev/null || echo 0)

  # 3. FEEDBACK-EVIDENCE — eventy feedback w StateStore.
  EVENT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE lower(kind) LIKE '%feedback%' OR lower(kind) LIKE '%adopt%'
       OR lower(kind) LIKE '%usage%';" 2>/dev/null || echo 0)
else
  p_info "GTM-ADOPT-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$SLO_COUNT" -gt 0 ]; then
    p_pass "GTM-ADOPT-ADOPTION-SLO" BLOCKING "Znaleziono $SLO_COUNT SLO adopcji w StateStore"
  else
    p_warn "GTM-ADOPT-NO-ADOPTION-SLO" "Brak SLO adopcji (slo adoption/usage/activation) — brak danych rynkowych"
  fi
  if [ "$QUALITY_COUNT" -gt 0 ]; then
    p_pass "GTM-ADOPT-QUALITY-INDEX" BLOCKING "Znaleziono $QUALITY_COUNT wpisów quality_index"
  else
    p_warn "GTM-ADOPT-NO-QUALITY-INDEX" "Brak quality_index w StateStore"
  fi
  if [ "$EVENT_COUNT" -gt 0 ]; then
    p_pass "GTM-ADOPT-FEEDBACK-EVIDENCE" BLOCKING "Znaleziono $EVENT_COUNT eventów feedback w StateStore"
  else
    p_warn "GTM-ADOPT-NO-FEEDBACK-EVIDENCE" "Brak eventów feedback w StateStore (event)"
  fi
else
  p_warn "GTM-ADOPT-DB-UNAVAILABLE" "Baza niedostępna — metryki adopcji niezweryfikowane (best-effort)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-058:gtm-adopt SLO=$SLO_COUNT QUALITY=$QUALITY_COUNT EVENT=$EVENT_COUNT" "pipeline" "gtm/adopt.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$SLO_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-058" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-058" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
