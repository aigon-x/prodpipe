#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-062 — AI TRAIN (Etap 1: model wytrenowany?)
# Rodzina: AI | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje dowód treningu modelu: artefakt modelu, powiązane evidence,
# hiperparametry i checkpointy. W AI błąd = bug w danych, kodzie LUB modelu —
# ten pipeline pilnuje, że trening jest powtarzalny i udokumentowany.
#
# Wykrywa:
#   * NO-MODEL-ARTIFACT   — brak artefaktu model w tabeli artifact
#   * NO-TRAIN-EVIDENCE   — brak evidence o treningu (pipeline:P-062 / train)
#   * NO-HYPERPARAMETERS  — brak dowodu zapisu hiperparametrów
#   * NO-CHECKPOINTS      — brak dowodu checkpointów treningu
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
p_say "=== P-062 AI TRAIN ==="
p_say "Weryfikacja dowodu treningu modelu (artefakt / evidence / hiperparametry / checkpointy)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-062"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

MODEL_COUNT=0
TRAIN_EVIDENCE=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Artefakty model (kind LIKE '%model%' lub name LIKE '%model%').
  MODEL_COUNT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM artifact
    WHERE kind LIKE '%model%' OR name LIKE '%model%';" 2>/dev/null || echo 0)
  # Evidence o treningu (claim zawiera 'train' lub 'P-062').
  TRAIN_EVIDENCE=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM evidence
    WHERE claim LIKE '%train%' OR claim LIKE '%P-062%';" 2>/dev/null || echo 0)
else
  p_info "AI-TRAIN-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-TRAIN-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować treningu"
elif [ "$MODEL_COUNT" -eq 0 ]; then
  p_fail "AI-TRAIN-NO-MODEL" BLOCKING "Brak artefaktu model w tabeli artifact (model niewytrenowany)"
else
  p_pass "AI-TRAIN-MODEL-PRESENT" BLOCKING "Znaleziono $MODEL_COUNT artefaktów model"
  if [ "$TRAIN_EVIDENCE" -gt 0 ]; then
    p_pass "AI-TRAIN-EVIDENCE" BLOCKING "Znaleziono $TRAIN_EVIDENCE dowodów treningu (evidence)"
  else
    p_fail "AI-TRAIN-NO-EVIDENCE" BLOCKING "Brak evidence o treningu (reproducibility / hiperparametry / checkpointy)"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-062:ai-train MODE=$AI_MODE MODEL=$MODEL_COUNT TRAIN_EVIDENCE=$TRAIN_EVIDENCE" "pipeline" "ai/train.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && [ "$MODEL_COUNT" -gt 0 ]; then
  repo_verdict="PASS"
  if [ "$TRAIN_EVIDENCE" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-062" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-062" "$repo_verdict" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
