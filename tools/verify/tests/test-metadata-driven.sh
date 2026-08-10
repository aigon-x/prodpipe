#!/usr/bin/env bash
# ============================================================================
# test-metadata-driven.sh — Metadata-driven pipeline (gates.yaml → profiles.sh)
# ============================================================================
# Weryfikuje, że:
#   T1: Generator produkuje profiles.sh z markerem "GENERATED FILE"
#   T2: verify_profile_modules full zwraca oczekiwaną listę modułów
#   T3: module_script git = "git/integrity.sh"
#   T4: verify_module_severity dependencies full = "WARNING"
#   T5: YAML (gates.yaml) i wygenerowany profiles.sh są spójne
#
# Użycie: ./test-metadata-driven.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
GATES_YAML="$REPO_ROOT/config/canonical/gates.yaml"
GEN_SCRIPT="$VERIFY_DIR/core/gen-profiles.sh"
PROFILES_SH="$VERIFY_DIR/core/profiles.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== METADATA-DRIVEN PIPELINE TESTS ==="

# --- T1: Generator produkuje profiles.sh z markerem "GENERATED FILE" --------
echo ""
echo "--- T1: Generator produkuje profiles.sh z markerem GENERATED FILE ---"
if [ ! -f "$GEN_SCRIPT" ]; then
    t_fail "Brak generatora: $GEN_SCRIPT"
else
    bash "$GEN_SCRIPT" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        t_fail "Generator zwrócił błąd"
    elif [ ! -f "$PROFILES_SH" ]; then
        t_fail "Generator nie wyprodukował profiles.sh"
    elif grep -q "GENERATED FILE" "$PROFILES_SH"; then
        t_pass "profiles.sh wygenerowany z markerem GENERATED FILE"
    else
        t_fail "profiles.sh nie ma markera GENERATED FILE"
    fi
fi

# --- T2: verify_profile_modules full ----------------------------------------
echo ""
echo "--- T2: verify_profile_modules full ---"
# shellcheck source=core/profiles.sh
. "$PROFILES_SH"
EXPECTED_FULL="git security structure architecture dependencies reproducibility deployment contracts migration recovery"
GOT_FULL="$(verify_profile_modules full)"
if [ "$GOT_FULL" = "$EXPECTED_FULL" ]; then
    t_pass "verify_profile_modules full = $GOT_FULL"
else
    t_fail "verify_profile_modules full = '$GOT_FULL' (oczekiwano '$EXPECTED_FULL')"
fi

# --- T3: module_script git ---------------------------------------------------
echo ""
echo "--- T3: module_script git ---"
GOT_SCRIPT="$(module_script git)"
if [ "$GOT_SCRIPT" = "git/integrity.sh" ]; then
    t_pass "module_script git = $GOT_SCRIPT"
else
    t_fail "module_script git = '$GOT_SCRIPT' (oczekiwano 'git/integrity.sh')"
fi

# --- T4: verify_module_severity dependencies full ---------------------------
echo ""
echo "--- T4: verify_module_severity dependencies full ---"
GOT_SEV="$(verify_module_severity dependencies full)"
if [ "$GOT_SEV" = "WARNING" ]; then
    t_pass "verify_module_severity dependencies full = $GOT_SEV"
else
    t_fail "verify_module_severity dependencies full = '$GOT_SEV' (oczekiwano 'WARNING')"
fi

# --- T5: YAML i profiles.sh są spójne ---------------------------------------
echo ""
echo "--- T5: YAML (gates.yaml) i profiles.sh spójne ---"
# Każdy moduł z YAML musi mieć wpis w VERIFY_MODULES (przez module_script).
# Parsujemy moduły z YAML (sekcja gates:) i sprawdzamy, że module_script
# zwraca niepustą ścieżkę dla każdego z nich.
if [ ! -f "$GATES_YAML" ]; then
    t_fail "Brak pliku YAML: $GATES_YAML"
else
    YAML_MODULES="$(awk '/^  - module:/ { print $3 }' "$GATES_YAML")"
    ALL_OK=1
    for m in $YAML_MODULES; do
        s="$(module_script "$m")"
        if [ -z "$s" ]; then
            t_fail "Moduł '$m' z YAML nie ma wpisu w module_script (profiles.sh)"
            ALL_OK=0
        fi
    done
    # Sprawdź też, że każdy moduł z YAML ma wpis w VERIFY_MODULES.
    for m in $YAML_MODULES; do
        if ! grep -q "\"$m:" "$PROFILES_SH"; then
            t_fail "Moduł '$m' z YAML nie ma wpisu w VERIFY_MODULES (profiles.sh)"
            ALL_OK=0
        fi
    done
    if [ "$ALL_OK" -eq 1 ]; then
        t_pass "Wszystkie moduły z YAML mają wpisy w profiles.sh"
    fi
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== METADATA-DRIVEN PIPELINE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
