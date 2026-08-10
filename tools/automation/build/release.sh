#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-033 — RELEASE (Release registry)
# Rodzina: BUILD | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje rejestr wydań (tabela release w StateStore).
# Wykrywa brak wydania oraz wydanie bez wersji / bez statusu.
#
# Wykrywa:
#   * NO-RELEASE-REGISTRY — tabela release pusta / brak wydania
#   * RELEASE-NO-VERSION  — wydanie bez wersji (semver)
#   * RELEASE-NO-STATUS   — wydanie bez statusu
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
p_say "=== P-033 RELEASE ==="
p_say "Weryfikacja rejestru wydań (tabela release)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-033"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
RELEASE_COUNT=0
RELEASE_NO_VERSION=0
RELEASE_NO_STATUS=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  RELEASE_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM release;" 2>/dev/null || echo 0)
  RELEASE_NO_VERSION=$(sqlite3 "$db" "SELECT COUNT(*) FROM release WHERE version IS NULL OR version = '';" 2>/dev/null || echo 0)
  RELEASE_NO_STATUS=$(sqlite3 "$db" "SELECT COUNT(*) FROM release WHERE status IS NULL OR status = '';" 2>/dev/null || echo 0)
else
  p_info "RELEASE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "RELEASE-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować rejestru wydań"
elif [ "$RELEASE_COUNT" -eq 0 ]; then
  p_fail "RELEASE-NO-REGISTRY" BLOCKING "Brak rekordów wydań w tabeli release (rejestr pusty)"
else
  p_pass "RELEASE-REGISTRY-PRESENT" BLOCKING "Znaleziono $RELEASE_COUNT wydań w rejestrze"
  if [ "$RELEASE_NO_VERSION" -eq 0 ]; then
    p_pass "RELEASE-ALL-VERSIONED" BLOCKING "Wszystkie wydania mają wersję"
  else
    p_fail "RELEASE-NO-VERSION" BLOCKING "Znaleziono $RELEASE_NO_VERSION wydań bez wersji"
  fi
  if [ "$RELEASE_NO_STATUS" -eq 0 ]; then
    p_pass "RELEASE-ALL-STATUSED" BLOCKING "Wszystkie wydania mają status"
  else
    p_fail "RELEASE-NO-STATUS" BLOCKING "Znaleziono $RELEASE_NO_STATUS wydań bez statusu"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-033:release COUNT=$RELEASE_COUNT NO_VERSION=$RELEASE_NO_VERSION NO_STATUS=$RELEASE_NO_STATUS" "pipeline" "build/release.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$RELEASE_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
  if [ "$RELEASE_NO_VERSION" -gt 0 ] || [ "$RELEASE_NO_STATUS" -gt 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-033" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-033" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
