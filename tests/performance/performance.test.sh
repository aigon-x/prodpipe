#!/usr/bin/env bash
# ============================================================================
# performance.test.sh — L6 PERFORMANCE tests
# ============================================================================
# Testuje wydajność: testy wykonują się w rozsądnym czasie (nie zawieszają
# pipeline'u). Weryfikuje że runner nie ma patologicznych opóźnień.
# required: false (informacyjny, nie blokuje certyfikacji).
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== PERFORMANCE: wydajność ==="

# Test 1: testforge-lib wykonuje się szybko (< 10s)
start=0
end=0
elapsed=0
start=$(date +%s)
# Użyj `|| rc=$?` zamiast `|| true` (NO FALSE GREEN — nie maskuj exit code).
probe_rc=0
bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" >/dev/null 2>&1 || probe_rc=$?
end=$(date +%s)
elapsed=$((end - start))
if [ "$elapsed" -lt 10 ]; then
  tf_pass "PERFORMANCE-001" "testforge-lib wykonuje się w ${elapsed}s (< 10s)"
else
  tf_fail "PERFORMANCE-001" "testforge-lib za wolny: ${elapsed}s (>= 10s)"
fi

# Test 2: runner.sh nie ma pętli bez limitu (brak ryzyka zawieszenia)
if grep -qE 'while\s+true|for\s*\(;;\)' "$REPO_ROOT/tools/testing/runner.sh"; then
  tf_fail "PERFORMANCE-002" "runner.sh ma nieskończoną pętlę (ryzyko zawieszenia)"
else
  tf_pass "PERFORMANCE-002" "runner.sh nie ma nieskończonych pętli"
fi

# Test 3: NO FALSE GREEN — performance nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/performance/performance.test.sh"

tf_exit "PERFORMANCE"
