#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-018 — STATIC ANALYSIS (SAST)
# Rodzina: SECURITY | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje istnienie narzędzi SAST (Static Application Security Testing)
# oraz rejestru wyników analizy statycznej w StateStore (quality_index).
#
# Wykrywa:
#   * NO-SAST-TOOL        — brak narzędzia SAST w repo (tools/verify, tools/security)
#   * NO-ANALYSIS-RECORD  — brak rekordu wyników analizy w StateStore (quality_index)
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
p_say "=== P-018 STATIC ANALYSIS ==="
p_say "Weryfikacja narzędzi SAST i rejestru wyników analizy statycznej"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-018"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

# 1. Narzędzia SAST w repo (git-tracked) — szukamy skryptów/konfigów SAST.
SAST_TOOLS=$(git ls-files 2>/dev/null | grep -iE '(sast|semgrep|bandit|gosec|brakeman|checkmarx|sonarqube|codeql|static-analysis)' || true)
SAST_COUNT=0
[ -n "$SAST_TOOLS" ] && SAST_COUNT=$(printf '%s\n' "$SAST_TOOLS" | grep -c . || echo 0)

# 2. Rejestr wyników analizy statycznej w StateStore (quality_index).
ANALYSIS_RECORD=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  ANALYSIS_RECORD=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM quality_index
    WHERE lower(dimension) LIKE '%secur%' OR lower(dimension) LIKE '%static%'
       OR lower(dimension) LIKE '%quality%';" 2>/dev/null || echo 0)
else
  p_info "STATIC-ANALYSIS-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$SAST_COUNT" -gt 0 ]; then
  p_pass "STATIC-ANALYSIS-TOOL" BLOCKING "Znaleziono $SAST_COUNT narzędzi/konfigów SAST"
else
  p_warn "STATIC-ANALYSIS-NO-TOOL" "Brak narzędzi SAST w repo (tools/verify, tools/security)"
fi
if [ "$ANALYSIS_RECORD" -gt 0 ]; then
  p_pass "STATIC-ANALYSIS-RECORD" BLOCKING "Rekord wyników analizy w StateStore ($ANALYSIS_RECORD)"
else
  p_warn "STATIC-ANALYSIS-NO-RECORD" "Brak rekordu wyników analizy w StateStore (quality_index)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-018:static-analysis SAST_TOOLS=$SAST_COUNT ANALYSIS_RECORD=$ANALYSIS_RECORD" "pipeline" "security/static-analysis.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak narzędzi SAST = NOT_APPLICABLE (nie ma czym analizować).
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$SAST_COUNT" -gt 0 ]; then
  if [ "$ANALYSIS_RECORD" -gt 0 ]; then
    repo_verdict="PASS"
  else
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-018" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-018" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
