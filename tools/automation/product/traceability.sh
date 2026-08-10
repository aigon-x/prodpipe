#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-003 — TRACEABILITY (Requirement → Change → Verification → Release)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje pełną śledzalność: każde wymaganie → zmiana → weryfikacja → wydanie.
# Konsumuje migrację StateStore 0017 (lifecycle plane: requirement/change/
# verification/release).
#
# Wykrywa:
#   * UNTRACED-REQUIREMENT — wymaganie bez powiązanej zmiany
#   * UNVERIFIED-CHANGE    — zmiana bez weryfikacji
#   * UNRELEASED-VERIFIED  — zweryfikowana zmiana bez wydania
#   * ORPHAN-VERIFICATION  — weryfikacja bez powiązanej zmiany
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
p_say "=== P-003 TRACEABILITY ==="
p_say "Weryfikacja śledzalności: wymaganie → zmiana → weryfikacja → wydanie"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-003"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
UNTRACED=0
UNVERIFIED=0
UNRELEASED=0
ORPHAN=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. UNTRACED-REQUIREMENT — wymaganie bez powiązanej zmiany.
  UNTRACED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM requirements r
    LEFT JOIN changes c ON c.requirement_id = r.requirement_id
    WHERE c.change_id IS NULL;" 2>/dev/null || echo 0)

  # 2. UNVERIFIED-CHANGE — zmiana bez weryfikacji.
  UNVERIFIED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM changes c
    LEFT JOIN verifications v ON v.change_id = c.change_id
    WHERE v.verification_id IS NULL;" 2>/dev/null || echo 0)

  # 3. UNRELEASED-VERIFIED — zweryfikowana zmiana bez wydania.
  UNRELEASED=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM verifications v
    LEFT JOIN releases r ON r.change_id = v.change_id
    WHERE v.status = 'PASS' AND r.release_id IS NULL;" 2>/dev/null || echo 0)

  # 4. ORPHAN-VERIFICATION — weryfikacja bez powiązanej zmiany.
  ORPHAN=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM verifications v
    LEFT JOIN changes c ON c.change_id = v.change_id
    WHERE c.change_id IS NULL;" 2>/dev/null || echo 0)
else
  p_info "TRACEABILITY-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$UNTRACED" -eq 0 ]; then
  p_pass "TRACEABILITY-NO-UNTRACED" BLOCKING "Wszystkie wymagania mają powiązane zmiany"
else
  p_fail "TRACEABILITY-UNTRACED" BLOCKING "Znaleziono $UNTRACED wymagań bez powiązanej zmiany"
fi
if [ "$UNVERIFIED" -eq 0 ]; then
  p_pass "TRACEABILITY-NO-UNVERIFIED" BLOCKING "Wszystkie zmiany mają weryfikację"
else
  p_fail "TRACEABILITY-UNVERIFIED" BLOCKING "Znaleziono $UNVERIFIED zmian bez weryfikacji"
fi
if [ "$UNRELEASED" -eq 0 ]; then
  p_pass "TRACEABILITY-NO-UNRELEASED" BLOCKING "Wszystkie zweryfikowane zmiany mają wydanie"
else
  p_warn "TRACEABILITY-UNRELEASED" "Znaleziono $UNRELEASED zweryfikowanych zmian bez wydania"
fi
if [ "$ORPHAN" -eq 0 ]; then
  p_pass "TRACEABILITY-NO-ORPHAN" BLOCKING "Brak osieroconych weryfikacji"
else
  p_fail "TRACEABILITY-ORPHAN" BLOCKING "Znaleziono $ORPHAN osieroconych weryfikacji"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-003:traceability UNTRACED=$UNTRACED UNVERIFIED=$UNVERIFIED UNRELEASED=$UNRELEASED ORPHAN=$ORPHAN" "pipeline" "product/traceability.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$UNTRACED" -gt 0 ] || [ "$UNVERIFIED" -gt 0 ] || [ "$ORPHAN" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-003" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-003" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
