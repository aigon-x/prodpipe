#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-017 — DEPENDENCY SCAN (Supply Chain / Dependencies)
# Rodzina: SECURITY | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje istnienie plików zależności oraz rejestru skanowania
# zależności (SBOM / artifact w StateStore).
#
# Wykrywa:
#   * NO-DEPENDENCY-FILES  — brak plików zależności (package.json, requirements.txt, ...)
#   * NO-SCAN-RECORD       — brak rekordu skanu zależności w StateStore (artifact)
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
p_say "=== P-017 DEPENDENCY SCAN ==="
p_say "Weryfikacja plików zależności i rejestru skanowania"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-017"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

# 1. Pliki zależności w repo (git-tracked).
DEP_FILES=$(git ls-files 2>/dev/null | grep -E '(package\.json|requirements\.txt|Cargo\.toml|go\.mod|pyproject\.toml|Pipfile|composer\.json|Gemfile|pom\.xml|build\.gradle)$' || true)
DEP_COUNT=0
[ -n "$DEP_FILES" ] && DEP_COUNT=$(printf '%s\n' "$DEP_FILES" | grep -c . || echo 0)

# 2. Rejestr skanowania zależności w StateStore (artifact — SBOM/dependency).
SCAN_RECORD=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  SCAN_RECORD=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE lower(kind) LIKE '%sbom%' OR lower(kind) LIKE '%depend%'
       OR lower(name) LIKE '%sbom%' OR lower(name) LIKE '%depend%';" 2>/dev/null || echo 0)
else
  p_info "DEPENDENCY-SCAN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DEP_COUNT" -gt 0 ]; then
  p_pass "DEPENDENCY-FILES-PRESENT" BLOCKING "Znaleziono $DEP_COUNT plików zależności"
else
  p_warn "DEPENDENCY-NO-FILES" "Brak plików zależności w repo (repo bez zewnętrznych zależności)"
fi
if [ "$SCAN_RECORD" -gt 0 ]; then
  p_pass "DEPENDENCY-SCAN-RECORD" BLOCKING "Rekord skanu zależności w StateStore ($SCAN_RECORD)"
else
  p_warn "DEPENDENCY-NO-SCAN-RECORD" "Brak rekordu skanu zależności w StateStore (artifact)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-017:dependency-scan DEP_FILES=$DEP_COUNT SCAN_RECORD=$SCAN_RECORD" "pipeline" "security/dependency-scan.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: brak plików zależności = NOT_APPLICABLE (nie ma czego skanować).
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DEP_COUNT" -gt 0 ]; then
  if [ "$SCAN_RECORD" -gt 0 ]; then
    repo_verdict="PASS"
  else
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-017" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-017" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
