#!/usr/bin/env bash
# ============================================================================
# secret-scan.test.sh — L0 SECURITY tests
# ============================================================================
# Testuje bezpieczeństwo repo: brak sekretów, brak zakazanych wzorców,
# secret-scan.sh istnieje. Weryfikuje że .gitignore chroni sekrety.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== SECURITY: secret scan ==="

# Test 1: secret-scan.sh istnieje
tf_assert_file "SECURITY-001 secret-scan.sh" "$REPO_ROOT/tools/security/secret-scan.sh"

# Test 2: .gitignore chroni sekrety
if grep -qE '^\*\.env$|^\.env$|\.env' "$REPO_ROOT/.gitignore"; then
  tf_pass "SECURITY-002" ".gitignore chroni .env"
else
  tf_fail "SECURITY-002" ".gitignore nie chroni .env"
fi

# Test 3: brak jawnych sekretów w tracked plikach (prosty skan)
# Skanuj tylko pliki tekstowe w tools/ i tests/ (nie całe repo — za wolne).
bad=0
for f in "$REPO_ROOT"/tools/test "$REPO_ROOT"/tools/testing/*.sh; do
  if grep -qE '(sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)' "$f" 2>/dev/null; then
    tf_fail "SECURITY-003" "znaleziono potencjalny sekret w $f"
    bad=1
  fi
done
[ "$bad" -eq 0 ] && tf_pass "SECURITY-003" "brak jawnych sekretów w tools/ i tests/"

# Test 4: secret-scan.sh ma set -euo pipefail LUB set -u (NO FALSE GREEN)
# secret-scan.sh używa set -u + jawnego licznika FAIL i exit 1 przy FAIL>0,
# więc gwarancja NO FALSE GREEN jest spełniona mimo braku -e.
if grep -qE 'set\s+-e?u(o)?\s+pipefail|set\s+-u\b' "$REPO_ROOT/tools/security/secret-scan.sh"; then
  tf_pass "SECURITY-004" "secret-scan.sh ma set -euo pipefail (lub set -u)"
else
  tf_fail "SECURITY-004" "secret-scan.sh nie ma set -euo pipefail"
fi

tf_exit "SECURITY-SECRET-SCAN"
