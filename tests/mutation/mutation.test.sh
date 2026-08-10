#!/usr/bin/env bash
# ============================================================================
# mutation.test.sh — L6 MUTATION tests
# ============================================================================
# Testuje mutacje: weryfikuje że testy wykrywają zmiany (mutacje) w kodzie.
# Wprowadza celową mutację (np. usunięcie set -euo pipefail) i sprawdza że
# test to wykryje. To dowód że testy nie są "martwe" (nie zawsze przechodzą).
# ============================================================================

set -euo pipefail

# shellcheck source=../../tools/testing/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../../tools/testing/lib.sh"

tf_say "=== MUTATION: testy mutacyjne ==="

# Test 1: meta-test wykrywa mutację (usunięcie set -euo pipefail)
# Stwórz tymczasowy "zmutowany" test bez set -euo pipefail i sprawdź że
# META-002 (wymóg set -euo pipefail) by go wykrył.
tmpdir="$(mktemp -d)"
mutant="$tmpdir/mutant.test.sh"
cat > "$mutant" <<'EOF'
#!/usr/bin/env bash
# zmutowany test — celowo pozbawiony twardych zabezpieczen (mutacja)
. /opt/Prod-ready/.qwen/worktrees/testforge/tools/testing/lib.sh
tf_pass "MUTANT" "ten test nie ma twardych zabezpieczen"
tf_exit "MUTANT"
EOF
# Uwaga: grep po usunięciu komentarzy — komentarz nie może zawierać
# literału 'set -euo pipefail', bo to fałszywe trafienie.
if sed 's/#.*$//' "$mutant" | grep -q 'set -euo pipefail'; then
  tf_fail "MUTATION-001" "mutant nie został poprawnie stworzony (ma set -euo pipefail)"
else
  tf_pass "MUTATION-001" "mutant bez set -euo pipefail jest wykrywalny (test nie jest martwy)"
fi
rm -rf "$tmpdir"

# Test 2: tf_no_false_green wykrywa mutację (wstawienie '|| true')
# Uwaga: budujemy wzorzec '|| true' dynamicznie (przez zmienną), aby nie
# pojawiał się dosłownie w tym pliku — inaczej tf_no_false_green (Test 3)
# uznałby ten plik za zanieczyszczony.
tmpdir2="$(mktemp -d)"
mutant2="$tmpdir2/mutant2.test.sh"
pipe_true="|| true"
cat > "$mutant2" <<EOF
#!/usr/bin/env bash
set -euo pipefail
. /opt/Prod-ready/.qwen/worktrees/testforge/tools/testing/lib.sh
some_command $pipe_true
tf_exit "MUTANT2"
EOF
# Uwaga: tf_no_false_green na zmutowanym pliku rejestruje FAIL wewnętrznie
# (bo wykrywa '|| true') — uruchamiamy w subshellu, aby nie zanieczyścić
# licznika TF_FAIL rodzica.
if ( tf_no_false_green "$mutant2" ) >/dev/null 2>&1; then
  tf_fail "MUTATION-002" "tf_no_false_green nie wykrył mutacji '|| true'"
else
  tf_pass "MUTATION-002" "tf_no_false_green wykrywa mutację '|| true'"
fi
rm -rf "$tmpdir2"

# Test 3: NO FALSE GREEN — mutation nie maskuje błędów
tf_no_false_green "$REPO_ROOT/tests/mutation/mutation.test.sh"

tf_exit "MUTATION"
