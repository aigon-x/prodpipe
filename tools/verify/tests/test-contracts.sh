#!/usr/bin/env bash
# ============================================================================
# test-contracts.sh — CONTRACTS module tests (contracts.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/contracts/contracts.sh:
#   T1: pełny kontrakt (OpenAPI + semver + schema + testy + diff) → PASS (rc=0)
#   T2: fail-closed — brak kontraktu → CONTRACT-001 FAIL (rc != 0)
#   T3: fail-closed — kontrakt bez wersji semver → CONTRACT-002 FAIL (rc != 0)
#   T4: fail-closed — kontrakt bez schematów request/response → CONTRACT-003 FAIL (rc != 0)
#   T5: fail-closed — brak testów kontraktowych → CONTRACT-005 FAIL (rc != 0)
#   T6: fail-closed — brak mechanizmu diff → CONTRACT-006 FAIL (rc != 0)
#   T7: spójność z implementacją — endpoint w kontrakcie nieobecny w kodzie
#       → CONTRACT-004 WARN (nie blokuje, rc=0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), więc nie dotykają prawdziwego repo ani
# równoległej pracy innych subagentów.
#
# Użycie: ./test-contracts.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
CONTRACTS_SH="$VERIFY_DIR/contracts/contracts.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== CONTRACTS (KONTRAKTY) TESTS ==="

# ── Helper: buduje izolowane repo git z kontraktami ────────────────────────
# Argumenty: <katalog_docelowy> [--no-contract] [--no-semver] [--no-schema]
#            [--no-tests] [--no-diff] [--missing-endpoint]
# Tworzy git repo, opcjonalnie api/openapi.yaml (pełny kontrakt lub warianty),
# opcjonalnie testy kontraktowe, opcjonalnie mechanizm diff. Zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_contract=0
  local no_semver=0
  local no_schema=0
  local no_tests=0
  local no_diff=0
  local missing_endpoint=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-contract) no_contract=1 ;;
      --no-semver) no_semver=1 ;;
      --no-schema) no_schema=1 ;;
      --no-tests) no_tests=1 ;;
      --no-diff) no_diff=1 ;;
      --missing-endpoint) missing_endpoint=1 ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "CONTRACTS Test" )
  echo "# test" > "$dir/README.md"

  # Kontrakt OpenAPI.
  if [ "$no_contract" -eq 0 ]; then
    mkdir -p "$dir/api"
    if [ "$no_semver" -eq 1 ]; then
      # Kontrakt bez wersji semver.
      cat > "$dir/api/openapi.yaml" <<'EOF'
openapi: 3.0.0
info:
  title: Test API
paths:
  /health:
    get:
      responses:
        '200':
          description: OK
EOF
    elif [ "$no_schema" -eq 1 ]; then
      # Kontrakt z wersją semver, ale bez schematów request/response.
      cat > "$dir/api/openapi.yaml" <<'EOF'
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /health:
    get:
      description: health check
EOF
    else
      # Pełny kontrakt: semver + schematy request/response.
      cat > "$dir/api/openapi.yaml" <<'EOF'
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /health:
    get:
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
  /api/v1/users:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                type: object
EOF
    fi
  fi

  # Testy kontraktowe.
  if [ "$no_tests" -eq 0 ]; then
    mkdir -p "$dir/tests/contract"
    echo "# contract tests" > "$dir/tests/contract/README.md"
  fi

  # Mechanizm diff kontraktów.
  if [ "$no_diff" -eq 0 ]; then
    mkdir -p "$dir/tools/verify/contracts"
    cat > "$dir/tools/verify/contracts/diff.sh" <<'EOF'
#!/usr/bin/env bash
# diff kontraktów — porównuje wersje kontraktów.
echo "contract diff"
EOF
    chmod +x "$dir/tools/verify/contracts/diff.sh"
  fi

  # Endpoint z kontraktu nieobecny w kodzie (CONTRACT-004 WARN).
  if [ "$missing_endpoint" -eq 1 ]; then
    # Kontrakt deklaruje /api/v1/users, ale kod go nie zawiera.
    mkdir -p "$dir/api"
    cat > "$dir/api/openapi.yaml" <<'EOF'
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /api/v1/users:
    get:
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
EOF
    # Kod zawiera tylko /health, nie /api/v1/users.
    mkdir -p "$dir/src"
    echo 'app.get("/health", handler)' > "$dir/src/app.js"
    # Testy kontraktowe + diff, żeby CONTRACT-005/006 PASS (jedyny WARN to CONTRACT-004).
    mkdir -p "$dir/tests/contract"
    echo "# contract tests" > "$dir/tests/contract/README.md"
    mkdir -p "$dir/tools/verify/contracts"
    cat > "$dir/tools/verify/contracts/diff.sh" <<'EOF'
#!/usr/bin/env bash
# diff kontraktów.
echo "contract diff"
EOF
    chmod +x "$dir/tools/verify/contracts/diff.sh"
  fi

  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: pełny kontrakt → PASS (rc=0) ───────────────────────────────────────
echo ""
echo "--- T1: pełny kontrakt (OpenAPI + semver + schema + testy + diff) → PASS (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR" "$T6_DIR" "$T7_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] CONTRACT-001" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] CONTRACT-002" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] CONTRACT-003" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] CONTRACT-005" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] CONTRACT-006"; then
  t_pass "pełny kontrakt → PASS (rc=$T1_RC, CONTRACT-001/002/003/005/006 PASS)"
else
  t_fail "pełny kontrakt NIE dał PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak kontraktu → CONTRACT-001 FAIL ───────────────────
echo ""
echo "--- T2: fail-closed — brak kontraktu → CONTRACT-001 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-contract >/dev/null

T2_OUT="$(cd "$T2_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] CONTRACT-001"; then
  t_pass "brak kontraktu → CONTRACT-001 FAIL (rc=$T2_RC)"
else
  t_fail "brak kontraktu NIE dał CONTRACT-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — kontrakt bez semver → CONTRACT-002 FAIL ──────────────
echo ""
echo "--- T3: fail-closed — kontrakt bez wersji semver → CONTRACT-002 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-semver >/dev/null

T3_OUT="$(cd "$T3_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] CONTRACT-002"; then
  t_pass "kontrakt bez semver → CONTRACT-002 FAIL (rc=$T3_RC)"
else
  t_fail "kontrakt bez semver NIE dał CONTRACT-002 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — kontrakt bez schematów → CONTRACT-003 FAIL ───────────
echo ""
echo "--- T4: fail-closed — kontrakt bez schematów request/response → CONTRACT-003 FAIL ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-schema >/dev/null

T4_OUT="$(cd "$T4_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] CONTRACT-003"; then
  t_pass "kontrakt bez schematów → CONTRACT-003 FAIL (rc=$T4_RC)"
else
  t_fail "kontrakt bez schematów NIE dał CONTRACT-003 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── T5: fail-closed — brak testów kontraktowych → CONTRACT-005 FAIL ────────
echo ""
echo "--- T5: fail-closed — brak testów kontraktowych → CONTRACT-005 FAIL ---"
T5_DIR="$(mktemp -d)"
make_isolated_repo "$T5_DIR" --no-tests >/dev/null

T5_OUT="$(cd "$T5_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "\[FAIL\] CONTRACT-005"; then
  t_pass "brak testów kontraktowych → CONTRACT-005 FAIL (rc=$T5_RC)"
else
  t_fail "brak testów kontraktowych NIE dał CONTRACT-005 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -30
fi

# ── T6: fail-closed — brak mechanizmu diff → CONTRACT-006 FAIL ─────────────
echo ""
echo "--- T6: fail-closed — brak mechanizmu diff → CONTRACT-006 FAIL ---"
T6_DIR="$(mktemp -d)"
make_isolated_repo "$T6_DIR" --no-diff >/dev/null

T6_OUT="$(cd "$T6_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T6_RC=$?
if [ "$T6_RC" -ne 0 ] && printf '%s' "$T6_OUT" | grep -q "\[FAIL\] CONTRACT-006"; then
  t_pass "brak mechanizmu diff → CONTRACT-006 FAIL (rc=$T6_RC)"
else
  t_fail "brak mechanizmu diff NIE dał CONTRACT-006 FAIL (rc=$T6_RC)"
  printf '%s\n' "$T6_OUT" | tail -30
fi

# ── T7: spójność z implementacją — endpoint nieobecny w kodzie → WARN ──────
echo ""
echo "--- T7: endpoint z kontraktu nieobecny w kodzie → CONTRACT-004 WARN (rc=0) ---"
T7_DIR="$(mktemp -d)"
make_isolated_repo "$T7_DIR" --missing-endpoint >/dev/null

T7_OUT="$(cd "$T7_DIR" && bash "$CONTRACTS_SH" 2>&1)"
T7_RC=$?
if [ "$T7_RC" -eq 0 ] && printf '%s' "$T7_OUT" | grep -q "\[WARN\] CONTRACT-004"; then
  t_pass "endpoint nieobecny w kodzie → CONTRACT-004 WARN (rc=$T7_RC)"
else
  t_fail "endpoint nieobecny w kodzie NIE dał CONTRACT-004 WARN (rc=$T7_RC)"
  printf '%s\n' "$T7_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== CONTRACTS (KONTRAKTY) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
