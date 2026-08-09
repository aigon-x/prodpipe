#!/usr/bin/env bash
# repository-integrity.sh — AIGON Production Platform
# STAGE 0 — GIT GENESIS integrity check.
# Sprawdza integralność kanonicznego repozytorium.
# STATUS: FOUNDATION PLACEHOLDER

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
WARN=0

say()  { printf '%s\n' "$*"; }
fail() { say "[FAIL] $*"; FAIL=$((FAIL+1)); }
warn() { say "[WARN] $*"; WARN=$((WARN+1)); }
pass() { say "[PASS] $*"; }

say "=== AIGON repository-integrity ==="

# 1. Git initialized
if [ -d ".git" ]; then pass "Git initialized"; else fail "Git NOT initialized"; fi

# 2. main exists
if git rev-parse --verify main >/dev/null 2>&1; then pass "main exists"; else fail "main missing"; fi

# 3. Working tree state (informational)
if [ -z "$(git status --porcelain)" ]; then
  pass "working tree clean"
else
  warn "working tree has uncommitted changes"
fi

# 4. Required files
for f in .gitignore .gitattributes CODEOWNERS VERSION LICENSE README.md CONTRIBUTING.md SECURITY.md CHANGELOG.md; do
  if [ -f "$f" ]; then pass "required file: $f"; else fail "missing required file: $f"; fi
done

# 5. Required directories
for d in docs governance contracts config deployment tests tools artifacts archive; do
  if [ -d "$d" ]; then pass "required dir: $d"; else fail "missing required dir: $d"; fi
done

# 6. No secrets (delegated to authoritative tools/security/secret-scan.sh)
if bash tools/security/secret-scan.sh >/dev/null 2>&1; then
  pass "no secrets (secret-scan.sh)"
else
  fail "secrets detected (tools/security/secret-scan.sh)"
fi

# 7. No nested git repository
NESTED=$(find . -name .git -not -path "./.git" -not -path "./.git/*" 2>/dev/null)
if [ -n "$NESTED" ]; then
  fail "nested git repository found: $NESTED"
else
  pass "no nested git repositories"
fi

# 8. No legacy code (blocked paths)
for legacy in /opt/aigon /opt/projects/aigon-x /opt/archive/aigon-x; do
  if [ -e "$legacy" ] && [ -d "$REPO_ROOT/$(basename "$legacy")" ]; then
    warn "possible legacy import: $legacy"
  fi
done
pass "legacy import check (informational)"

# 9. No unexpected large files (>50MB)
LARGE=$(find . -type f -size +50M -not -path "./.git/*" 2>/dev/null)
if [ -n "$LARGE" ]; then
  warn "large files found: $LARGE"
else
  pass "no large files"
fi

# 10. No generated runtime state
for pat in "*.log" "*.tmp" "*.temp" "target/" "node_modules/" "dist/" "build/"; do
  if find . -path "./.git" -prune -o -name "$pat" -print 2>/dev/null | grep -q .; then
    warn "generated/runtime state present: $pat"
  fi
done
pass "generated runtime state check (informational)"

say ""
say "=== RESULT ==="
say "FAIL=$FAIL WARN=$WARN"
if [ "$FAIL" -gt 0 ]; then
  say "INTEGRITY: FAIL"
  exit 1
else
  say "INTEGRITY: PASS"
  exit 0
fi
