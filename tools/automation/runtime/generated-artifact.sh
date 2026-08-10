#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-049 — GENERATED ARTIFACT (Generated Artifact Freshness)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że generowane artefakty są aktualne względem źródła:
#   * ARTIFACT-FRESHNESS — pipelines.sh jest aktualny względem pipelines.yaml
#   * ARTIFACT-REGENERATION — ponowna generacja nie zmienia pipelines.sh (idempotentność)
#   * ARTIFACT-CONSISTENCY — pipelines.sh odzwierciedla statusy z pipelines.yaml
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
p_say "=== P-049 GENERATED ARTIFACT ==="
p_say "Weryfikacja aktualności generowanych artefaktów (pipelines.sh vs pipelines.yaml)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-049"

# ── EXECUTE ─────────────────────────────────────────────────
YAML="$ROOT/config/canonical/pipelines.yaml"
GEN="$AUTOMATION_DIR/core/gen-pipelines.sh"
SH="$AUTOMATION_DIR/core/pipelines.sh"
ARTIFACT_OK=1

# 1. ARTIFACT-FRESHNESS — pipelines.sh jest aktualny względem pipelines.yaml.
#    Test idempotentności: zapisujemy kopię pipelines.sh, uruchamiamy generator,
#    a następnie porównujemy. Jeśli generator zmienił pipelines.sh → był nieaktualny.
#    Po porównaniu przywracamy oryginał z kopii (pipeline nie modyfikuje pliku).
if [ ! -f "$YAML" ]; then
  ARTIFACT_OK=0
  p_fail "ARTIFACT-FRESHNESS" BLOCKING "Brak źródła prawdy: $YAML"
elif [ ! -f "$GEN" ]; then
  ARTIFACT_OK=0
  p_fail "ARTIFACT-FRESHNESS" BLOCKING "Brak generatora: $GEN"
elif [ ! -f "$SH" ]; then
  ARTIFACT_OK=0
  p_fail "ARTIFACT-FRESHNESS" BLOCKING "Brak generowanego artefaktu: $SH"
else
  TMP="$(mktemp)"
  cp "$SH" "$TMP"
  if bash "$GEN" >/dev/null 2>&1; then
    # Porównaj kopię (stan sprzed generacji) z nowo wygenerowanym pipelines.sh.
    if cmp -s "$TMP" "$SH"; then
      p_pass "ARTIFACT-FRESHNESS" BLOCKING "pipelines.sh jest aktualny względem pipelines.yaml (generacja idempotentna)"
    else
      ARTIFACT_OK=0
      p_fail "ARTIFACT-FRESHNESS" BLOCKING "pipelines.sh NIE jest aktualny względem pipelines.yaml — uruchom gen-pipelines.sh"
    fi
    # Przywróć oryginał — pipeline nie powinien modyfikować pliku.
    cp "$TMP" "$SH"
  else
    ARTIFACT_OK=0
    p_fail "ARTIFACT-FRESHNESS" BLOCKING "Generator gen-pipelines.sh zwrócił błąd"
  fi
  rm -f "$TMP"
fi

# 2. ARTIFACT-CONSISTENCY — pipelines.sh odzwierciedla statusy z pipelines.yaml.
#    (każdy pipeline IMPLEMENTED w YAML ma status IMPLEMENTED w pipelines.sh).
YAML_IMPL="$(awk '/^  - id:/ { id=$3 } /^    status:/ { if ($2 == "IMPLEMENTED") print id }' "$YAML" 2>/dev/null)"
CONSISTENT=1
for id in $YAML_IMPL; do
  st="$(pipeline_status "$id")"
  if [ "$st" != "IMPLEMENTED" ]; then
    CONSISTENT=0
    p_fail "ARTIFACT-CONSISTENCY: $id" BLOCKING "Pipeline $id jest IMPLEMENTED w YAML, a pipelines.sh zwraca status '$st'"
  fi
done
if [ "$CONSISTENT" -eq 1 ]; then
  p_pass "ARTIFACT-CONSISTENCY" BLOCKING "pipelines.sh odzwierciedla statusy IMPLEMENTED z pipelines.yaml"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$ARTIFACT_OK" -eq 1 ] && [ "$CONSISTENT" -eq 1 ]; then
  p_pass "GENERATED-ARTIFACT-SELF-TEST" BLOCKING "Generowane artefakty są aktualne i spójne"
else
  p_fail "GENERATED-ARTIFACT-SELF-TEST" BLOCKING "Wykryto nieaktualny lub niespójny generowany artefakt"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-049:generated-artifact FRESH=$ARTIFACT_OK CONSISTENT=$CONSISTENT" "pipeline" "runtime/generated-artifact.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$ARTIFACT_OK" -ne 1 ] || [ "$CONSISTENT" -ne 1 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-049" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-049" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
