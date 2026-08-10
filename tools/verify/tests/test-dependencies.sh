#!/usr/bin/env bash
# ============================================================================
# test-dependencies.sh — DEPENDENCIES module tests (dependencies.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/dependencies/dependencies.sh:
#   T1: repo z manifestem (package.json) i zależnościami ≤ max_outdated
#       → D-001..D-005 PASS (rc=0)
#   T2: fail-closed — brak manifestów + brak kontraktu dependency-free
#       → D-001 FAIL (NO_MANIFEST ≠ PASS, rc != 0)
#   T3: brak manifestów + kontrakt dependency-free (dependencies.yaml)
#       → D-001 NOT_APPLICABLE (info, rc=0)
#   T4: fail-closed — manifest + node_modules/ → D-002 FAIL (INVALID, rc != 0)
#   T5: fail-closed — manifest z zależnościami > max_outdated
#       → D-005 FAIL (STALE, rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), tworzą manifesty i registry.yaml, więc nie
# dotykają prawdziwego repo ani równoległej pracy innych subagentów.
# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-dependencies.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
DEP_SH="$VERIFY_DIR/dependencies/dependencies.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== DEPENDENCIES (ZALEŻNOŚCI) TESTS ==="

# ── Helper: buduje izolowane repo git z manifestami i registry.yaml ────────
# Argumenty: <katalog_docelowy> [--no-manifest] [--dep-free-contract]
#            [--node-modules] [--max-outdated <N>] [--deps <N>]
# Tworzy git repo, tworzy config/canonical/registry.yaml z max_outdated,
# opcjonalnie package.json z N zależnościami, opcjonalnie node_modules/,
# opcjonalnie dependencies.yaml (kontrakt dependency-free). Zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_manifest=0
  local dep_free_contract=0
  local node_modules=0
  local max_outdated=10
  local deps=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-manifest) no_manifest=1 ;;
      --dep-free-contract) dep_free_contract=1 ;;
      --node-modules) node_modules=1 ;;
      --max-outdated) max_outdated="$2"; shift ;;
      --deps) deps="$2"; shift ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "DEP Test" )
  echo "# test" > "$dir/README.md"

  # registry.yaml — canonical config contract (max_outdated).
  mkdir -p "$dir/config/canonical"
  cat > "$dir/config/canonical/registry.yaml" <<EOF
gates:
  dependencies.integrity.max_outdated:
    default: $max_outdated
    floor: 5
    ratchet: true
    reload: hot
    owner: platform
    tier: stable
    doc: "Maksymalna liczba przestarzałych zależności."
EOF

  # Manifest zależności (package.json) z N zależnościami.
  if [ "$no_manifest" -eq 0 ]; then
    if [ "$deps" -gt 0 ]; then
      # Generuj package.json z N zależnościami.
      {
        echo '{'
        echo '  "name": "test",'
        echo '  "version": "1.0.0",'
        echo '  "dependencies": {'
        local i
        for i in $(seq 1 "$deps"); do
          if [ "$i" -gt 1 ]; then echo ','; fi
          printf '    "dep%s": "1.0.%s"' "$i" "$i"
        done
        echo ''
        echo '  }'
        echo '}'
      } > "$dir/package.json"
    else
      cat > "$dir/package.json" <<'EOF'
{
  "name": "test",
  "version": "1.0.0",
  "dependencies": {}
}
EOF
    fi
  fi

  # Kontrakt dependency-free (dependencies.yaml).
  if [ "$dep_free_contract" -eq 1 ]; then
    cat > "$dir/config/canonical/dependencies.yaml" <<'EOF'
# dependencies.yaml — kontrakt zależności.
# Repo jest dependency-free — manifesty zależności nie mają zastosowania.
dependency-free: true
EOF
  fi

  # Zakazane drzewo node_modules/.
  if [ "$node_modules" -eq 1 ]; then
    mkdir -p "$dir/node_modules"
    echo "x" > "$dir/node_modules/placeholder"
  fi

  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: repo z manifestem i zależnościami ≤ max_outdated (rc=0) ────────────
echo ""
echo "--- T1: repo z manifestem i zależnościami ≤ max_outdated (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR"' EXIT
make_isolated_repo "$T1_DIR" --max-outdated 10 --deps 3 >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$DEP_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-001" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-002" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] D-005"; then
  t_pass "repo z manifestem i zależnościami ≤ max_outdated (rc=$T1_RC, D-001/002/005 PASS)"
else
  t_fail "repo z manifestem NIE dał PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak manifestów + brak kontraktu → D-001 FAIL ────────
echo ""
echo "--- T2: fail-closed — brak manifestów + brak kontraktu dependency-free → D-001 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-manifest >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$DEP_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] D-001"; then
  t_pass "brak manifestów + brak kontraktu → D-001 FAIL (NO_MANIFEST ≠ PASS, rc=$T2_RC)"
else
  t_fail "brak manifestów + brak kontraktu NIE dał D-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: brak manifestów + kontrakt dependency-free → NOT_APPLICABLE ────────
echo ""
echo "--- T3: brak manifestów + kontrakt dependency-free → D-001 NOT_APPLICABLE ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-manifest --dep-free-contract >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$DEP_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -eq 0 ] \
   && printf '%s' "$T3_OUT" | grep -q "NOT_APPLICABLE" \
   && printf '%s' "$T3_OUT" | grep -q "\[INFO\] D-001"; then
  t_pass "brak manifestów + kontrakt dependency-free → D-001 NOT_APPLICABLE (rc=$T3_RC)"
else
  t_fail "brak manifestów + kontrakt dependency-free NIE dał NOT_APPLICABLE (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — manifest + node_modules/ → D-002 FAIL ────────────────
echo ""
echo "--- T4: fail-closed — manifest + node_modules/ → D-002 FAIL (INVALID) ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --node-modules --deps 1 >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$DEP_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] D-002"; then
  t_pass "manifest + node_modules/ → D-002 FAIL (INVALID, rc=$T4_RC)"
else
  t_fail "manifest + node_modules/ NIE dał D-002 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── T5: fail-closed — zależności > max_outdated → D-005 FAIL (STALE) ───────
echo ""
echo "--- T5: fail-closed — zależności > max_outdated → D-005 FAIL (STALE) ---"
T5_DIR="$(mktemp -d)"
make_isolated_repo "$T5_DIR" --max-outdated 5 --deps 8 >/dev/null

T5_OUT="$(cd "$T5_DIR" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$DEP_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "\[FAIL\] D-005"; then
  t_pass "zależności > max_outdated → D-005 FAIL (STALE, rc=$T5_RC)"
else
  t_fail "zależności > max_outdated NIE dał D-005 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== DEPENDENCIES (ZALEŻNOŚCI) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
