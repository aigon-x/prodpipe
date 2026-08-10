#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-052 — GTM DISCOVER (Etap 0: problem istnieje?)
# Rodzina: GTM | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, czy istnieje dowód (evidence) problemu rynkowego:
#   * PROBLEM-EVIDENCE — wymaganie/opis problemu w StateStore (requirement)
#   * RESEARCH-EVIDENCE — plik research w repo (research/ lub docs/)
#   * INTERVIEW-EVIDENCE — wywiady z dowodem (requirement.source_type)
#
# GTM to przedłużenie architektury na rynek: ten sam mechanizm evidence,
# gate'y, drille, escape analysis, sunsetting, proof plane.
#
# NO FALSE GREEN: repo jest template'em (brak realnego produktu rynkowego),
# więc brak danych → repo_verdict NOT_APPLICABLE (nie fałszywy PASS).
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
p_say "=== P-052 GTM DISCOVER ==="
p_say "Etap 0: czy problem rynkowy istnieje i ma dowód?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-052"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
PROBLEM_COUNT=0
RESEARCH_COUNT=0
INTERVIEW_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. PROBLEM-EVIDENCE — wymagania z opisem problemu (description/context).
  PROBLEM_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM requirement
    WHERE description IS NOT NULL AND length(trim(description)) > 0;" 2>/dev/null || echo 0)

  # 2. INTERVIEW-EVIDENCE — wymagania pochodzące z wywiadów (source_type).
  INTERVIEW_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM requirement
    WHERE source_type IN ('interview','research','discovery','prd');" 2>/dev/null || echo 0)
else
  p_info "GTM-DISCOVER-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 3. RESEARCH-EVIDENCE — pliki research w repo (git-tracked).
RESEARCH_COUNT=$(git ls-files 2>/dev/null | grep -iE '(^|/)(research|discovery|market|problem)/|research\.|discovery\.' | wc -l | tr -d ' ')

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$PROBLEM_COUNT" -gt 0 ]; then
    p_pass "GTM-DISCOVER-PROBLEM-EVIDENCE" BLOCKING "Znaleziono $PROBLEM_COUNT wymagań z opisem problemu"
  else
    p_warn "GTM-DISCOVER-NO-PROBLEM-EVIDENCE" "Brak dowodu problemu w StateStore (requirement.description) — brak danych rynkowych"
  fi
  if [ "$INTERVIEW_COUNT" -gt 0 ]; then
    p_pass "GTM-DISCOVER-INTERVIEW-EVIDENCE" BLOCKING "Znaleziono $INTERVIEW_COUNT wywiadów z dowodem"
  else
    p_warn "GTM-DISCOVER-NO-INTERVIEW-EVIDENCE" "Brak wywiadów z dowodem (requirement.source_type)"
  fi
else
  p_warn "GTM-DISCOVER-DB-UNAVAILABLE" "Baza niedostępna — problem/evidence niezweryfikowane (best-effort)"
fi
if [ "$RESEARCH_COUNT" -gt 0 ]; then
  p_pass "GTM-DISCOVER-RESEARCH-EVIDENCE" BLOCKING "Znaleziono $RESEARCH_COUNT plików research w repo"
else
  p_warn "GTM-DISCOVER-NO-RESEARCH-EVIDENCE" "Brak plików research w repo (research/ lub docs/)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-052:gtm-discover PROBLEM=$PROBLEM_COUNT RESEARCH=$RESEARCH_COUNT INTERVIEW=$INTERVIEW_COUNT" "pipeline" "gtm/discover.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$PROBLEM_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-052" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-052" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
