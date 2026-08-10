#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-048 — SOURCE OF TRUTH (Single Source of Truth)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że istnieje pojedyncze źródło prawdy (Single Source of Truth):
#   * SOT-DECLARATION   — istnieje deklaracja SoT (SOURCE-OF-TRUTH.md)
#   * SOT-CANONICAL     — istnieje katalog config/canonical (kanoniczna konfiguracja)
#   * SOT-CONSISTENCY   — deklaracja SoT jest spójna z rzeczywistym stanem repo
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
p_say "=== P-048 SOURCE OF TRUTH ==="
p_say "Weryfikacja pojedynczego źródła prawdy (SOURCE-OF-TRUTH.md, config/canonical)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-048"

# ── EXECUTE ─────────────────────────────────────────────────
SOT_DECL=0
SOT_CANONICAL=0
SOT_CONSISTENT=1

# 1. SOT-DECLARATION — istnieje deklaracja źródła prawdy.
if [ -f "$ROOT/SOURCE-OF-TRUTH.md" ]; then
  SOT_DECL=1
fi

# 2. SOT-CANONICAL — istnieje katalog kanonicznej konfiguracji z plikami.
if [ -d "$ROOT/config/canonical" ]; then
  CANONICAL_COUNT="$(git ls-files "config/canonical" 2>/dev/null | grep -c '\.ya*ml$' || echo 0)"
  if [ "${CANONICAL_COUNT:-0}" -gt 0 ]; then
    SOT_CANONICAL=1
  fi
fi

# 3. SOT-CONSISTENCY — deklaracja SoT nie jest sprzeczna z repo.
#    (jeśli SOURCE-OF-TRUTH.md istnieje, ale config/canonical jest pusty → rozjazd).
if [ "$SOT_DECL" -eq 1 ] && [ "$SOT_CANONICAL" -eq 0 ]; then
  SOT_CONSISTENT=0
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$SOT_DECL" -eq 1 ]; then
  p_pass "SOT-DECLARATION" BLOCKING "Istnieje deklaracja źródła prawdy (SOURCE-OF-TRUTH.md)"
else
  p_fail "SOT-DECLARATION" BLOCKING "Brak deklaracji źródła prawdy (SOURCE-OF-TRUTH.md)"
fi
if [ "$SOT_CANONICAL" -eq 1 ]; then
  p_pass "SOT-CANONICAL" BLOCKING "Istnieje katalog kanonicznej konfiguracji (config/canonical, $CANONICAL_COUNT plików YAML)"
else
  p_fail "SOT-CANONICAL" BLOCKING "Brak kanonicznej konfiguracji (config/canonical)"
fi
if [ "$SOT_CONSISTENT" -eq 1 ]; then
  p_pass "SOT-CONSISTENCY" BLOCKING "Deklaracja SoT jest spójna z rzeczywistym stanem repo"
else
  p_fail "SOT-CONSISTENCY" BLOCKING "Rozjazd: SOURCE-OF-TRUTH.md istnieje, a config/canonical jest pusty"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-048:source-of-truth DECL=$SOT_DECL CANONICAL=$SOT_CANONICAL CONSISTENT=$SOT_CONSISTENT" "pipeline" "runtime/source-of-truth.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$SOT_DECL" -ne 1 ] || [ "$SOT_CANONICAL" -ne 1 ] || [ "$SOT_CONSISTENT" -ne 1 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-048" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-048" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
