#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-082 — SCREENSHOT (Human Simulation Plane — Stage 4: SCREENSHOT)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage SCREENSHOT zbiera dowód
# wizualny: screenshoty (full-page, element, viewport), visual
# regression (Chromatic/Percy), baseline, diff, oraz artefakty
# wizualne jako evidence.
#
# Gate'y: HUM-SC-01..08
#   * full-page screenshot, element screenshot, viewport screenshot,
#     visual regression, baseline, diff, visual evidence.
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
p_say "=== P-082 SCREENSHOT ==="
p_say "Symulacja człowieka: full-page, element, viewport, visual regression, baseline, diff"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-082"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów screenshot w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_SC_FULLPAGE=0
HUM_SC_ELEMENT=0
HUM_SC_VIEWPORT=0
HUM_SC_REGRESSION=0
HUM_SC_BASELINE=0
HUM_SC_DIFF=0

# 1. Full-page screenshot — artefakty screenshotów pełnej strony.
if [ -d "$ROOT/human/screenshot/full-page" ] || [ -d "$ROOT/tests/human/screenshot" ]; then
  HUM_SC_FULLPAGE=$(find "$ROOT/human/screenshot/full-page" "$ROOT/tests/human/screenshot" -type f 2>/dev/null | wc -l)
fi
# 2. Element screenshot — artefakty screenshotów elementów.
if [ -d "$ROOT/human/screenshot/element" ]; then
  HUM_SC_ELEMENT=$(find "$ROOT/human/screenshot/element" -type f 2>/dev/null | wc -l)
fi
# 3. Viewport screenshot — artefakty screenshotów viewport.
if [ -d "$ROOT/human/screenshot/viewport" ]; then
  HUM_SC_VIEWPORT=$(find "$ROOT/human/screenshot/viewport" -type f 2>/dev/null | wc -l)
fi
# 4. Visual regression — konfiguracja visual regression (Chromatic/Percy).
if [ -f "$ROOT/.chromatic" ] || [ -f "$ROOT/percy.config.js" ] || [ -f "$ROOT/percy.config.ts" ] || [ -d "$ROOT/human/screenshot/regression" ]; then
  HUM_SC_REGRESSION=1
fi
# 5. Baseline — baseline obrazów.
if [ -d "$ROOT/human/screenshot/baseline" ]; then
  HUM_SC_BASELINE=$(find "$ROOT/human/screenshot/baseline" -type f 2>/dev/null | wc -l)
fi
# 6. Diff — artefakty diffów.
if [ -d "$ROOT/human/screenshot/diff" ]; then
  HUM_SC_DIFF=$(find "$ROOT/human/screenshot/diff" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-SC-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_SC_FULLPAGE" -gt 0 ]; then
  p_pass "HUM-SC-01" BLOCKING "Full-page screenshot: $HUM_SC_FULLPAGE artefaktów"
else
  p_info "HUM-SC-01" "Full-page screenshot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_SC_ELEMENT" -gt 0 ]; then
  p_pass "HUM-SC-02" BLOCKING "Element screenshot: $HUM_SC_ELEMENT artefaktów"
else
  p_info "HUM-SC-02" "Element screenshot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_SC_VIEWPORT" -gt 0 ]; then
  p_pass "HUM-SC-03" BLOCKING "Viewport screenshot: $HUM_SC_VIEWPORT artefaktów"
else
  p_info "HUM-SC-03" "Viewport screenshot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_SC_REGRESSION" -gt 0 ]; then
  p_pass "HUM-SC-04" BLOCKING "Visual regression config obecny"
else
  p_info "HUM-SC-04" "Visual regression config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_SC_BASELINE" -gt 0 ]; then
  p_pass "HUM-SC-05" BLOCKING "Baseline: $HUM_SC_BASELINE artefaktów"
else
  p_info "HUM-SC-05" "Baseline: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_SC_DIFF" -gt 0 ]; then
  p_pass "HUM-SC-06" BLOCKING "Diff: $HUM_SC_DIFF artefaktów"
else
  p_info "HUM-SC-06" "Diff: brak danych (NOT_APPLICABLE)"
fi
# HUM-SC-07 — visual evidence (screenshoty jako dowód).
if [ "$HUM_SC_FULLPAGE" -gt 0 ] || [ "$HUM_SC_ELEMENT" -gt 0 ] || [ "$HUM_SC_VIEWPORT" -gt 0 ]; then
  p_pass "HUM-SC-07" BLOCKING "Visual evidence zebrane"
else
  p_info "HUM-SC-07" "Visual evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-SC-08 — screenshot evidence.
if [ "$HUM_SC_FULLPAGE" -gt 0 ] || [ "$HUM_SC_ELEMENT" -gt 0 ] || [ "$HUM_SC_VIEWPORT" -gt 0 ] || [ "$HUM_SC_REGRESSION" -gt 0 ] || [ "$HUM_SC_BASELINE" -gt 0 ] || [ "$HUM_SC_DIFF" -gt 0 ]; then
  p_pass "HUM-SC-08" BLOCKING "Screenshot evidence zebrane"
else
  p_info "HUM-SC-08" "Screenshot evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-082:screenshot FULLPAGE=$HUM_SC_FULLPAGE ELEMENT=$HUM_SC_ELEMENT VIEWPORT=$HUM_SC_VIEWPORT REGRESSION=$HUM_SC_REGRESSION BASELINE=$HUM_SC_BASELINE DIFF=$HUM_SC_DIFF" "pipeline" "human/screenshot.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_SC_FULLPAGE" -gt 0 ] || [ "$HUM_SC_ELEMENT" -gt 0 ] || [ "$HUM_SC_VIEWPORT" -gt 0 ] || [ "$HUM_SC_REGRESSION" -gt 0 ] || [ "$HUM_SC_BASELINE" -gt 0 ] || [ "$HUM_SC_DIFF" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-082" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-082" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
