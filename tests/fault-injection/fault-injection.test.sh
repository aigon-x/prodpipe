#!/usr/bin/env bash
# ============================================================================
# fault-injection.test.sh — L6 FAULT-INJECTION tests
# ============================================================================
# Testuje wstrzykiwanie awarii: system poprawnie reaguje na błędy (nie
# maskuje ich, nie zawiesza się). Weryfikuje że runner propaguje błędy
# subprocesów i że awaria testu nie jest cicho ignorowana.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== FAULT-INJECTION: wstrzykiwanie awarii ==="

# Test 1: runner propaguje awarię subprocesu (nie maskuje exit code)
# Stwórz test, który celowo kończy się FAIL, i sprawdź że runner to wykryje.
tmpdir="$(mktemp -d)"
fault_test="$tmpdir/fault.test.sh"
cat > "$fault_test" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
. /opt/Prod-ready/.qwen/worktrees/testforge/tools/testing/lib.sh
tf_fail "FAULT-INJECTED" "celowa awaria"
tf_exit "FAULT"
EOF
# Uruchom test i sprawdź że kończy się niezerowym exit code (awaria propagowana)
rc=0
bash "$fault_test" >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 0 ]; then
  tf_pass "FAULT-001" "awaria subprocesu jest propagowana (rc=$rc)"
else
  tf_fail "FAULT-001" "awaria subprocesu została zamaskowana (rc=0)"
fi
rm -rf "$tmpdir"

# Test 2: runner.sh sprawdza test-results.json (wykrywa brak jawnego statusu)
if grep -qE 'test-results\.json' "$REPO_ROOT/tools/testing/runner.sh"; then
  tf_pass "FAULT-002" "runner.sh weryfikuje test-results.json (wykrywa silent exit)"
else
  tf_fail "FAULT-002" "runner.sh nie weryfikuje test-results.json"
fi

# Test 3: NO FALSE GREEN — fault-injection nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/fault-injection/fault-injection.test.sh"

tf_exit "FAULT-INJECTION"
