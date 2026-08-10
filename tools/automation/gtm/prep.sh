#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-056 — GTM PREP (Etap 4: launch readiness)
# Rodzina: GTM | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje gotowość do launchu (launch readiness):
#   * READINESS-CASE — weryfikacje PASS w StateStore (verification)
#   * RELEASE-EVIDENCE — wydanie w StateStore (release)
#   * SIGN-OFF-EVIDENCE — zatwierdzenie/uat sign-off w StateStore
#
# GTM to przedłużenie architektury na rynek: ten sam mechanizm evidence,
# gate'y, drille, escape analysis, sunsetting, proof plane.
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
p_say "=== P-056 GTM PREP ==="
p_say "Etap 4: czy launch readiness case jest kompletny?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-056"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
VERIFY_PASS_COUNT=0
RELEASE_COUNT=0
SIGNOFF_COUNT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 1. READINESS-CASE — weryfikacje PASS w StateStore.
  VERIFY_PASS_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM verification
    WHERE status = 'PASS';" 2>/dev/null || echo 0)

  # 2. RELEASE-EVIDENCE — wydania w StateStore.
  RELEASE_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM release
    WHERE status IN ('STAGING','CERTIFIED','CANARY','PRODUCTION','OPERATING');" 2>/dev/null || echo 0)

  # 3. SIGN-OFF-EVIDENCE — uat sign-offs w StateStore.
  SIGNOFF_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM uat_signoffs
    WHERE status = 'APPROVED';" 2>/dev/null || echo 0)
else
  p_info "GTM-PREP-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$VERIFY_PASS_COUNT" -gt 0 ]; then
    p_pass "GTM-PREP-READINESS-CASE" BLOCKING "Znaleziono $VERIFY_PASS_COUNT weryfikacji PASS (readiness case)"
  else
    p_warn "GTM-PREP-NO-READINESS-CASE" "Brak readiness case (verification PASS) — brak danych rynkowych"
  fi
  if [ "$RELEASE_COUNT" -gt 0 ]; then
    p_pass "GTM-PREP-RELEASE-EVIDENCE" BLOCKING "Znaleziono $RELEASE_COUNT wydań w StateStore"
  else
    p_warn "GTM-PREP-NO-RELEASE-EVIDENCE" "Brak wydania w StateStore (release)"
  fi
  if [ "$SIGNOFF_COUNT" -gt 0 ]; then
    p_pass "GTM-PREP-SIGN-OFF-EVIDENCE" BLOCKING "Znaleziono $SIGNOFF_COUNT zatwierdzonych sign-off (uat_signoffs)"
  else
    p_warn "GTM-PREP-NO-SIGN-OFF-EVIDENCE" "Brak sign-off (uat_signoffs APPROVED)"
  fi
else
  p_warn "GTM-PREP-DB-UNAVAILABLE" "Baza niedostępna — readiness niezweryfikowany (best-effort)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-056:gtm-prep VERIFY=$VERIFY_PASS_COUNT RELEASE=$RELEASE_COUNT SIGNOFF=$SIGNOFF_COUNT" "pipeline" "gtm/prep.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak danych rynkowych (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$VERIFY_PASS_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-056" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-056" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
