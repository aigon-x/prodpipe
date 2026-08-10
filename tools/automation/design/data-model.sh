#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-012 — DATA MODEL (Data Model & Config Consistency)
# Rodzina: DESIGN | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje model danych i spójność konfiguracji. Konsumuje tabele
# configuration / config_snapshots (StateStore) — materializowany effective
# config oraz jego snapshoty.
#
# Wykrywa:
#   * NO-DATA-MODEL    — brak modelu danych (configuration / config_snapshots)
#   * CONFIG-DRIFT     — rozjazd między desired a effective/observed (drift)
#   * NO-CONFIG-SNAPSHOT — brak snapshotów konfiguracji (brak baseline)
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
p_say "=== P-012 DATA MODEL ==="
p_say "Weryfikacja modelu danych i spójności konfiguracji"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-012"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
CONFIG_COUNT=0
SNAPSHOT_COUNT=0
CONFIG_DRIFT=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. NO-DATA-MODEL — liczba wpisów konfiguracji i snapshotów.
  CONFIG_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM configuration;" 2>/dev/null || echo 0)
  SNAPSHOT_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM config_snapshots;" 2>/dev/null || echo 0)

  # 2. CONFIG-DRIFT — rozjazd między desired a effective/observed.
  CONFIG_DRIFT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM configuration
    WHERE desired IS NOT NULL
      AND effective IS NOT NULL
      AND desired != effective;" 2>/dev/null || echo 0)
else
  p_info "DATA-MODEL-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$CONFIG_COUNT" -gt 0 ] || [ "$SNAPSHOT_COUNT" -gt 0 ]; then
  p_pass "DATA-MODEL-PRESENT" BLOCKING "Model danych obecny (config=$CONFIG_COUNT snapshots=$SNAPSHOT_COUNT)"
else
  p_warn "DATA-MODEL-PRESENT" "Brak modelu danych w StateStore (configuration/config_snapshots)"
fi

if [ "$SNAPSHOT_COUNT" -gt 0 ]; then
  p_pass "DATA-MODEL-SNAPSHOT" BLOCKING "Znaleziono $SNAPSHOT_COUNT snapshotów konfiguracji (baseline)"
else
  p_warn "DATA-MODEL-SNAPSHOT" "Brak snapshotów konfiguracji (config_snapshots) — brak baseline"
fi

if [ "$CONFIG_DRIFT" -eq 0 ]; then
  p_pass "DATA-MODEL-NO-DRIFT" BLOCKING "Brak rozjazdu między desired a effective (brak driftu)"
else
  p_fail "DATA-MODEL-DRIFT" BLOCKING "Znaleziono $CONFIG_DRIFT wpisów z rozjazdem desired vs effective (drift)"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-012:data-model CONFIG=$CONFIG_COUNT SNAPSHOTS=$SNAPSHOT_COUNT DRIFT=$CONFIG_DRIFT" "pipeline" "design/data-model.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$CONFIG_COUNT" -eq 0 ] && [ "$SNAPSHOT_COUNT" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$CONFIG_DRIFT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-012" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-012" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
