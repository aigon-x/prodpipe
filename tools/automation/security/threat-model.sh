#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-015 — THREAT MODEL (Security Threat Model)
# Rodzina: SECURITY | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje istnienie i aktualność modelu zagrożeń (threat model).
# Konsumuje StateStore (policy/document) oraz artefakty repo
# (SECURITY.md, THREAT-MODEL.md, security/threat-model/).
#
# Wykrywa:
#   * NO-THREAT-MODEL      — brak jakiegokolwiek threat modelu w repo/StateStore
#   * THREAT-MODEL-STALE   — threat model istnieje, ale brak rekordu w StateStore
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
p_say "=== P-015 THREAT MODEL ==="
p_say "Weryfikacja istnienia i aktualności modelu zagrożeń"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-015"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"

# 1. Artefakty threat modelu w repo (git-tracked).
TM_REPO=0
for f in THREAT-MODEL.md SECURITY.md security/threat-model/README.md; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    TM_REPO=1
  fi
done
# Dowolny plik w security/threat-model/ (poza .gitkeep).
if git ls-files 'security/threat-model/*' 2>/dev/null | grep -v '\.gitkeep$' | grep -q .; then
  TM_REPO=1
fi

# 2. Rekord threat modelu w StateStore (policy/document).
TM_DB=0
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  TM_DB=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM (
      SELECT policy_id FROM policy WHERE lower(name) LIKE '%threat%' OR lower(domain) LIKE '%threat%'
      UNION
      SELECT document_id FROM document WHERE lower(path) LIKE '%threat%' OR lower(kind) LIKE '%threat%'
    );" 2>/dev/null || echo 0)
else
  p_info "THREAT-MODEL-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$TM_REPO" -eq 1 ] || [ "$TM_DB" -gt 0 ]; then
  p_pass "THREAT-MODEL-PRESENT" BLOCKING "Threat model obecny (repo=$TM_REPO, state=$TM_DB)"
else
  p_fail "THREAT-MODEL-MISSING" BLOCKING "Brak threat modelu w repo i StateStore"
fi
if [ "$TM_DB" -gt 0 ]; then
  p_pass "THREAT-MODEL-REGISTERED" BLOCKING "Threat model zarejestrowany w StateStore ($TM_DB rekordów)"
else
  p_warn "THREAT-MODEL-STALE" "Threat model nie ma rekordu w StateStore (brak aktualizacji)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-015:threat-model TM_REPO=$TM_REPO TM_DB=$TM_DB" "pipeline" "security/threat-model.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$TM_REPO" -eq 1 ] || [ "$TM_DB" -gt 0 ]; then
  repo_verdict="PASS"
else
  repo_verdict="FAIL"
fi
p_dual_verdict "P-015" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-015" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
