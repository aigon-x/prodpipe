#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gates/domains/ci.sh — GATE-017 CI
# Weryfikuje że workflow CI wywołują verify.sh gates.
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../../../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GATE-017 CI ==="

# ── CI-001: katalog .github/workflows istnieje ──────────────
if [ -d "./.github/workflows" ]; then
  pass "CI-001 .github/workflows istnieje" BLOCKING "Katalog workflows obecny."
else
  fail "CI-001 .github/workflows istnieje" BLOCKING "Brak .github/workflows."
fi

# ── CI-002: ci.yml wywołuje verify.sh gates ────────────────
if [ -f "./.github/workflows/ci.yml" ]; then
  if grep -qE 'verify\.sh.*gates|gates.*verify\.sh' ./.github/workflows/ci.yml 2>/dev/null; then
    pass "CI-002 ci.yml wywołuje verify.sh gates" BLOCKING "ci.yml wywołuje verify.sh gates."
  else
    fail "CI-002 ci.yml wywołuje verify.sh gates" BLOCKING "ci.yml NIE wywołuje verify.sh gates."
  fi
else
  fail "CI-002 ci.yml wywołuje verify.sh gates" BLOCKING "Brak ci.yml."
fi

# ── CI-003: release.yml wywołuje verify.sh gates ────────────
if [ -f "./.github/workflows/release.yml" ]; then
  if grep -qE 'verify\.sh.*gates|gates.*verify\.sh' ./.github/workflows/release.yml 2>/dev/null; then
    pass "CI-003 release.yml wywołuje verify.sh gates" BLOCKING "release.yml wywołuje verify.sh gates."
  else
    fail "CI-003 release.yml wywołuje verify.sh gates" BLOCKING "release.yml NIE wywołuje verify.sh gates."
  fi
else
  fail "CI-003 release.yml wywołuje verify.sh gates" BLOCKING "Brak release.yml."
fi

# ── CI-004: brak placeholderów w CI ─────────────────────────
PLACEHOLDER_COUNT=0
while IFS= read -r wf; do
  if grep -qiE 'placeholder|brak implementacji' "$wf" 2>/dev/null; then
    PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT+1))
  fi
done < <(find ./.github/workflows -name '*.yml' -o -name '*.yaml' 2>/dev/null)
if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
  pass "CI-004 brak placeholderów w CI" BLOCKING "Brak placeholderów w workflow."
else
  fail "CI-004 brak placeholderów w CI" BLOCKING "$PLACEHOLDER_COUNT workflow z placeholderami."
fi

verify_module_exit
