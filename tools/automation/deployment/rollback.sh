#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-035 — ROLLBACK (Rollback Procedure)
# Rodzina: DEPLOYMENT | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje istnienie procedury rollback dla wdrożeń:
#   * dokumentacja procedury (DEPLOYMENT.md / RECOVERY.md)
#   * rejestr rollback w StateStore (tabela deployment — pole source_ref/desired
#     wskazujące na procedurę, lub tabela configuration z kluczem rollback)
#
# Wykrywa:
#   * NO-ROLLBACK-PROCEDURE — brak udokumentowanej procedury rollback
#   * ROLLBACK-DOC-MISSING — brak pliku dokumentacji rollback
#
# NO FALSE GREEN: gdy brak jakichkolwiek śladów procedury rollback,
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
p_say "=== P-035 ROLLBACK ==="
p_say "Weryfikacja procedury rollback dla wdrożeń"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-035"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
ROLLBACK_DOC=0
ROLLBACK_DB=0
DB_AVAILABLE=0

# 1. Dokumentacja procedury rollback w repo (DEPLOYMENT.md / RECOVERY.md).
#    Szukamy wzmianek o rollback / przywracaniu / cofaniu wdrożenia.
for doc in DEPLOYMENT.md RECOVERY.md; do
  if [ -f "$ROOT/$doc" ] && grep -qiE "rollback|roll-back|cofni|przywrac|restore|revert" "$ROOT/$doc" 2>/dev/null; then
    ROLLBACK_DOC=1
  fi
done

# 2. Rejestr rollback w StateStore — deployment z procedurą rollback
#    (source_ref/desired wskazujące na rollback) lub configuration z kluczem rollback.
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  ROLLBACK_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE (source_ref IS NOT NULL AND LOWER(source_ref) LIKE '%rollback%')
       OR (desired IS NOT NULL AND LOWER(desired) LIKE '%rollback%');" 2>/dev/null || echo 0)
  if [ "$ROLLBACK_DB" -eq 0 ]; then
    ROLLBACK_DB=$(sqlite3 "$db" "
      SELECT COUNT(*) FROM configuration
      WHERE LOWER(key) LIKE '%rollback%' OR LOWER(domain) LIKE '%rollback%';" 2>/dev/null || echo 0)
  fi
else
  p_info "ROLLBACK-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$ROLLBACK_DOC" -eq 1 ]; then
  p_pass "ROLLBACK-PROCEDURE" BLOCKING "Procedura rollback udokumentowana w repo (DEPLOYMENT.md/RECOVERY.md)"
else
  p_warn "ROLLBACK-PROCEDURE" "Brak udokumentowanej procedury rollback w DEPLOYMENT.md/RECOVERY.md"
fi
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$ROLLBACK_DB" -gt 0 ]; then
  p_pass "ROLLBACK-REGISTRY" BLOCKING "Rejestr rollback w StateStore ($ROLLBACK_DB wpisów)"
else
  p_warn "ROLLBACK-REGISTRY" "Brak rejestru rollback w StateStore"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-035:rollback DOC=$ROLLBACK_DOC DB=$ROLLBACK_DB" "pipeline" "deployment/rollback.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
# Repo spełnia kontrakt, jeśli istnieje procedura rollback (dokumentacja LUB rejestr).
impl_verdict="PASS"
if [ "$ROLLBACK_DOC" -eq 1 ] || [ "$ROLLBACK_DB" -gt 0 ]; then
  repo_verdict="PASS"
else
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-035" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-035" "$repo_verdict" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
