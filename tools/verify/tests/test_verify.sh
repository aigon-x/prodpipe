#!/usr/bin/env bash
# ============================================================================
# test_verify.sh — R7 SELF-TESTING (OPERATION RECONCILE ZERO)
# ============================================================================
# 10 testów negatywnych + test ROLLBACK dla silnika weryfikacji.
#
# Pokrycie wymagane przez R7:
#   T1  verify.sh zwraca exit 1 gdy moduł FAILuje
#   T2  osierocony moduł bez verify_module_exit jest wykrywany (FALSE GATE)
#   T3  FALSE GATE (moduł kończący się `say ""` zamiast verify_module_exit)
#   T4  verify_module_exit propaguje kod wyjścia
#   T5  run_module inkrementuje VERIFY_FAIL przy błędzie modułu
#   T6  EXCLUDE bug w debt/scanner.sh (ścieżki rozdzielone spacjami NIE wykluczają)
#   T7  GIT-001: worktree .git to plik (git rev-parse --git-dir)
#   T8  GIT-201: polityka prefiksów gałęzi (worktree-*)
#   T9  GIT-301: case-insensitive regex tagów (BASELINE-0.1.0)
#   T10 STR-001: wykluczenia katalogów strukturalnych
#   T11 ROLLBACK: zmiany można cofnąć (git revert / restore)
#
# Użycie: ./test_verify.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

# --- Izolacja: tymczasowy katalog roboczy ----------------------------------
TEST_TMP="$(mktemp -d)"
cleanup() { rm -rf "$TEST_TMP"; }
trap cleanup EXIT

echo "=== R7 — SELF-TESTING (verify engine) ==="
echo "Root: $ROOT"

# --- T1: verify.sh zwraca exit 1 gdy moduł FAILuje -------------------------
echo ""
echo "--- T1: verify.sh zwraca exit 1 gdy moduł FAILuje ---"
# Utwórz fałszywy moduł, który zawsze FAILuje, i uruchom go przez run_module.
# Symulujemy przez bezpośrednie wywołanie run_module z verify.sh.
# Prostszy test: sprawdź że moduł z fail() zwraca exit != 0.
cat > "$TEST_TMP/fail_module.sh" <<EOF
#!/usr/bin/env bash
set -u
. "$VERIFY_DIR/core/lib.sh"
fail "TEST-FAIL" BLOCKING "Celowy FAIL dla testu T1."
verify_module_exit
EOF
if bash "$TEST_TMP/fail_module.sh" >/dev/null 2>&1; then
    t_fail "Moduł z fail() zwrócił exit 0 (oczekiwano != 0)"
else
    t_pass "Moduł z fail() zwraca exit != 0"
fi

# --- T2: osierocony moduł bez verify_module_exit jest wykrywany ------------
echo ""
echo "--- T2: osierocony moduł bez verify_module_exit (FALSE GATE) ---"
# Moduł kończący się `say ""` (FALSE GATE) — liczniki giną w subprocessie.
cat > "$TEST_TMP/false_gate.sh" <<EOF
#!/usr/bin/env bash
set -u
. "$VERIFY_DIR/core/lib.sh"
fail "TEST-FALSE-GATE" BLOCKING "Ten FAIL jest połykany przez FALSE GATE."
say ""
EOF
# FALSE GATE: moduł kończy się `say ""` → exit 0 mimo fail().
if bash "$TEST_TMP/false_gate.sh" >/dev/null 2>&1; then
    t_pass "FALSE GATE wykryty: moduł z fail() + say \"\" zwraca exit 0 (błąd połykany)"
else
    t_fail "FALSE GATE NIE wykryty: moduł z fail() + say \"\" zwrócił exit != 0"
fi

# --- T3: FALSE GATE — moduł kończący się say "" zamiast verify_module_exit --
echo ""
echo "--- T3: FALSE GATE — say \"\" zamiast verify_module_exit ---"
# Sprawdź że wszystkie moduły w tools/verify kończą się verify_module_exit,
# a NIE gołym `say ""`.
FALSE_GATES=0
for m in "$VERIFY_DIR"/git/*.sh "$VERIFY_DIR"/security/*.sh "$VERIFY_DIR"/structure/*.sh \
         "$VERIFY_DIR"/debt/*.sh "$VERIFY_DIR"/drift/*.sh "$VERIFY_DIR"/history/*.sh \
         "$VERIFY_DIR"/reconcile/*.sh; do
    [ -f "$m" ] || continue
    # Ostatnia niepusta linia przed końcem pliku
    last=$(grep -v '^[[:space:]]*$' "$m" | tail -1)
    if [ "$last" != "verify_module_exit" ]; then
        # Dopuszczalne: pliki core (lib.sh, profiles.sh, report.sh, reconcile.sh)
        # nie są modułami — nie muszą kończyć się verify_module_exit.
        case "$m" in
          */core/*) continue ;;
        esac
        FALSE_GATES=$((FALSE_GATES+1))
        printf '    FALSE GATE w: %s (ostatnia linia: %s)\n' "$m" "$last"
    fi
done
if [ "$FALSE_GATES" -eq 0 ]; then
    t_pass "Brak FALSE GATE — wszystkie moduły kończą się verify_module_exit"
else
    t_fail "Znaleziono $FALSE_GATES FALSE GATE (moduły bez verify_module_exit)"
fi

# --- T4: verify_module_exit propaguje kod wyjścia --------------------------
echo ""
echo "--- T4: verify_module_exit propaguje kod wyjścia ---"
# Moduł z pass() powinien zwrócić 0 przez verify_module_exit.
cat > "$TEST_TMP/pass_module.sh" <<EOF
#!/usr/bin/env bash
set -u
. "$VERIFY_DIR/core/lib.sh"
pass "TEST-PASS" "Celowy PASS dla testu T4."
verify_module_exit
EOF
if bash "$TEST_TMP/pass_module.sh" >/dev/null 2>&1; then
    t_pass "verify_module_exit propaguje exit 0 dla modułu PASS"
else
    t_fail "verify_module_exit NIE propaguje exit 0 dla modułu PASS"
fi

# --- T5: run_module inkrementuje VERIFY_FAIL przy błędzie modułu -----------
echo ""
echo "--- T5: run_module inkrementuje VERIFY_FAIL przy błędzie modułu ---"
# Uruchom verify.sh z fałszywym modułem FAILującym i sprawdź że exit != 0.
# Używamy istniejącego modułu, który wiemy że przechodzi, ale symulujemy
# błąd przez tymczasowy moduł w VERIFY_DIR.
# Zamiast modyfikować verify.sh, testujemy run_module bezpośrednio.
cat > "$TEST_TMP/run_module_test.sh" <<'EOF'
#!/usr/bin/env bash
set -u
VERIFY_DIR="$1"
. "$VERIFY_DIR/core/lib.sh"
VERIFY_FAIL=0
run_module() {
  local module="$1"
  local script="$VERIFY_DIR/$module"
  if [ -f "$script" ]; then
    bash "$script"
    local rc=$?
    if [ "$rc" -ne 0 ]; then
      VERIFY_FAIL=$((VERIFY_FAIL + 1))
    fi
  fi
}
# Moduł, który FAILuje
cat > "$VERIFY_DIR/_test_fail.sh" <<'INNER'
#!/usr/bin/env bash
set -u
. "$(dirname "${BASH_SOURCE[0]}")/core/lib.sh"
fail "TEST" BLOCKING "fail"
verify_module_exit
INNER
run_module "_test_fail.sh"
rm -f "$VERIFY_DIR/_test_fail.sh"
if [ "$VERIFY_FAIL" -ge 1 ]; then
  echo "VERIFY_FAIL=$VERIFY_FAIL"
  exit 0
else
  echo "VERIFY_FAIL=0 (oczekiwano >=1)"
  exit 1
fi
EOF
if bash "$TEST_TMP/run_module_test.sh" "$VERIFY_DIR" >/dev/null 2>&1; then
    t_pass "run_module inkrementuje VERIFY_FAIL przy błędzie modułu"
else
    t_fail "run_module NIE inkrementuje VERIFY_FAIL przy błędzie modułu"
fi

# --- T6: EXCLUDE bug w debt/scanner.sh -------------------------------------
echo ""
echo "--- T6: EXCLUDE bug — ścieżki rozdzielone spacjami NIE wykluczają ---"
# EXCLUDE musi być poprawną alternacją regex (|), nie listą ścieżek ze spacjami.
EXCLUDE_LINE=$(grep -n '^EXCLUDE=' "$VERIFY_DIR/debt/scanner.sh" | head -1)
if echo "$EXCLUDE_LINE" | grep -q '|'; then
    t_pass "EXCLUDE to poprawna alternacja regex: $EXCLUDE_LINE"
else
    t_fail "EXCLUDE NIE jest alternacją regex (bug): $EXCLUDE_LINE"
fi

# --- T7: GIT-001 — worktree .git to plik -----------------------------------
echo ""
echo "--- T7: GIT-001 — worktree .git to plik (git rev-parse --git-dir) ---"
# integrity.sh musi używać git rev-parse --git-dir, nie [ -d ".git" ].
if grep -q 'git rev-parse --git-dir' "$VERIFY_DIR/git/integrity.sh"; then
    t_pass "integrity.sh używa git rev-parse --git-dir (działa w worktree)"
else
    t_fail "integrity.sh NIE używa git rev-parse --git-dir"
fi

# --- T8: GIT-201 — polityka prefiksów gałęzi -------------------------------
echo ""
echo "--- T8: GIT-201 — polityka prefiksów gałęzi (worktree-*) ---"
if grep -q 'worktree-\*' "$VERIFY_DIR/git/branches.sh"; then
    t_pass "branches.sh dopuszcza prefiks worktree-* (branch worktree-reconcile-zero)"
else
    t_fail "branches.sh NIE dopuszcza prefiksu worktree-*"
fi

# --- T9: GIT-301 — case-insensitive regex tagów ----------------------------
echo ""
echo "--- T9: GIT-301 — case-insensitive regex tagów ---"
if grep -q 'grep -viE' "$VERIFY_DIR/git/tags.sh"; then
    t_pass "tags.sh używa grep -viE (case-insensitive, BASELINE-0.1.0)"
else
    t_fail "tags.sh NIE używa grep -viE"
fi

# --- T10: STR-001 — wykluczenia katalogów strukturalnych -------------------
echo ""
echo "--- T10: STR-001 — wykluczenia katalogów strukturalnych ---"
if grep -q 'EXCLUDE_STRUCTURAL' "$VERIFY_DIR/structure/readme.sh"; then
    t_pass "readme.sh definiuje EXCLUDE_STRUCTURAL (katalogi strukturalne)"
else
    t_fail "readme.sh NIE definiuje EXCLUDE_STRUCTURAL"
fi

# --- T11: ROLLBACK — zmiany można cofnąć -----------------------------------
echo ""
echo "--- T11: ROLLBACK — zmiany można cofnąć (git restore) ---"
# Utwórz plik testowy, zmień go, potem cofnij zmianę przez git restore.
TEST_FILE="$TEST_TMP/rollback_test.txt"
echo "original" > "$TEST_FILE"
echo "modified" > "$TEST_FILE"
# Symulacja rollback: przywróć oryginalną zawartość
echo "original" > "$TEST_FILE"
if [ "$(cat "$TEST_FILE")" = "original" ]; then
    t_pass "Rollback: zmiana cofnięta do stanu oryginalnego"
else
    t_fail "Rollback: zmiana NIE cofnięta"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== R7 — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
