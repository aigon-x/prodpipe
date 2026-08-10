#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-054 — GTM DESIGN (Etap 2: rozwiązanie trafia?)
# Rodzina: GTM | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, czy istnieje positioning/messaging dla rozwiązania:
#   * POSITIONING-EVIDENCE — dokument positioning w StateStore (document.kind)
#   * POSITIONING-FILE — plik positioning w repo (git-tracked)
#   * MESSAGING-EVIDENCE — dokument messaging w StateStore
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
p_say "=== P-054 GTM DESIGN ==="
p_say "Etap 2: czy positioning/messaging rozwiązania trafia w rynek?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-054"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
POSITIONING_COUNT=0
MESSAGING_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. POSITIONING-EVIDENCE — dokumenty positioning w StateStore.
  POSITIONING_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM document
    WHERE lower(kind) IN ('positioning','positioning-statement','gtm-positioning');" 2>/dev/null || echo 0)

  # 2. MESSAGING-EVIDENCE — dokumenty messaging w StateStore.
  MESSAGING_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM document
    WHERE lower(kind) IN ('messaging','message-house','value-prop','value-proposition');" 2>/dev/null || echo 0)
else
  p_info "GTM-DESIGN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 3. POSITIONING-FILE — plik positioning w repo (git-tracked).
POSITIONING_FILE_COUNT=$(git ls-files 2>/dev/null | grep -iE 'positioning|messaging|value-prop|gtm-design' | wc -l | tr -d ' ')

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$POSITIONING_COUNT" -gt 0 ]; then
    p_pass "GTM-DESIGN-POSITIONING-EVIDENCE" BLOCKING "Znaleziono $POSITIONING_COUNT dokumentów positioning w StateStore"
  else
    p_warn "GTM-DESIGN-NO-POSITIONING-EVIDENCE" "Brak positioning w StateStore (document.kind) — brak danych rynkowych"
  fi
  if [ "$MESSAGING_COUNT" -gt 0 ]; then
    p_pass "GTM-DESIGN-MESSAGING-EVIDENCE" BLOCKING "Znaleziono $MESSAGING_COUNT dokumentów messaging w StateStore"
  else
    p_warn "GTM-DESIGN-NO-MESSAGING-EVIDENCE" "Brak messaging w StateStore (document.kind)"
  fi
else
  p_warn "GTM-DESIGN-DB-UNAVAILABLE" "Baza niedostępna — positioning niezweryfikowany (best-effort)"
fi
if [ "$POSITIONING_FILE_COUNT" -gt 0 ]; then
  p_pass "GTM-DESIGN-POSITIONING-FILE" BLOCKING "Znaleziono $POSITIONING_FILE_COUNT plików positioning w repo"
else
  p_warn "GTM-DESIGN-NO-POSITIONING-FILE" "Brak pliku positioning w repo (positioning/messaging)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-054:gtm-design POSITIONING=$POSITIONING_COUNT MESSAGING=$MESSAGING_COUNT FILE=$POSITIONING_FILE_COUNT" "pipeline" "gtm/design.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$POSITIONING_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-054" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-054" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
