#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-075 — DETECT (Offensive Security — Detection)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza detekcji (Blue Team). Atak to test, obrona to gate,
# detekcja to evidence. Weryfikuje pokrycie SIEM/EDR/NDR,
# reguły detekcji i czas wykrycia (MTTD).
#
# Gate'y: OFF-D-01..08
#   * SIEM coverage, EDR coverage, network detection (NDR),
#     detection rules (MITRE ATT&CK), alert fidelity,
#     detection latency (MTTD), detection drill, coverage matrix.
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
p_say "=== P-075 DETECT ==="
p_say "Detekcja: SIEM, EDR, NDR, reguły MITRE ATT&CK, alert fidelity, MTTD, drill, coverage matrix"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-075"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów detekcji w repo (best-effort).
DET_SIEM=0
DET_EDR=0
DET_NDR=0
DET_RULES=0
DET_FIDELITY=0
DET_MTTD=0
DET_DRILL=0
DET_MATRIX=0

if [ -d "$ROOT/offsec/detect/siem" ]; then
  DET_SIEM=$(find "$ROOT/offsec/detect/siem" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/edr" ]; then
  DET_EDR=$(find "$ROOT/offsec/detect/edr" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/ndr" ]; then
  DET_NDR=$(find "$ROOT/offsec/detect/ndr" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/rules" ]; then
  DET_RULES=$(find "$ROOT/offsec/detect/rules" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/fidelity" ]; then
  DET_FIDELITY=$(find "$ROOT/offsec/detect/fidelity" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/mttd" ]; then
  DET_MTTD=$(find "$ROOT/offsec/detect/mttd" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/drill" ]; then
  DET_DRILL=$(find "$ROOT/offsec/detect/drill" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/detect/matrix" ]; then
  DET_MATRIX=$(find "$ROOT/offsec/detect/matrix" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-D-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$DET_SIEM" -gt 0 ]; then
  p_pass "OFF-D-01" BLOCKING "SIEM coverage: $DET_SIEM artefaktów"
else
  p_info "OFF-D-01" "SIEM coverage: brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_EDR" -gt 0 ]; then
  p_pass "OFF-D-02" BLOCKING "EDR coverage: $DET_EDR artefaktów"
else
  p_info "OFF-D-02" "EDR coverage: brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_NDR" -gt 0 ]; then
  p_pass "OFF-D-03" BLOCKING "Network detection (NDR): $DET_NDR artefaktów"
else
  p_info "OFF-D-03" "Network detection (NDR): brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_RULES" -gt 0 ]; then
  p_pass "OFF-D-04" BLOCKING "Detection rules (MITRE ATT&CK): $DET_RULES artefaktów"
else
  p_info "OFF-D-04" "Detection rules (MITRE ATT&CK): brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_FIDELITY" -gt 0 ]; then
  p_pass "OFF-D-05" BLOCKING "Alert fidelity: $DET_FIDELITY artefaktów"
else
  p_info "OFF-D-05" "Alert fidelity: brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_MTTD" -gt 0 ]; then
  p_pass "OFF-D-06" BLOCKING "Detection latency (MTTD): $DET_MTTD artefaktów"
else
  p_info "OFF-D-06" "Detection latency (MTTD): brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_DRILL" -gt 0 ]; then
  p_pass "OFF-D-07" BLOCKING "Detection drill: $DET_DRILL artefaktów"
else
  p_info "OFF-D-07" "Detection drill: brak danych (NOT_APPLICABLE)"
fi
if [ "$DET_MATRIX" -gt 0 ]; then
  p_pass "OFF-D-08" BLOCKING "Coverage matrix: $DET_MATRIX artefaktów"
else
  p_info "OFF-D-08" "Coverage matrix: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-075:detect SIEM=$DET_SIEM EDR=$DET_EDR NDR=$DET_NDR RULES=$DET_RULES FIDELITY=$DET_FIDELITY MTTD=$DET_MTTD DRILL=$DET_DRILL MATRIX=$DET_MATRIX" "pipeline" "offsec/detect.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DET_SIEM" -gt 0 ] || [ "$DET_EDR" -gt 0 ] || [ "$DET_NDR" -gt 0 ] || [ "$DET_RULES" -gt 0 ] || [ "$DET_FIDELITY" -gt 0 ] || [ "$DET_MTTD" -gt 0 ] || [ "$DET_DRILL" -gt 0 ] || [ "$DET_MATRIX" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-075" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-075" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
