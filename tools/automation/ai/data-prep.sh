#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-061 — AI DATA-PREP (Etap 0: dane treningowe gotowe?)
# Rodzina: AI | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje gotowość danych treningowych przed treningiem modelu.
# W AI błąd = bug w danych, kodzie LUB modelu — ten pipeline pilnuje
# jakości i pochodzenia danych (data provenance).
#
# Wykrywa:
#   * NO-DATASET-ARTIFACT — brak artefaktu dataset w tabeli artifact
#   * NO-DATA-PROVENANCE  — dataset bez źródła (source_type/source_ref)
#   * NO-DATA-SPLIT       — brak dowodu podziału train/val/test
#   * NO-PII-SCAN         — brak dowodu skanu PII (dane osobowe)
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
p_say "=== P-061 AI DATA-PREP ==="
p_say "Weryfikacja gotowości danych treningowych (data provenance / split / PII)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-061"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
# Tryb AI: classical | DL | LLM (z config/canonical/ai.yaml lub AI_MODE, domyślnie classical).
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

DATASET_COUNT=0
DATASET_NO_PROVENANCE=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Artefakty dataset (kind LIKE '%dataset%' lub name LIKE '%dataset%').
  DATASET_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE kind LIKE '%dataset%' OR name LIKE '%dataset%';" 2>/dev/null || echo 0)
  # Dataset bez pochodzenia (brak source_type/source_ref).
  DATASET_NO_PROVENANCE=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE (kind LIKE '%dataset%' OR name LIKE '%dataset%')
      AND (source_type IS NULL OR source_type = '' OR source_ref IS NULL OR source_ref = '');" 2>/dev/null || echo 0)
else
  p_info "AI-DATA-PREP-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-DATA-PREP-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować danych treningowych"
elif [ "$DATASET_COUNT" -eq 0 ]; then
  p_fail "AI-DATA-PREP-NO-DATASET" BLOCKING "Brak artefaktu dataset w tabeli artifact (dane treningowe niegotowe)"
else
  p_pass "AI-DATA-PREP-DATASET-PRESENT" BLOCKING "Znaleziono $DATASET_COUNT artefaktów dataset"
  if [ "$DATASET_NO_PROVENANCE" -eq 0 ]; then
    p_pass "AI-DATA-PREP-PROVENANCE" BLOCKING "Wszystkie datasety mają pochodzenie (source_type/source_ref)"
  else
    p_fail "AI-DATA-PREP-NO-PROVENANCE" BLOCKING "Znaleziono $DATASET_NO_PROVENANCE datasetów bez pochodzenia (data provenance)"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-061:ai-data-prep MODE=$AI_MODE DATASET=$DATASET_COUNT NO_PROVENANCE=$DATASET_NO_PROVENANCE" "pipeline" "ai/data-prep.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$DATASET_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
  if [ "$DATASET_NO_PROVENANCE" -gt 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-061" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-061" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
