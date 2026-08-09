#!/usr/bin/env bash
# secret-scan.sh — AIGON Production Platform
# STAGE 0 — GIT GENESIS secret scanner.
# Wykrywa sekrety (API keys, private keys, tokens, credentials) w repozytorium.
# Preferuje istniejące narzędzia (gitleaks, trufflehog, git-secrets) — fallback do heurystyk.
# STATUS: FOUNDATION PLACEHOLDER

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

FAIL=0
SCAN_MODE=""

say()  { printf '%s\n' "$*"; }
fail() { say "[FAIL] $*"; FAIL=$((FAIL+1)); }
pass() { say "[PASS] $*"; }

# --- Detect available tools (prefer existing scanners) ---
if command -v gitleaks >/dev/null 2>&1; then
  SCAN_MODE="gitleaks"
elif command -v trufflehog >/dev/null 2>&1; then
  SCAN_MODE="trufflehog"
elif command -v git-secrets >/dev/null 2>&1; then
  SCAN_MODE="git-secrets"
else
  SCAN_MODE="heuristic"
fi

say "=== AIGON secret-scan (mode: $SCAN_MODE) ==="

case "$SCAN_MODE" in
  gitleaks)
    if gitleaks detect --source "$REPO_ROOT" --no-banner; then
      pass "gitleaks: no secrets found"
    else
      fail "gitleaks: secrets detected"
    fi
    ;;
  trufflehog)
    if trufflehog git --no-update "$REPO_ROOT" >/dev/null 2>&1; then
      pass "trufflehog: no secrets found"
    else
      fail "trufflehog: secrets detected"
    fi
    ;;
  git-secrets)
    git secrets --scan 2>/dev/null && pass "git-secrets: no secrets found" || fail "git-secrets: secrets detected"
    ;;
  heuristic)
    say "No dedicated scanner found — using heuristic fallback."
    # API keys / tokens / secrets assignments
    if grep -rInE '(api[_-]?key|secret|password|passwd|token|auth[_-]?token|access[_-]?key|private[_-]?key)\s*[:=]\s*["'"'"'][A-Za-z0-9_\-]{16,}["'"'"']' \
        --exclude-dir=.git --exclude-dir=.git-hooks --exclude-dir=.github \
        --exclude='*.md' --exclude='*.sh' . 2>/dev/null | grep -q .; then
      fail "possible hardcoded secrets (assignments)"
    else
      pass "no hardcoded secret assignments"
    fi
    # Private keys
    if grep -rIlE 'BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY' \
        --exclude-dir=.git --exclude-dir=.git-hooks . 2>/dev/null | grep -q .; then
      fail "private keys found"
    else
      pass "no private keys"
    fi
    # Cloud credentials (AWS)
    if grep -rInE 'AKIA[0-9A-Z]{16}' --exclude-dir=.git . 2>/dev/null | grep -q .; then
      fail "AWS access key found"
    else
      pass "no AWS access keys"
    fi
    # JWT
    if grep -rInE 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' --exclude-dir=.git . 2>/dev/null | grep -q .; then
      fail "JWT token found"
    else
      pass "no JWT tokens"
    fi
    ;;
esac

say ""
say "=== RESULT ==="
if [ "$FAIL" -gt 0 ]; then
  say "SECRET-SCAN: FAIL"
  exit 1
else
  say "SECRET-SCAN: PASS"
  exit 0
fi
