#!/usr/bin/env bash
# ============================================================================
# meta.test.sh — L6 META tests (testy testów)
# ============================================================================
# Testuje sam system testowy (self-testing): weryfikuje że narzędzia
# testowe działają poprawnie, że nie ma false green, że każdy test kończy
# się jawnym statusem i produkuje test-results.json.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== META: testy testów (self-testing) ==="

# Test 1: każdy plik testowy kończy się tf_exit (produkuje test-results.json)
missing_exit=0
count=0
while IFS= read -r testfile; do
  [ -z "$testfile" ] && continue
  count=$((count + 1))
  if ! grep -q 'tf_exit' "$testfile"; then
    tf_fail "META-001" "test $testfile nie kończy się tf_exit (brak jawnego statusu)"
    missing_exit=1
  fi
done < <(find "$REPO_ROOT/tests" -name '*.test.sh' | sort)
[ "$missing_exit" -eq 0 ] && tf_pass "META-001" "wszystkie $count testów kończą się tf_exit"

# Test 2: każdy plik testowy ma set -euo pipefail (NO FALSE GREEN)
missing_set=0
while IFS= read -r testfile; do
  [ -z "$testfile" ] && continue
  if ! grep -q 'set -euo pipefail' "$testfile"; then
    tf_fail "META-002" "test $testfile nie ma set -euo pipefail"
    missing_set=1
  fi
done < <(find "$REPO_ROOT/tests" -name '*.test.sh' | sort)
[ "$missing_set" -eq 0 ] && tf_pass "META-002" "wszystkie testy mają set -euo pipefail"

# Test 3: żaden test nie zawiera zakazanych wzorców (|| true, set +e)
# Uwaga: usuwa komentarze, literały stringowe ORAZ zawartość heredoc przed
# grep, aby nie łapać fałszywych trafień (np. komentarze wyjaśniające
# '|| true' albo payload heredoc w testach mutacyjnych).
forbidden=0
while IFS= read -r testfile; do
  [ -z "$testfile" ] && continue
  # awk: usuń bloki heredoc (<<'EOF' ... EOF), potem sed usuwa komentarze
  # i literały stringowe.
  if awk '
    /<<.?EOF/ { in_heredoc=1; next }
    in_heredoc && /^[[:space:]]*EOF/ { in_heredoc=0; next }
    in_heredoc { next }
    { print }
  ' "$testfile" | sed 's/#.*$//; s/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g' | grep -qE '\|\|\s*true\b|^\s*set\s+\+e\b|continue-on-error'; then
    tf_fail "META-003" "test $testfile zawiera zakazany wzorzec (false green)"
    forbidden=1
  fi
done < <(find "$REPO_ROOT/tests" -name '*.test.sh' | sort)
[ "$forbidden" -eq 0 ] && tf_pass "META-003" "żaden test nie zawiera zakazanych wzorców"

# Test 4: NO FALSE GREEN — meta nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/meta/meta.test.sh"

tf_exit "META"
