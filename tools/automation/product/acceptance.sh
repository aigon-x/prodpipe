#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-007 — ACCEPTANCE (UAT Signoff / Acceptance)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje akceptację UAT: czy istnieją podpisy UAT (uat_signoffs)
# i czy każda usługa (service) ma powiązany signoff UAT.
#
# Wykrywa:
#   * NO-UAT-SIGNOFF   — brak jakichkolwiek podpisów UAT
#   * SERVICE-NO-UAT   — usługa bez podpisu UAT
#   * SIGNOFF-NO-TIER  — signoff bez tieru
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
p_say "=== P-007 ACCEPTANCE ==="
p_say "Weryfikacja akceptacji UAT (podpisy UAT / pokrycie usług)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-007"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
SIGNOFFS=0
SERVICES=0
SERVICE_NO_UAT=0
SIGNOFF_NO_TIER=0
DB_OK=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_OK=1
  SIGNOFFS=$(sqlite3 "$db" "SELECT COUNT(*) FROM uat_signoffs;" 2>/dev/null || echo 0)
  SERVICES=$(sqlite3 "$db" "SELECT COUNT(*) FROM service;" 2>/dev/null || echo 0)
  # 1. Usługa bez podpisu UAT (service LEFT JOIN uat_signoffs).
  SERVICE_NO_UAT=$(sqlite3 "$db" "SELECT COUNT(*) FROM service s LEFT JOIN uat_signoffs u ON u.service_id = s.service_id WHERE u.signoff_id IS NULL;" 2>/dev/null || echo 0)
  # 2. Signoff bez tieru.
  SIGNOFF_NO_TIER=$(sqlite3 "$db" "SELECT COUNT(*) FROM uat_signoffs WHERE tier IS NULL OR tier = '';" 2>/dev/null || echo 0)
else
  p_info "ACCEPTANCE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  p_info "ACCEPTANCE-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
elif [ "$SIGNOFFS" -eq 0 ] && [ "$SERVICES" -eq 0 ]; then
  p_info "ACCEPTANCE-EMPTY" "Brak usług i signoffów UAT w StateStore — repo_verdict NOT_APPLICABLE"
else
  if [ "$SIGNOFFS" -gt 0 ]; then
    p_pass "ACCEPTANCE-HAS-SIGNOFF" BLOCKING "Znaleziono $SIGNOFFS podpisów UAT"
  else
    p_fail "ACCEPTANCE-NO-UAT-SIGNOFF" BLOCKING "Brak jakichkolwiek podpisów UAT (tabela uat_signoffs pusta)"
  fi
  if [ "$SERVICE_NO_UAT" -eq 0 ]; then
    p_pass "ACCEPTANCE-ALL-SERVICES-UAT" BLOCKING "Wszystkie usługi mają podpis UAT"
  else
    p_fail "ACCEPTANCE-SERVICE-NO-UAT" BLOCKING "Znaleziono $SERVICE_NO_UAT usług bez podpisu UAT"
  fi
  if [ "$SIGNOFF_NO_TIER" -eq 0 ]; then
    p_pass "ACCEPTANCE-ALL-TIER" BLOCKING "Wszystkie signoffy mają tier"
  else
    p_warn "ACCEPTANCE-SIGNOFF-NO-TIER" "Znaleziono $SIGNOFF_NO_TIER signoffów bez tieru"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-007:acceptance SIGNOFFS=$SIGNOFFS SERVICES=$SERVICES SERVICE_NO_UAT=$SERVICE_NO_UAT SIGNOFF_NO_TIER=$SIGNOFF_NO_TIER" "pipeline" "product/acceptance.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$SIGNOFFS" -eq 0 ] && [ "$SERVICES" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$SIGNOFFS" -eq 0 ] || [ "$SERVICE_NO_UAT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-007" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-007" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
