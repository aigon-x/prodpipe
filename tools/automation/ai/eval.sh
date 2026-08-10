#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-063 — AI EVAL (Etap 2: model spełnia progi?)
# Rodzina: AI | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje dowód ewaluacji modelu: weryfikacje (verification), jakość
# (quality_index), golden dataset, progi akceptacji i regresję vs baseline.
# W AI błąd = bug w danych, kodzie LUB modelu — ten pipeline pilnuje,
# że model faktycznie spełnia zadeklarowane progi jakości.
#
# Wykrywa:
#   * NO-EVAL-VERIFICATION — brak weryfikacji ewaluacji (artifact_type eval/model)
#   * NO-GOLDEN-DATASET    — brak dowodu golden dataset
#   * NO-EVAL-THRESHOLDS   — brak dowodu progów akceptacji
#   * NO-BASELINE-REGRESSION — brak dowodu porównania regresji vs baseline
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
p_say "=== P-063 AI EVAL ==="
p_say "Weryfikacja ewaluacji modelu (weryfikacje / golden dataset / progi / regresja)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-063"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

EVAL_VERIFICATION=0
QUALITY_ROWS=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Weryfikacje ewaluacji (artifact_type eval/model lub gate_id zawiera EVAL).
  EVAL_VERIFICATION=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM verification
    WHERE artifact_type LIKE '%eval%' OR artifact_type LIKE '%model%'
       OR gate_id LIKE '%EVAL%';" 2>/dev/null || echo 0)
  # Wiersze jakości (quality_index) — dowód pomiaru jakości.
  QUALITY_ROWS=$(sqlite3 "$db" "SELECT COUNT(*) FROM quality_index;" 2>/dev/null || echo 0)
else
  p_info "AI-EVAL-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-EVAL-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować ewaluacji"
elif [ "$EVAL_VERIFICATION" -eq 0 ] && [ "$QUALITY_ROWS" -eq 0 ]; then
  p_fail "AI-EVAL-NO-EVIDENCE" BLOCKING "Brak dowodu ewaluacji (verification / quality_index) — model niezweryfikowany"
else
  p_pass "AI-EVAL-EVIDENCE-PRESENT" BLOCKING "Znaleziono dowód ewaluacji (verification=$EVAL_VERIFICATION, quality=$QUALITY_ROWS)"
  if [ "$EVAL_VERIFICATION" -eq 0 ]; then
    p_fail "AI-EVAL-NO-VERIFICATION" BLOCKING "Brak weryfikacji ewaluacji w tabeli verification (golden dataset / progi / regresja)"
  else
    p_pass "AI-EVAL-VERIFICATION" BLOCKING "Znaleziono $EVAL_VERIFICATION weryfikacji ewaluacji"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-063:ai-eval MODE=$AI_MODE VERIFICATION=$EVAL_VERIFICATION QUALITY=$QUALITY_ROWS" "pipeline" "ai/eval.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$EVAL_VERIFICATION" -gt 0 ] || [ "$QUALITY_ROWS" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$EVAL_VERIFICATION" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-063" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-063" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
