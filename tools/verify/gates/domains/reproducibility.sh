#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/reproducibility.sh — GATE-009 REPRODUCIBILITY
# Weryfikuje reprodukowalność build/deploy.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-009 REPRODUCIBILITY ==="

# ── REPRODUCIBILITY-001: skrypt build istnieje ──────────────
BUILD_SCRIPTS=0
for b in build.sh Makefile Dockerfile; do
  if [ -f "./$b" ]; then
    BUILD_SCRIPTS=$((BUILD_SCRIPTS+1))
  fi
done
if [ "$BUILD_SCRIPTS" -gt 0 ]; then
  pass "REPRODUCIBILITY-001 skrypt build" BLOCKING "$BUILD_SCRIPTS artefaktów build."
else
  info "REPRODUCIBILITY-001 skrypt build" "Brak skryptów build (repo bez build)."
fi

# ── REPRODUCIBILITY-002: brak timestampów w build ───────────
# Build nie powinien zależeć od bieżącego czasu (determinizm).
TIMESTAMP_COUNT=0
while IFS= read -r f; do
  case "$f" in
    *.sh|Makefile|Dockerfile) ;;
    *) continue ;;
  esac
  if grep -qE 'date \+%s|date \+%Y|$(date)' "$f" 2>/dev/null; then
    TIMESTAMP_COUNT=$((TIMESTAMP_COUNT+1))
  fi
done < <(find . -maxdepth 2 -type f \( -name '*.sh' -o -name 'Makefile' -o -name 'Dockerfile' \) -not -path './.git/*' 2>/dev/null)

if [ "$TIMESTAMP_COUNT" -eq 0 ]; then
  pass "REPRODUCIBILITY-002 brak timestampów w build" BLOCKING "Brak zależności od czasu w build."
else
  warn "REPRODUCIBILITY-002 brak timestampów w build" "$TIMESTAMP_COUNT plików build z timestampami."
fi

# ── REPRODUCIBILITY-003: lockfile deterministyczny ──────────
if [ -f "./Cargo.lock" ] || [ -f "./package-lock.json" ]; then
  pass "REPRODUCIBILITY-003 lockfile deterministyczny" BLOCKING "Lockfile obecny (deterministyczny build)."
else
  info "REPRODUCIBILITY-003 lockfile deterministyczny" "Brak lockfile."
fi

verify_module_exit
