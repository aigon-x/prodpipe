#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-030 — ARTIFACT (Artifact registry)
# Rodzina: BUILD | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje rejestr artefaktów (tabela artifact w StateStore).
# Wykrywa brak rekordu artefaktu oraz artefakt bez wersji/digest.
#
# Wykrywa:
#   * NO-ARTIFACT-REGISTRY — tabela artifact pusta / brak rekordu
#   * ARTIFACT-NO-DIGEST   — artefakt bez digest (niezidentyfikowany)
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
p_say "=== P-030 ARTIFACT ==="
p_say "Weryfikacja rejestru artefaktów (tabela artifact)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-030"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
ARTIFACT_COUNT=0
ARTIFACT_NO_DIGEST=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  ARTIFACT_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM artifact;" 2>/dev/null || echo 0)
  ARTIFACT_NO_DIGEST=$(sqlite3 "$db" "SELECT COUNT(*) FROM artifact WHERE digest IS NULL OR digest = '';" 2>/dev/null || echo 0)
else
  p_info "ARTIFACT-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "ARTIFACT-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować rejestru artefaktów"
elif [ "$ARTIFACT_COUNT" -eq 0 ]; then
  p_fail "ARTIFACT-NO-REGISTRY" BLOCKING "Brak rekordów artefaktów w tabeli artifact (rejestr pusty)"
else
  p_pass "ARTIFACT-REGISTRY-PRESENT" BLOCKING "Znaleziono $ARTIFACT_COUNT artefaktów w rejestrze"
  if [ "$ARTIFACT_NO_DIGEST" -eq 0 ]; then
    p_pass "ARTIFACT-ALL-DIGESTED" BLOCKING "Wszystkie artefakty mają digest"
  else
    p_fail "ARTIFACT-NO-DIGEST" BLOCKING "Znaleziono $ARTIFACT_NO_DIGEST artefaktów bez digest"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-030:artifact COUNT=$ARTIFACT_COUNT NO_DIGEST=$ARTIFACT_NO_DIGEST" "pipeline" "build/artifact.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$ARTIFACT_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
  if [ "$ARTIFACT_NO_DIGEST" -gt 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-030" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-030" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
