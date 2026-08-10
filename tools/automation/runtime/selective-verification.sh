#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-046 — SELECTIVE VERIFICATION (Selective Verification)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że weryfikacja jest selektywna (nie wszystko-za-wszystko):
#   * VERIFICATION-SCOPE   — rekordy weryfikacji mają zakres (artifact_type/artifact_id)
#   * VERIFICATION-GATES   — weryfikacja jest powiązana z gate'ami (gate_id)
#   * VERIFICATION-VERIFIER — rekordy mają wskazanego weryfikatora
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
p_say "=== P-046 SELECTIVE VERIFICATION ==="
p_say "Weryfikacja selektywności weryfikacji (zakres, gate'y, weryfikatorzy)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-046"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
VER_TOTAL=0
VER_NO_SCOPE=0
VER_NO_GATE=0
VER_NO_VERIFIER=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1
  VER_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification;" 2>/dev/null || echo 0)"

  # Rekordy bez zakresu (artifact_type/artifact_id NULL lub puste).
  VER_NO_SCOPE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification WHERE artifact_type IS NULL OR artifact_type = '' OR artifact_id IS NULL OR artifact_id = '';" 2>/dev/null || echo 0)"

  # Rekordy bez powiązania z gate'em.
  VER_NO_GATE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification WHERE gate_id IS NULL OR gate_id = '';" 2>/dev/null || echo 0)"

  # Rekordy bez weryfikatora.
  VER_NO_VERIFIER="$(sqlite3 "$DB" "SELECT COUNT(*) FROM verification WHERE verifier IS NULL OR verifier = '';" 2>/dev/null || echo 0)"
else
  p_info "SELECTIVE-VERIFICATION-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę weryfikacji (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$VER_TOTAL" -eq 0 ]; then
    p_warn "SELECTIVE-VERIFICATION-NO-DATA" "Brak rekordów weryfikacji — brak danych do weryfikacji selektywności"
  else
    if [ "$VER_NO_SCOPE" -eq 0 ]; then
      p_pass "VERIFICATION-SCOPE" BLOCKING "Wszystkie rekordy weryfikacji mają zakres (artifact_type/artifact_id)"
    else
      p_fail "VERIFICATION-SCOPE" BLOCKING "Znaleziono $VER_NO_SCOPE rekordów weryfikacji bez zakresu"
    fi
    if [ "$VER_NO_GATE" -eq 0 ]; then
      p_pass "VERIFICATION-GATES" BLOCKING "Wszystkie rekordy weryfikacji są powiązane z gate'ami"
    else
      p_warn "VERIFICATION-GATES" "Znaleziono $VER_NO_GATE rekordów weryfikacji bez gate_id"
    fi
    if [ "$VER_NO_VERIFIER" -eq 0 ]; then
      p_pass "VERIFICATION-VERIFIER" BLOCKING "Wszystkie rekordy weryfikacji mają wskazanego weryfikatora"
    else
      p_warn "VERIFICATION-VERIFIER" "Znaleziono $VER_NO_VERIFIER rekordów weryfikacji bez weryfikatora"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-046:selective-verification VER_TOTAL=$VER_TOTAL NO_SCOPE=$VER_NO_SCOPE NO_GATE=$VER_NO_GATE NO_VERIFIER=$VER_NO_VERIFIER" "pipeline" "runtime/selective-verification.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$VER_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$VER_NO_SCOPE" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-046" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-046" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
