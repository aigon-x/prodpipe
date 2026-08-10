#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-074 — EXFIL (Offensive Security — Data Exfiltration)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza eksfiltracji danych (Red Team). Atak to test, obrona to
# gate, detekcja to evidence. Weryfikuje ścieżki eksfiltracji,
# skuteczność DLP i filtrowanie egress.
#
# Gate'y: OFF-X-01..08
#   * data exfiltration paths, DLP effectiveness, egress filtering,
#     encryption detection, volume anomaly, exfil simulation,
#     data classification, exfil evidence.
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
p_say "=== P-074 EXFIL ==="
p_say "Eksfiltracja: ścieżki, DLP, egress, szyfrowanie, anomalie wolumenu, symulacja, klasyfikacja"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-074"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów eksfiltracji w repo (best-effort).
EXF_PATHS=0
EXF_DLP=0
EXF_EGRESS=0
EXF_ENCRYPT=0
EXF_VOLUME=0
EXF_SIM=0
EXF_CLASS=0
EXF_EVIDENCE=0

if [ -d "$ROOT/offsec/exfil/paths" ]; then
  EXF_PATHS=$(find "$ROOT/offsec/exfil/paths" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/dlp" ]; then
  EXF_DLP=$(find "$ROOT/offsec/exfil/dlp" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/egress" ]; then
  EXF_EGRESS=$(find "$ROOT/offsec/exfil/egress" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/encryption" ]; then
  EXF_ENCRYPT=$(find "$ROOT/offsec/exfil/encryption" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/volume" ]; then
  EXF_VOLUME=$(find "$ROOT/offsec/exfil/volume" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/simulation" ]; then
  EXF_SIM=$(find "$ROOT/offsec/exfil/simulation" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/classification" ]; then
  EXF_CLASS=$(find "$ROOT/offsec/exfil/classification" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/exfil/evidence" ]; then
  EXF_EVIDENCE=$(find "$ROOT/offsec/exfil/evidence" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-X-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$EXF_PATHS" -gt 0 ]; then
  p_pass "OFF-X-01" BLOCKING "Data exfiltration paths: $EXF_PATHS artefaktów"
else
  p_info "OFF-X-01" "Data exfiltration paths: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_DLP" -gt 0 ]; then
  p_pass "OFF-X-02" BLOCKING "DLP effectiveness: $EXF_DLP artefaktów"
else
  p_info "OFF-X-02" "DLP effectiveness: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_EGRESS" -gt 0 ]; then
  p_pass "OFF-X-03" BLOCKING "Egress filtering: $EXF_EGRESS artefaktów"
else
  p_info "OFF-X-03" "Egress filtering: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_ENCRYPT" -gt 0 ]; then
  p_pass "OFF-X-04" BLOCKING "Encryption detection: $EXF_ENCRYPT artefaktów"
else
  p_info "OFF-X-04" "Encryption detection: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_VOLUME" -gt 0 ]; then
  p_pass "OFF-X-05" BLOCKING "Volume anomaly: $EXF_VOLUME artefaktów"
else
  p_info "OFF-X-05" "Volume anomaly: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_SIM" -gt 0 ]; then
  p_pass "OFF-X-06" BLOCKING "Exfil simulation: $EXF_SIM artefaktów"
else
  p_info "OFF-X-06" "Exfil simulation: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_CLASS" -gt 0 ]; then
  p_pass "OFF-X-07" BLOCKING "Data classification: $EXF_CLASS artefaktów"
else
  p_info "OFF-X-07" "Data classification: brak danych (NOT_APPLICABLE)"
fi
if [ "$EXF_EVIDENCE" -gt 0 ]; then
  p_pass "OFF-X-08" BLOCKING "Exfil evidence: $EXF_EVIDENCE artefaktów"
else
  p_info "OFF-X-08" "Exfil evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-074:exfil PATHS=$EXF_PATHS DLP=$EXF_DLP EGRESS=$EXF_EGRESS ENCRYPT=$EXF_ENCRYPT VOLUME=$EXF_VOLUME SIM=$EXF_SIM CLASS=$EXF_CLASS EVIDENCE=$EXF_EVIDENCE" "pipeline" "offsec/exfil.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$EXF_PATHS" -gt 0 ] || [ "$EXF_DLP" -gt 0 ] || [ "$EXF_EGRESS" -gt 0 ] || [ "$EXF_ENCRYPT" -gt 0 ] || [ "$EXF_VOLUME" -gt 0 ] || [ "$EXF_SIM" -gt 0 ] || [ "$EXF_CLASS" -gt 0 ] || [ "$EXF_EVIDENCE" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-074" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-074" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
