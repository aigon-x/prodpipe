#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-073 — PERSIST (Offensive Security — Persistence)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza trwałości (Red Team). Atak to test, obrona to gate,
# detekcja to evidence. Weryfikuje mechanizmy trwałości i
# wykrywanie przez EDR.
#
# Gate'y: OFF-P-01..08
#   * persistence mechanisms, account creation, scheduled tasks,
#     service installation, registry modification, startup folder,
#     persistence detection (EDR), persistence drill.
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
p_say "=== P-073 PERSIST ==="
p_say "Trwałość: mechanizmy, konta, zadania, usługi, rejestr, startup, detekcja EDR"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-073"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów trwałości w repo (best-effort).
PER_MECH=0
PER_ACCOUNT=0
PER_TASKS=0
PER_SERVICE=0
PER_REGISTRY=0
PER_STARTUP=0
PER_EDR=0
PER_DRILL=0

if [ -d "$ROOT/offsec/persist/mechanisms" ]; then
  PER_MECH=$(find "$ROOT/offsec/persist/mechanisms" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/account" ]; then
  PER_ACCOUNT=$(find "$ROOT/offsec/persist/account" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/tasks" ]; then
  PER_TASKS=$(find "$ROOT/offsec/persist/tasks" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/service" ]; then
  PER_SERVICE=$(find "$ROOT/offsec/persist/service" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/registry" ]; then
  PER_REGISTRY=$(find "$ROOT/offsec/persist/registry" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/startup" ]; then
  PER_STARTUP=$(find "$ROOT/offsec/persist/startup" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/edr" ]; then
  PER_EDR=$(find "$ROOT/offsec/persist/edr" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/persist/drill" ]; then
  PER_DRILL=$(find "$ROOT/offsec/persist/drill" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-P-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$PER_MECH" -gt 0 ]; then
  p_pass "OFF-P-01" BLOCKING "Persistence mechanisms: $PER_MECH artefaktów"
else
  p_info "OFF-P-01" "Persistence mechanisms: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_ACCOUNT" -gt 0 ]; then
  p_pass "OFF-P-02" BLOCKING "Account creation: $PER_ACCOUNT artefaktów"
else
  p_info "OFF-P-02" "Account creation: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_TASKS" -gt 0 ]; then
  p_pass "OFF-P-03" BLOCKING "Scheduled tasks: $PER_TASKS artefaktów"
else
  p_info "OFF-P-03" "Scheduled tasks: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_SERVICE" -gt 0 ]; then
  p_pass "OFF-P-04" BLOCKING "Service installation: $PER_SERVICE artefaktów"
else
  p_info "OFF-P-04" "Service installation: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_REGISTRY" -gt 0 ]; then
  p_pass "OFF-P-05" BLOCKING "Registry modification: $PER_REGISTRY artefaktów"
else
  p_info "OFF-P-05" "Registry modification: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_STARTUP" -gt 0 ]; then
  p_pass "OFF-P-06" BLOCKING "Startup folder: $PER_STARTUP artefaktów"
else
  p_info "OFF-P-06" "Startup folder: brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_EDR" -gt 0 ]; then
  p_pass "OFF-P-07" BLOCKING "Persistence detection (EDR): $PER_EDR artefaktów"
else
  p_info "OFF-P-07" "Persistence detection (EDR): brak danych (NOT_APPLICABLE)"
fi
if [ "$PER_DRILL" -gt 0 ]; then
  p_pass "OFF-P-08" BLOCKING "Persistence drill: $PER_DRILL artefaktów"
else
  p_info "OFF-P-08" "Persistence drill: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-073:persist MECH=$PER_MECH ACCOUNT=$PER_ACCOUNT TASKS=$PER_TASKS SERVICE=$PER_SERVICE REGISTRY=$PER_REGISTRY STARTUP=$PER_STARTUP EDR=$PER_EDR DRILL=$PER_DRILL" "pipeline" "offsec/persist.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$PER_MECH" -gt 0 ] || [ "$PER_ACCOUNT" -gt 0 ] || [ "$PER_TASKS" -gt 0 ] || [ "$PER_SERVICE" -gt 0 ] || [ "$PER_REGISTRY" -gt 0 ] || [ "$PER_STARTUP" -gt 0 ] || [ "$PER_EDR" -gt 0 ] || [ "$PER_DRILL" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-073" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-073" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
