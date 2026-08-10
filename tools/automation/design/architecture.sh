#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-008 — ARCHITECTURE (Architecture & ADR)
# Rodzina: DESIGN | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje kompletność dokumentacji architektonicznej:
#   * dokument architektury (ARCHITECTURE.md w repo / tabela document)
#   * ADR — Architecture Decision Records (tabela decision)
#
# Wykrywa:
#   * NO-ARCH-DOC      — brak dokumentu architektury
#   * NO-ADR           — brak rejestru decyzji architektonicznych (ADR)
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
p_say "=== P-008 ARCHITECTURE ==="
p_say "Weryfikacja dokumentacji architektonicznej (arch doc + ADR)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-008"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

# 1. NO-ARCH-DOC — dokument architektury w repo (ARCHITECTURE.md) lub w StateStore.
ARCH_DOC_REPO=0
if [ -f "ARCHITECTURE.md" ]; then
  ARCH_DOC_REPO=1
fi

# Dokument architektury w StateStore (tabela document, kind architektury).
ARCH_DOC_DB=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  ARCH_DOC_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM document
    WHERE kind IN ('ARCHITECTURE','ARCH','architecture') OR path LIKE '%ARCHITECTURE%';" 2>/dev/null || echo 0)
fi

# 2. NO-ADR — rejestr decyzji architektonicznych (tabela decision).
ADR_COUNT=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  ADR_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM decision
    WHERE domain IN ('architecture','ADR','adr') OR title LIKE '%ADR%' OR source_type = 'adr';" 2>/dev/null || echo 0)
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$ARCH_DOC_REPO" -eq 1 ] || [ "$ARCH_DOC_DB" -gt 0 ]; then
  p_pass "ARCHITECTURE-DOC" BLOCKING "Dokument architektury obecny (repo=$ARCH_DOC_REPO, state=$ARCH_DOC_DB)"
else
  p_fail "ARCHITECTURE-DOC" BLOCKING "Brak dokumentu architektury (ARCHITECTURE.md / tabela document)"
fi

if [ "$ADR_COUNT" -gt 0 ]; then
  p_pass "ARCHITECTURE-ADR" BLOCKING "Znaleziono $ADR_COUNT decyzji architektonicznych (ADR)"
else
  p_warn "ARCHITECTURE-ADR" "Brak rejestru ADR w StateStore (tabela decision) — brak decyzji architektonicznych"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-008:architecture ARCH_DOC_REPO=$ARCH_DOC_REPO ARCH_DOC_DB=$ARCH_DOC_DB ADR=$ADR_COUNT" "pipeline" "design/architecture.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$ARCH_DOC_REPO" -eq 0 ] && [ "$ARCH_DOC_DB" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-008" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-008" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
