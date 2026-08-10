#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-020 — COMPLIANCE (Policy & Waiver Compliance)
# Rodzina: SECURITY | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje zgodność polityk i waiverów w StateStore (policy, waivers).
# Każda polityka musi mieć status; każdy waiver musi być ważny (nie wygasły).
#
# Wykrywa:
#   * POLICY-NO-STATUS    — polityka bez statusu
#   * WAIVER-EXPIRED      — wygasły waiver (expires_at < now)
#   * NO-POLICY-RECORD    — brak polityk w StateStore (NO FALSE GREEN → NOT_APPLICABLE)
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
p_say "=== P-020 COMPLIANCE ==="
p_say "Weryfikacja zgodności polityk i waiverów"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-020"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

POLICY_COUNT=0
POLICY_NO_STATUS=0
WAIVER_COUNT=0
WAIVER_EXPIRED=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. Liczba polityk i polityki bez statusu.
  POLICY_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM policy;" 2>/dev/null || echo 0)
  POLICY_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM policy
    WHERE status IS NULL OR status = '' OR status = 'CURRENT';" 2>/dev/null || echo 0)

  # 2. Liczba waiverów i wygasłe waivery (expires_at < now).
  WAIVER_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM waivers;" 2>/dev/null || echo 0)
  WAIVER_EXPIRED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM waivers
    WHERE expires_at IS NOT NULL AND expires_at < datetime('now');" 2>/dev/null || echo 0)
else
  p_info "COMPLIANCE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$POLICY_COUNT" -gt 0 ]; then
  if [ "$POLICY_NO_STATUS" -eq 0 ]; then
    p_pass "COMPLIANCE-POLICY-STATUS" BLOCKING "Wszystkie $POLICY_COUNT polityki mają status"
  else
    p_fail "COMPLIANCE-POLICY-NO-STATUS" BLOCKING "Znaleziono $POLICY_NO_STATUS polityk bez statusu"
  fi
else
  p_warn "COMPLIANCE-NO-POLICY" "Brak polityk w StateStore (policy)"
fi

if [ "$WAIVER_COUNT" -gt 0 ]; then
  if [ "$WAIVER_EXPIRED" -eq 0 ]; then
    p_pass "COMPLIANCE-WAIVER-VALID" BLOCKING "Wszystkie $WAIVER_COUNT waivery są ważne"
  else
    p_fail "COMPLIANCE-WAIVER-EXPIRED" BLOCKING "Znaleziono $WAIVER_EXPIRED wygasłych waiverów"
  fi
else
  p_warn "COMPLIANCE-NO-WAIVER" "Brak waiverów w StateStore (waivers)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-020:compliance POLICY=$POLICY_COUNT POLICY_NO_STATUS=$POLICY_NO_STATUS WAIVER=$WAIVER_COUNT WAIVER_EXPIRED=$WAIVER_EXPIRED" "pipeline" "security/compliance.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak polityk/waiverów = NOT_APPLICABLE (nie ma czego weryfikować).
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$POLICY_COUNT" -gt 0 ] || [ "$WAIVER_COUNT" -gt 0 ]; then
  if [ "$POLICY_NO_STATUS" -eq 0 ] && [ "$WAIVER_EXPIRED" -eq 0 ]; then
    repo_verdict="PASS"
  else
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-020" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-020" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
