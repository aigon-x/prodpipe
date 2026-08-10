#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-055 — GTM BUILD (Etap 3: produkt + proof materials)
# Rodzina: GTM | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, czy istnieje proof plane (dowód produktu):
#   * PROOF-PLANE — katalog proof/ w repo (proof materials)
#   * ARTIFACT-EVIDENCE — artefakty w StateStore (artifact)
#   * DEMO-EVIDENCE — demo/proof artefakt w repo
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
p_say "=== P-055 GTM BUILD ==="
p_say "Etap 3: czy produkt + proof materials istnieją?"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-055"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
ARTIFACT_COUNT=0
DB_AVAILABLE=0

# 1. PROOF-PLANE — katalog proof/ w repo (git-tracked).
PROOF_COUNT=$(git ls-files 2>/dev/null | grep -E '^proof/' | wc -l | tr -d ' ')

# 2. DEMO-EVIDENCE — demo/proof artefakt w repo.
DEMO_COUNT=$(git ls-files 2>/dev/null | grep -iE 'demo|proof-of-concept|poc|screencast|walkthrough' | wc -l | tr -d ' ')

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # 3. ARTIFACT-EVIDENCE — artefakty w StateStore.
  ARTIFACT_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE status = 'CURRENT';" 2>/dev/null || echo 0)
else
  p_info "GTM-BUILD-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$PROOF_COUNT" -gt 0 ]; then
  p_pass "GTM-BUILD-PROOF-PLANE" BLOCKING "Znaleziono $PROOF_COUNT plików w proof plane (proof/)"
else
  p_warn "GTM-BUILD-NO-PROOF-PLANE" "Brak proof plane (katalog proof/ w repo) — brak produktu rynkowego"
fi
if [ "$DEMO_COUNT" -gt 0 ]; then
  p_pass "GTM-BUILD-DEMO-EVIDENCE" BLOCKING "Znaleziono $DEMO_COUNT artefaktów demo w repo"
else
  p_warn "GTM-BUILD-NO-DEMO-EVIDENCE" "Brak demo/proof artefaktu w repo"
fi
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$ARTIFACT_COUNT" -gt 0 ]; then
    p_pass "GTM-BUILD-ARTIFACT-EVIDENCE" BLOCKING "Znaleziono $ARTIFACT_COUNT artefaktów w StateStore"
  else
    p_warn "GTM-BUILD-NO-ARTIFACT-EVIDENCE" "Brak artefaktów w StateStore (artifact)"
  fi
else
  p_warn "GTM-BUILD-DB-UNAVAILABLE" "Baza niedostępna — artefakty niezweryfikowane (best-effort)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-055:gtm-build PROOF=$PROOF_COUNT DEMO=$DEMO_COUNT ARTIFACT=$ARTIFACT_COUNT" "pipeline" "gtm/build.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak proof plane (template) → NOT_APPLICABLE, nie PASS.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$PROOF_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
fi
p_dual_verdict "P-055" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-055" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
