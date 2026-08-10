#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-065 — AI PACKAGE (Etap 4: model jako artefakt?)
# Rodzina: AI | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje model jako artefakt: wersjonowanie, digest, podpis i BOM.
# W AI model to artefakt — ten pipeline pilnuje, że model jest
# identyfikowalny (digest), wersjonowany i ma kompletny manifest.
#
# Wykrywa:
#   * NO-MODEL-ARTIFACT   — brak artefaktu model w tabeli artifact
#   * MODEL-NO-DIGEST     — model bez digest (niezidentyfikowany)
#   * NO-MODEL-CONTRACT   — brak kontraktu modelu (wersjonowanie/podpis/BOM)
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
p_say "=== P-065 AI PACKAGE ==="
p_say "Weryfikacja modelu jako artefaktu (wersjonowanie / digest / podpis / BOM)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-065"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

MODEL_COUNT=0
MODEL_NO_DIGEST=0
MODEL_CONTRACT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Artefakty model (kind LIKE '%model%' lub name LIKE '%model%').
  MODEL_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE kind LIKE '%model%' OR name LIKE '%model%';" 2>/dev/null || echo 0)
  # Model bez digest.
  MODEL_NO_DIGEST=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE (kind LIKE '%model%' OR name LIKE '%model%')
      AND (digest IS NULL OR digest = '');" 2>/dev/null || echo 0)
  # Kontrakty modelu (kind LIKE '%model%' lub name LIKE '%model%'/'%bom%'/'%sign%').
  MODEL_CONTRACT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM contract
    WHERE kind LIKE '%model%' OR name LIKE '%model%'
       OR name LIKE '%bom%' OR name LIKE '%sign%' OR name LIKE '%manifest%';" 2>/dev/null || echo 0)
else
  p_info "AI-PACKAGE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-PACKAGE-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować pakowania modelu"
elif [ "$MODEL_COUNT" -eq 0 ]; then
  p_fail "AI-PACKAGE-NO-MODEL" BLOCKING "Brak artefaktu model w tabeli artifact (model nieopakowany)"
else
  p_pass "AI-PACKAGE-MODEL-PRESENT" BLOCKING "Znaleziono $MODEL_COUNT artefaktów model"
  if [ "$MODEL_NO_DIGEST" -eq 0 ]; then
    p_pass "AI-PACKAGE-ALL-DIGESTED" BLOCKING "Wszystkie modele mają digest (identyfikowalne)"
  else
    p_fail "AI-PACKAGE-NO-DIGEST" BLOCKING "Znaleziono $MODEL_NO_DIGEST modeli bez digest"
  fi
  if [ "$MODEL_CONTRACT" -eq 0 ]; then
    p_fail "AI-PACKAGE-NO-CONTRACT" BLOCKING "Brak kontraktu modelu (wersjonowanie / podpis / BOM)"
  else
    p_pass "AI-PACKAGE-CONTRACT" BLOCKING "Znaleziono $MODEL_CONTRACT kontraktów modelu (wersjonowanie/podpis/BOM)"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-065:ai-package MODE=$AI_MODE MODEL=$MODEL_COUNT NO_DIGEST=$MODEL_NO_DIGEST CONTRACT=$MODEL_CONTRACT" "pipeline" "ai/package.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$MODEL_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
  if [ "$MODEL_NO_DIGEST" -gt 0 ] || [ "$MODEL_CONTRACT" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-065" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-065" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
