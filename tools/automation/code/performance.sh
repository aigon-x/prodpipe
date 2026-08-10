#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-027 — PERFORMANCE (Wydajność / benchmarki)
# Rodzina: CODE | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium ma benchmarki wydajności. Wykrywa:
#   * NO-BENCHMARKS — brak benchmarków wydajności
#   * BENCHMARKS    — obecne benchmarki (katalog tests/performance/, models/benchmarks/)
#   * PREDICTION    — rejestr dokładności przewidywań (prediction_accuracy)
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
p_say "=== P-027 PERFORMANCE ==="
p_say "Weryfikacja obecności benchmarków wydajności"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-027"

# ── EXECUTE ─────────────────────────────────────────────────
# 1. Benchmarki w repo: katalog tests/performance/, models/benchmarks/,
#    pliki *.bench.*, benchmark/.
BENCH_FILES="$(p_repo_files --name '(^tests/performance/|^models/benchmarks/|^benchmarks/|\.bench\.|benchmark/)')"
BENCH_COUNT=$(printf '%s\n' "$BENCH_FILES" | grep -c . || true)

# 2. Rejestr dokładności przewidywań w StateStore (prediction_accuracy).
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
PREDICTION_COUNT=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  PREDICTION_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM prediction_accuracy;" 2>/dev/null || echo 0)
else
  p_info "PERFORMANCE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$BENCH_COUNT" -gt 0 ]; then
  p_pass "BENCHMARKS-PRESENT" BLOCKING "Znaleziono $BENCH_COUNT plików benchmarków"
else
  p_fail "BENCHMARKS-MISSING" BLOCKING "Brak benchmarków wydajności w repozytorium"
fi
if [ "$PREDICTION_COUNT" -gt 0 ]; then
  p_pass "PREDICTION-ACCURACY-REGISTRY" BLOCKING "Znaleziono $PREDICTION_COUNT rekordów dokładności przewidywań"
else
  p_info "PREDICTION-ACCURACY-EMPTY" "Brak rekordów w prediction_accuracy (informacyjnie)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-027:performance BENCH_FILES=$BENCH_COUNT PREDICTION=$PREDICTION_COUNT" "pipeline" "code/performance.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$BENCH_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-027" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-027" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
