#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# git/branches.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: GIT BRANCH POLICY
# Sprawdza zgodność gałęzi z polityką.
#
# Checki:
#   GIT-201  Branch prefix policy
#   GIT-202  main is canonical (no develop/master/release/staging)
#   GIT-203  No direct push to main (delegated to pre-push)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GIT BRANCH POLICY ==="

BRANCH="$(git branch --show-current 2>/dev/null || echo '')"

# GIT-201 Branch prefix policy
case "$BRANCH" in
  main)
    pass "GIT-201 Branch prefix policy" "main jest kanoniczną linią."
    ;;
  feature/*|fix/*|migration/*|security/*|release/*)
    pass "GIT-201 Branch prefix policy" "Branch '$BRANCH' ma dozwolony prefiks."
    ;;
  *)
    if [ -n "$BRANCH" ]; then
      fail "GIT-201 Branch prefix policy" BLOCKING "Branch '$BRANCH' nie ma dozwolonego prefiksu. Dozwolone: feature/*, fix/*, migration/*, security/*, release/*"
    else
      info "GIT-201 Branch prefix policy" "Brak aktywnej gałęzi (detached HEAD?)."
    fi
    ;;
esac

# GIT-202 main is canonical (no develop/master/release/staging)
FORBIDDEN_BRANCHES=$(git branch --no-color 2>/dev/null | grep -E '(^|/)(develop|master|release|staging)$' | tr -d ' *')
if [ -n "$FORBIDDEN_BRANCHES" ]; then
  fail "GIT-202 main is canonical" BLOCKING "Zakazane gałęzie: $FORBIDDEN_BRANCHES"
else
  pass "GIT-202 main is canonical"
fi

# GIT-203 No direct push to main (delegated to pre-push)
if [ -f ".git-hooks/pre-push" ]; then
  pass "GIT-203 No direct push to main" "pre-push hook blokuje bezpośredni push na main."
else
  fail "GIT-203 No direct push to main" BLOCKING "Brak pre-push hook."
fi

say ""
