#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/testing.sh — GATE-014 TESTING
# Weryfikuje że testy istnieją, nie są puste, nie są false green.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-014 TESTING ==="

# ── TESTING-001: testy istnieją ─────────────────────────────
TEST_DIRS=(
  "system/control-plane/state/tests"
  "tools/verify/gates/tests"
)
TEST_COUNT=0
for d in "${TEST_DIRS[@]}"; do
  if [ -d "./$d" ]; then
    n=$(find "./$d" -name 'test_*.sh' 2>/dev/null | wc -l)
    TEST_COUNT=$((TEST_COUNT+n))
  fi
done
if [ "$TEST_COUNT" -gt 0 ]; then
  pass "TESTING-001 testy istnieją" BLOCKING "$TEST_COUNT plików testowych."
else
  fail "TESTING-001 testy istnieją" BLOCKING "Brak plików testowych."
fi

# ── TESTING-002: testy nie są puste ─────────────────────────
EMPTY_TESTS=0
EMPTY_DETAIL=""
for d in "${TEST_DIRS[@]}"; do
  [ -d "./$d" ] || continue
  while IFS= read -r f; do
    size=$(wc -c < "$f")
    if [ "$size" -lt 50 ]; then
      EMPTY_TESTS=$((EMPTY_TESTS+1))
      EMPTY_DETAIL="$EMPTY_DETAIL $f"
    fi
  done < <(find "./$d" -name 'test_*.sh' 2>/dev/null)
done
if [ "$EMPTY_TESTS" -eq 0 ]; then
  pass "TESTING-002 testy niepuste" BLOCKING "Brak pustych testów."
else
  fail "TESTING-002 testy niepuste" BLOCKING "$EMPTY_TESTS pustych testów:$EMPTY_DETAIL"
fi

# ── TESTING-003: brak false green w testach ─────────────────
# Zakazane wzorce: || true, set +e, continue-on-error, ignorowany exit code.
FALSE_GREEN=0
FALSE_GREEN_DETAIL=""
for d in "${TEST_DIRS[@]}"; do
  [ -d "./$d" ] || continue
  while IFS= read -r f; do
    if grep -qE '\|\| true|set \+e|continue-on-error' "$f" 2>/dev/null; then
      FALSE_GREEN=$((FALSE_GREEN+1))
      FALSE_GREEN_DETAIL="$FALSE_GREEN_DETAIL $f"
    fi
  done < <(find "./$d" -name 'test_*.sh' 2>/dev/null)
done
if [ "$FALSE_GREEN" -eq 0 ]; then
  pass "TESTING-003 brak false green" BLOCKING "Brak wzorców false green w testach."
else
  fail "TESTING-003 brak false green" BLOCKING "$FALSE_GREEN testów z false green:$FALSE_GREEN_DETAIL"
fi

# ── TESTING-004: testy mają set -u ──────────────────────────
NO_SET_U=0
NO_SET_U_DETAIL=""
for d in "${TEST_DIRS[@]}"; do
  [ -d "./$d" ] || continue
  while IFS= read -r f; do
    if ! grep -qE 'set -[a-z]*u' "$f" 2>/dev/null; then
      NO_SET_U=$((NO_SET_U+1))
      NO_SET_U_DETAIL="$NO_SET_U_DETAIL $f"
    fi
  done < <(find "./$d" -name 'test_*.sh' 2>/dev/null)
done
if [ "$NO_SET_U" -eq 0 ]; then
  pass "TESTING-004 testy mają set -u" BLOCKING "Wszystkie testy mają set -u."
else
  fail "TESTING-004 testy mają set -u" BLOCKING "$NO_SET_U testów bez set -u:$NO_SET_U_DETAIL"
fi

verify_module_exit
