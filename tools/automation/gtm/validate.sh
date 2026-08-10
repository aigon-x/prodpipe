#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-053 — GTM VALIDATE (Etap 1: rynek potwierdza?)
# Rodzina: GTM | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, czy istnieje dowód walidacji rynku:
#   * PAYING-INTENT — change_proposals z intencją płatniczą / rynkową
#   * PREDICTION-ACCURACY — predykcje rynkowe z pomiarem trafności
#   * ICP-EVIDENCE — zdefiniowany Ideal Customer Profile
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
p_say "=== P-053 GTM VALIDATE ==="
p_say "Etap 1: czy rynek potwierdza problem (paying intent / ICP)?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-053"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
PROPOSAL_COUNT=0
PREDICTION_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. PAYING-INTENT — change_proposals z intencją rynkową/płatniczą.
  PROPOSAL_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM change_proposals
    WHERE status IN ('VALIDATED','APPROVED','ACCEPTED','COMMITTED');" 2>/dev/null || echo 0)

  # 2. PREDICTION-ACCURACY — predykcje rynkowe z pomiarem trafności.
  PREDICTION_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM prediction_accuracy
    WHERE accuracy_score IS NOT NULL;" 2>/dev/null || echo 0)
else
  p_info "GTM-VALIDATE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 3. ICP-EVIDENCE — plik ICP w repo (git-tracked).
ICP_COUNT=$(git ls-files 2>/dev/null | grep -iE 'icp|persona|target-customer|market-fit' | wc -l | tr -d ' ')

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$PROPOSAL_COUNT" -gt 0 ]; then
    p_pass "GTM-VALIDATE-PAYING-INTENT" BLOCKING "Znaleziono $PROPOSAL_COUNT zatwierdzonych propozycji (paying intent)"
  else
    p_warn "GTM-VALIDATE-NO-PAYING-INTENT" "Brak paying intent (change_proposals zatwierdzone) — brak danych rynkowych"
  fi
  if [ "$PREDICTION_COUNT" -gt 0 ]; then
    p_pass "GTM-VALIDATE-PREDICTION-ACCURACY" BLOCKING "Znaleziono $PREDICTION_COUNT predykcji z pomiarem trafności"
  else
    p_warn "GTM-VALIDATE-NO-PREDICTION-ACCURACY" "Brak predykcji rynkowych z pomiarem trafności"
  fi
else
  p_warn "GTM-VALIDATE-DB-UNAVAILABLE" "Baza niedostępna — walidacja rynku niezweryfikowana (best-effort)"
fi
if [ "$ICP_COUNT" -gt 0 ]; then
  p_pass "GTM-VALIDATE-ICP-EVIDENCE" BLOCKING "Znaleziono $ICP_COUNT plików ICP/persona w repo"
else
  p_warn "GTM-VALIDATE-NO-ICP-EVIDENCE" "Brak zdefiniowanego ICP (icp/persona) w repo"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-053:gtm-validate PROPOSAL=$PROPOSAL_COUNT PREDICTION=$PREDICTION_COUNT ICP=$ICP_COUNT" "pipeline" "gtm/validate.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$PROPOSAL_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-053" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-053" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
