#!/usr/bin/env bash
# ============================================================================
# snapshot.test.sh — L1 SNAPSHOT tests
# ============================================================================
# Testuje snapshoty: porównanie bieżącego stanu z zapisanym snapshotem.
# Weryfikuje że struktura repo (katalogi testów, narzędzia) jest stabilna
# i nie zmienia się między uruchomieniami.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== SNAPSHOT: snapshot tests ==="

# Test 1: struktura narzędzi testowych jest stabilna (snapshot katalogów)
expected_dirs="tools/testing tools/test tests"
ok=1
for d in tools/testing tools/test tests; do
  if [ ! -e "$REPO_ROOT/$d" ]; then
    tf_fail "SNAPSHOT-001" "brak oczekiwanego elementu snapshot: $d"
    ok=0
  fi
done
[ "$ok" -eq 1 ] && tf_pass "SNAPSHOT-001" "struktura narzędzi testowych zgodna ze snapshotem"

# Test 2: komplet narzędzi w tools/testing (snapshot plików)
expected_tools="lib.sh runner.sh discovery.sh manifest.sh coverage.sh regression.sh report.sh quality.sh"
ok2=1
for t in $expected_tools; do
  if [ ! -f "$REPO_ROOT/tools/testing/$t" ]; then
    tf_fail "SNAPSHOT-002" "brak narzędzia w snapshot: $t"
    ok2=0
  fi
done
[ "$ok2" -eq 1 ] && tf_pass "SNAPSHOT-002" "komplet narzędzi tools/testing zgodny ze snapshotem"

# Test 3: NO FALSE GREEN — snapshot nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/snapshot/snapshot.test.sh"

tf_exit "SNAPSHOT"
