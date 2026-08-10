#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-044 — CONTINUOUS CERTIFICATION (Continuous Certification)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że certyfikacja jest ciągła (nie jednorazowa):
#   * CERTIFICATION-RECORDS — istnieją rekordy weryfikacji (verification)
#   * CERTIFICATION-BASELINE — istnieje baseline certyfikacji
#   * CERTIFICATION-FRESHNESS — certyfikacja jest aktualna (nie wygasła)
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
p_say "=== P-044 CONTINUOUS CERTIFICATION ==="
p_say "Weryfikacja ciągłości certyfikacji (verification, baseline, freshness)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-044"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
VER_TOTAL=0
VER_PASS=0
BASELINE_TOTAL=0
VER_STALE=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1
  VER_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification;" 2>/dev/null || echo 0)"
  VER_PASS="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification WHERE status = 'PASS';" 2>/dev/null || echo 0)"
  BASELINE_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM baseline;" 2>/dev/null || echo 0)"

  # Certyfikacja nieaktualna: rekordy verification bez verified_at lub starsze niż 90 dni.
  VER_STALE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification WHERE verified_at IS NULL OR verified_at < datetime('now', '-90 days');" 2>/dev/null || echo 0)"
else
  p_info "CERTIFICATION-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę certyfikacji (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$VER_TOTAL" -eq 0 ] && [ "$BASELINE_TOTAL" -eq 0 ]; then
    p_warn "CERTIFICATION-NO-DATA" "Brak rekordów weryfikacji i baseline — brak danych do weryfikacji ciągłości"
  else
    if [ "$VER_TOTAL" -gt 0 ]; then
      p_pass "CERTIFICATION-RECORDS" BLOCKING "Znaleziono $VER_TOTAL rekordów weryfikacji (w tym $VER_PASS PASS)"
    else
      p_fail "CERTIFICATION-RECORDS" BLOCKING "Brak rekordów weryfikacji w StateStore"
    fi
    if [ "$BASELINE_TOTAL" -gt 0 ]; then
      p_pass "CERTIFICATION-BASELINE" BLOCKING "Znaleziono $BASELINE_TOTAL baseline'ów certyfikacji"
    else
      p_warn "CERTIFICATION-BASELINE" "Brak baseline'ów certyfikacji w StateStore"
    fi
    if [ "$VER_STALE" -eq 0 ]; then
      p_pass "CERTIFICATION-FRESHNESS" BLOCKING "Wszystkie rekordy weryfikacji są aktualne (≤90 dni)"
    else
      p_warn "CERTIFICATION-FRESHNESS" "Znaleziono $VER_STALE nieaktualnych rekordów weryfikacji (>90 dni)"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-044:continuous-certification VER_TOTAL=$VER_TOTAL VER_PASS=$VER_PASS BASELINE=$BASELINE_TOTAL STALE=$VER_STALE" "pipeline" "runtime/continuous-certification.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$VER_TOTAL" -eq 0 ] && [ "$BASELINE_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$VER_TOTAL" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-044" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-044" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
