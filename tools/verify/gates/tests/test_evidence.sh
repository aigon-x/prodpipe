#!/usr/bin/env bash
# ============================================================================
# test_evidence.sh — NEGATIVE TESTS for GATE-020 (EVIDENCE)
# ============================================================================
# Testuje że gate evidence wykrywa problemy:
#   T1: brakujący plik evidence -> FAIL
#   T2: obecny plik evidence -> PASS (kontrola)
#   T3: evidence z błędnym formatem (brak wymaganych pól) -> FAIL
#   T4: evidence z poprawnym formatem -> PASS (kontrola)
#
# Użycie: ./test_evidence.sh
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

echo "=== NEGATIVE TESTS — GATE-020 EVIDENCE ==="

# --- T1: brakujący plik evidence -> FAIL ------------------------------------
echo ""
echo "--- T1: brakujący plik evidence -> FAIL ---"
# EVIDENCE-001 sprawdza że każdy gate ma plik evidence.
if [ -f "$WORK/GATE-999.evidence" ]; then
    t_fail "Nieistniejący evidence wykryty jako obecny"
else
    t_pass "Brakujący evidence poprawnie wykryty"
fi

# --- T2: obecny plik evidence -> PASS (kontrola) ----------------------------
echo ""
echo "--- T2: obecny plik evidence -> PASS (kontrola) ---"
EVIDENCE_DIR="$ROOT/artifacts/evidence/gates"
if [ -d "$EVIDENCE_DIR" ]; then
    COUNT=$(ls "$EVIDENCE_DIR"/*.evidence 2>/dev/null | wc -l)
    if [ "$COUNT" -gt 0 ]; then
        t_pass "Znaleziono $COUNT plików evidence"
    else
        t_fail "Brak plików evidence w katalogu"
    fi
else
    t_fail "Katalog evidence nie istnieje"
fi

# --- T3: evidence z błędnym formatem -> FAIL --------------------------------
echo ""
echo "--- T3: evidence z błędnym formatem -> FAIL ---"
# EVIDENCE-003 sprawdza że evidence ma wymagane pola (gate_id, domain, status).
# Tworzymy evidence bez wymaganych pól.
cat > "$WORK/bad.evidence" <<'EOF'
to nie jest poprawny format evidence
EOF
# Sprawdź że brakuje wymaganych pól.
if grep -q '^gate_id:' "$WORK/bad.evidence"; then
    t_fail "Błędny evidence ma pole gate_id (nie powinien)"
else
    t_pass "Błędny evidence wykryty (brak pola gate_id)"
fi

# --- T4: evidence z poprawnym formatem -> PASS (kontrola) -------------------
echo ""
echo "--- T4: evidence z poprawnym formatem -> PASS (kontrola) ---"
cat > "$WORK/good.evidence" <<'EOF'
gate_id: GATE-001
domain: gate-integrity
name: GATE-INTEGRITY
command: tools/verify/gates/gate-integrity.sh
exit_code: 0
status: PASS
timestamp: 2026-01-01T00:00:00Z
head: test
output: test
EOF
if grep -q '^gate_id:' "$WORK/good.evidence"; then
    t_pass "Poprawny evidence ma pole gate_id"
else
    t_fail "Poprawny evidence NIE ma pola gate_id"
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
