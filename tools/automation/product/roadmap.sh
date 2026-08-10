#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-005 — ROADMAP (Release Roadmap)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje istnienie roadmapy wydań: czy istnieją wydania (release),
# czy każde ma wersję i status oraz datę (observed_at/recorded_at jako proxy).
#
# Wykrywa:
#   * NO-ROADMAP      — brak wydań w StateStore (brak roadmapy)
#   * RELEASE-NO-VERSION — wydanie bez wersji
#   * RELEASE-NO-STATUS  — wydanie bez statusu
#   * RELEASE-NO-DATE    — wydanie bez daty (observed_at/recorded_at)
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
p_say "=== P-005 ROADMAP ==="
p_say "Weryfikacja roadmapy wydań (release / wersja / status / data)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-005"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
TOTAL=0
NO_VERSION=0
NO_STATUS=0
NO_DATE=0
DB_OK=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # Baza może być niezainicjalizowana (pusty plik / brak tabel) — wtedy
  # nie możemy zweryfikować repo → NOT_APPLICABLE, nie FAIL.
  if [ "$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='release';" 2>/dev/null || echo 0)" -eq 0 ]; then
    p_info "ROADMAP-NO-TABLE" "Brak tabeli 'release' w StateStore — baza niezainicjalizowana (best-effort)"
  else
    DB_OK=1
    TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM release;" 2>/dev/null || echo 0)
    # 1. Wydanie bez wersji.
    NO_VERSION=$(sqlite3 "$db" "SELECT COUNT(*) FROM release WHERE version IS NULL OR version = '';" 2>/dev/null || echo 0)
    # 2. Wydanie bez statusu.
    NO_STATUS=$(sqlite3 "$db" "SELECT COUNT(*) FROM release WHERE status IS NULL OR status = '';" 2>/dev/null || echo 0)
    # 3. Wydanie bez daty (observed_at i recorded_at puste — brak punktu w roadmapie).
    NO_DATE=$(sqlite3 "$db" "SELECT COUNT(*) FROM release WHERE (observed_at IS NULL OR observed_at = '') AND (recorded_at IS NULL OR recorded_at = '');" 2>/dev/null || echo 0)
  fi
else
  p_info "ROADMAP-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  p_info "ROADMAP-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
elif [ "$TOTAL" -eq 0 ]; then
  p_fail "ROADMAP-NO-ROADMAP" BLOCKING "Brak wydań w StateStore — brak roadmapy (tabela release pusta)"
else
  if [ "$NO_VERSION" -eq 0 ]; then
    p_pass "ROADMAP-ALL-VERSION" BLOCKING "Wszystkie wydania mają wersję"
  else
    p_fail "ROADMAP-RELEASE-NO-VERSION" BLOCKING "Znaleziono $NO_VERSION wydań bez wersji"
  fi
  if [ "$NO_STATUS" -eq 0 ]; then
    p_pass "ROADMAP-ALL-STATUS" BLOCKING "Wszystkie wydania mają status"
  else
    p_fail "ROADMAP-RELEASE-NO-STATUS" BLOCKING "Znaleziono $NO_STATUS wydań bez statusu"
  fi
  if [ "$NO_DATE" -eq 0 ]; then
    p_pass "ROADMAP-ALL-DATE" BLOCKING "Wszystkie wydania mają datę (punkt w roadmapie)"
  else
    p_warn "ROADMAP-RELEASE-NO-DATE" "Znaleziono $NO_DATE wydań bez daty"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-005:roadmap TOTAL=$TOTAL NO_VERSION=$NO_VERSION NO_STATUS=$NO_STATUS NO_DATE=$NO_DATE" "pipeline" "product/roadmap.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$TOTAL" -eq 0 ] || [ "$NO_VERSION" -gt 0 ] || [ "$NO_STATUS" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-005" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-005" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
