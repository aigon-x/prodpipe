#!/usr/bin/env bash
# ============================================================================
# test_observability.sh — NEGATIVE/POSITIVE TESTS for GATE-043 (OBSERVABILITY)
# ============================================================================
# Testuje że gate observability (OBS-001..015) ma wymagane elementy:
#   T1: narzędzie tools/explore/explore.sh istnieje -> PASS
#   T2: biblioteki lib/ istnieją (8 plików) -> PASS
#   T3: testy tests/ istnieją (5 plików) -> PASS
#   T4: explore.sh ma set -u -> PASS
#   T5: explore.sh ma komendę all (GŁÓWNA KOMENDA) -> PASS
#   T6: biblioteki lib/ mają set -u -> PASS
#   T7: biblioteki lib/ nie mają false green (|| true, set +e) -> PASS
#   T8: gate observability.sh kończy się verify_module_exit (FAIL-CLOSED) -> PASS
#   T9: (kontrola negatywna) czysty explore.sh BEZ komendy all -> grep
#       OBS-006 NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty skrypt BEZ verify_module_exit -> grep
#        OBS-008 NIE pasuje -> PASS
#
# Użycie: ./test_observability.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$GATES_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== TESTS — GATE-043 OBSERVABILITY ==="

EXPLORE_SH="$ROOT/tools/explore/explore.sh"
EXPLORE_LIB="$ROOT/tools/explore/lib"
EXPLORE_TESTS="$ROOT/tools/explore/tests"
OBS_GATE="$ROOT/tools/verify/gates/domains/observability.sh"

# Lista bibliotek i testów (zgodna z gate observability.sh).
LIBS=(
  "discovery.sh"
  "model.sh"
  "git.sh"
  "docs.sh"
  "graphs.sh"
  "html.sh"
  "validate.sh"
  "security.sh"
)
TESTS=(
  "test-explorer.sh"
  "test-model.sh"
  "test-graphs.sh"
  "test-html.sh"
  "test-determinism.sh"
)

# --- T1: narzędzie tools/explore/explore.sh istnieje ------------------------
echo ""
echo "--- T1: narzędzie tools/explore/explore.sh istnieje ---"
if [ -f "$EXPLORE_SH" ]; then
    t_pass "explore.sh istnieje"
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T2: biblioteki lib/ istnieją (8 plików) --------------------------------
echo ""
echo "--- T2: biblioteki lib/ istnieją (8 plików) ---"
if [ -d "$EXPLORE_LIB" ]; then
    MISSING=0
    for libf in "${LIBS[@]}"; do
        if [ ! -f "$EXPLORE_LIB/$libf" ]; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak biblioteki %s\n' "$libf"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 8 bibliotek lib/ istnieją"
    else
        t_fail "Brak $MISSING bibliotek w tools/explore/lib/"
    fi
else
    t_fail "Brak katalogu tools/explore/lib/"
fi

# --- T3: testy tests/ istnieją (5 plików) -----------------------------------
echo ""
echo "--- T3: testy tests/ istnieją (5 plików) ---"
if [ -d "$EXPLORE_TESTS" ]; then
    MISSING=0
    for tf in "${TESTS[@]}"; do
        if [ ! -f "$EXPLORE_TESTS/$tf" ]; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak testu %s\n' "$tf"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 5 testów tests/ istnieją"
    else
        t_fail "Brak $MISSING testów w tools/explore/tests/"
    fi
else
    t_fail "Brak katalogu tools/explore/tests/"
fi

# --- T4: explore.sh ma set -u ------------------------------------------------
echo ""
echo "--- T4: explore.sh ma set -u ---"
if [ -f "$EXPLORE_SH" ]; then
    if grep -qE 'set -[a-z]*u' "$EXPLORE_SH" 2>/dev/null; then
        t_pass "explore.sh ma set -u"
    else
        t_fail "explore.sh bez set -u"
    fi
else
    t_fail "Brak explore.sh"
fi

# --- T5: explore.sh ma komendę all (GŁÓWNA KOMENDA) --------------------------
echo ""
echo "--- T5: explore.sh ma komendę all (GŁÓWNA KOMENDA) ---"
if [ -f "$EXPLORE_SH" ]; then
    if grep -qE 'explore_all\(\)' "$EXPLORE_SH" 2>/dev/null \
       && grep -qE 'all\)' "$EXPLORE_SH" 2>/dev/null; then
        t_pass "explore.sh ma komendę all"
    else
        t_fail "explore.sh bez komendy all"
    fi
else
    t_fail "Brak explore.sh"
fi

# --- T6: biblioteki lib/ mają set -u -----------------------------------------
echo ""
echo "--- T6: biblioteki lib/ mają set -u ---"
if [ -d "$EXPLORE_LIB" ]; then
    NO_SET_U=0
    for libf in "${LIBS[@]}"; do
        f="$EXPLORE_LIB/$libf"
        [ -f "$f" ] || continue
        if ! grep -qE 'set -[a-z]*u' "$f" 2>/dev/null; then
            NO_SET_U=$((NO_SET_U+1))
            printf '  [INFO] %s bez set -u\n' "$libf"
        fi
    done
    if [ "$NO_SET_U" -eq 0 ]; then
        t_pass "Wszystkie biblioteki lib/ mają set -u"
    else
        t_fail "$NO_SET_U bibliotek bez set -u"
    fi
else
    t_fail "Brak katalogu tools/explore/lib/"
fi

# --- T7: biblioteki lib/ nie mają false green (|| true, set +e) --------------
echo ""
echo "--- T7: biblioteki lib/ nie mają false green (|| true, set +e) ---"
if [ -d "$EXPLORE_LIB" ]; then
    FALSE_GREEN=0
    for libf in "${LIBS[@]}"; do
        f="$EXPLORE_LIB/$libf"
        [ -f "$f" ] || continue
        if awk '
            /^[[:space:]]*#/ { next }
            /<<[[:space:]]*['\''"]?[A-Za-z_]+/ { in_heredoc=1; next }
            in_heredoc && /^[[:space:]]*[A-Za-z_]+[[:space:]]*$/{ in_heredoc=0; next }
            in_heredoc { next }
            {
                line=$0
                gsub(/"[^"]*"/, "", line)
                gsub(/'\''[^'\'']*'\''/, "", line)
                if (line ~ /(^|[^'\''"])set \+[e]([[:space:]]|$)/ ||
                    line ~ /(^|[^'\''"])continue-on-[e]rror([[:space:]]|$)/ ||
                    line ~ /(^|[^'\''"])\|\| tru[e]([[:space:]]|$)/) print
            }
        ' "$f" 2>/dev/null | grep -q .; then
            FALSE_GREEN=$((FALSE_GREEN+1))
            printf '  [INFO] %s ma false green\n' "$libf"
        fi
    done
    if [ "$FALSE_GREEN" -eq 0 ]; then
        t_pass "Wszystkie biblioteki lib/ bez false green"
    else
        t_fail "$FALSE_GREEN bibliotek z false green"
    fi
else
    t_fail "Brak katalogu tools/explore/lib/"
fi

# --- T8: gate observability.sh kończy się verify_module_exit (FAIL-CLOSED) ---
echo ""
echo "--- T8: gate observability.sh kończy się verify_module_exit (FAIL-CLOSED) ---"
if [ -f "$OBS_GATE" ]; then
    if grep -qE 'verify_module_exit' "$OBS_GATE" 2>/dev/null; then
        t_pass "observability.sh ma verify_module_exit (FAIL-CLOSED)"
    else
        t_fail "observability.sh bez verify_module_exit"
    fi
else
    t_fail "Brak tools/verify/gates/domains/observability.sh"
fi

# --- T9: kontrola negatywna — czysty explore.sh bez komendy all --------------
echo ""
echo "--- T9: czysty explore.sh bez komendy all -> grep OBS-006 NIE pasuje ---"
# OBS-006 w observability.sh grepuje 'explore_all()' i 'all)'. Czysty plik
# bez tych wpisów musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-explore.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "hello"
EOF
if grep -qE 'explore_all\(\)' "$WORK/clean-explore.sh" 2>/dev/null \
   || grep -qE 'all\)' "$WORK/clean-explore.sh" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty explore.sh pasuje do grep OBS-006"
else
    t_pass "Czysty explore.sh NIE pasuje do grep OBS-006 (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty skrypt bez verify_module_exit ----------
echo ""
echo "--- T10: czysty skrypt bez verify_module_exit -> grep OBS-008 NIE pasuje ---"
# OBS-008 w observability.sh grepuje 'verify_module_exit'. Czysty skrypt bez
# tego wywołania musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-gate.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "hello"
EOF
if grep -qE 'verify_module_exit' "$WORK/clean-gate.sh" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty skrypt pasuje do grep OBS-008"
else
    t_pass "Czysty skrypt NIE pasuje do grep OBS-008 (brak fałszywego pozytywu)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
