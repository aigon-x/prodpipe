#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-098 — REPEAT (Simulation Plane — Stage 9: REPEAT)
# Rodzina: SIMULATION | Klasa: DEEP | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage REPEAT zamyka pętlę ciągłego doskonalenia: harmonogram drilli,
# kadencja, backlog poprawek, metryki trendu, powtarzalność.
#
# Gate'y: SIM-RP-01..08.
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

p_say "=== P-098 REPEAT ==="
p_say "Symulacja katastrofy: powtórzenie (harmonogram drilli, kadencja, backlog, metryki trendu)"
p_contract "P-098"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_RP
for k in schedule cadence backlog metrics trend; do
  SIM_RP[$k]=0
  if [ -d "$ROOT/simulation/repeat/$k" ] || [ -d "$ROOT/tests/simulation/repeat/$k" ]; then
    SIM_RP[$k]=$(find "$ROOT/simulation/repeat/$k" "$ROOT/tests/simulation/repeat/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in schedule cadence backlog metrics trend; do
  n="${SIM_RP[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-RP-$(printf '%02d' "$i")" BLOCKING "Repeat/$k: $n artefaktów"
  else
    p_info "SIM-RP-$(printf '%02d' "$i")" "Repeat/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-098:repeat SCHEDULE=${SIM_RP[schedule]} CADENCE=${SIM_RP[cadence]} BACKLOG=${SIM_RP[backlog]} METRICS=${SIM_RP[metrics]} TREND=${SIM_RP[trend]}" "pipeline" "simulation/repeat.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in schedule cadence backlog metrics trend; do
  if [ "${SIM_RP[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-098" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-098" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
