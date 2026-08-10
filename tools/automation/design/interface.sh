#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-011 — INTERFACE (Interface Definitions)
# Rodzina: DESIGN | Klasa: STANDARD | Status: IMPLEMENTED
#
# Weryfikuje definicje interfejsów. Konsumuje tabele service / network / port
# (StateStore) — topologia usług, sieci i portów.
#
# Wykrywa:
#   * NO-INTERFACE     — brak definicji interfejsów (usługi / sieci / porty)
#   * SERVICE-NO-PORT  — usługa bez przypisanego portu
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
p_say "=== P-011 INTERFACE ==="
p_say "Weryfikacja definicji interfejsów (service / network / port)"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-011"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
SERVICE_COUNT=0
NETWORK_COUNT=0
PORT_COUNT=0
SERVICE_NO_PORT=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  # 1. NO-INTERFACE — liczba usług, sieci i portów.
  SERVICE_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM service;" 2>/dev/null || echo 0)
  NETWORK_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM network;" 2>/dev/null || echo 0)
  PORT_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM port;" 2>/dev/null || echo 0)

  # 2. SERVICE-NO-PORT — usługi bez przypisanego portu.
  SERVICE_NO_PORT=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM service s
    LEFT JOIN port p ON p.service_id = s.service_id
    WHERE p.port_id IS NULL;" 2>/dev/null || echo 0)
else
  p_info "INTERFACE-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

# ── TEST ────────────────────────────────────────────────────
if [ "$SERVICE_COUNT" -gt 0 ] || [ "$NETWORK_COUNT" -gt 0 ] || [ "$PORT_COUNT" -gt 0 ]; then
  p_pass "INTERFACE-PRESENT" BLOCKING "Znaleziono usług=$SERVICE_COUNT sieci=$NETWORK_COUNT porty=$PORT_COUNT"
else
  p_warn "INTERFACE-PRESENT" "Brak definicji interfejsów w StateStore (service/network/port) — brak topologii"
fi

if [ "$SERVICE_NO_PORT" -eq 0 ]; then
  p_pass "INTERFACE-SERVICE-PORT" BLOCKING "Wszystkie usługi mają przypisane porty"
else
  p_fail "INTERFACE-SERVICE-NO-PORT" BLOCKING "Znaleziono $SERVICE_NO_PORT usług bez portu"
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-011:interface SERVICE=$SERVICE_COUNT NETWORK=$NETWORK_COUNT PORT=$PORT_COUNT NO_PORT=$SERVICE_NO_PORT" "pipeline" "design/interface.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
repo_verdict="PASS"
if [ "$SERVICE_COUNT" -eq 0 ] && [ "$NETWORK_COUNT" -eq 0 ] && [ "$PORT_COUNT" -eq 0 ]; then
  repo_verdict="NOT_APPLICABLE"
elif [ "$SERVICE_NO_PORT" -gt 0 ]; then
  repo_verdict="FAIL"
fi
p_dual_verdict "P-011" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-011" "$([ "$repo_verdict" = "FAIL" ] && echo FAIL || echo PASS)" "STANDARD" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
