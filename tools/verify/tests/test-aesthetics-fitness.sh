#!/usr/bin/env bash
# ============================================================================
# test-aesthetics-fitness.sh — AESTHETICS PLANE — CONS-01 golden path fitness
# ============================================================================
# Weryfikuje moduł tools/verify/aesthetics/fitness.sh:
#   T1: golden-path.yaml jest poprawnie parsowany (moduł działa bez błędu)
#   T2: fitness.sh poprawnie wykrywa targety w przykładowym katalogu z kodem
#   T3: fail-closed — katalog z kodem bez targetów → CONS-01-02 FAIL
#   T4: layout — katalog serwisu bez standardowego layoutu → CONS-01-01 FAIL
#   T5: golden path score — pełna conformance → PASS (exit 0)
#
# Testy są IZOLOWANE: tworzą własny katalog tymczasowy z git + golden-path.yaml
# + przykładowe katalogi serwisów/kodu, więc nie dotykają prawdziwego repo
# ani równoległej pracy innych subagentów.
#
# Użycie: ./test-aesthetics-fitness.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
FITNESS_SH="$VERIFY_DIR/aesthetics/fitness.sh"
GOLDEN_PATH_SRC="$VERIFY_DIR/../../config/aesthetics/golden-path.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== AESTHETICS FITNESS (CONS-01) TESTS ==="

# ── Helper: buduje izolowany katalog z git + golden-path.yaml ──────────────
# Argumenty: <katalog_docelowy>
# Tworzy git repo, kopiuje golden-path.yaml, zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  cp "$GOLDEN_PATH_SRC" "$dir/config/aesthetics/golden-path.yaml" 2>/dev/null \
    || { mkdir -p "$dir/config/aesthetics"; cp "$GOLDEN_PATH_SRC" "$dir/config/aesthetics/golden-path.yaml"; }
  # git ls-files wymaga, żeby pliki były śledzone — dodajemy wszystko.
  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: golden-path.yaml jest poprawnie parsowany ──────────────────────────
echo ""
echo "--- T1: golden-path.yaml jest poprawnie parsowany ---"
# Uruchamiamy fitness.sh na pustym repo (tylko golden-path.yaml + README root).
# Brak serwisów i kodu → moduł powinien zakończyć się PASS (exit 0), bo
# conformance jest vacuously true (brak wymagań = brak odstępstw).
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null
# Root README (żeby repo nie było puste dla git).
echo "# test" > "$T1_DIR/README.md"
( cd "$T1_DIR" && git add -A 2>/dev/null )

T1_OUT="$(cd "$T1_DIR" && bash "$FITNESS_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] && printf '%s' "$T1_OUT" | grep -q "CONS-01-01 Layout projektu"; then
  t_pass "golden-path.yaml poprawnie sparsowany (moduł wykonał checki, rc=$T1_RC)"
else
  t_fail "golden-path.yaml NIE sparsowany poprawnie (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -20
fi

# ── T2: fitness.sh poprawnie wykrywa targety w katalogu z kodem ────────────
echo ""
echo "--- T2: fitness.sh wykrywa targety test/verify/deploy ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" >/dev/null
echo "# svc" > "$T2_DIR/README.md"
# Katalog serwisu z pełnym layoutem.
mkdir -p "$T2_DIR/apps/good/src" "$T2_DIR/apps/good/tests"
echo "# good" > "$T2_DIR/apps/good/README.md"
echo "src" > "$T2_DIR/apps/good/src/main.txt"
echo "tests" > "$T2_DIR/apps/good/tests/test.txt"
# Makefile z targetami test/verify/deploy.
cat > "$T2_DIR/apps/good/Makefile" <<'MK'
test:
	@echo test
verify:
	@echo verify
deploy:
	@echo deploy
MK
( cd "$T2_DIR" && git add -A 2>/dev/null )

T2_OUT="$(cd "$T2_DIR" && bash "$FITNESS_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -eq 0 ] && printf '%s' "$T2_OUT" | grep -q "CONS-01-02 Standardowe targety" \
   && printf '%s' "$T2_OUT" | grep -q "Wszystkie 1 katalogów z kodem mają targety"; then
  t_pass "fitness.sh wykrył targety test/verify/deploy w katalogu z kodem (rc=$T2_RC)"
else
  t_fail "fitness.sh NIE wykrył targetów (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -20
fi

# ── T3: fail-closed — katalog z kodem bez targetów → CONS-01-02 FAIL ───────
echo ""
echo "--- T3: fail-closed — katalog z kodem bez targetów → CONS-01-02 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" >/dev/null
echo "# svc" > "$T3_DIR/README.md"
# Katalog serwisu z layoutem, ale Makefile BEZ targetów test/verify/deploy.
mkdir -p "$T3_DIR/apps/bad/src" "$T3_DIR/apps/bad/tests"
echo "# bad" > "$T3_DIR/apps/bad/README.md"
echo "src" > "$T3_DIR/apps/bad/src/main.txt"
echo "tests" > "$T3_DIR/apps/bad/tests/test.txt"
cat > "$T3_DIR/apps/bad/Makefile" <<'MK'
build:
	@echo build
MK
( cd "$T3_DIR" && git add -A 2>/dev/null )

T3_OUT="$(cd "$T3_DIR" && bash "$FITNESS_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "CONS-01-02 Standardowe targety" \
   && printf '%s' "$T3_OUT" | grep -q "\[FAIL\]"; then
  t_pass "katalog z kodem bez targetów → CONS-01-02 FAIL (rc=$T3_RC)"
else
  t_fail "katalog z kodem bez targetów NIE dał FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -20
fi

# ── T4: layout — katalog serwisu bez standardowego layoutu → CONS-01-01 FAIL ─
echo ""
echo "--- T4: layout — katalog serwisu bez src/tests → CONS-01-01 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" >/dev/null
echo "# svc" > "$T4_DIR/README.md"
# Katalog serwisu z README, ale bez src/ i tests/ (brak standardowego layoutu).
mkdir -p "$T4_DIR/apps/nolayout"
echo "# nolayout" > "$T4_DIR/apps/nolayout/README.md"
echo "x" > "$T4_DIR/apps/nolayout/foo.txt"
( cd "$T4_DIR" && git add -A 2>/dev/null )

T4_OUT="$(cd "$T4_DIR" && bash "$FITNESS_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "CONS-01-01 Layout projektu" \
   && printf '%s' "$T4_OUT" | grep -q "\[FAIL\]"; then
  t_pass "katalog serwisu bez standardowego layoutu → CONS-01-01 FAIL (rc=$T4_RC)"
else
  t_fail "katalog serwisu bez layoutu NIE dał FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -20
fi

# ── T5: golden path score — pełna conformance → PASS (exit 0) ──────────────
echo ""
echo "--- T5: golden path score — pełna conformance → PASS (exit 0) ---"
# T2_DIR ma pełną conformance (layout + targety). Sprawdzamy, że CONS-01-04 PASS.
T5_OUT="$(cd "$T2_DIR" && bash "$FITNESS_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -eq 0 ] && printf '%s' "$T5_OUT" | grep -q "CONS-01-04 Golden path score" \
   && printf '%s' "$T5_OUT" | grep -q "100%"; then
  t_pass "pełna conformance → CONS-01-04 PASS 100% (rc=$T5_RC)"
else
  t_fail "pełna conformance NIE dała PASS 100% (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -20
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== AESTHETICS FITNESS — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
