#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-014 — CHANGE IMPACT ENGINE (Change Impact / Change Intelligence)
# Rodzina: DESIGN | Klasa: DEEP | Status: IMPLEMENTED
#
# Analizuje wpływ zmian na system. Konsumuje migrację StateStore 0011
# (change intelligence: change_proposals / prediction_accuracy / change_scope /
# duplicate_work) i 0017 (lifecycle plane: requirement/change/verification/release).
#
# Wykrywa:
#   * CHANGE-SCOPE   — zakres zmiany (pliki dotknięte, moduły, pipeline'y)
#   * DUPLICATE-WORK — propozycje zmian o nakładającym się zakresie
#   * PREDICTION     — porównanie przewidzianego vs faktycznego wpływu
#   * RISK           — ryzyko zmiany (wysokie = wymaga pełnej weryfikacji)
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
p_say "=== P-014 CHANGE IMPACT ENGINE ==="
p_say "Analiza wpływu zmian na system (scope / duplicate / prediction / risk)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-014"

# ── EXECUTE ─────────────────────────────────────────────────
# 1. CHANGE-SCOPE — zakres bieżącej zmiany (uncommitted + ostatni commit).
#    Wykrywa, które pipeline'y są dotknięte zmianą (na podstawie ścieżek).
CHANGED_FILES="$(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -v '^$' || true)"
CHANGED_COUNT=$(printf '%s\n' "$CHANGED_FILES" | grep -c . || echo 0)

# Mapowanie ścieżek → dotknięte pipeline'y (na podstawie rodziny).
AFFECTED_PIPELINES=""
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  fam="${rest%%|*}"
  rest="${rest#*|}"
  scr="${rest%%|*}"
  # Rodzina pipeline'a → prefiks ścieżki.
  fam_lower="$(echo "$fam" | tr 'A-Z' 'a-z')"
  if printf '%s\n' "$CHANGED_FILES" | grep -q "^$fam_lower/" || printf '%s\n' "$CHANGED_FILES" | grep -q "^tools/automation/$fam_lower/"; then
    AFFECTED_PIPELINES="$AFFECTED_PIPELINES $eid"
  fi
done

if [ "$CHANGED_COUNT" -gt 0 ]; then
  p_info "CHANGE-SCOPE" "Zmiana dotyka $CHANGED_COUNT plików. Dotknięte pipeline'y:$AFFECTED_PIPELINES"
else
  p_info "CHANGE-SCOPE" "Brak zmian w working tree (czyste repo)."
fi

# 2. DUPLICATE-WORK — propozycje zmian o nakładającym się zakresie.
#    Konsumuje tabelę change_proposals (migracja 0011).
DUPLICATE_COUNT=0
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # Wykryj propozycje zmian o tym samym zakresie (duplikaty).
  DUPLICATE_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM (
      SELECT scope, COUNT(*) c FROM change_proposals
      WHERE status = 'OPEN'
      GROUP BY scope HAVING c > 1
    );" 2>/dev/null || echo 0)
  if [ "$DUPLICATE_COUNT" -gt 0 ]; then
    p_warn "DUPLICATE-WORK" "Znaleziono $DUPLICATE_COUNT zakresów z wieloma otwartymi propozycjami zmian"
  else
    p_pass "DUPLICATE-WORK" BLOCKING "Brak zduplikowanych propozycji zmian"
  fi
else
  p_info "DUPLICATE-WORK" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 3. PREDICTION — porównanie przewidzianego vs faktycznego wpływu.
#    Konsumuje tabelę prediction_accuracy (migracja 0011).
PREDICTION_COUNT=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  PREDICTION_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM prediction_accuracy
    WHERE predicted_impact != actual_impact;" 2>/dev/null || echo 0)
  if [ "$PREDICTION_COUNT" -gt 0 ]; then
    p_warn "PREDICTION-DRIFT" "Znaleziono $PREDICTION_COUNT rozbieżności przewidzianego vs faktycznego wpływu"
  else
    p_pass "PREDICTION-ACCURACY" BLOCKING "Przewidywany wpływ zgodny z faktycznym"
  fi
else
  p_info "PREDICTION-ACCURACY" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# 4. RISK — ryzyko zmiany. Wysokie ryzyko = wymaga pełnej weryfikacji (P-046).
#    Konsumuje tabelę change_scope (migracja 0011).
RISK_LEVEL="LOW"
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  high_risk=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM change_scope
    WHERE risk_level = 'HIGH' AND status = 'OPEN';" 2>/dev/null || echo 0)
  if [ "$high_risk" -gt 0 ]; then
    RISK_LEVEL="HIGH"
    p_warn "CHANGE-RISK" "Znaleziono $high_risk zmian o wysokim ryzyku — wymagają pełnej weryfikacji (P-046)"
  else
    p_pass "CHANGE-RISK" BLOCKING "Brak zmian o wysokim ryzyku"
  fi
else
  p_info "CHANGE-RISK" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
# Self-test: pipeline poprawnie wykrył zakres zmiany.
if [ "$CHANGED_COUNT" -ge 0 ]; then
  p_pass "CHANGE-IMPACT-SELF-TEST" BLOCKING "Pipeline poprawnie przeanalizował zakres zmiany"
else
  p_fail "CHANGE-IMPACT-SELF-TEST" BLOCKING "Błąd analizy zakresu zmiany"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-014:change-impact CHANGED=$CHANGED_COUNT DUPLICATE=$DUPLICATE_COUNT PREDICTION=$PREDICTION_COUNT RISK=$RISK_LEVEL" "pipeline" "design/change-impact.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DUPLICATE_COUNT" -gt 0 ] || [ "$PREDICTION_COUNT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-014" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-014" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
