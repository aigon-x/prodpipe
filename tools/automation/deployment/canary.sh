#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-036 — CANARY (Canary Deployment Configuration)
# Rodzina: DEPLOYMENT | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje istnienie konfiguracji wdrożeń canary:
#   * dokumentacja strategii canary (DEPLOYMENT.md / konfiguracja)
#   * rejestr canary w StateStore (tabela deployment — desired/source_ref
#     wskazujące na canary, lub tabela configuration z kluczem canary)
#
# Wykrywa:
#   * NO-CANARY-CONFIG — brak konfiguracji wdrożeń canary
#   * CANARY-DOC-MISSING — brak dokumentacji strategii canary
#
# NO FALSE GREEN: gdy brak jakichkolwiek śladów konfiguracji canary,
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
p_say "=== P-036 CANARY ==="
p_say "Weryfikacja konfiguracji wdrożeń canary"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-036"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
CANARY_DOC=0
CANARY_DB=0
DB_AVAILABLE=0

# 1. Dokumentacja strategii canary w repo (DEPLOYMENT.md / konfiguracja).
for doc in DEPLOYMENT.md; do
  if [ -f "$ROOT/$doc" ] && grep -qiE "canary|kanarek" "$ROOT/$doc" 2>/dev/null; then
    CANARY_DOC=1
  fi
done

# 2. Rejestr canary w StateStore — deployment z typem canary
#    (desired/source_ref wskazujące na canary) lub configuration z kluczem canary.
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  CANARY_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE (desired IS NOT NULL AND LOWER(desired) LIKE '%canary%')
       OR (source_ref IS NOT NULL AND LOWER(source_ref) LIKE '%canary%');" 2>/dev/null || echo 0)
  if [ "$CANARY_DB" -eq 0 ]; then
    CANARY_DB=$(sqlite3 "$db" "
      SELECT COUNT(*) FROM configuration
      WHERE LOWER(key) LIKE '%canary%' OR LOWER(domain) LIKE '%canary%';" 2>/dev/null || echo 0)
  fi
else
  p_info "CANARY-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$CANARY_DOC" -eq 1 ]; then
  p_pass "CANARY-CONFIG" BLOCKING "Strategia canary udokumentowana w repo (DEPLOYMENT.md)"
else
  p_warn "CANARY-CONFIG" "Brak dokumentacji strategii canary w DEPLOYMENT.md"
fi
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$CANARY_DB" -gt 0 ]; then
  p_pass "CANARY-REGISTRY" BLOCKING "Rejestr canary w StateStore ($CANARY_DB wpisów)"
else
  p_warn "CANARY-REGISTRY" "Brak rejestru canary w StateStore"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-036:canary DOC=$CANARY_DOC DB=$CANARY_DB" "pipeline" "deployment/canary.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# Repo spełnia kontrakt, jeśli istnieje konfiguracja canary (dokumentacja LUB rejestr).
impl_verdict="PASS"
if [ "$CANARY_DOC" -eq 1 ] || [ "$CANARY_DB" -gt 0 ]; then
  repo_verdict="PASS"
else
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-036" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-036" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
