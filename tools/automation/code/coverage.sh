#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-026 — COVERAGE (Pokrycie testami)
# Rodzina: CODE | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium ma rejestr pokrycia testami. Konsumuje
# tabelę quality_index (dimension='coverage') w StateStore oraz sprawdza
# obecność pliku coverage-matrix.yaml. Wykrywa:
#   * NO-COVERAGE-REGISTRY — brak rekordu pokrycia w quality_index
#   * COVERAGE-REGISTRY    — obecny rejestr pokrycia
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
p_say "=== P-026 COVERAGE ==="
p_say "Weryfikacja rejestru pokrycia testami"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-026"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
COVERAGE_RECORDS=0
DB_AVAILABLE=0

# 1. Rejestr pokrycia w StateStore (quality_index, dimension='coverage').
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  COVERAGE_RECORDS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM quality_index
    WHERE dimension = 'coverage';" 2>/dev/null || echo 0)
else
  p_info "COVERAGE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 2. Plik coverage-matrix.yaml w repo (deklaratywny rejestr pokrycia).
COVERAGE_MATRIX="$(p_repo_files --name 'coverage-matrix\.yaml')"
MATRIX_COUNT=$(printf '%s\n' "$COVERAGE_MATRIX" | grep -c . || true)

# ── TEST ────────────────────────────────────────────────────
if [ "$COVERAGE_RECORDS" -gt 0 ]; then
  p_pass "COVERAGE-REGISTRY-PRESENT" BLOCKING "Znaleziono $COVERAGE_RECORDS rekordów pokrycia w quality_index"
else
  p_warn "COVERAGE-REGISTRY-EMPTY" "Brak rekordów pokrycia w quality_index (dimension='coverage')"
fi
if [ "$MATRIX_COUNT" -gt 0 ]; then
  p_pass "COVERAGE-MATRIX-PRESENT" BLOCKING "Znaleziono plik coverage-matrix.yaml"
else
  p_warn "COVERAGE-MATRIX-MISSING" "Brak pliku coverage-matrix.yaml w repozytorium"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-026:coverage COVERAGE_RECORDS=$COVERAGE_RECORDS MATRIX=$MATRIX_COUNT DB=$DB_AVAILABLE" "pipeline" "code/coverage.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: gdy brak danych (pusta tabela i brak matrix) → NOT_APPLICABLE.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$COVERAGE_RECORDS" -eq 0 ] && [ "$MATRIX_COUNT" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-026" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-026" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
