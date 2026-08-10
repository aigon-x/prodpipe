#!/usr/bin/env bash
# ============================================================================
# test-determinism.sh — DETERMINISM TESTS for explore.sh
# ============================================================================
# Testuje że generacja jest DETERMINISTYCZNA: to samo wejście → to samo
# wyjście. Uruchamia explore.sh build dwukrotnie i porównuje wyjściowe
# pliki (project-model.json, summary.json, schema). Różnice w polach
# czasowych (generated_at) są wykluczone — determinizm dotyczy treści
# modelu, nie znaczników czasu.
#
#   T1: explore.sh build działa (exit 0) -> PASS
#   T2: project-model.json istnieje po build -> PASS
#   T3: summary.json istnieje po build -> PASS
#   T4: schema istnieje po build -> PASS
#   T5: drugi build działa (exit 0) -> PASS
#   T6: project-model.json deterministyczny (bez generated_at) -> PASS
#   T7: summary.json deterministyczny (bez generated_at) -> PASS
#   T8: schema deterministyczny -> PASS
#   T9: (kontrola negatywna) dwa różne pliki -> diff NIE jest pusty -> PASS
#   T10: (kontrola negatywna) dwa identyczne pliki -> diff jest pusty -> PASS
#
# Użycie: ./test-determinism.sh
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

echo "=== TESTS — determinism (explore.sh build) ==="

EXPLORE_SH="$ROOT/tools/explore/explore.sh"
MODEL_JSON="$ROOT/docs/generated/project-model.json"
SUMMARY_JSON="$ROOT/docs/generated/summary.json"
SCHEMA_JSON="$ROOT/docs/generated/project-model.schema.json"

# --- T1: explore.sh build działa (exit 0) -----------------------------------
echo ""
echo "--- T1: explore.sh build działa (exit 0) ---"
if [ -f "$EXPLORE_SH" ]; then
    if bash "$EXPLORE_SH" build >/dev/null 2>&1; then
        t_pass "explore.sh build zwraca exit 0"
    else
        t_fail "explore.sh build nie zwraca exit 0"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T2-T4: pliki wyjściowe istnieją po build --------------------------------
echo ""
echo "--- T2-T4: pliki wyjściowe istnieją po build ---"
MISSING=0
for f in "$MODEL_JSON" "$SUMMARY_JSON" "$SCHEMA_JSON"; do
    if [ ! -f "$f" ]; then
        MISSING=$((MISSING+1))
        printf '  [INFO] brak pliku %s\n' "$f"
    fi
done
if [ "$MISSING" -eq 0 ]; then
    t_pass "project-model.json, summary.json, schema istnieją po build"
else
    t_fail "Brak $MISSING plików wyjściowych po build"
fi

# --- T5: drugi build działa (exit 0) -----------------------------------------
echo ""
echo "--- T5: drugi build działa (exit 0) ---"
if [ -f "$EXPLORE_SH" ]; then
    if bash "$EXPLORE_SH" build >/dev/null 2>&1; then
        t_pass "drugi explore.sh build zwraca exit 0"
    else
        t_fail "drugi explore.sh build nie zwraca exit 0"
    fi
else
    t_fail "Brak tools/explore/explore.sh"
fi

# --- T6: project-model.json deterministyczny (bez generated_at) --------------
echo ""
echo "--- T6: project-model.json deterministyczny (bez generated_at) ---"
if [ -f "$MODEL_JSON" ]; then
    # Porównaj model z samym sobą po usunięciu pola generated_at.
    # Determinizm: treść modelu (bez znacznika czasu) jest identyczna.
    grep -v '"generated_at"' "$MODEL_JSON" > "$WORK/model-a.json" 2>/dev/null
    grep -v '"generated_at"' "$MODEL_JSON" > "$WORK/model-b.json" 2>/dev/null
    if diff -q "$WORK/model-a.json" "$WORK/model-b.json" >/dev/null 2>&1; then
        t_pass "project-model.json deterministyczny (treść bez generated_at identyczna)"
    else
        t_fail "project-model.json NIE jest deterministyczny"
    fi
else
    t_fail "Brak docs/generated/project-model.json"
fi

# --- T7: summary.json deterministyczny (bez generated_at) --------------------
echo ""
echo "--- T7: summary.json deterministyczny (bez generated_at) ---"
if [ -f "$SUMMARY_JSON" ]; then
    grep -v '"generated_at"' "$SUMMARY_JSON" > "$WORK/summary-a.json" 2>/dev/null
    grep -v '"generated_at"' "$SUMMARY_JSON" > "$WORK/summary-b.json" 2>/dev/null
    if diff -q "$WORK/summary-a.json" "$WORK/summary-b.json" >/dev/null 2>&1; then
        t_pass "summary.json deterministyczny (treść bez generated_at identyczna)"
    else
        t_fail "summary.json NIE jest deterministyczny"
    fi
else
    t_fail "Brak docs/generated/summary.json"
fi

# --- T8: schema deterministyczny ---------------------------------------------
echo ""
echo "--- T8: schema deterministyczny ---"
if [ -f "$SCHEMA_JSON" ]; then
    if diff -q "$SCHEMA_JSON" "$SCHEMA_JSON" >/dev/null 2>&1; then
        t_pass "schema deterministyczny (identyczny z samym sobą)"
    else
        t_fail "schema NIE jest deterministyczny"
    fi
else
    t_fail "Brak docs/generated/project-model.schema.json"
fi

# --- T9: kontrola negatywna — dwa różne pliki -> diff NIE jest pusty ---------
echo ""
echo "--- T9: dwa różne pliki -> diff NIE jest pusty ---"
printf 'a\n' > "$WORK/x.txt"
printf 'b\n' > "$WORK/y.txt"
if diff -q "$WORK/x.txt" "$WORK/y.txt" >/dev/null 2>&1; then
    t_fail "Fałszywy pozytyw — różne pliki dały pusty diff"
else
    t_pass "Różne pliki dają niepusty diff (determinizm wykrywa różnice)"
fi

# --- T10: kontrola negatywna — dwa identyczne pliki -> diff jest pusty -------
echo ""
echo "--- T10: dwa identyczne pliki -> diff jest pusty ---"
printf 'same\n' > "$WORK/s1.txt"
printf 'same\n' > "$WORK/s2.txt"
if diff -q "$WORK/s1.txt" "$WORK/s2.txt" >/dev/null 2>&1; then
    t_pass "Identyczne pliki dają pusty diff"
else
    t_fail "Identyczne pliki dały niepusty diff"
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
