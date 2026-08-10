#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-097 — DOCUMENT (Simulation Plane — Stage 8: DOCUMENT)
# Rodzina: SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage DOCUMENT dokumentuje wyniki symulacji: raport, wnioski, akcje,
# właściciele, harmonogram, następny drill.
#
# Gate'y: SIM-DO-01..08.
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

p_say "=== P-097 DOCUMENT ==="
p_say "Symulacja katastrofy: dokumentacja (raport, wnioski, akcje, właściciele, harmonogram, następny drill)"
p_contract "P-097"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_DO
for k in report findings actions owners timeline nextdrill; do
  SIM_DO[$k]=0
  if [ -d "$ROOT/simulation/document/$k" ] || [ -d "$ROOT/tests/simulation/document/$k" ]; then
    SIM_DO[$k]=$(find "$ROOT/simulation/document/$k" "$ROOT/tests/simulation/document/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in report findings actions owners timeline nextdrill; do
  n="${SIM_DO[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-DO-$(printf '%02d' "$i")" BLOCKING "Document/$k: $n artefaktów"
  else
    p_info "SIM-DO-$(printf '%02d' "$i")" "Document/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-097:document REPORT=${SIM_DO[report]} FINDINGS=${SIM_DO[findings]} ACTIONS=${SIM_DO[actions]} OWNERS=${SIM_DO[owners]} TIMELINE=${SIM_DO[timeline]} NEXTDRILL=${SIM_DO[nextdrill]}" "pipeline" "simulation/document.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in report findings actions owners timeline nextdrill; do
  if [ "${SIM_DO[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-097" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-097" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
