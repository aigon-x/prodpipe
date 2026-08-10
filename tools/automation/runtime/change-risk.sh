#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-045 — CHANGE RISK (Change Risk / Change Intelligence)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje rejestr zmian i ryzyka (Change Intelligence):
#   * CHANGE-REGISTRY   — istnieje rejestr zmian (change_proposals)
#   * RISK-ASSESSMENT   — każda zmiana ma ocenę ryzyka (expected_risk)
#   * SCOPE-TRACKING    — istnieje śledzenie zakresu zmian (change_scope)
#   * DUPLICATE-TRACKING — istnieje rejestr duplikatów pracy (duplicate_work)
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
p_say "=== P-045 CHANGE RISK ==="
p_say "Weryfikacja rejestru zmian i ryzyka (change_proposals, risk, scope, duplicate)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-045"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
CHANGE_TOTAL=0
CHANGE_NO_RISK=0
SCOPE_TOTAL=0
DUPLICATE_TOTAL=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1
  CHANGE_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM change_proposals;" 2>/dev/null || echo 0)"

  # Zmiany bez oceny ryzyka (expected_risk NULL/puste).
  CHANGE_NO_RISK="$(sqlite3 "$DB" "SELECT COUNT(*) FROM change_proposals WHERE expected_risk IS NULL OR expected_risk = '';" 2>/dev/null || echo 0)"

  SCOPE_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM change_scope;" 2>/dev/null || echo 0)"
  DUPLICATE_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM duplicate_work;" 2>/dev/null || echo 0)"
else
  p_info "CHANGE-RISK-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę rejestru zmian (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$CHANGE_TOTAL" -eq 0 ] && [ "$SCOPE_TOTAL" -eq 0 ] && [ "$DUPLICATE_TOTAL" -eq 0 ]; then
    p_warn "CHANGE-RISK-NO-DATA" "Brak rejestru zmian, zakresu i duplikatów — brak danych do weryfikacji ryzyka"
  else
    if [ "$CHANGE_TOTAL" -gt 0 ]; then
      p_pass "CHANGE-REGISTRY" BLOCKING "Znaleziono $CHANGE_TOTAL propozycji zmian w rejestrze"
      if [ "$CHANGE_NO_RISK" -eq 0 ]; then
        p_pass "RISK-ASSESSMENT" BLOCKING "Wszystkie zmiany mają ocenę ryzyka (expected_risk)"
      else
        p_fail "RISK-ASSESSMENT" BLOCKING "Znaleziono $CHANGE_NO_RISK zmian bez oceny ryzyka"
      fi
    else
      p_fail "CHANGE-REGISTRY" BLOCKING "Brak rejestru zmian (change_proposals) w StateStore"
    fi
    if [ "$SCOPE_TOTAL" -gt 0 ]; then
      p_pass "SCOPE-TRACKING" BLOCKING "Znaleziono $SCOPE_TOTAL rekordów śledzenia zakresu zmian"
    else
      p_warn "SCOPE-TRACKING" "Brak śledzenia zakresu zmian (change_scope) w StateStore"
    fi
    if [ "$DUPLICATE_TOTAL" -gt 0 ]; then
      p_pass "DUPLICATE-TRACKING" BLOCKING "Znaleziono $DUPLICATE_TOTAL rekordów duplikatów pracy"
    else
      p_warn "DUPLICATE-TRACKING" "Brak rejestru duplikatów pracy (duplicate_work) w StateStore"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-045:change-risk CHANGE=$CHANGE_TOTAL NO_RISK=$CHANGE_NO_RISK SCOPE=$SCOPE_TOTAL DUPLICATE=$DUPLICATE_TOTAL" "pipeline" "runtime/change-risk.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$CHANGE_TOTAL" -eq 0 ] && [ "$SCOPE_TOTAL" -eq 0 ] && [ "$DUPLICATE_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$CHANGE_TOTAL" -eq 0 ] || [ "$CHANGE_NO_RISK" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-045" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-045" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
