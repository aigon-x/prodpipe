#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-031 — SBOM (Software Bill of Materials)
# Rodzina: BUILD | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje obecność SBOM (Software Bill of Materials) dla
# artefaktów. Sprawdza plik sbom.json w repo oraz pole sbom_ref
# w tabeli artifact (StateStore). Wykrywa brak SBOM.
#
# Wykrywa:
#   * NO-SBOM-FILE     — brak pliku sbom.json / sbom w repo
#   * NO-SBOM-ARTIFACT — brak artefaktu z powiązanym SBOM
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
p_say "=== P-031 SBOM ==="
p_say "Weryfikacja obecności Software Bill of Materials (SBOM)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-031"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
HAS_SBOM_FILE=0
SBOM_ARTIFACT_COUNT=0
DB_AVAILABLE=0

# 1. Plik SBOM w repo (git-tracked): sbom.json, *.sbom.json, *.sbom, cyclonedx, spdx
if git ls-files | grep -qiE '(^|/)(sbom\.json|.*\.sbom\.json|.*\.sbom|.*cyclonedx.*\.json|.*spdx.*\.json)$'; then
  HAS_SBOM_FILE=1
fi

# 2. Artefakt z powiązanym SBOM (pole sbom_ref w tabeli artifact)
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  SBOM_ARTIFACT_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM artifact WHERE sbom_ref IS NOT NULL AND sbom_ref != '';" 2>/dev/null || echo 0)
else
  p_info "SBOM-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$HAS_SBOM_FILE" -eq 1 ]; then
  p_pass "SBOM-FILE-PRESENT" BLOCKING "Znaleziono plik SBOM w repo"
else
  p_fail "SBOM-NO-FILE" BLOCKING "Brak pliku SBOM w repo (sbom.json / cyclonedx / spdx)"
fi
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$SBOM_ARTIFACT_COUNT" -gt 0 ]; then
    p_pass "SBOM-ARTIFACT-LINKED" BLOCKING "Znaleziono $SBOM_ARTIFACT_COUNT artefaktów z powiązanym SBOM"
  else
    p_warn "SBOM-NO-ARTIFACT-LINK" "Brak artefaktów z powiązanym SBOM w tabeli artifact"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-031:sbom FILE=$HAS_SBOM_FILE ARTIFACT_LINKED=$SBOM_ARTIFACT_COUNT" "pipeline" "build/sbom.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$HAS_SBOM_FILE" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-031" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-031" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
