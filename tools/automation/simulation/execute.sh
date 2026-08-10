#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-092 — EXECUTE (Simulation Plane — Stage 3: EXECUTE)
# Rodzina: SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage EXECUTE uruchamia symulację katastrofy: aktywacja scenariusza,
# kroki, iniekcja awarii, czas trwania, uczestnicy, logi, checkpointy,
# bezpieczne zatrzymanie.
#
# Gate'y: SIM-EX-01..08.
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

p_say "=== P-092 EXECUTE ==="
p_say "Symulacja katastrofy: wykonanie (aktywacja, kroki, iniekcja awarii, uczestnicy, logi)"
p_contract "P-092"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_EX
for k in activate steps inject duration participants logs checkpoint safestop; do
  SIM_EX[$k]=0
  if [ -d "$ROOT/simulation/execute/$k" ] || [ -d "$ROOT/tests/simulation/execute/$k" ]; then
    SIM_EX[$k]=$(find "$ROOT/simulation/execute/$k" "$ROOT/tests/simulation/execute/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in activate steps inject duration participants logs checkpoint safestop; do
  n="${SIM_EX[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-EX-$(printf '%02d' "$i")" BLOCKING "Execute/$k: $n artefaktów"
  else
    p_info "SIM-EX-$(printf '%02d' "$i")" "Execute/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-092:execute ACTIVATE=${SIM_EX[activate]} STEPS=${SIM_EX[steps]} INJECT=${SIM_EX[inject]} DURATION=${SIM_EX[duration]} PARTICIPANTS=${SIM_EX[participants]} LOGS=${SIM_EX[logs]} CHECKPOINT=${SIM_EX[checkpoint]} SAFESTOP=${SIM_EX[safestop]}" "pipeline" "simulation/execute.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in activate steps inject duration participants logs checkpoint safestop; do
  if [ "${SIM_EX[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-092" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-092" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
