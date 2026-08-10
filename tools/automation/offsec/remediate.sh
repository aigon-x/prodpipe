#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-077 — REMEDIATE (Offensive Security — Remediation)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza naprawy (Purple Team). Atak to test, obrona to gate,
# detekcja to evidence. Weryfikuje zarządzanie poprawkami,
# SLA remediacji i weryfikację napraw.
#
# Gate'y: OFF-RM-01..08
#   * patch management, vulnerability remediation SLA, root cause analysis,
#     fix verification, regression testing, remediation evidence,
#     remediation metrics (MTTR), preventive measures.
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
p_say "=== P-077 REMEDIATE ==="
p_say "Naprawa: patch management, SLA, RCA, weryfikacja fixów, regression, MTTR, prewencja"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-077"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów remediacji w repo (best-effort).
REM_PATCH=0
REM_SLA=0
REM_RCA=0
REM_FIX=0
REM_REGRESSION=0
REM_EVIDENCE=0
REM_MTTR=0
REM_PREVENT=0

if [ -d "$ROOT/offsec/remediate/patch" ]; then
  REM_PATCH=$(find "$ROOT/offsec/remediate/patch" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/sla" ]; then
  REM_SLA=$(find "$ROOT/offsec/remediate/sla" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/rca" ]; then
  REM_RCA=$(find "$ROOT/offsec/remediate/rca" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/fix" ]; then
  REM_FIX=$(find "$ROOT/offsec/remediate/fix" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/regression" ]; then
  REM_REGRESSION=$(find "$ROOT/offsec/remediate/regression" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/evidence" ]; then
  REM_EVIDENCE=$(find "$ROOT/offsec/remediate/evidence" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/mttr" ]; then
  REM_MTTR=$(find "$ROOT/offsec/remediate/mttr" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/remediate/preventive" ]; then
  REM_PREVENT=$(find "$ROOT/offsec/remediate/preventive" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-RM-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$REM_PATCH" -gt 0 ]; then
  p_pass "OFF-RM-01" BLOCKING "Patch management: $REM_PATCH artefaktów"
else
  p_info "OFF-RM-01" "Patch management: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_SLA" -gt 0 ]; then
  p_pass "OFF-RM-02" BLOCKING "Vulnerability remediation SLA: $REM_SLA artefaktów"
else
  p_info "OFF-RM-02" "Vulnerability remediation SLA: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_RCA" -gt 0 ]; then
  p_pass "OFF-RM-03" BLOCKING "Root cause analysis: $REM_RCA artefaktów"
else
  p_info "OFF-RM-03" "Root cause analysis: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_FIX" -gt 0 ]; then
  p_pass "OFF-RM-04" BLOCKING "Fix verification: $REM_FIX artefaktów"
else
  p_info "OFF-RM-04" "Fix verification: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_REGRESSION" -gt 0 ]; then
  p_pass "OFF-RM-05" BLOCKING "Regression testing: $REM_REGRESSION artefaktów"
else
  p_info "OFF-RM-05" "Regression testing: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_EVIDENCE" -gt 0 ]; then
  p_pass "OFF-RM-06" BLOCKING "Remediation evidence: $REM_EVIDENCE artefaktów"
else
  p_info "OFF-RM-06" "Remediation evidence: brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_MTTR" -gt 0 ]; then
  p_pass "OFF-RM-07" BLOCKING "Remediation metrics (MTTR): $REM_MTTR artefaktów"
else
  p_info "OFF-RM-07" "Remediation metrics (MTTR): brak danych (NOT_APPLICABLE)"
fi
if [ "$REM_PREVENT" -gt 0 ]; then
  p_pass "OFF-RM-08" BLOCKING "Preventive measures: $REM_PREVENT artefaktów"
else
  p_info "OFF-RM-08" "Preventive measures: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-077:remediate PATCH=$REM_PATCH SLA=$REM_SLA RCA=$REM_RCA FIX=$REM_FIX REGRESSION=$REM_REGRESSION EVIDENCE=$REM_EVIDENCE MTTR=$REM_MTTR PREVENT=$REM_PREVENT" "pipeline" "offsec/remediate.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$REM_PATCH" -gt 0 ] || [ "$REM_SLA" -gt 0 ] || [ "$REM_RCA" -gt 0 ] || [ "$REM_FIX" -gt 0 ] || [ "$REM_REGRESSION" -gt 0 ] || [ "$REM_EVIDENCE" -gt 0 ] || [ "$REM_MTTR" -gt 0 ] || [ "$REM_PREVENT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-077" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-077" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
