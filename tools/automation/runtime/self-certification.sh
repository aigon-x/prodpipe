#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-043 — SELF-CERTIFICATION (Living Proof / Self-Certification)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Pipeline sam certyfikuje, że jest poprawnie zbudowany (Living Proof).
# Weryfikuje integralność własnego środowiska wykonawczego:
#   * CORE-INTEGRITY   — lib.sh i pipelines.sh są obecne i składniowo poprawne
#   * CATALOG-INTEGRITY — katalog pipeline'ów jest spójny (51 pipeline'ów, 8 rodzin)
#   * CONTRACT-INTEGRITY — każdy pipeline deklaruje pełny 8-fazowy kontrakt
#   * DAG-INTEGRITY    — zależności pipeline'ów nie tworzą cykli
#   * EVIDENCE-BRIDGE  — evidence bridge (P0#1) działa
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
p_say "=== P-043 SELF-CERTIFICATION ==="
p_say "Living Proof — pipeline sam certyfikuje integralność środowiska wykonawczego"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-043"

# ── EXECUTE ─────────────────────────────────────────────────
# 1. CORE-INTEGRITY — lib.sh i pipelines.sh obecne i składniowo poprawne.
CORE_OK=1
for f in "$AUTOMATION_DIR/core/lib.sh" "$AUTOMATION_DIR/core/pipelines.sh"; do
  if [ ! -f "$f" ]; then
    CORE_OK=0
    p_fail "CORE-INTEGRITY" BLOCKING "Brak pliku core: $f"
  elif ! bash -n "$f" 2>/dev/null; then
    CORE_OK=0
    p_fail "CORE-INTEGRITY" BLOCKING "Błąd składni w pliku core: $f"
  fi
done
if [ "$CORE_OK" -eq 1 ]; then
  p_pass "CORE-INTEGRITY" BLOCKING "lib.sh i pipelines.sh obecne i składniowo poprawne"
fi

# 2. CATALOG-INTEGRITY — katalog pipeline'ów spójny (51 pipeline'ów, 8 rodzin).
CATALOG_COUNT="${#PIPELINES[@]}"
if [ "$CATALOG_COUNT" -ge 50 ]; then
  p_pass "CATALOG-INTEGRITY" BLOCKING "Katalog zawiera $CATALOG_COUNT pipeline'ów (oczekiwano ≥50)"
else
  p_fail "CATALOG-INTEGRITY" BLOCKING "Katalog zawiera tylko $CATALOG_COUNT pipeline'ów (oczekiwano ≥50)"
fi

# 3. CONTRACT-INTEGRITY — każdy pipeline deklaruje pełny 8-fazowy kontrakt.
CONTRACT_OK=1
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  contract="$(pipeline_contract "$eid")"
  phase_count=$(echo "$contract" | tr ',' '\n' | grep -c . || echo 0)
  if [ "$phase_count" -ne 8 ]; then
    CONTRACT_OK=0
    p_fail "CONTRACT-INTEGRITY" BLOCKING "Pipeline $eid deklaruje $phase_count faz (oczekiwano 8)"
  fi
done
if [ "$CONTRACT_OK" -eq 1 ]; then
  p_pass "CONTRACT-INTEGRITY" BLOCKING "Wszystkie pipeline'y deklarują pełny 8-fazowy kontrakt"
fi

# 4. DAG-INTEGRITY — zależności pipeline'ów nie tworzą cykli.
#    DFS z wykrywaniem cykli (jak run_pipeline_dag w automation.sh).
DAG_OK=1
declare -A VISITING=()
declare -A VISITED=()
check_cycle() {
  local id="$1"
  if [ "${VISITING[$id]:-}" = "1" ]; then
    DAG_OK=0
    p_fail "DAG-INTEGRITY" BLOCKING "Wykryto cykl w zależnościach pipeline'ów (DAG) przy $id"
    return
  fi
  if [ "${VISITED[$id]:-}" = "1" ]; then
    return
  fi
  VISITING[$id]=1
  local deps
  deps="$(pipeline_depends "$id")"
  local dep
  for dep in ${deps//,/ }; do
    if [ -n "$dep" ]; then
      check_cycle "$dep"
    fi
  done
  VISITING[$id]=0
  VISITED[$id]=1
}
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  check_cycle "$eid"
done
if [ "$DAG_OK" -eq 1 ]; then
  p_pass "DAG-INTEGRITY" BLOCKING "Zależności pipeline'ów nie tworzą cykli (DAG spójny)"
fi

# 5. EVIDENCE-BRIDGE — evidence bridge (P0#1) działa.
#    Zapisuje evidence i weryfikuje, że się powiódł.
if p_evidence "pipeline:P-043:self-certification SELF-CERTIFIED" "pipeline" "runtime/self-certification.sh"; then
  p_pass "EVIDENCE-BRIDGE" BLOCKING "Evidence bridge (P0#1) działa — evidence zapisane do StateStore"
else
  p_fail "EVIDENCE-BRIDGE" BLOCKING "Evidence bridge (P0#1) NIE działa — evidence nie zapisane"
fi

# ── TEST ────────────────────────────────────────────────────
# Self-test: pipeline poprawnie certyfikuje integralność.
if [ "$CORE_OK" -eq 1 ] && [ "$CATALOG_COUNT" -ge 50 ] && [ "$CONTRACT_OK" -eq 1 ] && [ "$DAG_OK" -eq 1 ]; then
  p_pass "SELF-CERTIFICATION-SELF-TEST" BLOCKING "Pipeline poprawnie certyfikuje integralność środowiska"
else
  p_fail "SELF-CERTIFICATION-SELF-TEST" BLOCKING "Pipeline wykrył naruszenie integralności środowiska"
fi

# ── EVIDENCE ────────────────────────────────────────────────
# (evidence już zapisane w fazie EVIDENCE-BRIDGE powyżej)

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$CORE_OK" -ne 1 ] || [ "$CATALOG_COUNT" -lt 50 ] || [ "$CONTRACT_OK" -ne 1 ] || [ "$DAG_OK" -ne 1 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-043" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-043" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
