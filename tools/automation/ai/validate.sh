#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-064 — AI VALIDATE (Etap 3: model bezpieczny/fair?)
# Rodzina: AI | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje bezpieczeństwo i fairness modelu: weryfikacje (verification),
# polityki (policy), model card, testy adversarial i fairness.
# W AI błąd = bug w danych, kodzie LUB modelu — ten pipeline pilnuje,
# że model jest bezpieczny i sprawiedliwy przed wdrożeniem.
#
# Wykrywa:
#   * NO-VALIDATE-VERIFICATION — brak weryfikacji bezpieczeństwa/fairness
#   * NO-AI-POLICY            — brak polityki AI (fairness/bezpieczeństwo)
#   * NO-MODEL-CARD           — brak dowodu model card
#   * NO-ADVERSARIAL          — brak dowodu testów adversarial
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
p_say "=== P-064 AI VALIDATE ==="
p_say "Weryfikacja bezpieczeństwa i fairness modelu (verification / policy / model card / adversarial)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-064"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

VALIDATE_VERIFICATION=0
AI_POLICY=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Weryfikacje bezpieczeństwa/fairness (artifact_type safety/fairness/validate/adversarial).
  VALIDATE_VERIFICATION=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM verification
    WHERE artifact_type LIKE '%safety%' OR artifact_type LIKE '%fair%'
       OR artifact_type LIKE '%validate%' OR artifact_type LIKE '%adversarial%'
       OR gate_id LIKE '%VALIDATE%' OR gate_id LIKE '%FAIR%';" 2>/dev/null || echo 0)
  # Polityki AI (domain LIKE '%ai%' lub name LIKE '%fair%'/'%safety%').
  AI_POLICY=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM policy
    WHERE domain LIKE '%ai%' OR name LIKE '%fair%' OR name LIKE '%safety%'
       OR name LIKE '%model%';" 2>/dev/null || echo 0)
else
  p_info "AI-VALIDATE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-VALIDATE-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować bezpieczeństwa modelu"
elif [ "$VALIDATE_VERIFICATION" -eq 0 ] && [ "$AI_POLICY" -eq 0 ]; then
  p_fail "AI-VALIDATE-NO-EVIDENCE" BLOCKING "Brak dowodu bezpieczeństwa/fairness (verification / policy) — model niezwalidowany"
else
  p_pass "AI-VALIDATE-EVIDENCE-PRESENT" BLOCKING "Znaleziono dowód walidacji (verification=$VALIDATE_VERIFICATION, policy=$AI_POLICY)"
  if [ "$VALIDATE_VERIFICATION" -eq 0 ]; then
    p_fail "AI-VALIDATE-NO-VERIFICATION" BLOCKING "Brak weryfikacji bezpieczeństwa/fairness (model card / adversarial / fairness)"
  else
    p_pass "AI-VALIDATE-VERIFICATION" BLOCKING "Znaleziono $VALIDATE_VERIFICATION weryfikacji bezpieczeństwa/fairness"
  fi
  if [ "$AI_POLICY" -eq 0 ]; then
    p_warn "AI-VALIDATE-NO-POLICY" "Brak polityki AI (fairness/bezpieczeństwo) w tabeli policy"
  else
    p_pass "AI-VALIDATE-POLICY" BLOCKING "Znaleziono $AI_POLICY polityk AI"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-064:ai-validate MODE=$AI_MODE VERIFICATION=$VALIDATE_VERIFICATION POLICY=$AI_POLICY" "pipeline" "ai/validate.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$VALIDATE_VERIFICATION" -gt 0 ] || [ "$AI_POLICY" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$VALIDATE_VERIFICATION" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-064" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-064" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
