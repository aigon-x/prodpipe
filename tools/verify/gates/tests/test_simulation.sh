#!/usr/bin/env bash
# ============================================================================
# test_simulation.sh — NEGATIVE/POSITIVE TESTS for GATE-042 (SIMULATION)
# ============================================================================
# Testuje że gate simulation (SIM-REG-01..08) ma wymagane elementy:
#   T1: pipeline'y P-090..P-098 zarejestrowane w pipelines.sh -> PASS
#   T2: skrypty tools/automation/simulation/ istnieją (9 plików) -> PASS
#   T3: skrypty mają set -u -> PASS
#   T4: skrypty kończą się p_module_exit (FAIL-CLOSED) -> PASS
#   T5: skrypty mają p_contract -> PASS
#   T6: skrypty mają p_dual_verdict -> PASS
#   T7: skrypty mają p_register_run -> PASS
#   T8: skrypty mają p_evidence -> PASS
#   T9: (kontrola negatywna) czysty pipelines.sh BEZ P-090 -> grep SIM-REG-01
#       NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty skrypt BEZ p_module_exit -> grep
#        SIM-REG-03 NIE pasuje -> PASS
#
# Użycie: ./test_simulation.sh
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

echo "=== TESTS — GATE-042 SIMULATION ==="

PIPELINES_SH="$ROOT/tools/automation/core/pipelines.sh"
SIM_DIR="$ROOT/tools/automation/simulation"

# Lista pipeline'ów i skryptów (zgodna z gate simulation.sh).
STAGES=(
  "P-090|scenario.sh"
  "P-091|prepare.sh"
  "P-092|execute.sh"
  "P-093|observe.sh"
  "P-094|measure.sh"
  "P-095|evaluate.sh"
  "P-096|remediate.sh"
  "P-097|document.sh"
  "P-098|repeat.sh"
)

# --- T1: pipeline'y P-090..P-098 zarejestrowane w pipelines.sh --------------
echo ""
echo "--- T1: pipeline'y P-090..P-098 zarejestrowane w pipelines.sh ---"
if [ -f "$PIPELINES_SH" ]; then
    MISSING=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        if ! grep -qE "\"$pid\|SIMULATION" "$PIPELINES_SH" 2>/dev/null; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak rejestracji %s\n' "$pid"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 9 pipeline'ów SIMULATION zarejestrowane w pipelines.sh"
    else
        t_fail "Brak rejestracji $MISSING pipeline'ów w pipelines.sh"
    fi
else
    t_fail "Brak tools/automation/core/pipelines.sh"
fi

# --- T2: skrypty tools/automation/simulation/ istnieją -----------------------
echo ""
echo "--- T2: skrypty tools/automation/simulation/ istnieją (9 plików) ---"
if [ -d "$SIM_DIR" ]; then
    MISSING=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        if [ ! -f "$SIM_DIR/$script" ]; then
            MISSING=$((MISSING+1))
            printf '  [INFO] brak skryptu %s (%s)\n' "$pid" "$script"
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie 9 skryptów simulation/ istnieją"
    else
        t_fail "Brak $MISSING skryptów w tools/automation/simulation/"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T3: skrypty mają set -u -------------------------------------------------
echo ""
echo "--- T3: skrypty mają set -u ---"
if [ -d "$SIM_DIR" ]; then
    NO_SET_U=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'set -[a-z]*u' "$f" 2>/dev/null; then
            NO_SET_U=$((NO_SET_U+1))
            printf '  [INFO] %s bez set -u\n' "$pid"
        fi
    done
    if [ "$NO_SET_U" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają set -u"
    else
        t_fail "$NO_SET_U skryptów bez set -u"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T4: skrypty kończą się p_module_exit (FAIL-CLOSED) ----------------------
echo ""
echo "--- T4: skrypty kończą się p_module_exit (FAIL-CLOSED) ---"
if [ -d "$SIM_DIR" ]; then
    NO_EXIT=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_module_exit' "$f" 2>/dev/null; then
            NO_EXIT=$((NO_EXIT+1))
            printf '  [INFO] %s bez p_module_exit\n' "$pid"
        fi
    done
    if [ "$NO_EXIT" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają p_module_exit (FAIL-CLOSED)"
    else
        t_fail "$NO_EXIT skryptów bez p_module_exit"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T5: skrypty mają p_contract ---------------------------------------------
echo ""
echo "--- T5: skrypty mają p_contract ---"
if [ -d "$SIM_DIR" ]; then
    NO_CONTRACT=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE "p_contract \"$pid\"" "$f" 2>/dev/null; then
            NO_CONTRACT=$((NO_CONTRACT+1))
            printf '  [INFO] %s bez p_contract\n' "$pid"
        fi
    done
    if [ "$NO_CONTRACT" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają p_contract"
    else
        t_fail "$NO_CONTRACT skryptów bez p_contract"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T6: skrypty mają p_dual_verdict -----------------------------------------
echo ""
echo "--- T6: skrypty mają p_dual_verdict ---"
if [ -d "$SIM_DIR" ]; then
    NO_DUAL=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_dual_verdict' "$f" 2>/dev/null; then
            NO_DUAL=$((NO_DUAL+1))
            printf '  [INFO] %s bez p_dual_verdict\n' "$pid"
        fi
    done
    if [ "$NO_DUAL" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają p_dual_verdict"
    else
        t_fail "$NO_DUAL skryptów bez p_dual_verdict"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T7: skrypty mają p_register_run -----------------------------------------
echo ""
echo "--- T7: skrypty mają p_register_run ---"
if [ -d "$SIM_DIR" ]; then
    NO_REGISTER=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_register_run' "$f" 2>/dev/null; then
            NO_REGISTER=$((NO_REGISTER+1))
            printf '  [INFO] %s bez p_register_run\n' "$pid"
        fi
    done
    if [ "$NO_REGISTER" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają p_register_run"
    else
        t_fail "$NO_REGISTER skryptów bez p_register_run"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T8: skrypty mają p_evidence ---------------------------------------------
echo ""
echo "--- T8: skrypty mają p_evidence ---"
if [ -d "$SIM_DIR" ]; then
    NO_EVIDENCE=0
    for entry in "${STAGES[@]}"; do
        pid="${entry%%|*}"
        script="${entry#*|}"
        f="$SIM_DIR/$script"
        [ -f "$f" ] || continue
        if ! grep -qE 'p_evidence' "$f" 2>/dev/null; then
            NO_EVIDENCE=$((NO_EVIDENCE+1))
            printf '  [INFO] %s bez p_evidence\n' "$pid"
        fi
    done
    if [ "$NO_EVIDENCE" -eq 0 ]; then
        t_pass "Wszystkie skrypty simulation/ mają p_evidence"
    else
        t_fail "$NO_EVIDENCE skryptów bez p_evidence"
    fi
else
    t_fail "Brak katalogu tools/automation/simulation/"
fi

# --- T9: kontrola negatywna — czysty pipelines.sh bez P-090 ------------------
echo ""
echo "--- T9: czysty pipelines.sh bez P-090 -> grep SIM-REG-01 NIE pasuje ---"
# SIM-REG-01 w simulation.sh grepuje '"P-090|SIMULATION' itd.
# Czysty plik bez tych wpisów musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-pipelines.sh" <<'EOF'
#!/usr/bin/env bash
# czysty plik bez pipeline'ów SIMULATION
PIPELINES=(
  "P-001|PRODUCT|product/foo.sh|STANDARD|IMPLEMENTED||DISCOVER"
)
EOF
if grep -qE '"P-090\|SIMULATION' "$WORK/clean-pipelines.sh" \
   || grep -qE '"P-098\|SIMULATION' "$WORK/clean-pipelines.sh"; then
    t_fail "Fałszywy pozytyw — czysty pipelines.sh pasuje do grep SIM-REG-01"
else
    t_pass "Czysty pipelines.sh NIE pasuje do grep SIM-REG-01 (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty skrypt bez p_module_exit ---------------
echo ""
echo "--- T10: czysty skrypt bez p_module_exit -> grep SIM-REG-03 NIE pasuje ---"
# SIM-REG-03 w simulation.sh grepuje 'p_module_exit'. Czysty skrypt bez tego
# wywołania musi NIE pasować (brak fałszywego pozytywu).
cat > "$WORK/clean-script.sh" <<'EOF'
#!/usr/bin/env bash
set -u
echo "hello"
EOF
if grep -qE 'p_module_exit' "$WORK/clean-script.sh" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty skrypt pasuje do grep SIM-REG-03"
else
    t_pass "Czysty skrypt NIE pasuje do grep SIM-REG-03 (brak fałszywego pozytywu)"
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
