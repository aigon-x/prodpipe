#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-032 — REPRODUCIBILITY (Reproducible build evidence)
# Rodzina: BUILD | Klasa: RELEASE | Status: IMPLEMENTED
#
# Weryfikuje dowód reprodukowalności budowy. Sprawdza plik
# build hash (build.hash / reproducibility) w repo oraz tabelę
# baseline (StateStore) z state_hash. Wykrywa brak dowodu
# reprodukowalności.
#
# Wykrywa:
#   * NO-REPRO-HASH     — brak pliku z hashem budowy w repo
#   * NO-REPRO-BASELINE — brak baseline z state_hash w StateStore
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
p_say "=== P-032 REPRODUCIBILITY ==="
p_say "Weryfikacja dowodu reprodukowalności budowy"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-032"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
HAS_REPRO_HASH=0
BASELINE_HASHED=0
BASELINE_TOTAL=0
DB_AVAILABLE=0

# 1. Plik z hashem budowy w repo (git-tracked)
if git ls-files | grep -qiE '(^|/)(build\.hash|build\.sha256|reproducibility\.(txt|json|sha256)|\.reproducible)$'; then
  HAS_REPRO_HASH=1
fi

# 2. Baseline z state_hash w StateStore
if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  BASELINE_TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM baseline;" 2>/dev/null || echo 0)
  BASELINE_HASHED=$(sqlite3 "$db" "SELECT COUNT(*) FROM baseline WHERE state_hash IS NOT NULL AND state_hash != '';" 2>/dev/null || echo 0)
else
  p_info "REPRO-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$HAS_REPRO_HASH" -eq 1 ]; then
  p_pass "REPRO-HASH-PRESENT" BLOCKING "Znaleziono plik z hashem budowy w repo"
else
  p_fail "REPRO-NO-HASH" BLOCKING "Brak pliku z hashem budowy w repo (build.hash / reproducibility)"
fi
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$BASELINE_TOTAL" -eq 0 ]; then
    p_warn "REPRO-NO-BASELINE" "Brak baseline w StateStore — brak dowodu reprodukowalności w StateStore"
  elif [ "$BASELINE_HASHED" -eq "$BASELINE_TOTAL" ]; then
    p_pass "REPRO-BASELINE-HASHED" BLOCKING "Wszystkie baseline ($BASELINE_TOTAL) mają state_hash"
  else
    p_fail "REPRO-BASELINE-UNHASHED" BLOCKING "Znaleziono $((BASELINE_TOTAL - BASELINE_HASHED)) baseline bez state_hash"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-032:reproducibility HASH=$HAS_REPRO_HASH BASELINE=$BASELINE_TOTAL HASHED=$BASELINE_HASHED" "pipeline" "build/reproducibility.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$HAS_REPRO_HASH" -eq 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-032" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-032" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "RELEASE" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
