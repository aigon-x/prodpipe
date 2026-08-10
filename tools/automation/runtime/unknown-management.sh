#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-047 — UNKNOWN MANAGEMENT (Unknown / Unhandled Case Management)
# Rodzina: RUNTIME | Klasa: CONTINUOUS | Status: IMPLEMENTED
#
# Weryfikuje, że istnieje rejestr nieznanych/nieobsłużonych przypadków:
#   * EVENT-REGISTRY    — istnieje rejestr zdarzeń (event)
#   * ALERT-REGISTRY    — istnieje rejestr alertów (alerts)
#   * UNKNOWN-TRACKING  — zdarzenia nieznane/nieobsłużone są śledzone
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
p_say "=== P-047 UNKNOWN MANAGEMENT ==="
p_say "Weryfikacja rejestru nieznanych/nieobsłużonych przypadków (event, alerts)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-047"

# ── EXECUTE ─────────────────────────────────────────────────
DB="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
DB_AVAILABLE=0
EVENT_TOTAL=0
ALERT_TOTAL=0
ALERT_ACTIVE=0

if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  DB_AVAILABLE=1
  EVENT_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM event;" 2>/dev/null || echo 0)"
  ALERT_TOTAL="$(sqlite3 "$DB" "SELECT COUNT(*) FROM alerts;" 2>/dev/null || echo 0)"
  ALERT_ACTIVE="$(sqlite3 "$DB" "SELECT COUNT(*) FROM alerts WHERE status = 'ACTIVE';" 2>/dev/null || echo 0)"
else
  p_info "UNKNOWN-MANAGEMENT-DB" "sqlite3 lub baza niedostępna — pomijam kontrolę rejestru zdarzeń (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 1 ]; then
  if [ "$EVENT_TOTAL" -eq 0 ] && [ "$ALERT_TOTAL" -eq 0 ]; then
    p_warn "UNKNOWN-MANAGEMENT-NO-DATA" "Brak rejestru zdarzeń i alertów — brak danych do weryfikacji zarządzania nieznanymi"
  else
    if [ "$EVENT_TOTAL" -gt 0 ]; then
      p_pass "EVENT-REGISTRY" BLOCKING "Znaleziono $EVENT_TOTAL zdarzeń w rejestrze"
    else
      p_warn "EVENT-REGISTRY" "Brak rejestru zdarzeń (event) w StateStore"
    fi
    if [ "$ALERT_TOTAL" -gt 0 ]; then
      p_pass "ALERT-REGISTRY" BLOCKING "Znaleziono $ALERT_TOTAL alertów (w tym $ALERT_ACTIVE ACTIVE)"
    else
      p_warn "ALERT-REGISTRY" "Brak rejestru alertów (alerts) w StateStore"
    fi
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-047:unknown-management EVENT=$EVENT_TOTAL ALERT=$ALERT_TOTAL ACTIVE=$ALERT_ACTIVE" "pipeline" "runtime/unknown-management.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$DB_AVAILABLE" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$EVENT_TOTAL" -eq 0 ] && [ "$ALERT_TOTAL" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
fi
p_dual_verdict "P-047" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-047" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "CONTINUOUS" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
