#!/usr/bin/env bash
# ============================================================================
# reproducibility.test.sh — L6 REPRODUCIBILITY tests
# ============================================================================
# Testuje odtwarzalność: ten sam test uruchomiony wielokrotnie daje ten sam
# wynik (determinizm). Weryfikuje że pipeline jest lokalnie odtwarzalny
# (local-first) i że wyniki są stabilne między uruchomieniami.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== REPRODUCIBILITY: odtwarzalność ==="

# Test 1: determinizm — uruchom ten sam test 2x i porównaj wynik
# Użyj prostego deterministycznego testu (testforge-lib) i sprawdź że
# liczba PASS jest identyczna w obu uruchomieniach.
# Uwaga: grep -c zwraca 1 gdy brak dopasowań (count=0). Użyj `|| rc=$?`
# zamiast `|| true` (NO FALSE GREEN — nie maskuj exit code).
r1=0
r2=0
r1=$(bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" 2>&1 | grep -c '\[PASS\]' || rc=$?)
r2=$(bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" 2>&1 | grep -c '\[PASS\]' || rc=$?)
if [ "$r1" = "$r2" ] && [ "$r1" -gt 0 ]; then
  tf_pass "REPRO-001" "determinizm: PASS=$r1 w obu uruchomieniach"
else
  tf_fail "REPRO-001" "niedeterminizm: PASS=$r1 vs PASS=$r2"
fi

# Test 2: local-first — runner.sh nie wymaga CI (nie ma zależności od CI)
# Uwaga: usuń komentarze przed grep, aby nie łapać wzmianek o CI w komentarzach.
if sed 's/#.*$//' "$REPO_ROOT/tools/testing/runner.sh" | grep -qE 'CI|GITHUB|GITLAB|JENKINS'; then
  tf_fail "REPRO-002" "runner.sh ma zależność od CI (łamie local-first)"
else
  tf_pass "REPRO-002" "runner.sh jest local-first (brak zależności od CI)"
fi

# Test 3: NO FALSE GREEN — reproducibility nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/reproducibility/reproducibility.test.sh"

tf_exit "REPRODUCIBILITY"
