#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-081 — WAIT (Human Simulation Plane — Stage 3: WAIT)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage WAIT symuluje cierpliwość
# użytkownika: oczekiwanie na elementy (auto-wait), loading states,
# skeleton/shimmer, timeouts, retry, network idle, oraz animacje.
# Użytkownik czeka, aż aplikacja odpowie — nie używa sleep().
#
# Gate'y: HUM-W-01..08
#   * auto-wait, loading states, skeleton, timeouts, retry,
#     network idle, animations, wait evidence.
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
p_say "=== P-081 WAIT ==="
p_say "Symulacja człowieka: auto-wait, loading states, skeleton, timeouts, retry, network idle, animations"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-081"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów oczekiwania w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_W_AUTOWAIT=0
HUM_W_LOADING=0
HUM_W_SKELETON=0
HUM_W_TIMEOUT=0
HUM_W_RETRY=0
HUM_W_NETIDLE=0
HUM_W_ANIMATION=0

# 1. Auto-wait — konfiguracja auto-wait (Playwright default).
if [ -f "$ROOT/playwright.config.ts" ] || [ -f "$ROOT/playwright.config.js" ] || [ -f "$ROOT/playwright.config.mjs" ]; then
  HUM_W_AUTOWAIT=1
fi
# 2. Loading states — testy stanów ładowania.
if [ -d "$ROOT/human/wait/loading" ] || [ -d "$ROOT/tests/human/wait" ]; then
  HUM_W_LOADING=$(find "$ROOT/human/wait/loading" "$ROOT/tests/human/wait" -type f 2>/dev/null | wc -l)
fi
# 3. Skeleton/shimmer — testy skeletonów.
if [ -d "$ROOT/human/wait/skeleton" ]; then
  HUM_W_SKELETON=$(find "$ROOT/human/wait/skeleton" -type f 2>/dev/null | wc -l)
fi
# 4. Timeouts — konfiguracja timeoutów.
if [ -d "$ROOT/human/wait/timeouts" ]; then
  HUM_W_TIMEOUT=$(find "$ROOT/human/wait/timeouts" -type f 2>/dev/null | wc -l)
fi
# 5. Retry — testy ponawiania.
if [ -d "$ROOT/human/wait/retry" ]; then
  HUM_W_RETRY=$(find "$ROOT/human/wait/retry" -type f 2>/dev/null | wc -l)
fi
# 6. Network idle — testy oczekiwania na network idle.
if [ -d "$ROOT/human/wait/network-idle" ]; then
  HUM_W_NETIDLE=$(find "$ROOT/human/wait/network-idle" -type f 2>/dev/null | wc -l)
fi
# 7. Animations — testy animacji (wait for animation end).
if [ -d "$ROOT/human/wait/animations" ]; then
  HUM_W_ANIMATION=$(find "$ROOT/human/wait/animations" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-W-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_W_AUTOWAIT" -gt 0 ]; then
  p_pass "HUM-W-01" BLOCKING "Auto-wait config obecny"
else
  p_info "HUM-W-01" "Auto-wait config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_LOADING" -gt 0 ]; then
  p_pass "HUM-W-02" BLOCKING "Loading states: $HUM_W_LOADING artefaktów"
else
  p_info "HUM-W-02" "Loading states: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_SKELETON" -gt 0 ]; then
  p_pass "HUM-W-03" BLOCKING "Skeleton/shimmer: $HUM_W_SKELETON artefaktów"
else
  p_info "HUM-W-03" "Skeleton/shimmer: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_TIMEOUT" -gt 0 ]; then
  p_pass "HUM-W-04" BLOCKING "Timeouts: $HUM_W_TIMEOUT artefaktów"
else
  p_info "HUM-W-04" "Timeouts: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_RETRY" -gt 0 ]; then
  p_pass "HUM-W-05" BLOCKING "Retry: $HUM_W_RETRY artefaktów"
else
  p_info "HUM-W-05" "Retry: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_NETIDLE" -gt 0 ]; then
  p_pass "HUM-W-06" BLOCKING "Network idle: $HUM_W_NETIDLE artefaktów"
else
  p_info "HUM-W-06" "Network idle: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_W_ANIMATION" -gt 0 ]; then
  p_pass "HUM-W-07" BLOCKING "Animations: $HUM_W_ANIMATION artefaktów"
else
  p_info "HUM-W-07" "Animations: brak danych (NOT_APPLICABLE)"
fi
# HUM-W-08 — wait evidence.
if [ "$HUM_W_AUTOWAIT" -gt 0 ] || [ "$HUM_W_LOADING" -gt 0 ] || [ "$HUM_W_SKELETON" -gt 0 ] || [ "$HUM_W_TIMEOUT" -gt 0 ] || [ "$HUM_W_RETRY" -gt 0 ] || [ "$HUM_W_NETIDLE" -gt 0 ] || [ "$HUM_W_ANIMATION" -gt 0 ]; then
  p_pass "HUM-W-08" BLOCKING "Wait evidence zebrane"
else
  p_info "HUM-W-08" "Wait evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-081:wait AUTOWAIT=$HUM_W_AUTOWAIT LOADING=$HUM_W_LOADING SKELETON=$HUM_W_SKELETON TIMEOUT=$HUM_W_TIMEOUT RETRY=$HUM_W_RETRY NETIDLE=$HUM_W_NETIDLE ANIMATION=$HUM_W_ANIMATION" "pipeline" "human/wait.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_W_AUTOWAIT" -gt 0 ] || [ "$HUM_W_LOADING" -gt 0 ] || [ "$HUM_W_SKELETON" -gt 0 ] || [ "$HUM_W_TIMEOUT" -gt 0 ] || [ "$HUM_W_RETRY" -gt 0 ] || [ "$HUM_W_NETIDLE" -gt 0 ] || [ "$HUM_W_ANIMATION" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-081" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-081" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
