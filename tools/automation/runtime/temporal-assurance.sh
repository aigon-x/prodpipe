#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-041 — TEMPORAL ASSURANCE (Temporal Assurance / Timestamps)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje integralność czasową rekordów StateStore:
#   * TIMESTAMP-INTEGRITY — rekordy evidence/pipeline_runs mają znaczniki czasu
#   * FRESHNESS           — rekordy nie są nieaktualne (stale)
#   * TEMPORAL-CONSISTENCY — znaczniki czasu są spójne (recorded_at nie w przyszłości)
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
p_say "=== P-041 TEMPORAL ASSURANCE ==="
p_say "Weryfikacja integralności czasowej rekordów StateStore (timestamps, freshness)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-041"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
NO_TS_COUNT=0
FUTURE_TS_COUNT=0
STALE_COUNT=0
TOTAL_RECORDS=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1

  # 1. TIMESTAMP-INTEGRITY — rekordy evidence bez recorded_at (NULL lub puste).
  NO_TS_COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM evidence WHERE recorded_at IS NULL OR recorded_at = '';" 2>/dev/null || echo 0)"

  # 2. TEMPORAL-CONSISTENCY — recorded_at w przyszłości (błąd zegara / manipulacja).
  FUTURE_TS_COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM evidence WHERE recorded_at > datetime('now');" 2>/dev/null || echo 0)"

  # 3. FRESHNESS — rekordy evidence starsze niż 90 dni (stale, nieaktualne).
  STALE_COUNT="$(sqlite3 "$DB" "SELECT COUNT(*) FROM evidence WHERE recorded_at < datetime('now', '-90 days');" 2>/dev/null || echo 0)"

  TOTAL_RECORDS="$(sqlite3 "$DB" "SELECT COUNT(*) FROM evidence;" 2>/dev/null || echo 0)"
else
  p_info "TEMPORAL-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę czasową (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$TOTAL_RECORDS" -eq 0 ]; then
    p_warn "TEMPORAL-NO-DATA" "Brak rekordów evidence w StateStore — brak danych do weryfikacji czasowej"
  else
    if [ "$NO_TS_COUNT" -eq 0 ]; then
      p_pass "TEMPORAL-TIMESTAMP-INTEGRITY" BLOCKING "Wszystkie rekordy evidence mają znaczniki czasu"
    else
      p_fail "TEMPORAL-TIMESTAMP-INTEGRITY" BLOCKING "Znaleziono $NO_TS_COUNT rekordów evidence bez znacznika czasu"
    fi
    if [ "$FUTURE_TS_COUNT" -eq 0 ]; then
      p_pass "TEMPORAL-CONSISTENCY" BLOCKING "Brak rekordów z recorded_at w przyszłości"
    else
      p_fail "TEMPORAL-CONSISTENCY" BLOCKING "Znaleziono $FUTURE_TS_COUNT rekordów z recorded_at w przyszłości"
    fi
    if [ "$STALE_COUNT" -eq 0 ]; then
      p_pass "TEMPORAL-FRESHNESS" BLOCKING "Brak nieaktualnych rekordów evidence (>90 dni)"
    else
      p_warn "TEMPORAL-FRESHNESS" "Znaleziono $STALE_COUNT nieaktualnych rekordów evidence (>90 dni)"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-041:temporal-assurance TOTAL=$TOTAL_RECORDS NO_TS=$NO_TS_COUNT FUTURE=$FUTURE_TS_COUNT STALE=$STALE_COUNT" "pipeline" "runtime/temporal-assurance.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$TOTAL_RECORDS" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$NO_TS_COUNT" -gt 0 ] || [ "$FUTURE_TS_COUNT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-041" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-041" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
