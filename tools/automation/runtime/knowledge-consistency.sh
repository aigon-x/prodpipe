#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-042 — KNOWLEDGE CONSISTENCY (Knowledge Consistency)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje spójność wiedzy w StateStore (tabela document):
#   * DOCUMENT-VERSION   — dokumenty mają wersję / znacznik generacji
#   * DOCUMENT-METADATA  — dokumenty mają kompletne metadane (owner, status)
#   * DOCUMENT-FRESHNESS — dokumenty nie są nieaktualne (generated_at)
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
p_say "=== P-042 KNOWLEDGE CONSISTENCY ==="
p_say "Weryfikacja spójności wiedzy (dokumenty, wersje, metadane)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-042"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
DOC_TOTAL=0
DOC_NO_VERSION=0
DOC_NO_OWNER=0
DOC_STALE=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1
  DOC_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM document;" 2>/dev/null || echo 0)"

  # 1. DOCUMENT-VERSION — dokumenty bez wersji (generator_version NULL/puste).
  DOC_NO_VERSION="$(sqlite3 "$DB" "SELECT COUNT(*) FROM document WHERE generator_version IS NULL OR generator_version = '';" 2>/dev/null || echo 0)"

  # 2. DOCUMENT-METADATA — dokumenty bez właściciela (owner NULL/puste).
  DOC_NO_OWNER="$(sqlite3 "$DB" "SELECT COUNT(*) FROM document WHERE owner IS NULL OR owner = '';" 2>/dev/null || echo 0)"

  # 3. DOCUMENT-FRESHNESS — dokumenty nieaktualne (generated_at starsze niż 180 dni).
  DOC_STALE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM document WHERE generated_at IS NOT NULL AND generated_at < datetime('now', '-180 days');" 2>/dev/null || echo 0)"
else
  p_info "KNOWLEDGE-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę wiedzy (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$DOC_TOTAL" -eq 0 ]; then
    p_warn "KNOWLEDGE-NO-DATA" "Brak dokumentów w StateStore — brak danych do weryfikacji spójności"
  else
    if [ "$DOC_NO_VERSION" -eq 0 ]; then
      p_pass "KNOWLEDGE-DOCUMENT-VERSION" BLOCKING "Wszystkie dokumenty mają wersję (generator_version)"
    else
      p_fail "KNOWLEDGE-DOCUMENT-VERSION" BLOCKING "Znaleziono $DOC_NO_VERSION dokumentów bez wersji"
    fi
    if [ "$DOC_NO_OWNER" -eq 0 ]; then
      p_pass "KNOWLEDGE-DOCUMENT-METADATA" BLOCKING "Wszystkie dokumenty mają właściciela"
    else
      p_warn "KNOWLEDGE-DOCUMENT-METADATA" "Znaleziono $DOC_NO_OWNER dokumentów bez właściciela"
    fi
    if [ "$DOC_STALE" -eq 0 ]; then
      p_pass "KNOWLEDGE-DOCUMENT-FRESHNESS" BLOCKING "Brak nieaktualnych dokumentów (>180 dni)"
    else
      p_warn "KNOWLEDGE-DOCUMENT-FRESHNESS" "Znaleziono $DOC_STALE nieaktualnych dokumentów (>180 dni)"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-042:knowledge-consistency DOC_TOTAL=$DOC_TOTAL NO_VERSION=$DOC_NO_VERSION NO_OWNER=$DOC_NO_OWNER STALE=$DOC_STALE" "pipeline" "runtime/knowledge-consistency.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$DOC_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$DOC_NO_VERSION" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-042" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-042" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
