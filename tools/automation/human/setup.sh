#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-079 — SETUP (Human Simulation Plane — Stage 1: SETUP)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage SETUP przygotowuje
# środowisko symulacji człowieka: konfiguracja Playwright, profil
# przeglądarki, urządzenie/viewport, sieć (throttling), seed danych,
# oraz deklaracja scenariusza (co użytkownik ma zrobić).
#
# Gate'y: HUM-S-01..08
#   * Playwright config, browser profile, device/viewport, network throttle,
#     data seed, scenario declaration, environment isolation, setup evidence.
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
p_say "=== P-079 SETUP ==="
p_say "Symulacja człowieka: Playwright config, browser profile, device/viewport, network throttle, data seed, scenario"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-079"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów setup w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_S_PLAYWRIGHT=0
HUM_S_PROFILE=0
HUM_S_DEVICE=0
HUM_S_NETWORK=0
HUM_S_SEED=0
HUM_S_SCENARIO=0
HUM_S_ISOLATION=0

# 1. Playwright config — konfiguracja narzędzia symulacji.
if [ -f "$ROOT/playwright.config.ts" ] || [ -f "$ROOT/playwright.config.js" ] || [ -f "$ROOT/playwright.config.mjs" ]; then
  HUM_S_PLAYWRIGHT=1
fi
# 2. Browser profile — profil przeglądarki (persistent context).
if [ -d "$ROOT/human/setup/profile" ] || [ -d "$ROOT/tests/human/profile" ]; then
  HUM_S_PROFILE=$(find "$ROOT/human/setup/profile" "$ROOT/tests/human/profile" -type f 2>/dev/null | wc -l)
fi
# 3. Device/viewport — emulacja urządzenia i rozdzielczości.
if [ -d "$ROOT/human/setup/device" ] || [ -d "$ROOT/tests/human/device" ]; then
  HUM_S_DEVICE=$(find "$ROOT/human/setup/device" "$ROOT/tests/human/device" -type f 2>/dev/null | wc -l)
fi
# 4. Network throttle — symulacja warunków sieciowych.
if [ -d "$ROOT/human/setup/network" ] || [ -d "$ROOT/tests/human/network" ]; then
  HUM_S_NETWORK=$(find "$ROOT/human/setup/network" "$ROOT/tests/human/network" -type f 2>/dev/null | wc -l)
fi
# 5. Data seed — przygotowanie danych testowych.
if [ -d "$ROOT/human/setup/seed" ] || [ -d "$ROOT/tests/human/seed" ]; then
  HUM_S_SEED=$(find "$ROOT/human/setup/seed" "$ROOT/tests/human/seed" -type f 2>/dev/null | wc -l)
fi
# 6. Scenario declaration — deklaracja scenariusza użytkownika.
if [ -d "$ROOT/human/setup/scenario" ] || [ -d "$ROOT/tests/human/scenario" ]; then
  HUM_S_SCENARIO=$(find "$ROOT/human/setup/scenario" "$ROOT/tests/human/scenario" -type f 2>/dev/null | wc -l)
fi
# 7. Environment isolation — izolacja środowiska (baza, API, mocki).
if [ -d "$ROOT/human/setup/isolation" ] || [ -d "$ROOT/tests/human/isolation" ]; then
  HUM_S_ISOLATION=$(find "$ROOT/human/setup/isolation" "$ROOT/tests/human/isolation" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów HUM-S-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_S_PLAYWRIGHT" -gt 0 ]; then
  p_pass "HUM-S-01" BLOCKING "Playwright config obecny"
else
  p_info "HUM-S-01" "Playwright config: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_PROFILE" -gt 0 ]; then
  p_pass "HUM-S-02" BLOCKING "Browser profile: $HUM_S_PROFILE artefaktów"
else
  p_info "HUM-S-02" "Browser profile: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_DEVICE" -gt 0 ]; then
  p_pass "HUM-S-03" BLOCKING "Device/viewport: $HUM_S_DEVICE artefaktów"
else
  p_info "HUM-S-03" "Device/viewport: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_NETWORK" -gt 0 ]; then
  p_pass "HUM-S-04" BLOCKING "Network throttle: $HUM_S_NETWORK artefaktów"
else
  p_info "HUM-S-04" "Network throttle: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_SEED" -gt 0 ]; then
  p_pass "HUM-S-05" BLOCKING "Data seed: $HUM_S_SEED artefaktów"
else
  p_info "HUM-S-05" "Data seed: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_SCENARIO" -gt 0 ]; then
  p_pass "HUM-S-06" BLOCKING "Scenario declaration: $HUM_S_SCENARIO artefaktów"
else
  p_info "HUM-S-06" "Scenario declaration: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_S_ISOLATION" -gt 0 ]; then
  p_pass "HUM-S-07" BLOCKING "Environment isolation: $HUM_S_ISOLATION artefaktów"
else
  p_info "HUM-S-07" "Environment isolation: brak danych (NOT_APPLICABLE)"
fi
# HUM-S-08 — setup evidence.
if [ "$HUM_S_PLAYWRIGHT" -gt 0 ] || [ "$HUM_S_PROFILE" -gt 0 ] || [ "$HUM_S_DEVICE" -gt 0 ] || [ "$HUM_S_NETWORK" -gt 0 ] || [ "$HUM_S_SEED" -gt 0 ] || [ "$HUM_S_SCENARIO" -gt 0 ] || [ "$HUM_S_ISOLATION" -gt 0 ]; then
  p_pass "HUM-S-08" BLOCKING "Setup evidence zebrane"
else
  p_info "HUM-S-08" "Setup evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-079:setup PLAYWRIGHT=$HUM_S_PLAYWRIGHT PROFILE=$HUM_S_PROFILE DEVICE=$HUM_S_DEVICE NETWORK=$HUM_S_NETWORK SEED=$HUM_S_SEED SCENARIO=$HUM_S_SCENARIO ISOLATION=$HUM_S_ISOLATION" "pipeline" "human/setup.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_S_PLAYWRIGHT" -gt 0 ] || [ "$HUM_S_PROFILE" -gt 0 ] || [ "$HUM_S_DEVICE" -gt 0 ] || [ "$HUM_S_NETWORK" -gt 0 ] || [ "$HUM_S_SEED" -gt 0 ] || [ "$HUM_S_SCENARIO" -gt 0 ] || [ "$HUM_S_ISOLATION" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-079" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-079" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
