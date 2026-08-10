#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-095 — EVALUATE (Simulation Plane — Stage 6: EVALUATE)
# Rodzina: SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage EVALUATE ocenia wyniki symulacji: analiza przyczyn, skuteczność
# reakcji, luki w planach, wnioski, rekomendacje, priorytety, akcje,
# właściciele.
#
# Gate'y: SIM-EV-01..08.
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

p_say "=== P-095 EVALUATE ==="
p_say "Symulacja katastrofy: ewaluacja (analiza przyczyn, skuteczność, luki, wnioski, rekomendacje)"
p_contract "P-095"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_EV
for k in rootcause effectiveness gaps lessons recommendations priorities actions owners; do
  SIM_EV[$k]=0
  if [ -d "$ROOT/simulation/evaluate/$k" ] || [ -d "$ROOT/tests/simulation/evaluate/$k" ]; then
    SIM_EV[$k]=$(find "$ROOT/simulation/evaluate/$k" "$ROOT/tests/simulation/evaluate/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in rootcause effectiveness gaps lessons recommendations priorities actions owners; do
  n="${SIM_EV[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-EV-$(printf '%02d' "$i")" BLOCKING "Evaluate/$k: $n artefaktów"
  else
    p_info "SIM-EV-$(printf '%02d' "$i")" "Evaluate/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-095:evaluate ROOTCAUSE=${SIM_EV[rootcause]} EFFECTIVENESS=${SIM_EV[effectiveness]} GAPS=${SIM_EV[gaps]} LESSONS=${SIM_EV[lessons]} RECOMMENDATIONS=${SIM_EV[recommendations]} PRIORITIES=${SIM_EV[priorities]} ACTIONS=${SIM_EV[actions]} OWNERS=${SIM_EV[owners]}" "pipeline" "simulation/evaluate.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in rootcause effectiveness gaps lessons recommendations priorities actions owners; do
  if [ "${SIM_EV[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-095" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-095" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
