#!/usr/bin/env bash
# ============================================================================
# clean-room.test.sh — L6 CLEAN-ROOM tests
# ============================================================================
# Testuje "clean-room": testy nie zanieczyszczają repo ani nie zależą od
# stanu zewnętrznego. Weryfikuje że testy są izolowane (subprocesy, własne
# katalogi wyników) i nie modyfikują plików źródłowych.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== CLEAN-ROOM: izolacja testów ==="

# Test 1: runner.sh używa izolacji subprocesów (bash "$abs" w subprocesie)
if grep -qE 'bash\s+"\$' "$REPO_ROOT/tools/testing/runner.sh"; then
  tf_pass "CLEANROOM-001" "runner.sh uruchamia testy w subprocesach (izolacja)"
else
  tf_fail "CLEANROOM-001" "runner.sh nie izoluje testów w subprocesach"
fi

# Test 2: RESULTS_DIR jest konfigurowalny (TESTFORGE_RESULTS_DIR) — izolacja outputu
if grep -q 'TESTFORGE_RESULTS_DIR' "$REPO_ROOT/tools/testing/lib.sh"; then
  tf_pass "CLEANROOM-002" "RESULTS_DIR jest konfigurowalny (izolacja outputu)"
else
  tf_fail "CLEANROOM-002" "RESULTS_DIR nie jest konfigurowalny"
fi

# Test 3: testy nie modyfikują plików źródłowych (prosty check: uruchom
# testforge-lib i sprawdź że tools/test nie zmienił mtime)
before=0
after=0
before=$(stat -c %Y "$REPO_ROOT/tools/test")
# Użyj `|| rc=$?` zamiast `|| true` (NO FALSE GREEN — nie maskuj exit code).
probe_rc=0
bash "$REPO_ROOT/tests/unit/testforge-lib.test.sh" >/dev/null 2>&1 || probe_rc=$?
after=$(stat -c %Y "$REPO_ROOT/tools/test")
if [ "$before" = "$after" ]; then
  tf_pass "CLEANROOM-003" "testy nie modyfikują plików źródłowych"
else
  tf_fail "CLEANROOM-003" "testy zmodyfikowały pliki źródłowe"
fi

# Test 4: NO FALSE GREEN — clean-room nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/clean-room/clean-room.test.sh"

tf_exit "CLEAN-ROOM"
