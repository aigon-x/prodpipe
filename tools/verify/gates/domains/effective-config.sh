#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/effective-config.sh — GATE-025 EFFECTIVE-CONFIG
# Wykrywa rozjazd między EFFECTIVE STATE (co faktycznie działa)
# a DECLARED STATE (co jest w configu). Drift między deklaracją
# a rzeczywistością. "Never trust a component's claim about its
# own state. Verify the state externally."
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-025 EFFECTIVE-CONFIG ==="

STATE_DIR="./system/control-plane/state"
STATE_DB="$STATE_DIR/data/canonical-state.db"

# ── EFFECTIVE-CONFIG-001: declared state zdefiniowany ───────
# Declared state = schema_version w lib.sh (co jest w configu).
if [ -f "$STATE_DIR/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' "$STATE_DIR/lib.sh" | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  if [ -n "$declared" ]; then
    pass "EFFECTIVE-CONFIG-001 declared state" BLOCKING "Declared schema_version=$declared."
  else
    fail "EFFECTIVE-CONFIG-001 declared state" BLOCKING "Brak declared schema_version."
  fi
fi

# ── EFFECTIVE-CONFIG-002: effective state zdefiniowany ──────
# Effective state = faktyczna wersja schematu w bazie (co działa).
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
  effective=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';" 2>/dev/null || echo "0")
  if [ -n "$effective" ]; then
    pass "EFFECTIVE-CONFIG-002 effective state" BLOCKING "Effective schema_version=$effective."
  else
    fail "EFFECTIVE-CONFIG-002 effective state" BLOCKING "Brak effective schema_version w bazie."
  fi
else
  info "EFFECTIVE-CONFIG-002 effective state" "Baza StateStore niedostępna — UNKNOWN."
fi

# ── EFFECTIVE-CONFIG-003: brak driftu (declared == effective) ─
# Drift = rozjazd między deklaracją a rzeczywistością.
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ] && [ -f "$STATE_DIR/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' "$STATE_DIR/lib.sh" | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  effective=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';" 2>/dev/null || echo "0")
  if [ "$declared" = "$effective" ]; then
    pass "EFFECTIVE-CONFIG-003 brak driftu" BLOCKING "Declared=$declared == Effective=$effective."
  else
    fail "EFFECTIVE-CONFIG-003 brak driftu" BLOCKING "DRIFT: Declared=$declared != Effective=$effective."
  fi
else
  info "EFFECTIVE-CONFIG-003 brak driftu" "Baza StateStore niedostępna — UNKNOWN."
fi

# ── EFFECTIVE-CONFIG-004: system_twin declared vs effective ─
# Dla każdego noda w grafie: declared musi być zgodny z effective.
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
  node_count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM system_twin_node;" 2>/dev/null || echo "0")
  if [ "$node_count" -gt 0 ]; then
    drift=0
    while IFS='|' read -r node_id declared effective; do
      if [ -n "$declared" ] && [ -n "$effective" ] && [ "$declared" != "-" ] && [ "$effective" != "-" ] && [ "$declared" != "$effective" ]; then
        drift=$((drift+1))
        warn "EFFECTIVE-CONFIG-004 node $node_id: declared=$declared != effective=$effective"
      fi
    done < <(sqlite3 "$STATE_DB" "SELECT node_id, COALESCE(declared,'-'), COALESCE(effective,'-') FROM system_twin_node;" 2>/dev/null)
    if [ "$drift" -eq 0 ]; then
      pass "EFFECTIVE-CONFIG-004 system_twin bez driftu" BLOCKING "$node_count nodów, declared==effective."
    else
      fail "EFFECTIVE-CONFIG-004 system_twin bez driftu" BLOCKING "$drift nodów z driftem declared!=effective."
    fi
  else
    info "EFFECTIVE-CONFIG-004 system_twin bez driftu" "Brak nodów w grafie."
  fi
else
  info "EFFECTIVE-CONFIG-004 system_twin bez driftu" "Baza StateStore niedostępna — UNKNOWN."
fi

verify_module_exit
