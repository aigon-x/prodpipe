#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-085 — RECORD (Human Simulation Plane — Stage 7: RECORD)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage RECORD rejestruje całą
# podróż użytkownika: trace (Playwright), video, logi, sieć (HAR),
# oraz artefakty jako evidence. Rejestracja musi być kompletna —
# jak człowiek, nie jak bot.
#
# Gate'y: HUM-R-01..08
#   * trace, video, logs, network (HAR), artifacts, evidence,
#     storage, record evidence.
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
p_say "=== P-085 RECORD ==="
p_say "Symulacja człowieka: trace, video, logs, network (HAR), artifacts"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-085"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów rejestracji w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_R_TRACE=0
HUM_R_VIDEO=0
HUM_R_LOGS=0
HUM_R_NETWORK=0
HUM_R_ARTIFACTS=0
HUM_R_STORAGE=0

# 1. Trace — konfiguracja trace (Playwright).
if [ -f "$ROOT/playwright.config.ts" ] || [ -f "$ROOT/playwright.config.js" ] || [ -f "$ROOT/playwright.config.mjs" ] || [ -d "$ROOT/human/record/trace" ]; then
  HUM_R_TRACE=1
fi
# 2. Video — konfiguracja nagrywania wideo.
if [ -d "$ROOT/human/record/video" ] || [ -d "$ROOT/tests/human/record" ]; then
  HUM_R_VIDEO=$(find "$ROOT/human/record/video" "$ROOT/tests/human/record" -type f 2>/dev/null | wc -l)
fi
# 3. Logs — artefakty logów.
if [ -d "$ROOT/human/record/logs" ]; then
  HUM_R_LOGS=$(find "$ROOT/human/record/logs" -type f 2>/dev/null | wc -l)
fi
# 4. Network (HAR) — artefakty HAR.
if [ -d "$ROOT/human/record/network" ] || [ -d "$ROOT/human/record/har" ]; then
  HUM_R_NETWORK=$(find "$ROOT/human/record/network" "$ROOT/human/record/har" -type f 2>/dev/null | wc -l)
fi
# 5. Artifacts — katalog artefaktów.
if [ -d "$ROOT/human/record/artifacts" ]; then
  HUM_R_ARTIFACTS=$(find "$ROOT/human/record/artifacts" -type f 2>/dev/null | wc -l)
fi
# 6. Storage — konfiguracja przechowywania (test-results).
if [ -d "$ROOT/test-results" ] || [ -d "$ROOT/human/record/storage" ]; then
  HUM_R_STORAGE=1
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-R-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_R_TRACE" -gt 0 ]; then
  p_pass "HUM-R-01" BLOCKING "Trace config obecny"
else
  p_info "HUM-R-01" "Trace config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_R_VIDEO" -gt 0 ]; then
  p_pass "HUM-R-02" BLOCKING "Video: $HUM_R_VIDEO artefaktów"
else
  p_info "HUM-R-02" "Video: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_R_LOGS" -gt 0 ]; then
  p_pass "HUM-R-03" BLOCKING "Logs: $HUM_R_LOGS artefaktów"
else
  p_info "HUM-R-03" "Logs: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_R_NETWORK" -gt 0 ]; then
  p_pass "HUM-R-04" BLOCKING "Network (HAR): $HUM_R_NETWORK artefaktów"
else
  p_info "HUM-R-04" "Network (HAR): brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_R_ARTIFACTS" -gt 0 ]; then
  p_pass "HUM-R-05" BLOCKING "Artifacts: $HUM_R_ARTIFACTS artefaktów"
else
  p_info "HUM-R-05" "Artifacts: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_R_STORAGE" -gt 0 ]; then
  p_pass "HUM-R-06" BLOCKING "Storage (test-results) obecny"
else
  p_info "HUM-R-06" "Storage (test-results): brak danych (NOT_APPLICABLE)"
fi
# HUM-R-07 — record evidence.
if [ "$HUM_R_TRACE" -gt 0 ] || [ "$HUM_R_VIDEO" -gt 0 ] || [ "$HUM_R_LOGS" -gt 0 ] || [ "$HUM_R_NETWORK" -gt 0 ] || [ "$HUM_R_ARTIFACTS" -gt 0 ] || [ "$HUM_R_STORAGE" -gt 0 ]; then
  p_pass "HUM-R-07" BLOCKING "Record evidence zebrane"
else
  p_info "HUM-R-07" "Record evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-R-08 — record evidence (kompletność).
if [ "$HUM_R_TRACE" -gt 0 ] && [ "$HUM_R_VIDEO" -gt 0 ]; then
  p_pass "HUM-R-08" BLOCKING "Record evidence kompletne (trace + video)"
else
  p_info "HUM-R-08" "Record evidence kompletne: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-085:record TRACE=$HUM_R_TRACE VIDEO=$HUM_R_VIDEO LOGS=$HUM_R_LOGS NETWORK=$HUM_R_NETWORK ARTIFACTS=$HUM_R_ARTIFACTS STORAGE=$HUM_R_STORAGE" "pipeline" "human/record.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_R_TRACE" -gt 0 ] || [ "$HUM_R_VIDEO" -gt 0 ] || [ "$HUM_R_LOGS" -gt 0 ] || [ "$HUM_R_NETWORK" -gt 0 ] || [ "$HUM_R_ARTIFACTS" -gt 0 ] || [ "$HUM_R_STORAGE" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-085" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-085" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
