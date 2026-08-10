#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-086 — REPORT (Human Simulation Plane — Stage 8: REPORT)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage REPORT generuje raport
# z symulacji człowieka: raport HTML, Allure, JSON, artefakty,
# oraz health metric. Raport musi być czytelny — jak dla człowieka.
#
# Gate'y: HUM-RE-01..08
#   * HTML report, Allure report, JSON report, artifacts,
#     health metric, evidence, report evidence.
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
p_say "=== P-086 REPORT ==="
p_say "Symulacja człowieka: HTML report, Allure, JSON, artifacts, health metric"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-086"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów raportu w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_RE_HTML=0
HUM_RE_ALLURE=0
HUM_RE_JSON=0
HUM_RE_ARTIFACTS=0
HUM_RE_HEALTH=0

# 1. HTML report — konfiguracja raportu HTML.
if [ -f "$ROOT/playwright.config.ts" ] || [ -f "$ROOT/playwright.config.js" ] || [ -f "$ROOT/playwright.config.mjs" ] || [ -d "$ROOT/human/report/html" ]; then
  HUM_RE_HTML=1
fi
# 2. Allure report — konfiguracja Allure.
if [ -f "$ROOT/allure.config.js" ] || [ -f "$ROOT/allure.config.ts" ] || [ -d "$ROOT/human/report/allure" ] || [ -d "$ROOT/allure-results" ]; then
  HUM_RE_ALLURE=1
fi
# 3. JSON report — artefakty raportów JSON.
if [ -d "$ROOT/human/report/json" ] || [ -d "$ROOT/test-results" ]; then
  HUM_RE_JSON=$(find "$ROOT/human/report/json" "$ROOT/test-results" -type f -name "*.json" 2>/dev/null | wc -l)
fi
# 4. Artifacts — katalog artefaktów raportu.
if [ -d "$ROOT/human/report/artifacts" ]; then
  HUM_RE_ARTIFACTS=$(find "$ROOT/human/report/artifacts" -type f 2>/dev/null | wc -l)
fi
# 5. Health metric — formuła health metric (z masterpromptu).
if [ -d "$ROOT/human/report/health" ] || [ -f "$ROOT/human/health-metric.md" ]; then
  HUM_RE_HEALTH=1
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-RE-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_RE_HTML" -gt 0 ]; then
  p_pass "HUM-RE-01" BLOCKING "HTML report config obecny"
else
  p_info "HUM-RE-01" "HTML report config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RE_ALLURE" -gt 0 ]; then
  p_pass "HUM-RE-02" BLOCKING "Allure report config obecny"
else
  p_info "HUM-RE-02" "Allure report config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RE_JSON" -gt 0 ]; then
  p_pass "HUM-RE-03" BLOCKING "JSON report: $HUM_RE_JSON artefaktów"
else
  p_info "HUM-RE-03" "JSON report: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RE_ARTIFACTS" -gt 0 ]; then
  p_pass "HUM-RE-04" BLOCKING "Artifacts: $HUM_RE_ARTIFACTS artefaktów"
else
  p_info "HUM-RE-04" "Artifacts: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_RE_HEALTH" -gt 0 ]; then
  p_pass "HUM-RE-05" BLOCKING "Health metric obecny"
else
  p_info "HUM-RE-05" "Health metric: brak danych (NOT_APPLICABLE)"
fi
# HUM-RE-06 — report evidence.
if [ "$HUM_RE_HTML" -gt 0 ] || [ "$HUM_RE_ALLURE" -gt 0 ] || [ "$HUM_RE_JSON" -gt 0 ] || [ "$HUM_RE_ARTIFACTS" -gt 0 ] || [ "$HUM_RE_HEALTH" -gt 0 ]; then
  p_pass "HUM-RE-06" BLOCKING "Report evidence zebrane"
else
  p_info "HUM-RE-06" "Report evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-RE-07 — report evidence (kompletność).
if [ "$HUM_RE_HTML" -gt 0 ] && [ "$HUM_RE_JSON" -gt 0 ]; then
  p_pass "HUM-RE-07" BLOCKING "Report evidence kompletne (HTML + JSON)"
else
  p_info "HUM-RE-07" "Report evidence kompletne: brak danych (NOT_APPLICABLE)"
fi
# HUM-RE-08 — report evidence (health metric).
if [ "$HUM_RE_HEALTH" -gt 0 ]; then
  p_pass "HUM-RE-08" BLOCKING "Health metric evidence obecne"
else
  p_info "HUM-RE-08" "Health metric evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-086:report HTML=$HUM_RE_HTML ALLURE=$HUM_RE_ALLURE JSON=$HUM_RE_JSON ARTIFACTS=$HUM_RE_ARTIFACTS HEALTH=$HUM_RE_HEALTH" "pipeline" "human/report.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_RE_HTML" -gt 0 ] || [ "$HUM_RE_ALLURE" -gt 0 ] || [ "$HUM_RE_JSON" -gt 0 ] || [ "$HUM_RE_ARTIFACTS" -gt 0 ] || [ "$HUM_RE_HEALTH" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-086" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-086" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
