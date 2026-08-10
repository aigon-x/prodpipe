#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-019 — PENETRATION (Penetration Testing)
# Rodzina: SECURITY | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje istnienie raportu pentest oraz autoryzacji testów
# penetracyjnych w StateStore (document, manual_charters).
#
# Wykrywa:
#   * NO-PENTEST-REPORT   — brak raportu pentest w repo/StateStore
#   * NO-PENTEST-AUTH     — brak autoryzacji testów penetracyjnych
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
p_say "=== P-019 PENETRATION ==="
p_say "Weryfikacja raportu pentest i autoryzacji testów penetracyjnych"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-019"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

# 1. Raport pentest w repo (git-tracked).
PENTEST_REPO=0
if git ls-files 2>/dev/null | grep -iE '(pentest|penetration|security/audit)' | grep -v '\.gitkeep$' | grep -q .; then
  PENTEST_REPO=1
fi

# 2. Raport pentest w StateStore (document / manual_charters).
PENTEST_DB=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  PENTEST_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM (
      SELECT document_id FROM document WHERE lower(path) LIKE '%pentest%' OR lower(path) LIKE '%penetration%' OR lower(kind) LIKE '%pentest%'
      UNION
      SELECT charter_id FROM manual_charters WHERE lower(journey_id) LIKE '%pentest%' OR lower(journey_id) LIKE '%penetration%' OR lower(service_id) LIKE '%pentest%'
    );" 2>/dev/null || echo 0)
else
  p_info "PENETRATION-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 3. Autoryzacja testów penetracyjnych (manual_charters z coverage_type MANUAL / status ACTIVE).
PENTEST_AUTH=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  PENTEST_AUTH=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM manual_charters
    WHERE (lower(journey_id) LIKE '%pentest%' OR lower(journey_id) LIKE '%penetration%')
      AND status = 'ACTIVE';" 2>/dev/null || echo 0)
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$PENTEST_REPO" -eq 1 ] || [ "$PENTEST_DB" -gt 0 ]; then
  p_pass "PENTEST-REPORT-PRESENT" BLOCKING "Raport pentest obecny (repo=$PENTEST_REPO, state=$PENTEST_DB)"
else
  p_fail "PENTEST-REPORT-MISSING" BLOCKING "Brak raportu pentest w repo i StateStore"
fi
if [ "$PENTEST_AUTH" -gt 0 ]; then
  p_pass "PENTEST-AUTHORIZED" BLOCKING "Autoryzacja testów penetracyjnych obecna ($PENTEST_AUTH)"
else
  p_warn "PENTEST-NO-AUTHORIZATION" "Brak autoryzacji testów penetracyjnych w StateStore"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-019:penetration PENTEST_REPO=$PENTEST_REPO PENTEST_DB=$PENTEST_DB PENTEST_AUTH=$PENTEST_AUTH" "pipeline" "security/penetration.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$PENTEST_REPO" -eq 1 ] || [ "$PENTEST_DB" -gt 0 ]; then
  repo_verdict="PASS"
else
  repo_verdict="FAIL"
fi
p_dual_verdict "P-019" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-019" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
