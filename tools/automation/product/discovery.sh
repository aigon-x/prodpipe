#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-001 — DISCOVERY (Product Discovery / Opportunity)
# Rodzina: PRODUCT | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje kompletność fazy discovery produktu: czy istnieje projekt,
# artefakty discovery (dokumenty), badania UX i manualne charters.
#
# Wykrywa:
#   * NO-PROJECT        — brak zarejestrowanego projektu w StateStore
#   * NO-DISCOVERY-DOC  — brak dokumentów discovery (document)
#   * NO-UX-STUDY       — brak badań UX (ux_studies)
#   * NO-MANUAL-CHARTER — brak manualnych charters (manual_charters)
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
p_say "=== P-001 DISCOVERY ==="
p_say "Weryfikacja kompletności fazy discovery produktu (projekt / dokumenty / UX / charters)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-001"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
PROJECTS=0
DOCS=0
UX=0
CHARTERS=0
DB_OK=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # Baza może być niezainicjalizowana (pusty plik / brak tabel) — wtedy
  # nie możemy zweryfikować repo → NOT_APPLICABLE, nie FAIL.
  if [ "$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='project';" 2>/dev/null || echo 0)" -eq 0 ]; then
    p_info "DISCOVERY-NO-TABLE" "Brak tabeli 'project' w StateStore — baza niezainicjalizowana (best-effort)"
  else
    DB_OK=1
    # 1. Projekt — czy istnieje jakikolwiek zarejestrowany projekt.
    PROJECTS=$(sqlite3 "$db" "SELECT COUNT(*) FROM project;" 2>/dev/null || echo 0)
    # 2. Dokumenty discovery — artefakty dokumentacyjne.
    DOCS=$(sqlite3 "$db" "SELECT COUNT(*) FROM document;" 2>/dev/null || echo 0)
    # 3. Badania UX.
    UX=$(sqlite3 "$db" "SELECT COUNT(*) FROM ux_studies;" 2>/dev/null || echo 0)
    # 4. Manualne charters.
    CHARTERS=$(sqlite3 "$db" "SELECT COUNT(*) FROM manual_charters;" 2>/dev/null || echo 0)
  fi
else
  p_info "DISCOVERY-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_OK" -eq 0 ]; then
  # Brak bazy — nie możemy zweryfikować repo. NOT_APPLICABLE, nie FAIL.
  p_info "DISCOVERY-NO-DB" "Brak danych StateStore — repo_verdict NOT_APPLICABLE"
else
  if [ "$PROJECTS" -gt 0 ]; then
    p_pass "DISCOVERY-HAS-PROJECT" BLOCKING "Znaleziono $PROJECTS projektów w StateStore"
  else
    p_fail "DISCOVERY-NO-PROJECT" BLOCKING "Brak zarejestrowanego projektu (tabela project pusta)"
  fi
  if [ "$DOCS" -gt 0 ]; then
    p_pass "DISCOVERY-HAS-DOC" BLOCKING "Znaleziono $DOCS dokumentów discovery"
  else
    p_fail "DISCOVERY-NO-DOC" BLOCKING "Brak dokumentów discovery (tabela document pusta)"
  fi
  if [ "$UX" -gt 0 ]; then
    p_pass "DISCOVERY-HAS-UX" BLOCKING "Znaleziono $UX badań UX"
  else
    p_warn "DISCOVERY-NO-UX" "Brak badań UX (tabela ux_studies pusta)"
  fi
  if [ "$CHARTERS" -gt 0 ]; then
    p_pass "DISCOVERY-HAS-CHARTER" BLOCKING "Znaleziono $CHARTERS manualnych charters"
  else
    p_warn "DISCOVERY-NO-CHARTER" "Brak manualnych charters (tabela manual_charters pusta)"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-001:discovery PROJECTS=$PROJECTS DOCS=$DOCS UX=$UX CHARTERS=$CHARTERS" "pipeline" "product/discovery.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_OK" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$PROJECTS" -eq 0 ] || [ "$DOCS" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-001" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-001" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
