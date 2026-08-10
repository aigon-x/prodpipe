#!/usr/bin/env bash
# ============================================================================
# negative.test.sh — L1 NEGATIVE tests
# ============================================================================
# Testuje ścieżki negatywne: system MUSI poprawnie obsłużyć błędne dane
# wejściowe i zwrócić niezerowy exit code (nie cichy sukces). Weryfikuje
# że asercje wykrywają błędy i że runner propaguje FAIL.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== NEGATIVE: ścieżki negatywne ==="

# Test 1: tf_assert_eq wykrywa nierówność (zwraca FAIL)
# Uwaga: asercja oczekiwanej porażki rejestruje FAIL wewnętrznie — uruchamiamy
# ją w subshellu, aby nie zanieczyścić licznika TF_FAIL rodzica.
if ( tf_assert_eq "NEG-001" "a" "b" ) >/dev/null 2>&1; then
  tf_fail "NEG-001" "tf_assert_eq nie wykrył nierówności"
else
  tf_pass "NEG-001" "tf_assert_eq poprawnie wykrywa nierówność"
fi

# Test 2: tf_assert_file wykrywa brak pliku
if ( tf_assert_file "NEG-002" "/nonexistent/path/xyz" ) >/dev/null 2>&1; then
  tf_fail "NEG-002" "tf_assert_file nie wykrył braku pliku"
else
  tf_pass "NEG-002" "tf_assert_file poprawnie wykrywa brak pliku"
fi

# Test 3: tf_assert_contains wykrywa brak wzorca
if ( tf_assert_contains "NEG-003" "$REPO_ROOT/tools/test" "NIEISTNIEJACY_WZORZEC_XYZ" ) >/dev/null 2>&1; then
  tf_fail "NEG-003" "tf_assert_contains nie wykrył braku wzorca"
else
  tf_pass "NEG-003" "tf_assert_contains poprawnie wykrywa brak wzorca"
fi

# Test 4: tf_result z nieznanym statusem = ERROR (nigdy cichy)
if ( tf_result "BOGUS" "NEG-004 nieznany status" ) >/dev/null 2>&1; then
  tf_fail "NEG-004" "nieznany status nie zwrócił ERROR"
else
  tf_pass "NEG-004" "nieznany status poprawnie zwraca ERROR"
fi

# Test 5: NO FALSE GREEN — negative nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/negative/negative.test.sh"

tf_exit "NEGATIVE"
