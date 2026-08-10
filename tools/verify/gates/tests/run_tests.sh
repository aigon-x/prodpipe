#!/usr/bin/env bash
# ============================================================================
# run_tests.sh — RUNNER dla wszystkich testów negatywnych gate'ów
# ============================================================================
# Uruchamia wszystkie testy negatywne w katalogu tests/ i raportuje wynik.
# Każdy test MUSI zwrócić 0 (PASS) lub 1 (FAIL). Testy są REALNE — wykrywają
# problemy (nie są puste, nie są false green).
#
# Użycie: ./run_tests.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"

TOTAL=0; PASSED=0; FAILED=0; SKIPPED=0

echo "=== GATE NEGATIVE TESTS RUNNER ==="
echo ""

# Uruchamiamy każdy test_*.sh w katalogu tests/.
for test_file in "$TESTS_DIR"/test_*.sh; do
    [ -f "$test_file" ] || continue
    name="$(basename "$test_file")"
    TOTAL=$((TOTAL+1))
    echo "--- Running: $name ---"
    if bash "$test_file"; then
        PASSED=$((PASSED+1))
        echo "  [SUITE PASS] $name"
    else
        FAILED=$((FAILED+1))
        echo "  [SUITE FAIL] $name"
    fi
    echo ""
done

echo "=== WYNIK ==="
echo "Total: $TOTAL  Passed: $PASSED  Failed: $FAILED  Skipped: $SKIPPED"
if [ "$FAILED" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
    echo "ALL TEST SUITES PASS"
    exit 0
else
    echo "TEST SUITES FAILED"
    exit 1
fi
