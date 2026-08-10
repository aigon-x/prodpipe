#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-037 — BLUE-GREEN (Blue-Green Deployment Configuration)
# Rodzina: DEPLOYMENT | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje istnienie konfiguracji wdrożeń blue-green:
#   * dokumentacja strategii blue-green (DEPLOYMENT.md / konfiguracja)
#   * rejestr blue-green w StateStore (tabela deployment — desired/source_ref
#     wskazujące na blue-green, lub tabela configuration z kluczem blue-green)
#
# Wykrywa:
#   * NO-BLUE-GREEN-CONFIG — brak konfiguracji wdrożeń blue-green
#   * BLUE-GREEN-DOC-MISSING — brak dokumentacji strategii blue-green
#
# NO FALSE GREEN: gdy brak jakichkolwiek śladów konfiguracji blue-green,
# repo_verdict = NOT_APPLICABLE (nie zgłaszamy PASS na podstawie braku danych).
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
p_say "=== P-037 BLUE-GREEN ==="
p_say "Weryfikacja konfiguracji wdrożeń blue-green"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-037"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
BG_DOC=0
BG_DB=0
DB_AVAILABLE=0

# 1. Dokumentacja strategii blue-green w repo (DEPLOYMENT.md / konfiguracja).
for doc in DEPLOYMENT.md; do
  if [ -f "$ROOT/$doc" ] && grep -qiE "blue.?green|blue green|niebiesko.?zielon" "$ROOT/$doc" 2>/dev/null; then
    BG_DOC=1
  fi
done

# 2. Rejestr blue-green w StateStore — deployment z typem blue-green
#    (desired/source_ref wskazujące na blue-green) lub configuration z kluczem blue-green.
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  BG_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE (desired IS NOT NULL AND LOWER(desired) LIKE '%blue-green%')
       OR (desired IS NOT NULL AND LOWER(desired) LIKE '%blue_green%')
       OR (source_ref IS NOT NULL AND LOWER(source_ref) LIKE '%blue-green%');" 2>/dev/null || echo 0)
  if [ "$BG_DB" -eq 0 ]; then
    BG_DB=$(sqlite3 "$db" "
      SELECT COUNT(*) FROM configuration
      WHERE LOWER(key) LIKE '%blue-green%' OR LOWER(key) LIKE '%blue_green%'
         OR LOWER(domain) LIKE '%blue-green%';" 2>/dev/null || echo 0)
  fi
else
  p_info "BLUE-GREEN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$BG_DOC" -eq 1 ]; then
  p_pass "BLUE-GREEN-CONFIG" BLOCKING "Strategia blue-green udokumentowana w repo (DEPLOYMENT.md)"
else
  p_warn "BLUE-GREEN-CONFIG" "Brak dokumentacji strategii blue-green w DEPLOYMENT.md"
fi
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$BG_DB" -gt 0 ]; then
  p_pass "BLUE-GREEN-REGISTRY" BLOCKING "Rejestr blue-green w StateStore ($BG_DB wpisów)"
else
  p_warn "BLUE-GREEN-REGISTRY" "Brak rejestru blue-green w StateStore"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-037:blue-green DOC=$BG_DOC DB=$BG_DB" "pipeline" "deployment/blue-green.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# Repo spełnia kontrakt, jeśli istnieje konfiguracja blue-green (dokumentacja LUB rejestr).
impl_verdict="PASS"
if [ "$BG_DOC" -eq 1 ] || [ "$BG_DB" -gt 0 ]; then
  repo_verdict="PASS"
else
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-037" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-037" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
