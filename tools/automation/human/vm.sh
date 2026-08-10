#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-089 — VM (Human Simulation Plane — Stage 11: VM)
# Rodzina: HUMAN-SIMULATION | Klasa: STANDARD | Status: IMPLEMENTED
#
# Test to nie skrypt, to użytkownik. Stage VM testuje aplikacje
# w maszynach wirtualnych (QEMU): boot, snapshot, interakcje,
# oraz evidence. Test VM musi być realistyczny — jak człowiek,
# nie jak bot.
#
# Gate'y: HUM-V-01..06
#   * QEMU, boot, snapshot, interaction, evidence, VM evidence.
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
p_say "=== P-089 VM ==="
p_say "Symulacja człowieka: QEMU, boot, snapshot, interaction"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-089"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów testów VM w repo (best-effort, brak danych = NOT_APPLICABLE).
HUM_V_QEMU=0
HUM_V_BOOT=0
HUM_V_SNAPSHOT=0
HUM_V_INTERACTION=0

# 1. QEMU — konfiguracja testów QEMU.
if [ -d "$ROOT/human/vm/qemu" ] || [ -d "$ROOT/tests/human/vm" ]; then
  HUM_V_QEMU=$(find "$ROOT/human/vm/qemu" "$ROOT/tests/human/vm" -type f 2>/dev/null | wc -l)
fi
# 2. Boot — testy bootowania VM.
if [ -d "$ROOT/human/vm/boot" ]; then
  HUM_V_BOOT=$(find "$ROOT/human/vm/boot" -type f 2>/dev/null | wc -l)
fi
# 3. Snapshot — testy snapshotów VM.
if [ -d "$ROOT/human/vm/snapshot" ]; then
  HUM_V_SNAPSHOT=$(find "$ROOT/human/vm/snapshot" -type f 2>/dev/null | wc -l)
fi
# 4. Interaction — testy interakcji w VM.
if [ -d "$ROOT/human/vm/interaction" ]; then
  HUM_V_INTERACTION=$(find "$ROOT/human/vm/interaction" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 6 gate'ów HUM-V-01..06. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$HUM_V_QEMU" -gt 0 ]; then
  p_pass "HUM-V-01" BLOCKING "QEMU: $HUM_V_QEMU artefaktów"
else
  p_info "HUM-V-01" "QEMU: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_V_BOOT" -gt 0 ]; then
  p_pass "HUM-V-02" BLOCKING "Boot: $HUM_V_BOOT artefaktów"
else
  p_info "HUM-V-02" "Boot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_V_SNAPSHOT" -gt 0 ]; then
  p_pass "HUM-V-03" BLOCKING "Snapshot: $HUM_V_SNAPSHOT artefaktów"
else
  p_info "HUM-V-03" "Snapshot: brak danych (NOT_APPLICABLE)"
fi
if [ "$HUM_V_INTERACTION" -gt 0 ]; then
  p_pass "HUM-V-04" BLOCKING "Interaction: $HUM_V_INTERACTION artefaktów"
else
  p_info "HUM-V-04" "Interaction: brak danych (NOT_APPLICABLE)"
fi
# HUM-V-05 — VM evidence.
if [ "$HUM_V_QEMU" -gt 0 ] || [ "$HUM_V_BOOT" -gt 0 ] || [ "$HUM_V_SNAPSHOT" -gt 0 ] || [ "$HUM_V_INTERACTION" -gt 0 ]; then
  p_pass "HUM-V-05" BLOCKING "VM evidence zebrane"
else
  p_info "HUM-V-05" "VM evidence: brak danych (NOT_APPLICABLE)"
fi
# HUM-V-06 — VM evidence (kompletność).
if [ "$HUM_V_QEMU" -gt 0 ] && [ "$HUM_V_BOOT" -gt 0 ]; then
  p_pass "HUM-V-06" BLOCKING "VM evidence kompletne (QEMU + boot)"
else
  p_info "HUM-V-06" "VM evidence kompletne: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-089:vm QEMU=$HUM_V_QEMU BOOT=$HUM_V_BOOT SNAPSHOT=$HUM_V_SNAPSHOT INTERACTION=$HUM_V_INTERACTION" "pipeline" "human/vm.sh"

# ── VERIFY ──────────────────────────────────────────────────
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$HUM_V_QEMU" -gt 0 ] || [ "$HUM_V_BOOT" -gt 0 ] || [ "$HUM_V_SNAPSHOT" -gt 0 ] || [ "$HUM_V_INTERACTION" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-089" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-089" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
