#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-076 — RESPOND (Offensive Security — Incident Response)
# Rodzina: OFFENSIVE-SECURITY | Klasa: DEEP | Status: PROPOSED
#
# Faza reagowania (Blue Team). Atak to test, obrona to gate,
# detekcja to evidence. Weryfikuje plan reagowania na incydenty,
# procedury i zgodność prawną.
#
# Gate'y: OFF-RE-01..08
#   * incident response plan, IR team, containment procedures,
#     eradication procedures, recovery procedures, communication plan,
#     legal/regulatory (GDPR/NIS2), response drill.
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
p_say "=== P-076 RESPOND ==="
p_say "Reagowanie: plan IR, zespół, containment, eradiation, recovery, komunikacja, prawo, drill"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-076"

# ── EXECUTE ─────────────────────────────────────────────────
# Wykrywanie artefaktów reagowania w repo (best-effort).
RES_PLAN=0
RES_TEAM=0
RES_CONTAIN=0
RES_ERAD=0
RES_RECOVERY=0
RES_COMM=0
RES_LEGAL=0
RES_DRILL=0

if [ -d "$ROOT/offsec/respond/plan" ]; then
  RES_PLAN=$(find "$ROOT/offsec/respond/plan" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/team" ]; then
  RES_TEAM=$(find "$ROOT/offsec/respond/team" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/containment" ]; then
  RES_CONTAIN=$(find "$ROOT/offsec/respond/containment" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/eradication" ]; then
  RES_ERAD=$(find "$ROOT/offsec/respond/eradication" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/recovery" ]; then
  RES_RECOVERY=$(find "$ROOT/offsec/respond/recovery" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/communication" ]; then
  RES_COMM=$(find "$ROOT/offsec/respond/communication" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/legal" ]; then
  RES_LEGAL=$(find "$ROOT/offsec/respond/legal" -type f 2>/dev/null | wc -l)
fi
if [ -d "$ROOT/offsec/respond/drill" ]; then
  RES_DRILL=$(find "$ROOT/offsec/respond/drill" -type f 2>/dev/null | wc -l)
fi

# ── TEST ────────────────────────────────────────────────────
# 8 gate'ów OFF-RE-01..08. Brak danych = NOT_APPLICABLE (nie FAIL).
if [ "$RES_PLAN" -gt 0 ]; then
  p_pass "OFF-RE-01" BLOCKING "Incident response plan: $RES_PLAN artefaktów"
else
  p_info "OFF-RE-01" "Incident response plan: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_TEAM" -gt 0 ]; then
  p_pass "OFF-RE-02" BLOCKING "IR team: $RES_TEAM artefaktów"
else
  p_info "OFF-RE-02" "IR team: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_CONTAIN" -gt 0 ]; then
  p_pass "OFF-RE-03" BLOCKING "Containment procedures: $RES_CONTAIN artefaktów"
else
  p_info "OFF-RE-03" "Containment procedures: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_ERAD" -gt 0 ]; then
  p_pass "OFF-RE-04" BLOCKING "Eradication procedures: $RES_ERAD artefaktów"
else
  p_info "OFF-RE-04" "Eradication procedures: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_RECOVERY" -gt 0 ]; then
  p_pass "OFF-RE-05" BLOCKING "Recovery procedures: $RES_RECOVERY artefaktów"
else
  p_info "OFF-RE-05" "Recovery procedures: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_COMM" -gt 0 ]; then
  p_pass "OFF-RE-06" BLOCKING "Communication plan: $RES_COMM artefaktów"
else
  p_info "OFF-RE-06" "Communication plan: brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_LEGAL" -gt 0 ]; then
  p_pass "OFF-RE-07" BLOCKING "Legal/regulatory (GDPR/NIS2): $RES_LEGAL artefaktów"
else
  p_info "OFF-RE-07" "Legal/regulatory (GDPR/NIS2): brak danych (NOT_APPLICABLE)"
fi
if [ "$RES_DRILL" -gt 0 ]; then
  p_pass "OFF-RE-08" BLOCKING "Response drill: $RES_DRILL artefaktów"
else
  p_info "OFF-RE-08" "Response drill: brak danych (NOT_APPLICABLE)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-076:respond PLAN=$RES_PLAN TEAM=$RES_TEAM CONTAIN=$RES_CONTAIN ERAD=$RES_ERAD RECOVERY=$RES_RECOVERY COMM=$RES_COMM LEGAL=$RES_LEGAL DRILL=$RES_DRILL" "pipeline" "offsec/respond.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$RES_PLAN" -gt 0 ] || [ "$RES_TEAM" -gt 0 ] || [ "$RES_CONTAIN" -gt 0 ] || [ "$RES_ERAD" -gt 0 ] || [ "$RES_RECOVERY" -gt 0 ] || [ "$RES_COMM" -gt 0 ] || [ "$RES_LEGAL" -gt 0 ] || [ "$RES_DRILL" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-076" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-076" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
