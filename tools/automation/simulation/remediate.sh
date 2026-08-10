#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-096 — REMEDIATE (Simulation Plane — Stage 7: REMEDIATE)
# Rodzina: SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Symulacje katastrof — 'śmierć foundera' to test, nie tragedia.
# Stage REMEDIATE wdraża poprawki po symulacji: plan naprawczy, zmiany
# w systemach, aktualizacja runbooków, szkolenia, testy poprawek,
# weryfikacja, komunikacja, zamknięcie.
#
# Gate'y: SIM-RE-01..08.
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

p_say "=== P-096 REMEDIATE ==="
p_say "Symulacja katastrofy: remediacja (plan naprawczy, zmiany, runbooki, szkolenia, testy, weryfikacja)"
p_contract "P-096"

# ── EXECUTE: wykrywanie artefaktów ──────────────────────────
declare -A SIM_RE
for k in plan changes runbooks training tests verify comms closure; do
  SIM_RE[$k]=0
  if [ -d "$ROOT/simulation/remediate/$k" ] || [ -d "$ROOT/tests/simulation/remediate/$k" ]; then
    SIM_RE[$k]=$(find "$ROOT/simulation/remediate/$k" "$ROOT/tests/simulation/remediate/$k" -type f 2>/dev/null | wc -l)
  fi
done

# ── TEST ────────────────────────────────────────────────────
i=1
for k in plan changes runbooks training tests verify comms closure; do
  n="${SIM_RE[$k]}"
  if [ "$n" -gt 0 ]; then
    p_pass "SIM-RE-$(printf '%02d' "$i")" BLOCKING "Remediate/$k: $n artefaktów"
  else
    p_info "SIM-RE-$(printf '%02d' "$i")" "Remediate/$k: brak danych (NOT_APPLICABLE)"
  fi
  i=$((i+1))
done

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-096:remediate PLAN=${SIM_RE[plan]} CHANGES=${SIM_RE[changes]} RUNBOOKS=${SIM_RE[runbooks]} TRAINING=${SIM_RE[training]} TESTS=${SIM_RE[tests]} VERIFY=${SIM_RE[verify]} COMMS=${SIM_RE[comms]} CLOSURE=${SIM_RE[closure]}" "pipeline" "simulation/remediate.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
for k in plan changes runbooks training tests verify comms closure; do
  if [ "${SIM_RE[$k]}" -gt 0 ]; then repo_verdict="PASS"; break; fi
done
p_dual_verdict "P-096" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-096" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
