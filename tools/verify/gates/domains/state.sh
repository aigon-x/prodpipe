#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/state.sh — GATE-019 STATE
# Weryfikuje że StateStore jest spójny, schema_version zgodna.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-019 STATE ==="

STATE_DIR="./system/control-plane/state"

# ── STATE-001: state.sh istnieje ────────────────────────────
if [ -f "$STATE_DIR/state.sh" ]; then
  pass "STATE-001 state.sh istnieje" BLOCKING "state.sh obecny."
else
  fail "STATE-001 state.sh istnieje" BLOCKING "Brak state.sh."
fi

# ── STATE-002: lib.sh istnieje ──────────────────────────────
if [ -f "$STATE_DIR/lib.sh" ]; then
  pass "STATE-002 lib.sh istnieje" BLOCKING "lib.sh obecny."
else
  fail "STATE-002 lib.sh istnieje" BLOCKING "Brak lib.sh."
fi

# ── STATE-003: schema_version zdefiniowana ──────────────────
if [ -f "$STATE_DIR/lib.sh" ]; then
  declared=$(grep -E 'STATE_SCHEMA_VERSION=' "$STATE_DIR/lib.sh" | head -1 | sed 's/.*="\([0-9]*\)".*/\1/')
  if [ -n "$declared" ]; then
    pass "STATE-003 schema_version zdefiniowana" BLOCKING "STATE_SCHEMA_VERSION=$declared."
  else
    fail "STATE-003 schema_version zdefiniowana" BLOCKING "Brak STATE_SCHEMA_VERSION w lib.sh."
  fi
fi

# ── STATE-004: state.sh ma set -euo pipefail ────────────────
if [ -f "$STATE_DIR/state.sh" ]; then
  if grep -q 'set -euo pipefail' "$STATE_DIR/state.sh" 2>/dev/null; then
    pass "STATE-004 state.sh set -euo pipefail" BLOCKING "state.sh ma set -euo pipefail."
  else
    fail "STATE-004 state.sh set -euo pipefail" BLOCKING "state.sh nie ma set -euo pipefail."
  fi
fi

# ── STATE-005: tabela evidence w migracji ───────────────────
if [ -d "$STATE_DIR/migrations" ]; then
  if grep -qE 'CREATE TABLE.*evidence' "$STATE_DIR"/migrations/*.sql 2>/dev/null; then
    pass "STATE-005 tabela evidence w migracji" BLOCKING "Tabela evidence zdefiniowana w migracji."
  else
    fail "STATE-005 tabela evidence w migracji" BLOCKING "Brak tabeli evidence w migracjach."
  fi
fi

verify_module_exit
