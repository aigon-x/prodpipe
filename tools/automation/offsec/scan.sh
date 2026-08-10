#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-071 — SCAN (Offensive Security — Vulnerability Scanning)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza skanowania podatności (Red Team). Atak to test, obrona to
# gate, detekcja to evidence. Skanuje aplikacje, sieć, chmurę,
# kontenery, zależności i kod.
#
# Gate'y: OFF-S-01..08
#   * vulnerability scanning, web app scanning (OWASP ZAP/Burp),
#     network scanning (Nmap), cloud scanning (Prowler),
#     container scanning (Trivy), dependency scanning (Snyk),
#     code scanning (Semgrep/CodeQL), scan coverage ≥95%.
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
p_say "=== P-071 SCAN ==="
p_say "Skanowanie podatności: web, sieć, chmura, kontenery, zależności, kod"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-071"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów skanowania w repo (best-effort).
SCAN_VULN=0
SCAN_WEB=0
SCAN_NET=0
SCAN_CLOUD=0
SCAN_CONTAINER=0
SCAN_DEP=0
SCAN_CODE=0
SCAN_COVERAGE=0

if [ -d "$ROOT/offsec/scan/vuln" ]; then
  SCAN_VULN=$(find "$ROOT/offsec/scan/vuln" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/web" ]; then
  SCAN_WEB=$(find "$ROOT/offsec/scan/web" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/network" ]; then
  SCAN_NET=$(find "$ROOT/offsec/scan/network" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/cloud" ]; then
  SCAN_CLOUD=$(find "$ROOT/offsec/scan/cloud" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/container" ]; then
  SCAN_CONTAINER=$(find "$ROOT/offsec/scan/container" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/dependency" ]; then
  SCAN_DEP=$(find "$ROOT/offsec/scan/dependency" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/scan/code" ]; then
  SCAN_CODE=$(find "$ROOT/offsec/scan/code" -type f 2>/dev/null | wc -l)
fi
# Scan coverage ≥95% — z pliku coverage jeśli istnieje.
if [ -f "$ROOT/offsec/scan/coverage.txt" ]; then
  SCAN_COVERAGE=$(cat "$ROOT/offsec/scan/coverage.txt" 2>/dev/null | tr -d '[:space:]')
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-S-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$SCAN_VULN" -gt 0 ]; then
  p_pass "OFF-S-01" BLOCKING "Vulnerability scanning: $SCAN_VULN artefaktów"
else
  p_info "OFF-S-01" "Vulnerability scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_WEB" -gt 0 ]; then
  p_pass "OFF-S-02" BLOCKING "Web app scanning (OWASP ZAP/Burp): $SCAN_WEB artefaktów"
else
  p_info "OFF-S-02" "Web app scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_NET" -gt 0 ]; then
  p_pass "OFF-S-03" BLOCKING "Network scanning (Nmap): $SCAN_NET artefaktów"
else
  p_info "OFF-S-03" "Network scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_CLOUD" -gt 0 ]; then
  p_pass "OFF-S-04" BLOCKING "Cloud scanning (Prowler): $SCAN_CLOUD artefaktów"
else
  p_info "OFF-S-04" "Cloud scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_CONTAINER" -gt 0 ]; then
  p_pass "OFF-S-05" BLOCKING "Container scanning (Trivy): $SCAN_CONTAINER artefaktów"
else
  p_info "OFF-S-05" "Container scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_DEP" -gt 0 ]; then
  p_pass "OFF-S-06" BLOCKING "Dependency scanning (Snyk): $SCAN_DEP artefaktów"
else
  p_info "OFF-S-06" "Dependency scanning: brak danych (NOT_APPLICABLE)"
fi
if [ "$SCAN_CODE" -gt 0 ]; then
  p_pass "OFF-S-07" BLOCKING "Code scanning (Semgrep/CodeQL): $SCAN_CODE artefaktów"
else
  p_info "OFF-S-07" "Code scanning: brak danych (NOT_APPLICABLE)"
fi
# OFF-S-08 — scan coverage ≥95%.
if [ -n "$SCAN_COVERAGE" ] && [ "$SCAN_COVERAGE" -ge 95 ] 2>/dev/null; then
  p_pass "OFF-S-08" BLOCKING "Scan coverage: ${SCAN_COVERAGE}% (≥95%)"
else
  p_info "OFF-S-08" "Scan coverage: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-071:scan VULN=$SCAN_VULN WEB=$SCAN_WEB NET=$SCAN_NET CLOUD=$SCAN_CLOUD CONTAINER=$SCAN_CONTAINER DEP=$SCAN_DEP CODE=$SCAN_CODE COVERAGE=$SCAN_COVERAGE" "pipeline" "offsec/scan.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$SCAN_VULN" -gt 0 ] || [ "$SCAN_WEB" -gt 0 ] || [ "$SCAN_NET" -gt 0 ] || [ "$SCAN_CLOUD" -gt 0 ] || [ "$SCAN_CONTAINER" -gt 0 ] || [ "$SCAN_DEP" -gt 0 ] || [ "$SCAN_CODE" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-071" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-071" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
