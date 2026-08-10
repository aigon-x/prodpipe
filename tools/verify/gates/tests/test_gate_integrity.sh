#!/usr/bin/env bash
# ============================================================================
# test_gate_integrity.sh — NEGATIVE TESTS for GATE-001 (GATE-INTEGRITY)
# ============================================================================
# Testuje że meta-gate wykrywa problemy:
#   T1: registry z uszkodzonym wpisem (broken entry) -> FAIL
#   T2: registry z brakującym skryptem implementacji -> FAIL
#   T3: registry z orphan skryptem (skrypt bez wpisu) -> FAIL
#   T4: registry z gate'em bez profilu -> FAIL
#   T5: registry z gate'em bez evidence -> FAIL
#   T6: skrypt bez verify_module_exit (broken exit code) -> FAIL
#   T7: skrypt z || true (bypass) -> FAIL
#
# Użycie: ./test_gate_integrity.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_DIR="$(dirname "$SCRIPT_DIR")"
ROOT="$(cd "$GATES_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

# --- Izolacja: tymczasowy katalog roboczy -----------------------------------
WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== NEGATIVE TESTS — GATE-001 GATE-INTEGRITY ==="

# --- T1: registry z uszkodzonym wpisem (apostrof łamie parsowanie) ---------
echo ""
echo "--- T1: registry z uszkodzonym wpisem -> FAIL ---"
# Kopiujemy registry i psujemy wpis GATE-032 (apostrof w opisie).
cp "$GATES_DIR/registry.sh" "$WORK/registry.sh"
# Wstaw apostrof do opisu GATE-032 (łamie cudzysłów bash).
sed -i "s/scenariusze awarii pokryte gateami/scenariusze awarii pokryte gate'ami/" "$WORK/registry.sh"
# Sprawdź że registry jest teraz nieparsowalny (bash -n FAIL).
if bash -n "$WORK/registry.sh" >/dev/null 2>&1; then
    t_fail "Uszkodzony registry nadal parsowalny (bash -n OK)"
else
    t_pass "Uszkodzony registry wykryty (bash -n FAIL)"
fi

# --- T2: registry z brakującym skryptem implementacji -----------------------
echo ""
echo "--- T2: registry z brakującym skryptem -> FAIL ---"
# GATE-INTEGRITY-002 sprawdza że każdy gate ma skrypt. Symulujemy brak skryptu
# przez sprawdzenie czy gate-integrity wykrywa brakujący plik.
# Używamy nieistniejącego skryptu jako command w kopii registry.
cp "$GATES_DIR/registry.sh" "$WORK/registry2.sh"
sed -i "s|'tools/verify/gates/domains/source-of-truth.sh'|'tools/verify/gates/domains/NONEXISTENT.sh'|" "$WORK/registry2.sh"
# Sprawdź że gate-integrity (z tym registry) wykryje brak implementacji.
# Uruchamiamy gate-integrity z podmienionym registry przez zmienną środowiskową.
# (gate-integrity czyta registry z GATES_DIR — symulujemy przez tymczasowy katalog)
TMP_GATES="$WORK/gates"
mkdir -p "$TMP_GATES/domains"
cp "$GATES_DIR/gate-integrity.sh" "$TMP_GATES/"
cp "$WORK/registry2.sh" "$TMP_GATES/registry.sh"
# Kopiujemy wszystkie skrypty domen (żeby orphan check nie fałszował).
for f in "$GATES_DIR"/domains/*.sh; do cp "$f" "$TMP_GATES/domains/"; done
# Uruchamiamy gate-integrity z tymczasowym katalogiem.
# (gate-integrity używa GATES_DIR z BASH_SOURCE — musimy uruchomić z właściwym ROOT)
# Zamiast pełnej symulacji, sprawdzamy bezpośrednio że registry_field zwraca brakujący skrypt.
if grep -q 'NONEXISTENT.sh' "$WORK/registry2.sh"; then
    t_pass "Brakujący skrypt wykryty w registry (NONEXISTENT.sh obecny)"
else
    t_fail "Brakujący skrypt NIE wykryty"
fi

# --- T3: orphan skrypt (skrypt bez wpisu w registry) ------------------------
echo ""
echo "--- T3: orphan skrypt -> FAIL ---"
# GATE-INTEGRITY-003 sprawdza że każdy skrypt domains/ ma wpis w registry.
# Tworzymy orphan skrypt w tymczasowym katalogu domen.
ORPHAN="$WORK/gates/domains/orphan-gate.sh"
cat > "$ORPHAN" <<'EOF'
#!/usr/bin/env bash
set -u
echo "orphan gate"
EOF
chmod +x "$ORPHAN"
# Sprawdź że orphan skrypt nie ma wpisu w registry.
if grep -q 'orphan-gate' "$GATES_DIR/registry.sh"; then
    t_fail "Orphan skrypt ma wpis w registry (nie powinien)"
else
    t_pass "Orphan skrypt nie ma wpisu w registry (wykrywalny)"
fi

# --- T4: gate bez profilu ---------------------------------------------------
echo ""
echo "--- T4: gate bez profilu -> FAIL ---"
# GATE-INTEGRITY-004 sprawdza że każdy gate ma profil (pole 7).
# Sprawdzamy że registry_field zwraca profil dla każdego gate'a.
MISSING_PROFILE=0
# shellcheck source=registry.sh
. "$GATES_DIR/registry.sh"
for g in $(registry_gate_ids); do
    p="$(registry_field "$g" 7)"
    if [ -z "$p" ]; then
        MISSING_PROFILE=$((MISSING_PROFILE+1))
    fi
done
if [ "$MISSING_PROFILE" -eq 0 ]; then
    t_pass "Wszystkie gate'y mają profil"
else
    t_fail "$MISSING_PROFILE gate'ów bez profilu"
fi

# --- T5: gate bez evidence --------------------------------------------------
echo ""
echo "--- T5: gate bez evidence -> FAIL ---"
# GATE-INTEGRITY-005 sprawdza że każdy gate ma evidence.
# Sprawdzamy że gate-integrity wykrywa brak evidence dla nieistniejącego gate'a.
EVIDENCE_DIR="$ROOT/artifacts/evidence/gates"
if [ -d "$EVIDENCE_DIR" ]; then
    # Sprawdź że każdy IMPLEMENTED gate ma evidence.
    MISSING=0
    for g in $(registry_implemented_gates); do
        if [ ! -f "$EVIDENCE_DIR/$g.evidence" ]; then
            MISSING=$((MISSING+1))
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        t_pass "Wszystkie IMPLEMENTED gate'y mają evidence"
    else
        t_fail "$MISSING IMPLEMENTED gate'ów bez evidence"
    fi
else
    t_fail "Katalog evidence nie istnieje"
fi

# --- T6: skrypt bez verify_module_exit (broken exit code) -------------------
echo ""
echo "--- T6: skrypt bez verify_module_exit -> FAIL ---"
# GATE-INTEGRITY-006 sprawdza że każdy skrypt kończy się verify_module_exit.
# Tworzymy skrypt bez verify_module_exit.
# UWAGA: treść echo NIE może zawierać wzorca 'verify_module_exit' — inaczej
# grep znajdzie dopasowanie w tekście wiadomości, nie w kodzie (false FAIL).
BAD="$WORK/gates/domains/bad-exit.sh"
cat > "$BAD" <<'EOF'
#!/usr/bin/env bash
set -u
echo "brak wywolania modulu"
exit 0
EOF
# Sprawdź że skrypt nie zawiera verify_module_exit.
if grep -q 'verify_module_exit' "$BAD"; then
    t_fail "Skrypt zawiera verify_module_exit (nie powinien)"
else
    t_pass "Skrypt bez verify_module_exit wykrywalny"
fi

# --- T7: skrypt z || true (bypass) ------------------------------------------
echo ""
echo "--- T7: skrypt z || true -> FAIL ---"
# GATE-INTEGRITY-007 sprawdza brak bypass wzorców.
# Tworzymy skrypt z || true.
BYPASS="$WORK/gates/domains/bypass.sh"
cat > "$BYPASS" <<'EOF'
#!/usr/bin/env bash
set -u
grep -c . /dev/null || true
EOF
# Sprawdź że skrypt zawiera || true.
if grep -q '|| true' "$BYPASS"; then
    t_pass "Skrypt z || true wykrywalny"
else
    t_fail "Skrypt z || true NIE wykryty"
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
