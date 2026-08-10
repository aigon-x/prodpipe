#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/source-of-truth.sh — GATE-002 SOURCE-OF-TRUTH
# Weryfikuje że git (desired state) jest spójny z deklarowanym
# Source of Truth. PRAWDA wyłącznie z kodu, exit code, StateStore.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-002 SOURCE-OF-TRUTH ==="

# ── SOURCE-OF-TRUTH-001: SOURCE-OF-TRUTH.md istnieje ────────
if [ -f "./SOURCE-OF-TRUTH.md" ]; then
  pass "SOURCE-OF-TRUTH-001 SOURCE-OF-TRUTH.md istnieje" BLOCKING "Plik SOURCE-OF-TRUTH.md obecny."
else
  fail "SOURCE-OF-TRUTH-001 SOURCE-OF-TRUTH.md istnieje" BLOCKING "Brak SOURCE-OF-TRUTH.md."
fi

# ── SOURCE-OF-TRUTH-002: STATUS zdefiniowany ────────────────
if [ -f "./SOURCE-OF-TRUTH.md" ]; then
  sot_status=$(grep -E 'STATUS:' ./SOURCE-OF-TRUTH.md | head -1 | sed 's/.*STATUS:[[:space:]]*//')
  if [ -z "$sot_status" ] || [ "$sot_status" = "UNDEFINED" ]; then
    fail "SOURCE-OF-TRUTH-002 STATUS zdefiniowany" BLOCKING "SOURCE-OF-TRUTH.md STATUS: ${sot_status:-brak} — wymaga decyzji."
  else
    pass "SOURCE-OF-TRUTH-002 STATUS zdefiniowany" BLOCKING "STATUS: $sot_status"
  fi
fi

# ── SOURCE-OF-TRUTH-003: git clean (desired state) ──────────
if git diff --quiet 2>/dev/null; then
  pass "SOURCE-OF-TRUTH-003 git clean" BLOCKING "Working tree czysty (desired state == committed)."
else
  fail "SOURCE-OF-TRUTH-003 git clean" BLOCKING "Working tree ma niezacommitowane zmiany — desired state rozjechany."
fi

# ── SOURCE-OF-TRUTH-004: HEAD istnieje ──────────────────────
if git rev-parse HEAD >/dev/null 2>&1; then
  pass "SOURCE-OF-TRUTH-004 HEAD istnieje" BLOCKING "HEAD: $(git rev-parse --short HEAD)"
else
  fail "SOURCE-OF-TRUTH-004 HEAD istnieje" BLOCKING "Brak HEAD (repo bez commitów)."
fi

verify_module_exit
