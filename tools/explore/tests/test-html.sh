#!/usr/bin/env bash
# ============================================================================
# test-html.sh — NEGATIVE/POSITIVE TESTS for HTML explorer (html.sh)
# ============================================================================
# Testuje że statyczny HTML explorer (docs/explorer/) ma wymagane elementy:
#   T1: docs/explorer/index.html istnieje -> PASS
#   T2: index.html jest poprawnym HTML (ma <html> i <body>) -> PASS
#   T3: index.html zawiera tytuł -> PASS
#   T4: index.html zawiera sekcję metryk -> PASS
#   T5: index.html zawiera sekcję pipeline'ów -> PASS
#   T6: index.html zawiera sekcję gate'ów -> PASS
#   T7: data/project-model.json istnieje -> PASS
#   T8: data/summary.json istnieje -> PASS
#   T9: (kontrola negatywna) czysty plik bez <html> -> grep NIE pasuje -> PASS
#   T10: (kontrola negatywna) czysty plik bez <body> -> grep NIE pasuje -> PASS
#
# Użycie: ./test-html.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); printf '  [PASS] %s\n' "$*"; }
t_fail() { FAIL=$((FAIL+1)); printf '  [FAIL] %s\n' "$*"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "=== TESTS — HTML explorer (html.sh) ==="

EXPLORER_DIR="$ROOT/docs/explorer"
INDEX_HTML="$EXPLORER_DIR/index.html"

# --- T1: docs/explorer/index.html istnieje -----------------------------------
echo ""
echo "--- T1: docs/explorer/index.html istnieje ---"
if [ -f "$INDEX_HTML" ]; then
    t_pass "docs/explorer/index.html istnieje"
else
    t_fail "Brak docs/explorer/index.html (uruchom explore.sh all)"
fi

# --- T2: index.html jest poprawnym HTML --------------------------------------
echo ""
echo "--- T2: index.html jest poprawnym HTML (ma <html> i <body>) ---"
if [ -f "$INDEX_HTML" ]; then
    if grep -q '<html' "$INDEX_HTML" 2>/dev/null && grep -q '<body' "$INDEX_HTML" 2>/dev/null; then
        t_pass "index.html ma <html> i <body>"
    else
        t_fail "index.html nie jest poprawnym HTML"
    fi
else
    t_fail "Brak docs/explorer/index.html"
fi

# --- T3: index.html zawiera tytuł --------------------------------------------
echo ""
echo "--- T3: index.html zawiera tytuł ---"
if [ -f "$INDEX_HTML" ]; then
    if grep -q '<title>' "$INDEX_HTML" 2>/dev/null; then
        t_pass "index.html ma <title>"
    else
        t_fail "index.html bez <title>"
    fi
else
    t_fail "Brak docs/explorer/index.html"
fi

# --- T4: index.html zawiera sekcję metryk ------------------------------------
echo ""
echo "--- T4: index.html zawiera sekcję metryk ---"
if [ -f "$INDEX_HTML" ]; then
    if grep -q 'Metryki' "$INDEX_HTML" 2>/dev/null; then
        t_pass "index.html ma sekcję metryk"
    else
        t_fail "index.html bez sekcji metryk"
    fi
else
    t_fail "Brak docs/explorer/index.html"
fi

# --- T5: index.html zawiera sekcję pipeline'ów -------------------------------
echo ""
echo "--- T5: index.html zawiera sekcję pipeline'ów ---"
if [ -f "$INDEX_HTML" ]; then
    if grep -q 'Pipeline' "$INDEX_HTML" 2>/dev/null; then
        t_pass "index.html ma sekcję pipeline'ów"
    else
        t_fail "index.html bez sekcji pipeline'ów"
    fi
else
    t_fail "Brak docs/explorer/index.html"
fi

# --- T6: index.html zawiera sekcję gate'ów -----------------------------------
echo ""
echo "--- T6: index.html zawiera sekcję gate'ów ---"
if [ -f "$INDEX_HTML" ]; then
    if grep -q 'Gate' "$INDEX_HTML" 2>/dev/null; then
        t_pass "index.html ma sekcję gate'ów"
    else
        t_fail "index.html bez sekcji gate'ów"
    fi
else
    t_fail "Brak docs/explorer/index.html"
fi

# --- T7: data/project-model.json istnieje ------------------------------------
echo ""
echo "--- T7: data/project-model.json istnieje ---"
if [ -f "$EXPLORER_DIR/data/project-model.json" ]; then
    t_pass "docs/explorer/data/project-model.json istnieje"
else
    t_fail "Brak docs/explorer/data/project-model.json"
fi

# --- T8: data/summary.json istnieje ------------------------------------------
echo ""
echo "--- T8: data/summary.json istnieje ---"
if [ -f "$EXPLORER_DIR/data/summary.json" ]; then
    t_pass "docs/explorer/data/summary.json istnieje"
else
    t_fail "Brak docs/explorer/data/summary.json"
fi

# --- T9: kontrola negatywna — czysty plik bez <html> -------------------------
echo ""
echo "--- T9: czysty plik bez <html> -> grep NIE pasuje ---"
cat > "$WORK/clean.html" <<'EOF'
plain text
EOF
if grep -q '<html' "$WORK/clean.html" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty plik pasuje do grep <html>"
else
    t_pass "Czysty plik NIE pasuje do grep <html> (brak fałszywego pozytywu)"
fi

# --- T10: kontrola negatywna — czysty plik bez <body> ------------------------
echo ""
echo "--- T10: czysty plik bez <body> -> grep NIE pasuje ---"
if grep -q '<body' "$WORK/clean.html" 2>/dev/null; then
    t_fail "Fałszywy pozytyw — czysty plik pasuje do grep <body>"
else
    t_pass "Czysty plik NIE pasuje do grep <body> (brak fałszywego pozytywu)"
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
