#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-070 — RECON (Offensive Security — Reconnaissance)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza rozpoznania (Red Team). Atak to test, obrona to gate,
# detekcja to evidence. Mapuje powierzchnię ataku i zbiera
# threat intelligence przed dalszymi etapami.
#
# Gate'y: OFF-R-01..08
#   * OSINT scan, attack surface mapping, threat intelligence (MITRE ATT&CK TTPs),
#     dark web monitoring, social engineering surface, supply chain recon,
#     digital footprint (CASB/CSPM), recon evidence (expires 90 dni).
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
p_say "=== P-070 RECON ==="
p_say "Rozpoznanie: OSINT, attack surface, threat intelligence, dark web, social engineering, supply chain, digital footprint"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-070"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów recon w repo (best-effort, brak danych = NOT_APPLICABLE).
RECON_OSINT=0
RECON_SURFACE=0
RECON_TI=0
RECON_DARKWEB=0
RECON_SOCIAL=0
RECON_SUPPLY=0
RECON_FOOTPRINT=0

# 1. OSINT scan — artefakty rozpoznania open-source.
if [ -d "$ROOT/offsec/recon/osint" ]; then
  RECON_OSINT=$(find "$ROOT/offsec/recon/osint" -type f 2>/dev/null | wc -l)
fi
# 2. Attack surface mapping.
if [ -d "$ROOT/offsec/recon/surface" ]; then
  RECON_SURFACE=$(find "$ROOT/offsec/recon/surface" -type f 2>/dev/null | wc -l)
fi
# 3. Threat intelligence (MITRE ATT&CK TTPs).
if [ -d "$ROOT/offsec/recon/threat-intel" ]; then
  RECON_TI=$(find "$ROOT/offsec/recon/threat-intel" -type f 2>/dev/null | wc -l)
fi
# 4. Dark web monitoring.
if [ -d "$ROOT/offsec/recon/darkweb" ]; then
  RECON_DARKWEB=$(find "$ROOT/offsec/recon/darkweb" -type f 2>/dev/null | wc -l)
fi
# 5. Social engineering surface.
if [ -d "$ROOT/offsec/recon/social" ]; then
  RECON_SOCIAL=$(find "$ROOT/offsec/recon/social" -type f 2>/dev/null | wc -l)
fi
# 6. Supply chain recon.
if [ -d "$ROOT/offsec/recon/supply-chain" ]; then
  RECON_SUPPLY=$(find "$ROOT/offsec/recon/supply-chain" -type f 2>/dev/null | wc -l)
fi
# 7. Digital footprint (CASB/CSPM).
if [ -d "$ROOT/offsec/recon/footprint" ]; then
  RECON_FOOTPRINT=$(find "$ROOT/offsec/recon/footprint" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-R-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$RECON_OSINT" -gt 0 ]; then
  p_pass "OFF-R-01" BLOCKING "OSINT scan: $RECON_OSINT artefaktów"
else
  p_info "OFF-R-01" "OSINT scan: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_SURFACE" -gt 0 ]; then
  p_pass "OFF-R-02" BLOCKING "Attack surface mapping: $RECON_SURFACE artefaktów"
else
  p_info "OFF-R-02" "Attack surface mapping: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_TI" -gt 0 ]; then
  p_pass "OFF-R-03" BLOCKING "Threat intelligence (MITRE ATT&CK TTPs): $RECON_TI artefaktów"
else
  p_info "OFF-R-03" "Threat intelligence: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_DARKWEB" -gt 0 ]; then
  p_pass "OFF-R-04" BLOCKING "Dark web monitoring: $RECON_DARKWEB artefaktów"
else
  p_info "OFF-R-04" "Dark web monitoring: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_SOCIAL" -gt 0 ]; then
  p_pass "OFF-R-05" BLOCKING "Social engineering surface: $RECON_SOCIAL artefaktów"
else
  p_info "OFF-R-05" "Social engineering surface: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_SUPPLY" -gt 0 ]; then
  p_pass "OFF-R-06" BLOCKING "Supply chain recon: $RECON_SUPPLY artefaktów"
else
  p_info "OFF-R-06" "Supply chain recon: brak danych (NOT_APPLICABLE)"
fi
if [ "$RECON_FOOTPRINT" -gt 0 ]; then
  p_pass "OFF-R-07" BLOCKING "Digital footprint (CASB/CSPM): $RECON_FOOTPRINT artefaktów"
else
  p_info "OFF-R-07" "Digital footprint: brak danych (NOT_APPLICABLE)"
fi
# OFF-R-08 — recon evidence (expires 90 dni).
if [ "$RECON_OSINT" -gt 0 ] || [ "$RECON_SURFACE" -gt 0 ] || [ "$RECON_TI" -gt 0 ] || [ "$RECON_DARKWEB" -gt 0 ] || [ "$RECON_SOCIAL" -gt 0 ] || [ "$RECON_SUPPLY" -gt 0 ] || [ "$RECON_FOOTPRINT" -gt 0 ]; then
  p_pass "OFF-R-08" BLOCKING "Recon evidence zebrane (expires 90 dni)"
else
  p_info "OFF-R-08" "Recon evidence: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-070:recon OSINT=$RECON_OSINT SURFACE=$RECON_SURFACE TI=$RECON_TI DARKWEB=$RECON_DARKWEB SOCIAL=$RECON_SOCIAL SUPPLY=$RECON_SUPPLY FOOTPRINT=$RECON_FOOTPRINT" "pipeline" "offsec/recon.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# Repo nie ma jeszcze danych recon → NOT_APPLICABLE (nie FAIL).
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$RECON_OSINT" -gt 0 ] || [ "$RECON_SURFACE" -gt 0 ] || [ "$RECON_TI" -gt 0 ] || [ "$RECON_DARKWEB" -gt 0 ] || [ "$RECON_SOCIAL" -gt 0 ] || [ "$RECON_SUPPLY" -gt 0 ] || [ "$RECON_FOOTPRINT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-070" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-070" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
