#!/usr/bin/env bash
# ============================================================================
# testforge-lib.test.sh — L1 UNIT tests for TESTFORGE core library
# ============================================================================
# Testuje funkcje lib.sh: tf_result, tf_assert_eq, tf_assert_rc,
# tf_assert_file, tf_assert_dir, tf_assert_contains, tf_no_false_green.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== UNIT: testforge lib ==="

# Test 1: tf_assert_eq — równość
tf_assert_eq "LIB-001 tf_assert_eq równość" "abc" "abc"

# Test 2: tf_assert_eq — nierówność (oczekiwany FAIL)
# Uruchom w subshellu, aby wewnętrzny FAIL (rejestrowany przez tf_assert_eq)
# nie zanieczyszczał licznika TF_FAIL bieżącego testu.
if ( tf_assert_eq "LIB-002 tf_assert_eq nierówność" "abc" "xyz" ) >/dev/null 2>&1; then
  tf_fail "LIB-002" "tf_assert_eq zwrócił PASS dla nierównych wartości"
else
  tf_pass "LIB-002" "tf_assert_eq poprawnie wykrył nierówność"
fi

# Test 3: tf_assert_rc — exit code 0
tf_assert_rc "LIB-003 tf_assert_rc 0" 0 0

# Test 4: tf_assert_rc — exit code 1 vs oczekiwane 0
if ( tf_assert_rc "LIB-004 tf_assert_rc 1" 1 0 ) >/dev/null 2>&1; then
  tf_fail "LIB-004" "tf_assert_rc zwrócił PASS dla rc=1 oczekiwano 0"
else
  tf_pass "LIB-004" "tf_assert_rc poprawnie wykrył rc=1"
fi

# Test 5: tf_assert_file — istniejący plik
tf_assert_file "LIB-005 tf_assert_file" "$REPO_ROOT/tools/test"

# Test 6: tf_assert_dir — istniejący katalog
tf_assert_dir "LIB-006 tf_assert_dir" "$REPO_ROOT/tools/testing"

# Test 7: tf_assert_contains — wzorzec w pliku
tf_assert_contains "LIB-007 tf_assert_contains" "$REPO_ROOT/tools/test" "set -euo pipefail"

# Test 8: tf_no_false_green — czysty plik
tf_no_false_green "$REPO_ROOT/tools/test"

# Test 9: tf_result rejestruje liczniki
before=$TF_TOTAL
tf_result PASS "LIB-009 tf_result PASS"
if [ "$TF_TOTAL" -eq $((before + 1)) ]; then
  tf_pass "LIB-009" "tf_result inkrementuje TF_TOTAL"
else
  tf_fail "LIB-009" "tf_result nie inkrementuje TF_TOTAL"
fi

# Test 10: tf_result FAIL zwraca rc=1
if ( tf_result FAIL "LIB-010 tf_result FAIL" ) >/dev/null 2>&1; then
  tf_fail "LIB-010" "tf_result FAIL zwrócił rc=0"
else
  tf_pass "LIB-010" "tf_result FAIL zwraca rc=1"
fi

tf_exit "TESTFORGE-LIB"
