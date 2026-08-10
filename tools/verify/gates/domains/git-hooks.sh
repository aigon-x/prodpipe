#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/git-hooks.sh — GATE-018 GIT-HOOKS
# Weryfikuje że pre-commit/pre-push/validate-sot działają.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-018 GIT-HOOKS ==="

# ── GIT-HOOKS-001: .git-hooks istnieje ──────────────────────
if [ -d "./.git-hooks" ]; then
  pass "GIT-HOOKS-001 .git-hooks istnieje" BLOCKING "Katalog .git-hooks obecny."
else
  fail "GIT-HOOKS-001 .git-hooks istnieje" BLOCKING "Brak .git-hooks."
fi

# ── GIT-HOOKS-002: pre-commit istnieje ──────────────────────
if [ -f "./.git-hooks/pre-commit" ]; then
  pass "GIT-HOOKS-002 pre-commit istnieje" BLOCKING "pre-commit obecny."
else
  fail "GIT-HOOKS-002 pre-commit istnieje" BLOCKING "Brak pre-commit."
fi

# ── GIT-HOOKS-003: pre-push istnieje ────────────────────────
if [ -f "./.git-hooks/pre-push" ]; then
  pass "GIT-HOOKS-003 pre-push istnieje" BLOCKING "pre-push obecny."
else
  fail "GIT-HOOKS-003 pre-push istnieje" BLOCKING "Brak pre-push."
fi

# ── GIT-HOOKS-004: pre-commit ma set -euo pipefail ──────────
if [ -f "./.git-hooks/pre-commit" ]; then
  if grep -q 'set -euo pipefail' ./.git-hooks/pre-commit 2>/dev/null; then
    pass "GIT-HOOKS-004 pre-commit set -euo pipefail" BLOCKING "pre-commit ma set -euo pipefail."
  else
    fail "GIT-HOOKS-004 pre-commit set -euo pipefail" BLOCKING "pre-commit nie ma set -euo pipefail."
  fi
fi

# ── GIT-HOOKS-005: pre-commit wywołuje verify.sh gates ──────
if [ -f "./.git-hooks/pre-commit" ]; then
  if grep -qE 'verify\.sh.*gates|gates.*verify\.sh' ./.git-hooks/pre-commit 2>/dev/null; then
    pass "GIT-HOOKS-005 pre-commit wywołuje verify.sh gates" BLOCKING "pre-commit wywołuje verify.sh gates."
  else
    fail "GIT-HOOKS-005 pre-commit wywołuje verify.sh gates" BLOCKING "pre-commit NIE wywołuje verify.sh gates."
  fi
fi

# ── GIT-HOOKS-006: pre-push wywołuje verify.sh gates ────────
if [ -f "./.git-hooks/pre-push" ]; then
  if grep -qE 'verify\.sh.*gates|gates.*verify\.sh' ./.git-hooks/pre-push 2>/dev/null; then
    pass "GIT-HOOKS-006 pre-push wywołuje verify.sh gates" BLOCKING "pre-push wywołuje verify.sh gates."
  else
    fail "GIT-HOOKS-006 pre-push wywołuje verify.sh gates" BLOCKING "pre-push NIE wywołuje verify.sh gates."
  fi
fi

verify_module_exit
