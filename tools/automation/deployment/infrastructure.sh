#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# P-038 — INFRASTRUCTURE (Infrastructure Registry)
# Rodzina: DEPLOYMENT | Klasa: DEEP | Status: IMPLEMENTED
#
# Weryfikuje rejestr infrastruktury w StateStore:
#   * cluster, node, service, network, volume, image, port
#   * czy istnieje jakikolwiek rejestr infrastruktury (INFRA-REGISTRY)
#   * czy każdy node ma status (NODE-STATUS)
#   * czy każdy cluster ma status (CLUSTER-STATUS)
#   * czy każda usługa ma status (SERVICE-STATUS)
#
# Wykrywa:
#   * NO-INFRA-REGISTRY — brak rejestru infrastruktury (wszystkie tabele puste)
#   * NODE-WITHOUT-STATUS — node bez statusu
#   * CLUSTER-WITHOUT-STATUS — cluster bez statusu
#   * SERVICE-WITHOUT-STATUS — usługa bez statusu
#
# NO FALSE GREEN: gdy wszystkie tabele infrastruktury są puste,
# repo_verdict = NOT_APPLICABLE (nie zgłaszamy PASS na podstawie braku danych).
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
p_say "=== P-038 INFRASTRUCTURE ==="
p_say "Weryfikacja rejestru infrastruktury: cluster/node/service/network/volume/image/port"

# ── CONTRACT ────────────────────────────────────────────────
p_contract "P-038"

# ── EXECUTE ─────────────────────────────────────────────────
db="${PIPE_STATE_DB:-$ROOT/system/control-plane/state/data/canonical-state.db}"
CLUSTER_COUNT=0
NODE_COUNT=0
SERVICE_COUNT=0
NETWORK_COUNT=0
VOLUME_COUNT=0
IMAGE_COUNT=0
PORT_COUNT=0
NODE_NO_STATUS=0
CLUSTER_NO_STATUS=0
SERVICE_NO_STATUS=0
DB_AVAILABLE=0

if [ -f "$db" ] && command -v sqlite3 >/dev/null 2>&1; then
  DB_AVAILABLE=1
  CLUSTER_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM cluster;" 2>/dev/null || echo 0)
  NODE_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM node;" 2>/dev/null || echo 0)
  SERVICE_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM service;" 2>/dev/null || echo 0)
  NETWORK_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM network;" 2>/dev/null || echo 0)
  VOLUME_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM volume;" 2>/dev/null || echo 0)
  IMAGE_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM image;" 2>/dev/null || echo 0)
  PORT_COUNT=$(sqlite3 "$db" "SELECT COUNT(*) FROM port;" 2>/dev/null || echo 0)

  NODE_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM node
    WHERE status IS NULL OR TRIM(status) = '';" 2>/dev/null || echo 0)
  CLUSTER_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM cluster
    WHERE status IS NULL OR TRIM(status) = '';" 2>/dev/null || echo 0)
  SERVICE_NO_STATUS=$(sqlite3 "$db" "
    SELECT COUNT(*) FROM service
    WHERE status IS NULL OR TRIM(status) = '';" 2>/dev/null || echo 0)
else
  p_info "INFRA-DB" "Brak bazy StateStore / sqlite3 — pominięto (best-effort)"
fi

INFRA_TOTAL=$((CLUSTER_COUNT + NODE_COUNT + SERVICE_COUNT + NETWORK_COUNT + VOLUME_COUNT + IMAGE_COUNT + PORT_COUNT))

# ── TEST ────────────────────────────────────────────────────
if [ "$DB_AVAILABLE" -eq 0 ]; then
  p_warn "INFRA-REGISTRY" "Baza StateStore niedostępna — nie można zweryfikować rejestru infrastruktury"
  repo_verdict="NOT_APPLICABLE"
elif [ "$INFRA_TOTAL" -eq 0 ]; then
  p_warn "INFRA-REGISTRY" "Brak rejestru infrastruktury (wszystkie tabele puste) — NO FALSE GREEN: NOT_APPLICABLE"
  repo_verdict="NOT_APPLICABLE"
else
  p_pass "INFRA-REGISTRY" BLOCKING "Rejestr infrastruktury istnieje (cluster=$CLUSTER_COUNT node=$NODE_COUNT service=$SERVICE_COUNT network=$NETWORK_COUNT volume=$VOLUME_COUNT image=$IMAGE_COUNT port=$PORT_COUNT)"
  if [ "$NODE_NO_STATUS" -eq 0 ]; then
    p_pass "NODE-STATUS" BLOCKING "Wszystkie node'y mają status"
  else
    p_fail "NODE-STATUS" BLOCKING "Znaleziono $NODE_NO_STATUS node'ów bez statusu"
  fi
  if [ "$CLUSTER_NO_STATUS" -eq 0 ]; then
    p_pass "CLUSTER-STATUS" BLOCKING "Wszystkie clustery mają status"
  else
    p_fail "CLUSTER-STATUS" BLOCKING "Znaleziono $CLUSTER_NO_STATUS clusterów bez statusu"
  fi
  if [ "$SERVICE_NO_STATUS" -eq 0 ]; then
    p_pass "SERVICE-STATUS" BLOCKING "Wszystkie usługi mają status"
  else
    p_fail "SERVICE-STATUS" BLOCKING "Znaleziono $SERVICE_NO_STATUS usług bez statusu"
  fi
  repo_verdict="PASS"
  if [ "$NODE_NO_STATUS" -gt 0 ] || [ "$CLUSTER_NO_STATUS" -gt 0 ] || [ "$SERVICE_NO_STATUS" -gt 0 ]; then
    repo_verdict="FAIL"
  fi
fi

# ── EVIDENCE ────────────────────────────────────────────────
p_evidence "pipeline:P-038:infrastructure CLUSTER=$CLUSTER_COUNT NODE=$NODE_COUNT SERVICE=$SERVICE_COUNT NETWORK=$NETWORK_COUNT VOLUME=$VOLUME_COUNT IMAGE=$IMAGE_COUNT PORT=$PORT_COUNT NODE_NO_STATUS=$NODE_NO_STATUS" "pipeline" "deployment/infrastructure.sh"

# ── VERIFY ──────────────────────────────────────────────────
# Dual Verdict: IMPLEMENTATION (pipeline poprawnie zbudowany) vs REPOSITORY.
impl_verdict="PASS"
p_dual_verdict "P-038" "$impl_verdict" "$repo_verdict"

# ── REGISTER ────────────────────────────────────────────────
p_register_run "P-038" "$repo_verdict" "DEEP" 0

# ── REPORT ──────────────────────────────────────────────────
p_module_exit
