#!/usr/bin/env bash
# ============================================================================
# test-reproducibility.sh — REPRODUCIBILITY module tests (reproducibility.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/reproducibility/reproducibility.sh:
#   T1: repo z build scripts + przypięte wersje ≤ max_pinned_drift
#       → R-001..R-005 PASS (rc=0)
#   T2: fail-closed — brak build scripts + brak kontraktu no-build
#       → R-001 FAIL (NO_BUILD_SCRIPTS ≠ PASS, rc != 0)
#   T3: brak build scripts + kontrakt no-build (reproducibility.yaml)
#       → R-001 NOT_APPLICABLE (info, rc=0)
#   T4: fail-closed — build z timestampami (date +%s)
#       → R-002 FAIL (TIMESTAMP_DRIFT, rc != 0)
#   T5: fail-closed — dryf od przypiętych wersji > max_pinned_drift
#       → R-004 FAIL (UNPINNED_DRIFT, rc != 0)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), tworzą build scripts i registry.yaml, więc nie
# dotykają prawdziwego repo ani równoległej pracy innych subagentów.
# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-reproducibility.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
REPRO_SH="$VERIFY_DIR/reproducibility/reproducibility.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== REPRODUCIBILITY (REPRODUKOWALNOŚĆ) TESTS ==="

# ── Helper: buduje izolowane repo git z build scripts i registry.yaml ──────
# Argumenty: <katalog_docelowy> [--no-build] [--no-build-contract]
#            [--timestamp] [--max-pinned-drift <N>] [--deps <N>]
# Tworzy git repo, tworzy config/canonical/registry.yaml z max_pinned_drift,
# opcjonalnie build.sh, opcjonalnie build.sh z timestampem, opcjonalnie
# package.json z N zależnościami (przypiętymi lub ruchomymi),
# opcjonalnie reproducibility.yaml (kontrakt no-build). Zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_build=0
  local no_build_contract=0
  local timestamp=0
  local max_pinned_drift=0
  local deps=0
  local unpinned=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-build) no_build=1 ;;
      --no-build-contract) no_build_contract=1 ;;
      --timestamp) timestamp=1 ;;
      --max-pinned-drift) max_pinned_drift="$2"; shift ;;
      --deps) deps="$2"; shift ;;
      --unpinned) unpinned=1 ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "REPRO Test" )
  echo "# test" > "$dir/README.md"

  # registry.yaml — canonical config contract (max_pinned_drift).
  mkdir -p "$dir/config/canonical"
  cat > "$dir/config/canonical/registry.yaml" <<EOF
gates:
  reproducibility.integrity.max_pinned_drift:
    default: $max_pinned_drift
    floor: 0
    ratchet: true
    reload: hot
    owner: platform
    tier: stable
    doc: "Maksymalna liczba dryfów od przypiętych wersji."
EOF

  # Build script (build.sh).
  if [ "$no_build" -eq 0 ]; then
    if [ "$timestamp" -eq 1 ]; then
      cat > "$dir/build.sh" <<'EOF'
#!/usr/bin/env bash
# build z timestampem — niedeterministyczny
VERSION="1.0.0-$(date +%s)"
echo "building $VERSION"
EOF
    else
      cat > "$dir/build.sh" <<'EOF'
#!/usr/bin/env bash
# deterministyczny build
VERSION="1.0.0"
echo "building $VERSION"
EOF
    fi
    chmod +x "$dir/build.sh"
  fi

  # Manifest zależności (package.json) z N zależnościami.
  if [ "$deps" -gt 0 ]; then
    {
      echo '{'
      echo '  "name": "test",'
      echo '  "version": "1.0.0",'
      echo '  "dependencies": {'
      local i
      for i in $(seq 1 "$deps"); do
        if [ "$i" -gt 1 ]; then echo ','; fi
        if [ "$unpinned" -eq 1 ]; then
          # ruchoma wersja (dryf od przypiętej)
          printf '    "dep%s": "^1.0.%s"' "$i" "$i"
        else
          # przypięta wersja
          printf '    "dep%s": "1.0.%s"' "$i" "$i"
        fi
      done
      echo ''
      echo '  }'
      echo '}'
    } > "$dir/package.json"
  fi

  # Kontrakt no-build (reproducibility.yaml).
  if [ "$no_build_contract" -eq 1 ]; then
    cat > "$dir/config/canonical/reproducibility.yaml" <<'EOF'
# reproducibility.yaml — kontrakt reprodukowalności.
# Repo jest czysto dokumentacyjne — build nie ma zastosowania.
no-build: true
documentation-only: true
EOF
  fi

  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: repo z build scripts + przypięte wersje ≤ max_pinned_drift (rc=0) ──
# Uwaga: T1 NIE tworzy manifestów zależności (--deps 0), bo R-003 wymaga
# lockfile gdy build present + manifesty zależności. Bez manifestów R-003
# jest NOT_APPLICABLE (ekosystem bez lockfile), a R-004 PASS (0 dryfów).
echo ""
echo "--- T1: repo z build scripts + przypięte wersje ≤ max_pinned_drift (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR" "$T5_DIR"' EXIT
make_isolated_repo "$T1_DIR" --max-pinned-drift 0 >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$REPRO_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] R-001" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] R-002" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] R-004"; then
  t_pass "repo z build scripts + przypięte wersje ≤ max_pinned_drift (rc=$T1_RC, R-001/002/004 PASS)"
else
  t_fail "repo z build scripts NIE dał PASS (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak build scripts + brak kontraktu → R-001 FAIL ─────
echo ""
echo "--- T2: fail-closed — brak build scripts + brak kontraktu no-build → R-001 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-build >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$REPRO_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] R-001"; then
  t_pass "brak build scripts + brak kontraktu → R-001 FAIL (NO_BUILD_SCRIPTS ≠ PASS, rc=$T2_RC)"
else
  t_fail "brak build scripts + brak kontraktu NIE dał R-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: brak build scripts + kontrakt no-build → NOT_APPLICABLE ────────────
echo ""
echo "--- T3: brak build scripts + kontrakt no-build → R-001 NOT_APPLICABLE ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --no-build --no-build-contract >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$REPRO_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -eq 0 ] \
   && printf '%s' "$T3_OUT" | grep -q "NOT_APPLICABLE" \
   && printf '%s' "$T3_OUT" | grep -q "\[INFO\] R-001"; then
  t_pass "brak build scripts + kontrakt no-build → R-001 NOT_APPLICABLE (rc=$T3_RC)"
else
  t_fail "brak build scripts + kontrakt no-build NIE dał NOT_APPLICABLE (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: fail-closed — build z timestampami → R-002 FAIL (TIMESTAMP_DRIFT) ──
echo ""
echo "--- T4: fail-closed — build z timestampami → R-002 FAIL (TIMESTAMP_DRIFT) ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --timestamp >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$REPRO_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -ne 0 ] && printf '%s' "$T4_OUT" | grep -q "\[FAIL\] R-002"; then
  t_pass "build z timestampami → R-002 FAIL (TIMESTAMP_DRIFT, rc=$T4_RC)"
else
  t_fail "build z timestampami NIE dał R-002 FAIL (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── T5: fail-closed — dryf od przypiętych wersji > max_pinned_drift ────────
echo ""
echo "--- T5: fail-closed — dryf od przypiętych wersji > max_pinned_drift → R-004 FAIL ---"
T5_DIR="$(mktemp -d)"
make_isolated_repo "$T5_DIR" --max-pinned-drift 0 --deps 3 --unpinned >/dev/null

T5_OUT="$(cd "$T5_DIR" && VERIFY_STATE_DB="$T5_DIR/nonexistent.db" bash "$REPRO_SH" 2>&1)"
T5_RC=$?
if [ "$T5_RC" -ne 0 ] && printf '%s' "$T5_OUT" | grep -q "\[FAIL\] R-004"; then
  t_pass "dryf od przypiętych wersji > max_pinned_drift → R-004 FAIL (UNPINNED_DRIFT, rc=$T5_RC)"
else
  t_fail "dryf od przypiętych wersji NIE dał R-004 FAIL (rc=$T5_RC)"
  printf '%s\n' "$T5_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== REPRODUCIBILITY (REPRODUKOWALNOŚĆ) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
