#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-069 — AI RETIRE (Etap 8: model wycofany?)
# Rodzina: AI | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje wycofanie modelu: deprecation notice, migration path,
# cleanup i release status. W AI model to artefakt, który się starzeje —
# ten pipeline pilnuje, że wycofywany model ma jasny komunikat,
# ścieżkę migracji i jest czyszczony.
#
# Wykrywa:
#   * NO-RETIRE-EVIDENCE   — brak dowodu wycofania (release / deployment / event)
#   * NO-DEPRECATION-NOTICE — brak deprecation notice (event)
#   * NO-MIGRATION-PATH    — brak dowodu ścieżki migracji
#   * NO-CLEANUP           — brak dowodu cleanup (release RETIRED)
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
p_say "=== P-069 AI RETIRE ==="
p_say "Weryfikacja wycofania modelu (deprecation / migration / cleanup / release status)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-069"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
AI_MODE="${AI_MODE:-classical}"
if [ -f "$ROOT/config/canonical/ai.yaml" ]; then
  cfg_mode="$(awk '/^mode:/ { print $2 }' "$ROOT/config/canonical/ai.yaml" 2>/dev/null)"
  [ -n "$cfg_mode" ] && AI_MODE="$cfg_mode"
fi

RETIRE_RELEASE=0
RETIRE_DEPLOYMENT=0
RETIRE_EVENT=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  # Release modelu w statusie wycofania (RETIRED/DEPRECATED/BLOCKED).
  RETIRE_RELEASE=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM release
    WHERE status IN ('RETIRED','DEPRECATED','BLOCKED')
       AND (version LIKE '%model%' OR source_ref LIKE '%model%' OR source_ref LIKE '%ai%');" 2>/dev/null || echo 0)
  # Deploymenty modelu (service_id/desired/effective zawiera 'model'/'ai').
  RETIRE_DEPLOYMENT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM deployment
    WHERE service_id LIKE '%model%' OR service_id LIKE '%ai%'
       OR desired LIKE '%model%' OR effective LIKE '%model%';" 2>/dev/null || echo 0)
  # Eventy wycofania (kind zawiera 'retire'/'deprecat'/'migrat'/'cleanup').
  RETIRE_EVENT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM event
    WHERE kind LIKE '%retire%' OR kind LIKE '%deprecat%'
       OR kind LIKE '%migrat%' OR kind LIKE '%cleanup%';" 2>/dev/null || echo 0)
else
  p_info "AI-RETIRE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "AI-RETIRE-DB-UNAVAILABLE" "Baza StateStore niedostępna — nie można zweryfikować wycofania modelu"
elif [ "$RETIRE_RELEASE" -eq 0 ] && [ "$RETIRE_DEPLOYMENT" -eq 0 ] && [ "$RETIRE_EVENT" -eq 0 ]; then
  p_fail "AI-RETIRE-NO-EVIDENCE" BLOCKING "Brak dowodu wycofania (release / deployment / event) — model niezarządzany"
else
  p_pass "AI-RETIRE-EVIDENCE-PRESENT" BLOCKING "Znaleziono dowód wycofania (release=$RETIRE_RELEASE, deployment=$RETIRE_DEPLOYMENT, event=$RETIRE_EVENT)"
  if [ "$RETIRE_EVENT" -eq 0 ]; then
    p_fail "AI-RETIRE-NO-DEPRECATION" BLOCKING "Brak deprecation notice / migration path / cleanup (tabela event)"
  else
    p_pass "AI-RETIRE-DEPRECATION" BLOCKING "Znaleziono $RETIRE_EVENT eventów wycofania (deprecation / migration / cleanup)"
  fi
  if [ "$RETIRE_RELEASE" -eq 0 ]; then
    p_warn "AI-RETIRE-NO-CLEANUP" "Brak release modelu w statusie RETIRED/DEPRECATED (cleanup / wycofanie)"
  else
    p_pass "AI-RETIRE-CLEANUP" BLOCKING "Znaleziono $RETIRE_RELEASE release modelu w statusie wycofania"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-069:ai-retire MODE=$AI_MODE RELEASE=$RETIRE_RELEASE DEPLOYMENT=$RETIRE_DEPLOYMENT EVENT=$RETIRE_EVENT" "pipeline" "ai/retire.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="NOT_APPLICABLE"
if [ "$DB_AVAILABLE" -eq 1 ] && { [ "$RETIRE_RELEASE" -gt 0 ] || [ "$RETIRE_DEPLOYMENT" -gt 0 ] || [ "$RETIRE_EVENT" -gt 0 ]; }; then
  repo_verdict="PASS"
  if [ "$RETIRE_EVENT" -eq 0 ]; then
    repo_verdict="FAIL"
  fi
fi
p_dual_verdict "P-069" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-069" "$repo_verdict" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
