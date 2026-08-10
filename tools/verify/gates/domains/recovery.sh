#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/recovery.sh — GATE-013 RECOVERY
# Weryfikuje że backup/restore działa.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-013 RECOVERY ==="

STATE_SH="./system/control-plane/state/state.sh"

# ── RECOVERY-001: state.sh istnieje ─────────────────────────
if [ -f "$STATE_SH" ]; then
  pass "RECOVERY-001 state.sh istnieje" BLOCKING "state.sh obecny."
else
  fail "RECOVERY-001 state.sh istnieje" BLOCKING "Brak state.sh."
fi

# ── RECOVERY-002: state.sh ma komendę backup ────────────────
if [ -f "$STATE_SH" ]; then
  if grep -qE 'backup' "$STATE_SH" 2>/dev/null; then
    pass "RECOVERY-002 state.sh ma backup" BLOCKING "state.sh obsługuje backup."
  else
    fail "RECOVERY-002 state.sh ma backup" BLOCKING "state.sh nie ma komendy backup."
  fi
fi

# ── RECOVERY-003: state.sh ma komendę restore ───────────────
if [ -f "$STATE_SH" ]; then
  if grep -qE 'restore' "$STATE_SH" 2>/dev/null; then
    pass "RECOVERY-003 state.sh ma restore" BLOCKING "state.sh obsługuje restore."
  else
    fail "RECOVERY-003 state.sh ma restore" BLOCKING "state.sh nie ma komendy restore."
  fi
fi

# ── RECOVERY-004: state.sh ma set -euo pipefail ─────────────
if [ -f "$STATE_SH" ]; then
  if grep -q 'set -euo pipefail' "$STATE_SH" 2>/dev/null; then
    pass "RECOVERY-004 state.sh set -euo pipefail" BLOCKING "state.sh ma set -euo pipefail."
  else
    fail "RECOVERY-004 state.sh set -euo pipefail" BLOCKING "state.sh nie ma set -euo pipefail."
  fi
fi

verify_module_exit
