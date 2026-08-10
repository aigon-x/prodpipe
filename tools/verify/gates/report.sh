#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/report.sh — REPORT GENERATOR (PHASE 14)
# Generuje raporty do artifacts/reports/gates/ na podstawie
# registry (jedyne źródło prawdy o gate'ach) i evidence.
#
# Raporty:
#   integrity.md            — meta-raport GATE-INTEGRITY
#   <domain>.md             — raport per domena (z evidence)
#   control-planes.md       — 12 control planes (druga ekspansja)
#   invariants.md           — system invariants
#   drift.md                — system drift
#   state-consistency.md    — state consistency
#   trust-boundary.md       — trust boundary matrix
#   compatibility-matrix.md — version compatibility
#   bypass.md               — pipeline bypass
#   lifecycle.md            — gate lifecycle
#   recovery.md             — recovery
#   queue-retry-resource.md — queue/retry/resource
#   deployment-migration-rollback.md — deployment/migration/rollback
#   node-parity.md          — node parity
#
# Zasada: raporty są GENEROWANE z registry+evidence, nigdy ręcznie.
# NO FALSE GREEN: raport odzwierciedla rzeczywisty stan evidence.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

GATES_DIR="./tools/verify/gates"
REPORT_DIR="./artifacts/reports/gates"
EVIDENCE_DIR="./artifacts/evidence/gates"
REGISTRY="$GATES_DIR/registry.sh"

# ── Wczytaj registry ────────────────────────────────────────
if [ ! -f "$REGISTRY" ]; then
  fail "REPORT registry" BLOCKING "Brak registry.sh — nie można wygenerować raportów."
  verify_module_exit
fi
# shellcheck source=registry.sh
. "$REGISTRY"

mkdir -p "$REPORT_DIR"

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HEAD_SHORT="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

# ── Helper: status gate'a z evidence ────────────────────────
gate_status() {
  local gate_id="$1"
  local ev="$EVIDENCE_DIR/$gate_id.evidence"
  if [ -f "$ev" ]; then
    grep '^status=' "$ev" | cut -d= -f2
  else
    echo "NO_EVIDENCE"
  fi
}

# ── Helper: exit code gate'a z evidence ─────────────────────
gate_exit() {
  local gate_id="$1"
  local ev="$EVIDENCE_DIR/$gate_id.evidence"
  if [ -f "$ev" ]; then
    grep '^exit_code=' "$ev" | cut -d= -f2
  else
    echo "-"
  fi
}

# ── Helper: nagłówek raportu ────────────────────────────────
report_header() {
  local title="$1"
  cat <<EOF
# $title

> **Wygenerowano:** $NOW
> **HEAD:** $HEAD_SHORT
> **Źródło:** registry.sh + evidence (maszynowo weryfikowalne)

EOF
}

# ── 1. integrity.md — meta-raport ───────────────────────────
{
  report_header "GATE-INTEGRITY — Meta-raport"
  echo "## Podsumowanie"
  echo ""
  echo "| Pole | Wartość |"
  echo "|------|---------|"
  echo "| Liczba gate'ów w registry | $(registry_count) |"
  echo "| Liczba domen | $(registry_domains | wc -l) |"
  echo "| Gate'y IMPLEMENTED | $(registry_implemented_gates | wc -l) |"
  echo "| Gate'y PROPOSED | $(registry_non_implemented_gates | wc -l) |"
  echo "| Evidence wygenerowane | $(ls "$EVIDENCE_DIR"/*.evidence 2>/dev/null | wc -l) |"
  echo ""
  echo "## Status per gate"
  echo ""
  echo "| Gate | Domain | Status | Exit |"
  echo "|------|--------|--------|------|"
  for g in $(registry_gate_ids); do
    echo "| $g | $(registry_field "$g" 2) | $(gate_status "$g") | $(gate_exit "$g") |"
  done
  echo ""
} > "$REPORT_DIR/integrity.md"

# ── 2. Raporty per domena ───────────────────────────────────
for domain in $(registry_domains); do
  {
    report_header "Gate Report — $domain"
    echo "## Gate'y w domenie $domain"
    echo ""
    echo "| Gate | Name | Status | Exit | Profile |"
    echo "|------|------|--------|------|---------|"
    for g in $(registry_gates_for_domain "$domain"); do
      echo "| $g | $(registry_field "$g" 3) | $(gate_status "$g") | $(gate_exit "$g") | $(registry_field "$g" 7) |"
    done
    echo ""
  } > "$REPORT_DIR/$(echo "$domain" | tr 'A-Z' 'a-z').md"
done

# ── 3. control-planes.md — 12 control planes ────────────────
{
  report_header "Control Planes — 12 planes"
  echo "## Control Planes"
  echo ""
  echo "| Plane | Gate | Status |"
  echo "|-------|------|--------|"
  echo "| 1. Source of Truth | GATE-002 | $(gate_status GATE-002) |"
  echo "| 2. Canonicality | GATE-003 | $(gate_status GATE-003) |"
  echo "| 3. Configuration | GATE-004 | $(gate_status GATE-004) |"
  echo "| 4. Security | GATE-005 | $(gate_status GATE-005) |"
  echo "| 5. Structure | GATE-006 | $(gate_status GATE-006) |"
  echo "| 6. Architecture | GATE-007 | $(gate_status GATE-007) |"
  echo "| 7. Dependencies | GATE-008 | $(gate_status GATE-008) |"
  echo "| 8. Reproducibility | GATE-009 | $(gate_status GATE-009) |"
  echo "| 9. Deployment | GATE-010 | $(gate_status GATE-010) |"
  echo "| 10. Contracts | GATE-011 | $(gate_status GATE-011) |"
  echo "| 11. Migration | GATE-012 | $(gate_status GATE-012) |"
  echo "| 12. Recovery | GATE-013 | $(gate_status GATE-013) |"
  echo ""
} > "$REPORT_DIR/control-planes.md"

# ── 4. invariants.md ────────────────────────────────────────
{
  report_header "System Invariants"
  echo "## Invariant Engine (GATE-022)"
  echo ""
  echo "| Invariant | Status |"
  echo "|-----------|--------|"
  echo "| INVARIANT-001 schema_version | $(gate_status GATE-022) |"
  echo "| INVARIANT-002 migracje sekwencyjne | $(gate_status GATE-022) |"
  echo "| INVARIANT-003 state.sh set -euo pipefail | $(gate_status GATE-022) |"
  echo "| INVARIANT-004 registry parsowalny | $(gate_status GATE-022) |"
  echo "| INVARIANT-005 registry==implemented | $(gate_status GATE-022) |"
  echo "| INVARIANT-006 brak sekretów | $(gate_status GATE-022) |"
  echo "| INVARIANT-007 brak false green | $(gate_status GATE-022) |"
  echo "| INVARIANT-008 StateStore integrity | $(gate_status GATE-022) |"
  echo ""
} > "$REPORT_DIR/invariants.md"

# ── 5. drift.md ─────────────────────────────────────────────
{
  report_header "System Drift"
  echo "## Drift Detection"
  echo ""
  echo "| Gate | Status |"
  echo "|------|--------|"
  echo "| GATE-025 EFFECTIVE-CONFIG (declared vs effective) | $(gate_status GATE-025) |"
  echo "| GATE-021 SYSTEM-TWIN (graf vs rzeczywistość) | $(gate_status GATE-021) |"
  echo ""
} > "$REPORT_DIR/drift.md"

# ── 6. state-consistency.md ─────────────────────────────────
{
  report_header "State Consistency"
  echo "## StateStore Consistency"
  echo ""
  echo "| Check | Status |"
  echo "|-------|--------|"
  echo "| GATE-019 STATE | $(gate_status GATE-019) |"
  echo "| GATE-022 INVARIANT-008 integrity_check | $(gate_status GATE-022) |"
  echo ""
} > "$REPORT_DIR/state-consistency.md"

# ── 7. trust-boundary.md ────────────────────────────────────
{
  report_header "Trust Boundary Matrix"
  echo "## Trust Boundaries"
  echo ""
  echo "| Boundary | Gate | Status |"
  echo "|----------|------|--------|"
  echo "| Repo → Config | GATE-003 CANONICALITY | $(gate_status GATE-003) |"
  echo "| Repo → Secrets | GATE-005 SECURITY | $(gate_status GATE-005) |"
  echo "| Repo → State | GATE-019 STATE | $(gate_status GATE-019) |"
  echo "| Repo → CI | GATE-017 CI | $(gate_status GATE-017) |"
  echo ""
} > "$REPORT_DIR/trust-boundary.md"

# ── 8. compatibility-matrix.md ──────────────────────────────
{
  report_header "Version Compatibility Matrix"
  echo "## Compatibility"
  echo ""
  echo "| Component | Gate | Status |"
  echo "|-----------|------|--------|"
  echo "| Migracje StateStore | GATE-012 MIGRATION | $(gate_status GATE-012) |"
  echo "| Schema version | GATE-022 INVARIANT-001 | $(gate_status GATE-022) |"
  echo ""
} > "$REPORT_DIR/compatibility-matrix.md"

# ── 9. bypass.md ────────────────────────────────────────────
{
  report_header "Pipeline Bypass"
  echo "## Bypass Detection"
  echo ""
  echo "| Check | Status |"
  echo "|-------|--------|"
  echo "| GATE-INTEGRITY-007 brak bypass wzorców | $(gate_status GATE-001) |"
  echo "| INVARIANT-007 brak false green | $(gate_status GATE-022) |"
  echo ""
} > "$REPORT_DIR/bypass.md"

# ── 10. lifecycle.md ────────────────────────────────────────
{
  report_header "Gate Lifecycle"
  echo "## Lifecycle"
  echo ""
  echo "| Status | Liczba |"
  echo "|--------|--------|"
  echo "| PROPOSED | $(registry_non_implemented_gates | wc -l) |"
  echo "| IMPLEMENTED | $(registry_implemented_gates | wc -l) |"
  echo ""
} > "$REPORT_DIR/lifecycle.md"

# ── 11. recovery.md ─────────────────────────────────────────
{
  report_header "Recovery"
  echo "## Recovery"
  echo ""
  echo "| Gate | Status |"
  echo "|------|--------|"
  echo "| GATE-013 RECOVERY | $(gate_status GATE-013) |"
  echo ""
} > "$REPORT_DIR/recovery.md"

# ── 12. queue-retry-resource.md ─────────────────────────────
{
  report_header "Queue / Retry / Resource"
  echo "## Queue, Retry, Resource"
  echo ""
  echo "| Gate | Status |"
  echo "|------|--------|"
  echo "| GATE-015 PERFORMANCE | $(gate_status GATE-015) |"
  echo ""
} > "$REPORT_DIR/queue-retry-resource.md"

# ── 13. deployment-migration-rollback.md ────────────────────
{
  report_header "Deployment / Migration / Rollback"
  echo "## Deployment, Migration, Rollback"
  echo ""
  echo "| Gate | Status |"
  echo "|------|--------|"
  echo "| GATE-010 DEPLOYMENT | $(gate_status GATE-010) |"
  echo "| GATE-012 MIGRATION | $(gate_status GATE-012) |"
  echo ""
} > "$REPORT_DIR/deployment-migration-rollback.md"

# ── 14. node-parity.md ──────────────────────────────────────
{
  report_header "Node Parity"
  echo "## Node Parity"
  echo ""
  echo "| Gate | Status |"
  echo "|------|--------|"
  echo "| GATE-021 SYSTEM-TWIN (graf nodów) | $(gate_status GATE-021) |"
  echo ""
} > "$REPORT_DIR/node-parity.md"

# ── Podsumowanie ────────────────────────────────────────────
REPORT_COUNT="$(ls "$REPORT_DIR"/*.md 2>/dev/null | wc -l)"
pass "REPORT wszystkie raporty wygenerowane" BLOCKING "$REPORT_COUNT raportów w $REPORT_DIR."

verify_module_exit
