#!/usr/bin/env bash
# ============================================================================
# drift.test.sh — L4 DRIFT tests
# ============================================================================
# Testuje wykrywanie dryfu konfiguracji: porównanie stanu deklarowanego
# (manifest/config) ze stanem faktycznym (pliki na dysku). Weryfikuje że
# system potrafi wykryć rozjazd między oczekiwanym a rzeczywistym stanem.
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== DRIFT: wykrywanie dryfu ==="

# Test 1: manifest.yaml istnieje (stan deklarowany)
tf_assert_file "DRIFT-001 manifest.yaml istnieje" "$REPO_ROOT/tests/manifest.yaml"

# Test 2: każdy test z manifestu ma odpowiadający plik (brak dryfu ścieżek)
missing=0
while IFS= read -r path; do
  [ -z "$path" ] && continue
  if [ ! -f "$REPO_ROOT/$path" ]; then
    tf_fail "DRIFT-002" "dryf: manifest wskazuje na brakujący plik $path"
    missing=1
  fi
done < <(grep -E '^\s+path:' "$REPO_ROOT/tests/manifest.yaml" | awk '{print $2}')
[ "$missing" -eq 0 ] && tf_pass "DRIFT-002" "wszystkie ścieżki z manifestu istnieją (brak dryfu)"

# Test 3: coverage-matrix.yaml istnieje
tf_assert_file "DRIFT-003 coverage-matrix.yaml istnieje" "$REPO_ROOT/tests/coverage-matrix.yaml"

# Test 4: każdy komponent z coverage-matrix ma testy na deklarowanych poziomach
# (prosty skan: dla każdego komponentu sprawdź czy istnieje katalog testów
#  LUB plik testowy pasujący do nazwy komponentu — komponenty 'state' i
#  'verify' mają testy w tests/unit/ i tests/contract/, nie w dedykowanych
#  katalogach, więc wymaganie katalogu byłoby zbyt restrykcyjne)
comp_missing=0
while IFS= read -r comp; do
  [ -z "$comp" ] && continue
  # katalog testów LUB plik testowy pasujący do nazwy komponentu
  if [ ! -d "$REPO_ROOT/tests/$comp" ] && \
     ! find "$REPO_ROOT/tests" -type f -name "${comp}*.test.sh" | grep -q .; then
    tf_fail "DRIFT-004" "dryf: komponent '$comp' z coverage-matrix nie ma testów"
    comp_missing=1
  fi
done < <(grep -E '^\s+- name:' "$REPO_ROOT/tests/coverage-matrix.yaml" | awk '{print $3}')
[ "$comp_missing" -eq 0 ] && tf_pass "DRIFT-004" "wszystkie komponenty z coverage-matrix mają testy"

# Test 5: NO FALSE GREEN — test nie maskuje exit code
tf_no_false_green "$REPO_ROOT/tests/drift/drift.test.sh"

tf_exit "DRIFT"
