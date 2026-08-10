#!/usr/bin/env bash
# ============================================================================
# verify.test.sh — L3 CONTRACT tests (verify engine)
# ============================================================================
# Testuje kontrakty verify engine (tools/verify/verify.sh). Weryfikuje że
# verify.sh istnieje, ma poprawne subkomendy, i że moduły kończą się
# verify_module_exit (nie cichym exit).
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

VERIFY_SH="$REPO_ROOT/tools/verify/verify.sh"

tf_say "=== CONTRACT: verify engine ==="

# Test 1: verify.sh istnieje
tf_assert_file "CONTRACT-001 verify.sh istnieje" "$VERIFY_SH"

# Test 2: verify.sh ma set -u (kontrakt)
if grep -q '^set -u$' "$VERIFY_SH"; then
  tf_pass "CONTRACT-002" "verify.sh ma set -u"
else
  tf_fail "CONTRACT-002" "verify.sh nie ma set -u"
fi

# Test 3: verify.sh ma subkomendy reconcile/drift/history/debt
for sub in reconcile drift history debt; do
  if grep -q "run_module \"$sub" "$VERIFY_SH" || grep -q "^\s*$sub)" "$VERIFY_SH"; then
    tf_pass "CONTRACT-003 $sub" "subkomenda $sub zdefiniowana"
  else
    tf_fail "CONTRACT-003 $sub" "brak subkomendy $sub"
  fi
done

# Test 4: aktywne moduły kończą się verify_module_exit (nie cichym exit)
active_modules="reconcile/baseline.sh reconcile/reconcile.sh drift/drift.sh history/history.sh debt/scanner.sh debt/debt.sh"
for m in $active_modules; do
  mod="$REPO_ROOT/tools/verify/$m"
  if [ -f "$mod" ]; then
    if grep -q 'verify_module_exit' "$mod"; then
      tf_pass "CONTRACT-004 $m" "moduł kończy się verify_module_exit"
    else
      tf_fail "CONTRACT-004 $m" "moduł NIE kończy się verify_module_exit (FALSE GATE)"
    fi
  else
    tf_fail "CONTRACT-004 $m" "brak modułu"
  fi
done

# Test 5: verify.sh uruchamia się (help/nieznana subkomenda zwraca 2)
if bash "$VERIFY_SH" nonexistent-subcommand >/dev/null 2>&1; then
  tf_fail "CONTRACT-005" "verify.sh z nieznaną subkomendą zwrócił 0"
else
  tf_pass "CONTRACT-005" "verify.sh z nieznaną subkomendą zwraca != 0"
fi

# Test 6: verify.sh ma jawny exit code (kończy się exit $?)
if grep -q 'exit \$?' "$VERIFY_SH"; then
  tf_pass "CONTRACT-006" "verify.sh propaguje exit code"
else
  tf_fail "CONTRACT-006" "verify.sh nie propaguje exit code"
fi

tf_exit "CONTRACT-VERIFY"
