#!/usr/bin/env bash
# ============================================================================
# test_lifecycle.sh — NEGATIVE/POSITIVE TESTS for GATE-040 (LIFECYCLE)
# ============================================================================
# Testuje że gate lifecycle (LIFECYCLE-001..009) ma wymagane elementy:
#   T1: docs/00-foundation/LIFECYCLE.md istnieje i nie jest placeholderem
#       -> PASS
#   T2: state machine (IDEA→RETIRED, nigdy "DONE") jest kompletny -> PASS
#   T3: fazy F00-F17 zdefiniowane -> PASS
#   T4: gate'y G0-G17 zdefiniowane -> PASS
#   T5: model artefaktów (CHANGE_ID→VERIFICATION_ID) kompletny -> PASS
#   T6: traceability matrix obecna -> PASS
#   T7: StateStore ma tabele requirement/change/verification/release -> PASS
#   T8: registry.sh ma wpis GATE-040 LIFECYCLE -> PASS
#   T9: (kontrola negatywna) czysty plik bez state machine -> grep NIE pasuje
#       -> PASS
#
# Użycie: ./test_lifecycle.sh
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

echo "=== TESTS — GATE-040 LIFECYCLE ==="

LIFECYCLE_DOC="$ROOT/docs/00-foundation/LIFECYCLE.md"
STATE_DB="$ROOT/system/control-plane/state/data/canonical-state.db"
REGISTRY_SH="$ROOT/tools/verify/gates/registry.sh"

# --- T1: LIFECYCLE.md istnieje i nie jest placeholderem ---------------------
echo ""
echo "--- T1: LIFECYCLE.md istnieje i nie jest placeholderem ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    if grep -qiE 'placeholder|TODO|coming soon|brak implementacji' "$LIFECYCLE_DOC" 2>/dev/null; then
        t_fail "LIFECYCLE.md zawiera placeholder"
    else
        t_pass "LIFECYCLE.md istnieje i nie jest placeholderem"
    fi
else
    t_fail "Brak docs/00-foundation/LIFECYCLE.md"
fi

# --- T2: state machine (IDEA→RETIRED) kompletny -----------------------------
echo ""
echo "--- T2: state machine (IDEA→RETIRED) kompletny ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    # State machine jest w bloku kodu WIELOLINIOWYM — normalizujemy nowe linie.
    if tr '\n' ' ' < "$LIFECYCLE_DOC" 2>/dev/null | grep -qE 'IDEA.*DISCOVERING.*DEFINED.*CONTRACTED.*DESIGNED.*IMPLEMENTING.*VERIFYING.*INTEGRATING.*HARDENING.*RELEASING.*STAGING.*CERTIFIED.*CANARY.*PRODUCTION.*OPERATING.*DEPRECATED.*RETIRED'; then
        t_pass "State machine IDEA→RETIRED kompletny"
    else
        t_fail "State machine niekompletny (brak pełnej sekwencji IDEA→RETIRED)"
    fi
else
    t_fail "Brak LIFECYCLE.md (nie można sprawdzić state machine)"
fi

# --- T3: fazy F00-F17 zdefiniowane ------------------------------------------
echo ""
echo "--- T3: fazy F00-F17 zdefiniowane ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    if grep -q 'F00' "$LIFECYCLE_DOC" 2>/dev/null && grep -q 'F17' "$LIFECYCLE_DOC" 2>/dev/null; then
        t_pass "Fazy F00 i F17 obecne"
    else
        t_fail "Brak faz F00/F17 w konstytucji"
    fi
else
    t_fail "Brak LIFECYCLE.md (nie można sprawdzić faz)"
fi

# --- T4: gate'y G0-G17 zdefiniowane -----------------------------------------
echo ""
echo "--- T4: gate'y G0-G17 zdefiniowane ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    if grep -q 'G0' "$LIFECYCLE_DOC" 2>/dev/null && grep -q 'G17' "$LIFECYCLE_DOC" 2>/dev/null; then
        t_pass "Gate'y G0 i G17 obecne"
    else
        t_fail "Brak gate'ów G0/G17 w konstytucji"
    fi
else
    t_fail "Brak LIFECYCLE.md (nie można sprawdzić gate'ów)"
fi

# --- T5: model artefaktów (CHANGE_ID→VERIFICATION_ID) kompletny -------------
echo ""
echo "--- T5: model artefaktów (CHANGE_ID→VERIFICATION_ID) kompletny ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    # Model artefaktów jest w bloku kodu WIELOLINIOWYM — normalizujemy nowe linie.
    if tr '\n' ' ' < "$LIFECYCLE_DOC" 2>/dev/null | grep -qE 'CHANGE_ID.*REQUIREMENT_ID.*CONTRACT_ID.*DESIGN_ID.*CODE_ID.*TEST_ID.*GATE_ID.*BUILD_ID.*ARTIFACT_ID.*RELEASE_ID.*DEPLOYMENT_ID.*RUNTIME_ID.*EVIDENCE_ID.*VERIFICATION_ID'; then
        t_pass "Model artefaktów CHANGE_ID→VERIFICATION_ID kompletny"
    else
        t_fail "Model artefaktów niekompletny"
    fi
else
    t_fail "Brak LIFECYCLE.md (nie można sprawdzić modelu artefaktów)"
fi

# --- T6: traceability matrix obecna -----------------------------------------
echo ""
echo "--- T6: traceability matrix obecna ---"
if [ -f "$LIFECYCLE_DOC" ]; then
    if grep -qE 'REQUIREMENT.*CONTRACT.*DESIGN.*CODE.*TEST.*GATE.*EVIDENCE.*VERIFICATION' "$LIFECYCLE_DOC" 2>/dev/null; then
        t_pass "Traceability matrix obecna"
    else
        t_fail "Brak traceability matrix"
    fi
else
    t_fail "Brak LIFECYCLE.md (nie można sprawdzić traceability)"
fi

# --- T7: StateStore ma tabele lifecycle -------------------------------------
echo ""
echo "--- T7: StateStore ma tabele requirement/change/verification/release ---"
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
    missing=""
    for t in requirement change verification release; do
        if ! sqlite3 "$STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='$t';" 2>/dev/null | grep -q "$t"; then
            missing="$missing $t"
        fi
    done
    if [ -z "$missing" ]; then
        t_pass "StateStore ma tabele requirement/change/verification/release"
    else
        t_fail "StateStore brakuje tabel:$missing"
    fi
else
    t_fail "Brak sqlite3 lub bazy canonical-state.db (nie można sprawdzić tabel)"
fi

# --- T8: registry.sh ma wpis GATE-040 LIFECYCLE -----------------------------
echo ""
echo "--- T8: registry.sh ma wpis GATE-040 LIFECYCLE ---"
if [ -f "$REGISTRY_SH" ]; then
    if grep -q 'GATE-040' "$REGISTRY_SH" 2>/dev/null && grep -q 'LIFECYCLE' "$REGISTRY_SH" 2>/dev/null; then
        t_pass "registry.sh ma wpis GATE-040 LIFECYCLE"
    else
        t_fail "registry.sh NIE ma wpisu GATE-040 LIFECYCLE"
    fi
else
    t_fail "Brak registry.sh"
fi

# --- T9: kontrola negatywna — czysty plik bez state machine -----------------
echo ""
echo "--- T9: czysty plik bez state machine -> grep NIE pasuje ---"
# LIFECYCLE-003 grepuje pełną sekwencję IDEA→RETIRED. Czysty plik bez tych
# kluczy musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean.md" <<'EOF'
# Zwykły dokument bez state machine
Ten dokument opisuje prosty proces bez faz i gate'ów.
EOF
if tr '\n' ' ' < "$WORK/clean.md" 2>/dev/null | grep -qE 'IDEA.*DISCOVERING.*DEFINED.*CONTRACTED.*DESIGNED.*IMPLEMENTING.*VERIFYING.*INTEGRATING.*HARDENING.*RELEASING.*STAGING.*CERTIFIED.*CANARY.*PRODUCTION.*OPERATING.*DEPRECATED.*RETIRED'; then
    t_fail "Fałszywy pozytyw — czysty plik pasuje do grep state machine"
else
    t_pass "Czysty plik NIE pasuje do grep state machine (brak fałszywego pozytywu)"
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
