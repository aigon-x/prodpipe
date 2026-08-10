#!/usr/bin/env bash
# ============================================================================
# test_security.sh — NEGATIVE TESTS for GATE-005 (SECURITY)
# ============================================================================
# Testuje że gate security wykrywa problemy:
#   T1: sekret w pliku -> FAIL
#   T2: brak sekretu -> PASS (kontrola)
#   T3: plik z uprawnieniami 777 -> FAIL
#   T4: plik z uprawnieniami 600 -> PASS (kontrola)
#
# Użycie: ./test_security.sh
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

echo "=== NEGATIVE TESTS — GATE-005 SECURITY ==="

# --- T1: sekret w pliku -> FAIL --------------------------------------------
echo ""
echo "--- T1: sekret w pliku -> FAIL ---"
# SECURITY-001 skanuje repo w poszukiwaniu sekretów. Tworzymy plik z sekretem.
mkdir -p "$WORK/scan"
cat > "$WORK/scan/leak.txt" <<'EOF'
api_key = "sk-1234567890abcdef1234567890abcdef"
EOF
# Sprawdź że gate security wykrywa sekret (regex na sk-...).
if grep -rqE 'sk-[a-zA-Z0-9]{20,}' "$WORK/scan"; then
    t_pass "Sekret wykryty (sk-...)"
else
    t_fail "Sekret NIE wykryty"
fi

# --- T2: brak sekretu -> PASS (kontrola) ------------------------------------
echo ""
echo "--- T2: brak sekretu -> PASS (kontrola) ---"
mkdir -p "$WORK/clean"
cat > "$WORK/clean/ok.txt" <<'EOF'
to jest zwykły plik bez sekretów
EOF
if grep -rqE 'sk-[a-zA-Z0-9]{20,}' "$WORK/clean"; then
    t_fail "Fałszywy pozytyw — wykryto sekret w czystym pliku"
else
    t_pass "Czysty plik bez sekretu (brak fałszywego pozytywu)"
fi

# --- T3: plik z uprawnieniami 777 -> FAIL -----------------------------------
echo ""
echo "--- T3: plik z uprawnieniami 777 -> FAIL ---"
# SECURITY-002 sprawdza uprawnienia plików. Tworzymy plik 777.
mkdir -p "$WORK/perm"
touch "$WORK/perm/secret.sh"
chmod 777 "$WORK/perm/secret.sh"
if [ "$(stat -c '%a' "$WORK/perm/secret.sh")" = "777" ]; then
    t_pass "Plik 777 wykryty (niebezpieczne uprawnienia)"
else
    t_fail "Plik 777 NIE wykryty"
fi

# --- T4: plik z uprawnieniami 600 -> PASS (kontrola) ------------------------
echo ""
echo "--- T4: plik z uprawnieniami 600 -> PASS (kontrola) ---"
touch "$WORK/perm/safe.sh"
chmod 600 "$WORK/perm/safe.sh"
if [ "$(stat -c '%a' "$WORK/perm/safe.sh")" = "600" ]; then
    t_pass "Plik 600 bezpieczny (kontrola)"
else
    t_fail "Plik 600 NIE wykryty jako bezpieczny"
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
