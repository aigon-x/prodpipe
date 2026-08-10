#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/structure.sh — GATE-006 STRUCTURE
# Weryfikuje że struktura katalogów jest zgodna z kontraktem.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-006 STRUCTURE ==="

# ── STRUCTURE-001: wymagane katalogi istnieją ───────────────
REQUIRED_DIRS=(
  "tools/verify"
  "system/control-plane/state"
  "config"
  "artifacts"
  "docs"
)
MISSING_DIRS=""
for d in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "./$d" ]; then
    MISSING_DIRS="$MISSING_DIRS $d"
  fi
done
if [ -z "$MISSING_DIRS" ]; then
  pass "STRUCTURE-001 wymagane katalogi" BLOCKING "Wszystkie wymagane katalogi obecne."
else
  fail "STRUCTURE-001 wymagane katalogi" BLOCKING "Brak katalogów:$MISSING_DIRS"
fi

# ── STRUCTURE-002: brak katalogów meta-system ───────────────
# NO META-SYSTEM: nie tworzymy nowych katalogów meta-systemów.
META_DIRS=(
  "gate-system"
  "quality-gates"
  "gates-system"
  "meta-gates"
)
FOUND_META=""
for d in "${META_DIRS[@]}"; do
  if [ -d "./$d" ]; then
    FOUND_META="$FOUND_META $d"
  fi
done
if [ -z "$FOUND_META" ]; then
  pass "STRUCTURE-002 brak meta-system" BLOCKING "Brak katalogów meta-system."
else
  fail "STRUCTURE-002 brak meta-system" BLOCKING "Znaleziono katalogi meta-system:$FOUND_META"
fi

# ── STRUCTURE-003: tools/verify/gates istnieje ──────────────
if [ -d "./tools/verify/gates" ]; then
  pass "STRUCTURE-003 tools/verify/gates istnieje" BLOCKING "Katalog gates obecny."
else
  fail "STRUCTURE-003 tools/verify/gates istnieje" BLOCKING "Brak tools/verify/gates."
fi

verify_module_exit
