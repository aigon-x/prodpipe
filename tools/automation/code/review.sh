#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-028 — REVIEW (Proces przeglądu kodu)
# Rodzina: CODE | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje, że repozytorium ma zdefiniowany proces review kodu.
# Wykrywa:
#   * NO-REVIEW-PROCESS — brak procesu review (CODEOWNERS / CONTRIBUTING)
#   * REVIEW-PROCESS    — obecny proces review
#   * UNREVIEWED-CHANGE — zmiany w StateStore bez statusu review
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
p_say "=== P-028 REVIEW ==="
p_say "Weryfikacja procesu przeglądu kodu"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-028"

# ── EXECUTE ─────────────────────────────────────────────────
# 1. Proces review w repo: CODEOWNERS, CONTRIBUTING.md, .github/ (PR templates).
REVIEW_FILES="$(p_repo_files --name '(^CODEOWNERS$|^CONTRIBUTING\.md$|^\.github/|^OWNERSHIP\.md$|^SECURITY\.md$)')"
REVIEW_COUNT=$(printf '%s\n' "$REVIEW_FILES" | grep -c . || true)

# 2. Zmiany w StateStore bez statusu review (tabela change).
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
UNREVIEWED=0
CHANGE_TOTAL=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  CHANGE_TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM change;" 2>/dev/null || echo 0)
  UNREVIEWED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM change
    WHERE status NOT IN ('REVIEWED', 'APPROVED', 'MERGED', 'CLOSED');" 2>/dev/null || echo 0)
else
  p_info "REVIEW-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$REVIEW_COUNT" -gt 0 ]; then
  p_pass "REVIEW-PROCESS-PRESENT" BLOCKING "Znaleziono $REVIEW_COUNT plików definiujących proces review"
else
  p_fail "REVIEW-PROCESS-MISSING" BLOCKING "Brak procesu review (CODEOWNERS / CONTRIBUTING / .github)"
fi
if [ "$CHANGE_TOTAL" -gt 0 ]; then
  if [ "$UNREVIEWED" -eq 0 ]; then
    p_pass "REVIEW-ALL-CHANGES" BLOCKING "Wszystkie zmiany ($CHANGE_TOTAL) mają status review"
  else
    p_fail "REVIEW-UNREVIEWED" BLOCKING "Znaleziono $UNREVIEWED zmian bez statusu review"
  fi
else
  p_info "REVIEW-NO-CHANGES" "Brak zmian w StateStore (tabela change pusta) — informacyjnie"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-028:review REVIEW_FILES=$REVIEW_COUNT CHANGES=$CHANGE_TOTAL UNREVIEWED=$UNREVIEWED" "pipeline" "code/review.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# NO FALSE GREEN: gdy brak zmian w StateStore → NOT_APPLICABLE dla części DB,
# ale proces review w repo decyduje o werdykcie.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$REVIEW_COUNT" -eq 0 ]; then
  repo_verdict="FAIL"
elif [ "$CHANGE_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-028" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-028" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
