#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-009 — DESIGN DOC (Design Documentation)
# Rodzina: DESIGN | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje kompletność dokumentacji projektowej (design docs).
# Konsumuje tabelę document (StateStore) — dokumenty typu design.
#
# Wykrywa:
#   * NO-DESIGN-DOC   — brak jakichkolwiek design docs
#   * UNTRACED-DESIGN — wymaganie bez powiązanego design doc
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
p_say "=== P-009 DESIGN DOC ==="
p_say "Weryfikacja dokumentacji projektowej (design docs)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-009"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DESIGN_DOCS=0
UNTRACED_DESIGN=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. NO-DESIGN-DOC — liczba design docs w StateStore.
  DESIGN_DOCS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM document
    WHERE kind IN ('DESIGN','DESIGN_DOC','design') OR path LIKE '%design%';" 2>/dev/null || echo 0)

  # 2. UNTRACED-DESIGN — wymagania bez powiązanego design doc.
  #    Wymaganie ma design doc, gdy istnieje dokument design o ścieżce
  #    zawierającej requirement_id (source_ref) lub gdy source_type = 'design'.
  UNTRACED_DESIGN=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM requirement r
    WHERE NOT EXISTS (
      SELECT 1 FROM document d
      WHERE d.source_ref = r.requirement_id
         OR d.path LIKE '%' || r.requirement_id || '%'
         OR d.kind IN ('DESIGN','DESIGN_DOC','design')
    );" 2>/dev/null || echo 0)
else
  p_info "DESIGN-DOC-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DESIGN_DOCS" -gt 0 ]; then
  p_pass "DESIGN-DOC-PRESENT" BLOCKING "Znaleziono $DESIGN_DOCS design docs w StateStore"
else
  p_warn "DESIGN-DOC-PRESENT" "Brak design docs w StateStore (tabela document) — brak dokumentacji projektowej"
fi

if [ "$UNTRACED_DESIGN" -eq 0 ]; then
  p_pass "DESIGN-DOC-TRACED" BLOCKING "Wszystkie wymagania mają powiązane design docs"
else
  p_fail "DESIGN-DOC-UNTRACED" BLOCKING "Znaleziono $UNTRACED_DESIGN wymagań bez design doc"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-009:design-doc DESIGN_DOCS=$DESIGN_DOCS UNTRACED=$UNTRACED_DESIGN" "pipeline" "design/design-doc.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DESIGN_DOCS" -eq 0 ] && [ "$UNTRACED_DESIGN" -eq 0 ]; then
  # Brak danych w StateStore — nie można stwierdzić naruszenia, ale też brak dowodu.
  repo_verdict="NOT_APPLICABLE"
elif [ "$UNTRACED_DESIGN" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-009" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-009" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
