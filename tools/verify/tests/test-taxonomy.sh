#!/usr/bin/env bash
# ============================================================================
# test-taxonomy.sh — ARCHITECTURAL TAXONOMY GATE (taxonomy.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/architecture/taxonomy.sh:
#   T1: moduł działa na poprawnym taxonomy.yaml (32 wymiary, wagi=1.0,
#       TEN/AI warunkowe) + check-gate-map.yaml → TAX-001..015 PASS, rc=0
#   T2: fail-closed — brak taxonomy.yaml → TAX-001 FAIL (rc != 0)
#   T3: fail-closed — taxonomy z 30 wymiarami (zamiast 32) → TAX-003 FAIL
#   T4: fail-closed — wymiar bez `definition` → TAX-004 FAIL
#   T5: fail-closed — wagi nie sumują się do 1.0 → TAX-006 FAIL
#   T6: fail-closed — wymiar `always` bez wpisu w check-gate-map.yaml
#       → TAX-015 FAIL (rc != 0)
#
# Testy są IZOLOWANE i SAMOWYSTARCZALNE: tworzą własne tymczasowe repo git
# (bo moduł używa verify_root = git rev-parse) i generują własne kopie
# taxonomy.yaml (bo plik może jeszcze nie istnieć w repo — tworzony równolegle).
# Nie zależą od stanu prawdziwego repo.
#
# Użycie: ./test-taxonomy.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
TAXONOMY_SH="$VERIFY_DIR/architecture/taxonomy.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== ARCHITECTURAL TAXONOMY GATE TESTS ==="

# ── Helper: generuje kompletny, poprawny taxonomy.yaml ─────────────────────
# Argumenty: <plik_wyjściowy> [liczba_wymiarów_always] [waga_always]
# Generuje n_always wymiarów DIM (applicability=always) + TEN + AI (warunkowe).
# Łączna liczba wymiarów = n_always + 2. Format listy (zgodny z prawdziwym
# taxonomy.yaml): `dimensions:` → `- id: <ID>` → pola na 4 spacje → checki
# inline `- {id: ..., desc: ...}`.
#   - Domyślnie n_always=29 → 32 wymiary łącznie (29 always + TEN + AI).
#   - Waga always domyślnie 1/29 ≈ 0.034483 → suma always = 1.0.
#   - TEN i AI mają applicability warunkową (nie wchodzą do sumy always).
make_taxonomy() {
  local out="$1"
  local n_always="${2:-29}"
  local w_always="${3:-0.034483}"
  {
    echo "schema_version: 1"
    echo ""
    echo "# Taksonomia doskonałości — 32 wymiary."
    echo "dimensions:"
    local i
    for i in $(seq 1 "$n_always"); do
      printf '  - id: DIM-%02d\n' "$i"
      printf '    name: "Wymiar %02d"\n' "$i"
      printf '    definition: "Definicja wymiaru %02d."\n' "$i"
      printf '    source: "docs/architecture/taxonomy.md"\n'
      printf '    applicability: always\n'
      printf '    weight: %s\n' "$w_always"
      printf '    checks:\n'
      printf '      - {id: DIM-%02d-CHK-1, desc: "Check 1 wymiaru %02d."}\n' "$i" "$i"
    done
    # TEN i AI — wymiary warunkowe.
    printf '  - id: TEN\n'
    printf '    name: "Tenancy"\n'
    printf '    definition: "Wymiar tenancy."\n'
    printf '    source: "docs/architecture/taxonomy.md"\n'
    printf '    applicability: conditional\n'
    printf '    weight: 0.0\n'
    printf '    checks:\n'
    printf '      - {id: TEN-CHK-1, desc: "Check tenancy."}\n'
    printf '  - id: AI\n'
    printf '    name: "AI Capability"\n'
    printf '    definition: "Wymiar AI."\n'
    printf '    source: "docs/architecture/taxonomy.md"\n'
    printf '    applicability: conditional\n'
    printf '    weight: 0.0\n'
    printf '    checks:\n'
    printf '      - {id: AI-CHK-1, desc: "Check AI."}\n'
    echo ""
    echo "applicability_matrix:"
    echo "  always: [DIM-01, DIM-02]"
    echo "  conditional: [TEN, AI]"
    echo ""
    echo "qi_formula:"
    echo "  expression: \"sum(weight * score) / sum(weight)\""
    echo ""
    echo "priorities:"
    echo "  - DIM-01"
    echo "  - DIM-02"
  } > "$out"
}

# ── Helper: generuje check-gate-map.yaml ───────────────────────────────────
# Argumenty: <plik_wyjściowy> <lista_wymiarów_always>
# Generuje mapę, w której każdy wymiar z listy ma gate_type=automated i
# istniejący (fikcyjny) gate_script. Używane przez T1 (ścieżka PASS) i T6.
make_check_gate_map() {
  local out="$1"
  local dims="$2"
  {
    echo "schema_version: 1"
    echo ""
    echo "dimensions:"
    local d
    for d in $dims; do
      printf '  %s:\n' "$d"
      printf '    gate_type: automated\n'
      printf '    gate_module: test\n'
      printf '    gate_script: test/%s.sh\n' "$d"
      printf '    coverage: []\n'
      printf '    doc: "Testowy gate dla %s."\n' "$d"
    done
  } > "$out"
}

# ── Helper: buduje izolowane repo git z taxonomy.yaml ──────────────────────
# Argumenty: <katalog_docelowy> <plik_taxonomy> [plik_check_gate_map]
# Jeśli podano mapę, tworzy też fikcyjne skrypty tools/verify/test/<DIM>.sh
# dla każdego wymiaru w mapie (żeby TAX-015 znalazł istniejące gate_script).
make_isolated_repo() {
  local dir="$1" taxonomy="$2" map="${3:-}"
  mkdir -p "$dir/config/canonical"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "TAX Test" )
  cp "$taxonomy" "$dir/config/canonical/taxonomy.yaml"
  if [ -n "$map" ]; then
    cp "$map" "$dir/config/canonical/check-gate-map.yaml"
    # Fikcyjne skrypty dla wymiarów automated w mapie.
    local d
    for d in $(awk '/^  [A-Za-z0-9_-]+:/{sub(/^  /,"");sub(/:.*/,"");print}' "$map"); do
      mkdir -p "$dir/tools/verify/test"
      echo "#!/usr/bin/env bash" > "$dir/tools/verify/test/$d.sh"
      echo "exit 0" >> "$dir/tools/verify/test/$d.sh"
    done
  fi
  echo "# test" > "$dir/README.md"
  ( cd "$dir" && git add -A )
  ( cd "$dir" && git commit -qm "add taxonomy" )
}

# ── T1: moduł działa na poprawnym taxonomy.yaml → PASS (rc=0) ──────────────
echo ""
echo "--- T1: poprawny taxonomy.yaml → TAX-001..013 PASS (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR" "$T6_DIR"' EXIT
T1_TAX="$T1_DIR/taxonomy-ok.yaml"
mkdir -p "$T1_DIR"
# 30 always + TEN + AI = 32 wymiary, waga always = 1/30 → suma 1.0.
make_taxonomy "$T1_TAX" 30 0.033333
# applicability_matrix w wygenerowanym taxonomy to `always: [DIM-01, DIM-02]`.
# TAX-015 wymaga, żeby te wymiary miały wpis w check-gate-map.yaml.
make_check_gate_map "$T1_DIR/check-gate-map.yaml" "DIM-01 DIM-02"
make_isolated_repo "$T1_DIR/repo" "$T1_TAX" "$T1_DIR/check-gate-map.yaml"

# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku (rejestruje WARN, nie FAIL).
T1_OUT="$(cd "$T1_DIR/repo" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "TAX-001 Taxonomy istnieje" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-002 Taxonomy jest poprawnym YAML" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-003 Ma 32 wymiary" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-004 Każdy wymiar ma id, name, definition, source, applicability, weight, checks" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-005 Id wymiarów unikalne" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-006 Wagi sumują się do 1.0" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-007 Każdy check ma id + desc" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-008 Check ID unikalne" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-009 Applicability jest zdefiniowana" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-010 Wymiary warunkowe" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-011 Sekcja applicability_matrix istnieje" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-012 Sekcja qi_formula istnieje" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-013 Sekcja priorities istnieje" \
   && printf '%s' "$T1_OUT" | grep -q "TAX-015 Meta-gate: pokrycie check→gate" \
   && ! printf '%s' "$T1_OUT" | grep -q "\[FAIL\]"; then
  t_pass "moduł wykonał TAX-001..015 bez FAIL (rc=$T1_RC)"
else
  t_fail "moduł NIE przeszedł ścieżki PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak taxonomy.yaml → TAX-001 FAIL ────────────────────
echo ""
echo "--- T2: brak taxonomy.yaml → TAX-001 FAIL (rc != 0) ---"
T2_DIR="$(mktemp -d)"
mkdir -p "$T2_DIR/repo"
( cd "$T2_DIR/repo" && git init -q )
( cd "$T2_DIR/repo" && git config user.email "test@aigon.local" )
( cd "$T2_DIR/repo" && git config user.name "TAX Test" )
echo "# test" > "$T2_DIR/repo/README.md"
( cd "$T2_DIR/repo" && git add -A )
( cd "$T2_DIR/repo" && git commit -qm "no taxonomy" )

T2_OUT="$(cd "$T2_DIR/repo" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "TAX-001 Taxonomy istnieje" \
   && printf '%s' "$T2_OUT" | grep -q "\[FAIL\]"; then
  t_pass "brak taxonomy.yaml → TAX-001 FAIL (rc=$T2_RC)"
else
  t_fail "brak taxonomy.yaml NIE dał TAX-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -25
fi

# ── T3: fail-closed — 30 wymiarów zamiast 32 → TAX-003 FAIL ────────────────
echo ""
echo "--- T3: taxonomy z 30 wymiarami → TAX-003 FAIL (rc != 0) ---"
T3_DIR="$(mktemp -d)"
T3_TAX="$T3_DIR/taxonomy-30.yaml"
mkdir -p "$T3_DIR"
# 28 always + TEN + AI = 30 wymiarów (zamiast 32). Waga always = 1/28 → suma 1.0.
make_taxonomy "$T3_TAX" 28 0.035714
make_isolated_repo "$T3_DIR/repo" "$T3_TAX"

T3_OUT="$(cd "$T3_DIR/repo" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "TAX-003 Ma 32 wymiary" \
   && printf '%s' "$T3_OUT" | grep -q "\[FAIL\]"; then
  t_pass "30 wymiarów → TAX-003 FAIL (rc=$T3_RC)"
else
  t_fail "30 wymiarów NIE dał TAX-003 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -25
fi

# ── T4: fail-closed — wymiar bez `definition` → TAX-004 FAIL ───────────────
echo ""
echo "--- T4: wymiar bez definition → TAX-004 FAIL (rc != 0) ---"
T4_DIR="$(mktemp -d)"
T4_TAX="$T4_DIR/taxonomy-nodef.yaml"
mkdir -p "$T4_DIR"
make_taxonomy "$T4_TAX" 29 0.034483
# Usuń `definition` z wymiaru DIM-01.
awk '
  /^  - id: DIM-01/ {in_dim=1}
  in_dim && /^    definition:/ {skip=1; next}
  in_dim && /^    [a-z_]+:/ && !/^    definition:/ {skip=0}
  !skip {print}
' "$T4_TAX" > "$T4_TAX.tmp" && mv "$T4_TAX.tmp" "$T4_TAX"
make_isolated_repo "$T4_DIR/repo" "$T4_TAX"

T4_OUT="$(cd "$T4_DIR/repo" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "TAX-004 Każdy wymiar ma id, name, definition, source, applicability, weight, checks" \
   && printf '%s' "$T4_OUT" | grep -q "\[FAIL\]"; then
  t_pass "wymiar bez definition → TAX-004 FAIL (rc=$T4_RC)"
else
  t_fail "wymiar bez definition NIE dał TAX-004 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -25
fi

# ── T5: fail-closed — wagi nie sumują się do 1.0 → TAX-006 FAIL ────────────
echo ""
echo "--- T5: wagi nie sumują się do 1.0 → TAX-006 FAIL (rc != 0) ---"
T5_DIR="$(mktemp -d)"
T5_TAX="$T5_DIR/taxonomy-badweight.yaml"
mkdir -p "$T5_DIR"
# Waga always = 0.05 → 29 wymiarów * 0.05 = 1.45 ≠ 1.0 → TAX-006 FAIL.
make_taxonomy "$T5_TAX" 29 0.05
make_isolated_repo "$T5_DIR/repo" "$T5_TAX"

T5_OUT="$(cd "$T5_DIR/repo" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "TAX-006 Wagi sumują się do 1.0" \
   && printf '%s' "$T5_OUT" | grep -q "\[FAIL\]"; then
  t_pass "wagi ≠ 1.0 → TAX-006 FAIL (rc=$T5_RC)"
else
  t_fail "wagi ≠ 1.0 NIE dał TAX-006 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -25
fi

# ── T6: fail-closed — wymiar `always` bez wpisu w mapie → TAX-015 FAIL ─────
echo ""
echo "--- T6: wymiar always bez wpisu w check-gate-map.yaml → TAX-015 FAIL (rc != 0) ---"
T6_DIR="$(mktemp -d)"
T6_TAX="$T6_DIR/taxonomy-ok.yaml"
T6_MAP="$T6_DIR/check-gate-map.yaml"
mkdir -p "$T6_DIR"
# applicability_matrix: always: [DIM-01, DIM-02]. Mapa pokrywa TYLKO DIM-02 —
# DIM-01 jest `always` bez wpisu w mapie → TAX-015 FAIL.
make_taxonomy "$T6_TAX" 30 0.033333
make_check_gate_map "$T6_MAP" "DIM-02"
make_isolated_repo "$T6_DIR/repo" "$T6_TAX" "$T6_MAP"

T6_OUT="$(cd "$T6_DIR/repo" && VERIFY_STATE_DB="$T6_DIR/nonexistent.db" bash "$TAXONOMY_SH" 2>&1)"
T6_RC=$?
if [ "$T6_RC" -ne 0 ] && printf '%s' "$T6_OUT" | grep -q "TAX-015 Meta-gate: pokrycie check→gate" \
   && printf '%s' "$T6_OUT" | grep -q "\[FAIL\]"; then
  t_pass "wymiar always bez wpisu w mapie → TAX-015 FAIL (rc=$T6_RC)"
else
  t_fail "wymiar always bez wpisu w mapie NIE dał TAX-015 FAIL (rc=$T6_RC)"
  printf '%s\n' "$T6_OUT" | tail -25
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== ARCHITECTURAL TAXONOMY GATE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
