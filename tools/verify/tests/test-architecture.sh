#!/usr/bin/env bash
# ============================================================================
# test-architecture.sh — ARCHITECTURE module tests (architecture.sh)
# ============================================================================
# Weryfikuje moduł tools/verify/architecture/architecture.sh:
#   T1: moduł działa na repo z kompletem dokumentów architektury bez
#       STATUS: UNDEFINED (rc=0, ARCH-001..006 PASS)
#   T2: fail-closed — brak ARCHITECTURE.md → ARCH-001 FAIL (rc != 0)
#   T3: fail-closed — ARCHITECTURE.md z STATUS: UNDEFINED → ARCH-004 FAIL
#       (rc != 0)
#   T4: ARCHITECTURE.md bez linków do SOURCE-OF-TRUTH.md/OWNERSHIP.md
#       → ARCH-007 WARN (rc=0, bo WARNING nie blokuje)
#
# Testy są IZOLOWANE: tworzą własne tymczasowe repo git (bo moduł używa
# verify_root = git rev-parse), tworzą dokumenty architektury, więc nie
# dotykają prawdziwego repo ani równoległej pracy innych subagentów.
# Ustawiamy VERIFY_STATE_DB na nieistniejącą bazę, żeby evidence_record
# nie psuł wyniku.
#
# Użycie: ./test-architecture.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
ARCH_SH="$VERIFY_DIR/architecture/architecture.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== ARCHITECTURE (ARCHITEKTURA) TESTS ==="

# ── Helper: buduje izolowane repo git z dokumentami architektury ──────────
# Argumenty: <katalog_docelowy> [--no-arch] [--no-sot] [--no-own]
#            [--undefined-arch] [--no-links]
# Tworzy git repo, tworzy ARCHITECTURE.md / SOURCE-OF-TRUTH.md / OWNERSHIP.md
# (lub warianty), zwraca ścieżkę.
make_isolated_repo() {
  local dir="$1"; shift
  local no_arch=0
  local no_sot=0
  local no_own=0
  local undefined_arch=0
  local no_links=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-arch) no_arch=1 ;;
      --no-sot) no_sot=1 ;;
      --no-own) no_own=1 ;;
      --undefined-arch) undefined_arch=1 ;;
      --no-links) no_links=1 ;;
    esac
    shift
  done
  mkdir -p "$dir"
  ( cd "$dir" && git init -q )
  ( cd "$dir" && git config user.email "test@aigon.local" )
  ( cd "$dir" && git config user.name "ARCH Test" )
  echo "# test" > "$dir/README.md"

  if [ "$no_arch" -eq 0 ]; then
    if [ "$undefined_arch" -eq 1 ]; then
      cat > "$dir/ARCHITECTURE.md" <<'EOF'
# ARCHITECTURE — AIGON Production Platform

> **STATUS: UNDEFINED** — architektura w toku.
EOF
    elif [ "$no_links" -eq 1 ]; then
      cat > "$dir/ARCHITECTURE.md" <<'EOF'
# ARCHITECTURE — AIGON Production Platform

> **STATUS: DEFINED** — architektura zdefiniowana.

Brak odwołań do innych dokumentów.
EOF
    else
      cat > "$dir/ARCHITECTURE.md" <<'EOF'
# ARCHITECTURE — AIGON Production Platform

> **STATUS: DEFINED** — architektura zdefiniowana.

Zobacz [SOURCE-OF-TRUTH.md](SOURCE-OF-TRUTH.md) i [OWNERSHIP.md](OWNERSHIP.md).
EOF
    fi
  fi

  if [ "$no_sot" -eq 0 ]; then
    cat > "$dir/SOURCE-OF-TRUTH.md" <<'EOF'
# SOURCE-OF-TRUTH — AIGON Production Platform

> **STATUS: DEFINED** — źródło prawdy zdefiniowane.
EOF
  fi

  if [ "$no_own" -eq 0 ]; then
    cat > "$dir/OWNERSHIP.md" <<'EOF'
# OWNERSHIP — AIGON Production Platform

> **STATUS: DEFINED** — własność zdefiniowana.
EOF
  fi

  ( cd "$dir" && git add -A 2>/dev/null )
  echo "$dir"
}

# ── T1: moduł działa na repo z kompletem dokumentów (rc=0) ─────────────────
echo ""
echo "--- T1: moduł działa na repo z kompletem dokumentów bez UNDEFINED (rc=0) ---"
T1_DIR="$(mktemp -d)"
trap 'rm -rf "$T1_DIR" "$T2_DIR" "$T3_DIR" "$T4_DIR"' EXIT
make_isolated_repo "$T1_DIR" >/dev/null

T1_OUT="$(cd "$T1_DIR" && VERIFY_STATE_DB="$T1_DIR/nonexistent.db" bash "$ARCH_SH" 2>&1)"
T1_RC=$?
if [ "$T1_RC" -eq 0 ] \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-001" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-002" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-003" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-004" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-005" \
   && printf '%s' "$T1_OUT" | grep -q "\[PASS\] ARCH-006"; then
  t_pass "moduł działa na poprawnym repo (rc=$T1_RC, ARCH-001..006 PASS)"
else
  t_fail "moduł NIE działa poprawnie na poprawnym repo (rc=$T1_RC)"
  printf '%s\n' "$T1_OUT" | tail -30
fi

# ── T2: fail-closed — brak ARCHITECTURE.md → ARCH-001 FAIL ─────────────────
echo ""
echo "--- T2: fail-closed — brak ARCHITECTURE.md → ARCH-001 FAIL ---"
T2_DIR="$(mktemp -d)"
make_isolated_repo "$T2_DIR" --no-arch >/dev/null

T2_OUT="$(cd "$T2_DIR" && VERIFY_STATE_DB="$T2_DIR/nonexistent.db" bash "$ARCH_SH" 2>&1)"
T2_RC=$?
if [ "$T2_RC" -ne 0 ] && printf '%s' "$T2_OUT" | grep -q "\[FAIL\] ARCH-001"; then
  t_pass "brak ARCHITECTURE.md → ARCH-001 FAIL (fail-closed, rc=$T2_RC)"
else
  t_fail "brak ARCHITECTURE.md NIE dał ARCH-001 FAIL (rc=$T2_RC)"
  printf '%s\n' "$T2_OUT" | tail -30
fi

# ── T3: fail-closed — ARCHITECTURE.md z STATUS: UNDEFINED → ARCH-004 FAIL ──
echo ""
echo "--- T3: fail-closed — ARCHITECTURE.md z STATUS: UNDEFINED → ARCH-004 FAIL ---"
T3_DIR="$(mktemp -d)"
make_isolated_repo "$T3_DIR" --undefined-arch >/dev/null

T3_OUT="$(cd "$T3_DIR" && VERIFY_STATE_DB="$T3_DIR/nonexistent.db" bash "$ARCH_SH" 2>&1)"
T3_RC=$?
if [ "$T3_RC" -ne 0 ] && printf '%s' "$T3_OUT" | grep -q "\[FAIL\] ARCH-004"; then
  t_pass "ARCHITECTURE.md z STATUS: UNDEFINED → ARCH-004 FAIL (fail-closed, rc=$T3_RC)"
else
  t_fail "ARCHITECTURE.md z STATUS: UNDEFINED NIE dał ARCH-004 FAIL (rc=$T3_RC)"
  printf '%s\n' "$T3_OUT" | tail -30
fi

# ── T4: ARCHITECTURE.md bez linków → ARCH-007 WARN (rc=0) ──────────────────
echo ""
echo "--- T4: ARCHITECTURE.md bez linków do SoT/OWNERSHIP → ARCH-007 WARN ---"
T4_DIR="$(mktemp -d)"
make_isolated_repo "$T4_DIR" --no-links >/dev/null

T4_OUT="$(cd "$T4_DIR" && VERIFY_STATE_DB="$T4_DIR/nonexistent.db" bash "$ARCH_SH" 2>&1)"
T4_RC=$?
if [ "$T4_RC" -eq 0 ] \
   && printf '%s' "$T4_OUT" | grep -q "\[WARN\] ARCH-007" \
   && printf '%s' "$T4_OUT" | grep -q "\[PASS\] ARCH-004" \
   && printf '%s' "$T4_OUT" | grep -q "\[PASS\] ARCH-005" \
   && printf '%s' "$T4_OUT" | grep -q "\[PASS\] ARCH-006"; then
  t_pass "ARCHITECTURE.md bez linków → ARCH-007 WARN, rc=0 (WARNING nie blokuje)"
else
  t_fail "ARCHITECTURE.md bez linków NIE dał ARCH-007 WARN (rc=$T4_RC)"
  printf '%s\n' "$T4_OUT" | tail -30
fi

# ── Podsumowanie ───────────────────────────────────────────────────────────
echo ""
echo "=== ARCHITECTURE (ARCHITEKTURA) — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASS"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
