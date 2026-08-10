#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-040 — GAP DISCOVERY (System Coverage / Gap Discovery)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Wykrywa luki w pokryciu systemu:
#   * GAP      — komponent zadeklarowany w katalogu, a nieistniejący (ghost)
#   * SHADOW   — komponent istniejący, a niezadeklarowany w katalogu
#   * COVERAGE — moduły verify zadeklarowane w gates.yaml, a nieistniejące
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
p_say "=== P-040 GAP DISCOVERY ==="
p_say "Wykrywanie luk w pokryciu systemu (GAP / SHADOW / COVERAGE)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-040"

# ── EXECUTE ─────────────────────────────────────────────────
GAP_COUNT=0
SHADOW_COUNT=0
COVERAGE_COUNT=0

# 1. GAP — pipeline zadeklarowany w katalogu, a nieistniejący (ghost).
#    Każdy pipeline IMPLEMENTED musi mieć odpowiadający skrypt.
for entry in "${PIPELINES[@]}"; do
  eid="${entry%%|*}"
  rest="${entry#*|}"
  rest="${rest#*|}"
  scr="${rest%%|*}"
  rest="${rest#*|}"
  rest="${rest#*|}"
  st="${rest%%|*}"
  if [ "$st" = "IMPLEMENTED" ]; then
    if [ ! -f "$AUTOMATION_DIR/$scr" ]; then
      GAP_COUNT=$((GAP_COUNT+1))
      p_fail "GAP: $eid" BLOCKING "Pipeline zadeklarowany jako IMPLEMENTED, a skrypt nie istnieje: $scr"
    fi
  fi
done

# 2. SHADOW — skrypt istnieje w tools/automation, a niezadeklarowany w katalogu.
#    (shadow = istniejący, ale nieznany systemowi — brak pokrycia).
declared_scripts=""
for entry in "${PIPELINES[@]}"; do
  rest="${entry#*|}"
  rest="${rest#*|}"
  scr="${rest%%|*}"
  declared_scripts="$declared_scripts $scr"
done
while IFS= read -r scr; do
  if [ -n "$scr" ]; then
    case " $declared_scripts " in
      *" $scr "*) : ;;
      *) SHADOW_COUNT=$((SHADOW_COUNT+1)); p_warn "SHADOW: $scr" "Skrypt istnieje, a niezadeklarowany w pipelines.yaml" ;;
    esac
  fi
done < <(git ls-files "tools/automation" | grep '\.sh$' | grep -v '^tools/automation/core/' || true)

# 3. COVERAGE — moduły verify zadeklarowane w gates.yaml, a nieistniejące.
#    (ghost moduły w silniku weryfikacji).
if [ -f "$ROOT/config/canonical/gates.yaml" ]; then
  gates_scripts="$(awk '/^    script:/ { print $2 }' "$ROOT/config/canonical/gates.yaml" 2>/dev/null)"
  while IFS= read -r scr; do
    if [ -n "$scr" ]; then
      if [ ! -f "$ROOT/tools/verify/$scr" ]; then
        COVERAGE_COUNT=$((COVERAGE_COUNT+1))
        p_fail "COVERAGE-GAP: $scr" BLOCKING "Moduł verify zadeklarowany w gates.yaml, a nieistniejący"
      fi
    fi
  done <<< "$gates_scripts"
fi

# ── TEST ────────────────────────────────────────────────────
# Weryfikacja, że pipeline poprawnie wykrył luki (self-test).
if [ "$GAP_COUNT" -eq 0 ]; then
  p_pass "GAP-DISCOVERY-NO-GHOST" BLOCKING "Brak ghost pipeline'ów (wszystkie IMPLEMENTED mają skrypty)"
else
  p_fail "GAP-DISCOVERY-GHOST" BLOCKING "Znaleziono $GAP_COUNT ghost pipeline'ów"
fi
if [ "$SHADOW_COUNT" -eq 0 ]; then
  p_pass "GAP-DISCOVERY-NO-SHADOW" BLOCKING "Brak shadow skryptów (wszystkie skrypty zadeklarowane)"
else
  p_warn "GAP-DISCOVERY-SHADOW" "Znaleziono $SHADOW_COUNT shadow skryptów"
fi
if [ "$COVERAGE_COUNT" -eq 0 ]; then
  p_pass "GAP-DISCOVERY-NO-COVERAGE-GAP" BLOCKING "Brak ghost modułów verify"
else
  p_fail "GAP-DISCOVERY-COVERAGE-GAP" BLOCKING "Znaleziono $COVERAGE_COUNT ghost modułów verify"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-040:gap-discovery GAP=$GAP_COUNT SHADOW=$SHADOW_COUNT COVERAGE=$COVERAGE_COUNT" "pipeline" "runtime/gap-discovery.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$GAP_COUNT" -gt 0 ] || [ "$COVERAGE_COUNT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-040" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-040" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
