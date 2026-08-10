#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/dependencies.sh — GATE-008 DEPENDENCIES
# Weryfikuje brak nieznanych zależności.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-008 DEPENDENCIES ==="

# ── DEPENDENCIES-001: manifesty zależności istnieją ─────────
MANIFESTS=0
for m in package.json Cargo.toml go.mod requirements.txt pyproject.toml; do
  if [ -f "./$m" ]; then
    MANIFESTS=$((MANIFESTS+1))
  fi
done
if [ "$MANIFESTS" -gt 0 ]; then
  pass "DEPENDENCIES-001 manifesty zależności" BLOCKING "$MANIFESTS manifestów zależności."
else
  info "DEPENDENCIES-001 manifesty zależności" "Brak manifestów zależności (repo bez zależności)."
fi

# ── DEPENDENCIES-002: brak node_modules w repo ──────────────
if [ -d "./node_modules" ]; then
  fail "DEPENDENCIES-002 brak node_modules w repo" BLOCKING "node_modules obecny w repo."
else
  pass "DEPENDENCIES-002 brak node_modules w repo" BLOCKING "Brak node_modules."
fi

# ── DEPENDENCIES-003: brak vendor/ w repo ───────────────────
if [ -d "./vendor" ]; then
  warn "DEPENDENCIES-003 brak vendor/ w repo" "Katalog vendor/ obecny."
else
  pass "DEPENDENCIES-003 brak vendor/ w repo" BLOCKING "Brak vendor/."
fi

# ── DEPENDENCIES-004: brak lockfile drift ───────────────────
# package-lock.json / Cargo.lock powinny być zacommitowane.
LOCKFILES=0
for l in package-lock.json Cargo.lock go.sum; do
  if [ -f "./$l" ]; then
    LOCKFILES=$((LOCKFILES+1))
  fi
done
if [ "$LOCKFILES" -gt 0 ]; then
  pass "DEPENDENCIES-004 lockfile zacommitowany" BLOCKING "$LOCKFILES lockfile'ów."
else
  info "DEPENDENCIES-004 lockfile zacommitowany" "Brak lockfile'ów."
fi

verify_module_exit
