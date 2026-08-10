#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# git/tags.sh — AIGON Production Platform — Repository Certification Engine
# Moduł: GIT TAG POLICY
# Sprawdza zgodność tagów z polityką.
#
# Checki:
#   GIT-301  Tag naming policy
#   GIT-302  Tags are annotated (immutable)
#   GIT-303  Prod tags immutable (informational)
# ─────────────────────────────────────────────────────────────
set -u

# shellcheck source=../core/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib.sh"

ROOT="$(verify_root)"
cd "$ROOT"

say "=== GIT TAG POLICY ==="

# GIT-301 Tag naming policy
# Dozwolone: baseline-*, v*, milestone-*, release-*, recovery-*
BAD_TAGS=$(git tag -l 2>/dev/null | grep -vE '^(baseline-|v[0-9]|milestone-|release-|recovery-)' | head -5)
if [ -n "$BAD_TAGS" ]; then
  fail "GIT-301 Tag naming policy" BLOCKING "Tagi niezgodne z polityką: $BAD_TAGS"
else
  pass "GIT-301 Tag naming policy"
fi

# GIT-302 Tags are annotated (immutable)
LIGHTWEIGHT=$(git tag -l 2>/dev/null | while read -r t; do
  git cat-file -t "$t" 2>/dev/null | grep -q '^commit$' && echo "$t"
done)
if [ -n "$LIGHTWEIGHT" ]; then
  fail "GIT-302 Tags are annotated" BLOCKING "Lightweight tagi (nieannotated): $LIGHTWEIGHT"
else
  pass "GIT-302 Tags are annotated"
fi

# GIT-303 Prod tags immutable (informational)
# Sprawdzamy czy tagi release/baseline nie zostały przesunięte (informational).
info "GIT-303 Prod tags immutable" "Immutability tagów prod wymaga reflog/remote — informacyjnie."

say ""
