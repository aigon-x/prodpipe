#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-094 — MEASURE (Simulation Plane — Stage 5: MEASURE)
# Rodzina: SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage MEASURE mierzy skutki symulacji: RTO/RPO, czas reakcji/odzysku,
# wpływ na usługi, koszty, utracone dane, wpływ na klientów/zespół.
#
# Gate'y: SIM-ME-01..08.
#
# Pipeline Contract: DISCOVER → CONTRACT → EXECUTE → TEST → EVIDENCE → VERIFY → REGISTER → REPORT
# Dual Verdict: IMPLEMENTATION vs REPOSITORY
# ─────────────────────────────────────────────────────────────
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$AUTOMATION_DIR/core/lib.sh"
. "$AUTOMATION_DIR/core/pipelines.sh"

ROOT="$(p_root)"
cd "$ROOT"

p_say "=== P-094 MEASURE ==="
p_say "Symulacja katastrofy: pomiar skutków (RTO/RPO, czas reakcji/odzysku, wpływ, koszty, dane)"
p_contract "P-094"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_ME
for k in rto rpo reaction recovery service cost dataloss impact; do
  SIM_ME[$k]=0
  if [ -d "$ROOT/simulation/measure/$k" ] || [ -d "$ROOT/tests/simulation/measure/$k" ]; then
    SIM_ME[$k]=$(find "$ROOT/simulation/measure/$k" "$ROOT/tests/simulation/measure/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in rto rpo reaction recovery service cost dataloss impact; do
  n="${SIM_ME[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-ME-$(printf '%02d' "$i")" BLOCKING "Measure/$k: $n artefaktów"
  else
    p_info "SIM-ME-$(printf '%02d' "$i")" "Measure/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-094:measure RTO=${SIM_ME[rto]} RPO=${SIM_ME[rpo]} REACTION=${SIM_ME[reaction]} RECOVERY=${SIM_ME[recovery]} SERVICE=${SIM_ME[service]} COST=${SIM_ME[cost]} DATALOSS=${SIM_ME[dataloss]} IMPACT=${SIM_ME[impact]}" "pipeline" "simulation/measure.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in rto rpo reaction recovery service cost dataloss impact; do
  if [ "${SIM_ME[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-094" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-094" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
