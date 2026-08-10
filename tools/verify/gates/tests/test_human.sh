#!/usr/bin/env bash
# ============================================================================
# test_human.sh — NEGATIVE/POSITIVE TESTS for GATE-041 (HUMAN-SIMULATION)
# ============================================================================
# Testuje że gate human (HUM-REG-01..08) ma wymagane elementy:
#   T1: pipeline'y P-079..P-089 zarejestrowane w pipelines.sh -> PASS
#   T2: skrypty tools/automation/human/ istnieją (11 plików) -> PASS
#   T3: skrypty mają set -u -> PASS
#   T4: skrypty kończą się p_module_exit (FAIL-CLOSED) -> PASS
#   T5: skrypty mają p_contract -> PASS
#   T6: skrypty mają p_dual_verdict -> PASS
#   T7: skrypty mają p_register_run -> PASS
#   T8: skrypty mają p_evidence -> PASS
#   T9: (kontrola negatywna) czysty pipelines.sh BEZ P-079 -> grep HUM-REG-01
#       NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty skrypt BEZ p_module_exit -> grep
#        HUM-REG-03 NIE pasuje -> PASS
#
# Użycie: ./test_human.sh
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

echo "=== TESTS — GATE-041 HUMAN-SIMULATION ==="

PIPELINES_SH="$ROOT/tools/automation/core/pipelines.sh"
HUMAN_DIR="$ROOT/tools/automation/human"

# Lista pipeline'ów i skryptów (zgodna z gate human.sh).
STAGES=(
  "P-079|setup.sh"
  "P-080|navigate.sh"
  "P-081|wait.sh"
  "P-082|screenshot.sh"
  "P-083|interact.sh"
  "P-084|assert.sh"
  "P-085|record.sh"
  "P-086|report.sh"
  "P-087|replay.sh"
  "P-088|terminal.sh"
  "P-089|vm.sh"
)

# --- T1: pipeline'y P-079..P-089 zarejestrowane w pipelines.sh --------------
echo ""
echo "--- T1: pipeline'y P-079..P-089 zarejestrowane w pipelines.sh ---"
if [ -f "$PIPELINES_SH" ]; then
    MISSING=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        if ! grep -qE "\"$pid\|HUMAN-SIMULATION" "$PIPELINES_SH" 2>/dev/null; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak rejestracji %s\n' "$pid"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 11 pipeline'ów HUMAN-SIMULATION zarejestrowane w pipelines.sh"
    else
        t_fail "Brak rejestracji $MISSING pipeline'ów w pipelines.sh"
    fi
else
    t_fail "Brak tools/automation/core/pipelines.sh"
fi

# --- T2: skrypty tools/automation/human/ istnieją ---------------------------
echo ""
echo "--- T2: skrypty tools/automation/human/ istnieją (11 plików) ---"
if [ -d "$HUMAN_DIR" ]; then
    MISSING=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        if [ ! -f "$HUMAN_DIR/$script" ]; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak skryptu %s (%s)\n' "$pid" "$script"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 11 skryptów human/ istnieją"
    else
        t_fail "Brak $MISSING skryptów w tools/automation/human/"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T3: skrypty mają set -u -------------------------------------------------
echo ""
echo "--- T3: skrypty mają set -u ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_SET_U=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'set -[a-z]*u' "$f" 2>/dev/null; then
            NO_SET_U=$((NO_SET_U+1))
            printf '  [INFO] %s bez set -u\n' "$pid"
        fi
    done
    if [ "$NO_SET_U" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają set -u"
    else
        t_fail "$NO_SET_U skryptów bez set -u"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T4: skrypty kończą się p_module_exit (FAIL-CLOSED) ----------------------
echo ""
echo "--- T4: skrypty kończą się p_module_exit (FAIL-CLOSED) ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_EXIT=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_module_exit' "$f" 2>/dev/null; then
            NO_EXIT=$((NO_EXIT+1))
            printf '  [INFO] %s bez p_module_exit\n' "$pid"
        fi
    done
    if [ "$NO_EXIT" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają p_module_exit (FAIL-CLOSED)"
    else
        t_fail "$NO_EXIT skryptów bez p_module_exit"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T5: skrypty mają p_contract ---------------------------------------------
echo ""
echo "--- T5: skrypty mają p_contract ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_CONTRACT=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE "p_contract \"$pid\"" "$f" 2>/dev/null; then
            NO_CONTRACT=$((NO_CONTRACT+1))
            printf '  [INFO] %s bez p_contract\n' "$pid"
        fi
    done
    if [ "$NO_CONTRACT" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają p_contract"
    else
        t_fail "$NO_CONTRACT skryptów bez p_contract"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T6: skrypty mają p_dual_verdict -----------------------------------------
echo ""
echo "--- T6: skrypty mają p_dual_verdict ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_DUAL=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_dual_verdict' "$f" 2>/dev/null; then
            NO_DUAL=$((NO_DUAL+1))
            printf '  [INFO] %s bez p_dual_verdict\n' "$pid"
        fi
    done
    if [ "$NO_DUAL" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają p_dual_verdict"
    else
        t_fail "$NO_DUAL skryptów bez p_dual_verdict"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T7: skrypty mają p_register_run -----------------------------------------
echo ""
echo "--- T7: skrypty mają p_register_run ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_REGISTER=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_register_run' "$f" 2>/dev/null; then
            NO_REGISTER=$((NO_REGISTER+1))
            printf '  [INFO] %s bez p_register_run\n' "$pid"
        fi
    done
    if [ "$NO_REGISTER" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają p_register_run"
    else
        t_fail "$NO_REGISTER skryptów bez p_register_run"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T8: skrypty mają p_evidence ---------------------------------------------
echo ""
echo "--- T8: skrypty mają p_evidence ---"
if [ -d "$HUMAN_DIR" ]; then
    NO_EVIDENCE=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$HUMAN_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_evidence' "$f" 2>/dev/null; then
            NO_EVIDENCE=$((NO_EVIDENCE+1))
            printf '  [INFO] %s bez p_evidence\n' "$pid"
        fi
    done
    if [ "$NO_EVIDENCE" -eq 0 ]; then
        t_pass "Wszystkie skrypty human/ mają p_evidence"
    else
        t_fail "$NO_EVIDENCE skryptów bez p_evidence"
    fi
else
    t_fail "Brak katalogu tools/automation/human/"
fi

# --- T9: kontrola negatywna — czysty pipelines.sh bez P-079 ------------------
echo ""
echo "--- T9: czysty pipelines.sh bez P-079 -> grep HUM-REG-01 NIE pasuje ---"
# HUM-REG-01 w human.sh grepuje '"P-079|HUMAN-SIMULATION' itd.
# Czysty plik bez tych wpisów musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-pipelines.sh" <<'EOF'
#!/usr/bin/env bash
# czysty plik bez pipeline'ów HUMAN-SIMULATION
PIPELINES=(
  "P-001|PRODUCT|product/foo.sh|STANDARD|IMPLEMENTED||DISCOVER"
)
EOF
if grep -qE '"P-079\|HUMAN-SIMULATION' "$WORK/clean-pipelines.sh" \
   || grep -qE '"P-089\|HUMAN-SIMULATION' "$WORK/clean-pipelines.sh"; then
    t_fail "Fałszywy pozytyw — czysty pipelines.sh pasuje do grep HUM-REG-01"
else
    t_pass "Czysty pipelines.sh NIE pasuje do grep HUM-REG-01 (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty skrypt bez p_module_exit ---------------
echo ""
echo "--- T10: czysty skrypt bez p_module_exit -> grep HUM-REG-03 NIE pasuje ---"
# HUM-REG-03 w human.sh grepuje 'p_module_exit'. Czysty skrypt bez tego
# wywołania musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-script.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "hello"
EOF
if grep -qE 'p_module_exit' "$WORK/clean-script.sh" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty skrypt pasuje do grep HUM-REG-03"
else
    t_pass "Czysty skrypt NIE pasuje do grep HUM-REG-03 (brak fałszywego pozytywu)"
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
