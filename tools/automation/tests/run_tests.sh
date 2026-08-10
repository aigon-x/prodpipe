#!/usr/bin/env bash
# ============================================================================
# run_tests.sh — Runner testów Pipeline Operating System
# ============================================================================
# Uruchamia wszystkie testy w tools/automation/tests/.
#
# Użycie:
#   ./run_tests.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0; FAIL=0
declare -a FAILED_TESTS=()

echo "=== PIPELINE OPERATING SYSTEM — RUNNER ==="
echo ""

# Uruchom każdy test_*.sh w katalogu tests/.
for test in "$SCRIPT_DIR"/test_*.sh; do
    [ -f "$test" ] || continue
    name="$(basename "$test")"
    echo "────────────────────────────────────────────────────────────"
    echo "RUN: $name"
    echo "────────────────────────────────────────────────────────────"
    if bash "$test"; then
        PASS=$((PASS+1))
        echo "  [PASS] $name"
    else
        FAIL=$((FAIL+1))
        FAILED_TESTS+=("$name")
        echo "  [FAIL] $name"
    fi
    echo ""
done

echo "=== PIPELINE OPERATING SYSTEM — WYNIK ==="
echo "Test files PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
    echo "Nieudane testy:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  - $t"
    done
    exit 1
fi
echo "ALL TESTS PASS"
exit 0
