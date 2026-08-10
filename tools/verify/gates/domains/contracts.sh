#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/contracts.sh — GATE-011 CONTRACTS
# Weryfikuje że kontrakty README/API są spełnione.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-011 CONTRACTS ==="

# ── CONTRACTS-001: README.md istnieje ───────────────────────
if [ -f "./README.md" ]; then
  pass "CONTRACTS-001 README.md istnieje" BLOCKING "README.md obecny."
else
  fail "CONTRACTS-001 README.md istnieje" BLOCKING "Brak README.md."
fi

# ── CONTRACTS-002: README nie jest placeholderem ────────────
if [ -f "./README.md" ]; then
  if grep -qiE 'placeholder|TODO|brak implementacji|coming soon' ./README.md 2>/dev/null; then
    fail "CONTRACTS-002 README nie jest placeholderem" BLOCKING "README.md zawiera placeholder."
  else
    pass "CONTRACTS-002 README nie jest placeholderem" BLOCKING "README.md nie jest placeholderem."
  fi
fi

# ── CONTRACTS-003: README ma sekcję Purpose ─────────────────
if [ -f "./README.md" ]; then
  if grep -qE '^## 1\. Purpose|^# .*Purpose' ./README.md 2>/dev/null; then
    pass "CONTRACTS-003 README ma Purpose" BLOCKING "README.md ma sekcję Purpose."
  else
    warn "CONTRACTS-003 README ma Purpose" "README.md nie ma jawnej sekcji Purpose."
  fi
fi

# ── CONTRACTS-004: brak pustych README ──────────────────────
if [ -f "./README.md" ]; then
  size=$(wc -c < ./README.md)
  if [ "$size" -gt 100 ]; then
    pass "CONTRACTS-004 README niepusty" BLOCKING "README.md ma $size bajtów."
  else
    fail "CONTRACTS-004 README niepusty" BLOCKING "README.md jest pusty ($size bajtów)."
  fi
fi

verify_module_exit
