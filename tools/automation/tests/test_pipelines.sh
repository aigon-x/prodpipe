#!/usr/bin/env bash
# ============================================================================
# test_pipelines.sh — Pipeline Operating System (pipelines.yaml → pipelines.sh)
# ============================================================================
# Weryfikuje, że:
#   T1: Generator produkuje pipelines.sh z markerem "GENERATED FILE"
#   T2: Katalog zawiera ≥50 pipeline'ów (P-001..P-051)
#   T3: pipeline_script P-051 = "recovery/max-decomposition.sh"
#   T4: pipeline_class P-014 = "DEEP"
#   T5: pipeline_status P-003 = "IMPLEMENTED"
#   T6: pipeline_family P-051 = "RECOVERY"
#   T7: pipeline_depends P-033 = "P-031,P-032"
#   T8: pipeline_contract P-040 = 8 faz
#   T9: pipeline_implemented zwraca 5 pipeline'ów (P-003 P-014 P-040 P-043 P-051)
#   T10: YAML (pipelines.yaml) i wygenerowany pipelines.sh są spójne
#   T11: Wszystkie pipeline'y IMPLEMENTED mają istniejące skrypty (fail-closed)
#   T12: Zależności pipeline'ów nie tworzą cykli (DAG)
#
# Użycie: ./test_pipelines.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$AUTOMATION_DIR/../.." && pwd)"
PIPELINES_YAML="$REPO_ROOT/config/canonical/pipelines.yaml"
GEN_SCRIPT="$AUTOMATION_DIR/core/gen-pipelines.sh"
PIPELINES_SH="$AUTOMATION_DIR/core/pipelines.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== PIPELINE OPERATING SYSTEM TESTS ==="

# --- T1: Generator produkuje pipelines.sh z markerem "GENERATED FILE" --------
echo ""
echo "--- T1: Generator produkuje pipelines.sh z markerem GENERATED FILE ---"
if [ ! -f "$GEN_SCRIPT" ]; then
    t_fail "Brak generatora: $GEN_SCRIPT"
else
    bash "$GEN_SCRIPT" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        t_fail "Generator zwrócił błąd"
    elif [ ! -f "$PIPELINES_SH" ]; then
        t_fail "Generator nie wyprodukował pipelines.sh"
    elif grep -q "GENERATED FILE" "$PIPELINES_SH"; then
        t_pass "pipelines.sh wygenerowany z markerem GENERATED FILE"
    else
        t_fail "pipelines.sh nie ma markera GENERATED FILE"
    fi
fi

# --- T2: Katalog zawiera ≥50 pipeline'ów ------------------------------------
echo ""
echo "--- T2: Katalog zawiera ≥50 pipeline'ów ---"
# shellcheck source=core/pipelines.sh
. "$PIPELINES_SH"
CATALOG_COUNT="${#PIPELINES[@]}"
if [ "$CATALOG_COUNT" -ge 50 ]; then
    t_pass "Katalog zawiera $CATALOG_COUNT pipeline'ów (oczekiwano ≥50)"
else
    t_fail "Katalog zawiera tylko $CATALOG_COUNT pipeline'ów (oczekiwano ≥50)"
fi

# --- T3: pipeline_script P-051 ----------------------------------------------
echo ""
echo "--- T3: pipeline_script P-051 ---"
GOT_SCRIPT="$(pipeline_script P-051)"
if [ "$GOT_SCRIPT" = "recovery/max-decomposition.sh" ]; then
    t_pass "pipeline_script P-051 = $GOT_SCRIPT"
else
    t_fail "pipeline_script P-051 = '$GOT_SCRIPT' (oczekiwano 'recovery/max-decomposition.sh')"
fi

# --- T4: pipeline_class P-014 ------------------------------------------------
echo ""
echo "--- T4: pipeline_class P-014 ---"
GOT_CLASS="$(pipeline_class P-014)"
if [ "$GOT_CLASS" = "DEEP" ]; then
    t_pass "pipeline_class P-014 = $GOT_CLASS"
else
    t_fail "pipeline_class P-014 = '$GOT_CLASS' (oczekiwano 'DEEP')"
fi

# --- T5: pipeline_status P-003 ----------------------------------------------
echo ""
echo "--- T5: pipeline_status P-003 ---"
GOT_STATUS="$(pipeline_status P-003)"
if [ "$GOT_STATUS" = "IMPLEMENTED" ]; then
    t_pass "pipeline_status P-003 = $GOT_STATUS"
else
    t_fail "pipeline_status P-003 = '$GOT_STATUS' (oczekiwano 'IMPLEMENTED')"
fi

# --- T6: pipeline_family P-051 ----------------------------------------------
echo ""
echo "--- T6: pipeline_family P-051 ---"
GOT_FAMILY="$(pipeline_family P-051)"
if [ "$GOT_FAMILY" = "RECOVERY" ]; then
    t_pass "pipeline_family P-051 = $GOT_FAMILY"
else
    t_fail "pipeline_family P-051 = '$GOT_FAMILY' (oczekiwano 'RECOVERY')"
fi

# --- T7: pipeline_depends P-033 ---------------------------------------------
echo ""
echo "--- T7: pipeline_depends P-033 ---"
GOT_DEPENDS="$(pipeline_depends P-033)"
if [ "$GOT_DEPENDS" = "P-031,P-032" ]; then
    t_pass "pipeline_depends P-033 = $GOT_DEPENDS"
else
    t_fail "pipeline_depends P-033 = '$GOT_DEPENDS' (oczekiwano 'P-031,P-032')"
fi

# --- T8: pipeline_contract P-040 = 8 faz -------------------------------------
echo ""
echo "--- T8: pipeline_contract P-040 = 8 faz ---"
GOT_CONTRACT="$(pipeline_contract P-040)"
PHASE_COUNT=$(echo "$GOT_CONTRACT" | tr ',' '\n' | grep -c . || echo 0)
if [ "$PHASE_COUNT" -eq 8 ]; then
    t_pass "pipeline_contract P-040 = $PHASE_COUNT faz"
else
    t_fail "pipeline_contract P-040 = $PHASE_COUNT faz (oczekiwano 8)"
fi

# --- T9: pipeline_implemented zwraca wszystkie 98 pipeline'ów ----------------
echo ""
echo "--- T9: pipeline_implemented ---"
GOT_IMPL="$(pipeline_implemented)"
# pipeline_implemented zwraca trailing space (printf '%s '), więc porównujemy
# po usunięciu białych znaków.
GOT_IMPL_TRIMMED="$(echo "$GOT_IMPL" | xargs)"
# Wszystkie 98 pipeline'ów (P-001..P-098) jest IMPLEMENTED.
EXPECTED_IMPL="$(seq -f 'P-%03g' 1 98 | tr '\n' ' ' | xargs)"
if [ "$GOT_IMPL_TRIMMED" = "$EXPECTED_IMPL" ]; then
    t_pass "pipeline_implemented = $GOT_IMPL_TRIMMED"
else
    t_fail "pipeline_implemented = '$GOT_IMPL_TRIMMED' (oczekiwano '$EXPECTED_IMPL')"
fi

# --- T10: YAML i pipelines.sh są spójne --------------------------------------
echo ""
echo "--- T10: YAML (pipelines.yaml) i pipelines.sh spójne ---"
if [ ! -f "$PIPELINES_YAML" ]; then
    t_fail "Brak pliku YAML: $PIPELINES_YAML"
else
    # Każdy pipeline z YAML musi mieć wpis w PIPELINES (przez pipeline_script).
    YAML_IDS="$(awk '/^  - id:/ { print $3 }' "$PIPELINES_YAML")"
    ALL_OK=1
    for id in $YAML_IDS; do
        s="$(pipeline_script "$id")"
        if [ -z "$s" ]; then
            t_fail "Pipeline '$id' z YAML nie ma wpisu w pipeline_script (pipelines.sh)"
            ALL_OK=0
        fi
    done
    # Sprawdź też, że każdy pipeline z YAML ma wpis w PIPELINES.
    for id in $YAML_IDS; do
        if ! grep -q "\"$id|" "$PIPELINES_SH"; then
            t_fail "Pipeline '$id' z YAML nie ma wpisu w PIPELINES (pipelines.sh)"
            ALL_OK=0
        fi
    done
    if [ "$ALL_OK" -eq 1 ]; then
        t_pass "Wszystkie pipeline'y z YAML mają wpisy w pipelines.sh"
    fi
fi

# --- T11: Wszystkie pipeline'y IMPLEMENTED mają istniejące skrypty -----------
echo ""
echo "--- T11: Wszystkie pipeline'y IMPLEMENTED mają istniejące skrypty ---"
ALL_OK=1
for entry in "${PIPELINES[@]}"; do
    eid="${entry%%|*}"
    rest="${entry#*|}"
    rest="${rest#*|}"
    scr="${rest%%|*}"
    rest="${rest#*|}"
    rest="${rest#*|}"
    st="${rest%%|*}"
    if [ "$st" = "IMPLEMENTED" ]; then
        if [ ! -f "$AUTOMATION_DIR/$scr" ]; then
            t_fail "Pipeline $eid IMPLEMENTED, a skrypt nie istnieje: $scr"
            ALL_OK=0
        fi
    fi
done
if [ "$ALL_OK" -eq 1 ]; then
    t_pass "Wszystkie pipeline'y IMPLEMENTED mają istniejące skrypty (fail-closed)"
fi

# --- T12: Zależności pipeline'ów nie tworzą cykli (DAG) ----------------------
echo ""
echo "--- T12: Zależności pipeline'ów nie tworzą cykli (DAG) ---"
declare -A VISITING=()
declare -A VISITED=()
DAG_OK=1
check_cycle() {
    local id="$1"
    if [ "${VISITING[$id]:-}" = "1" ]; then
        DAG_OK=0
        t_fail "Wykryto cykl w zależnościach pipeline'ów przy $id"
        return
    fi
    if [ "${VISITED[$id]:-}" = "1" ]; then
        return
    fi
    VISITING[$id]=1
    local deps
    deps="$(pipeline_depends "$id")"
    local dep
    for dep in ${deps//,/ }; do
        if [ -n "$dep" ]; then
            check_cycle "$dep"
        fi
    done
    VISITING[$id]=0
    VISITED[$id]=1
}
for entry in "${PIPELINES[@]}"; do
    eid="${entry%%|*}"
    check_cycle "$eid"
done
if [ "$DAG_OK" -eq 1 ]; then
    t_pass "Zależności pipeline'ów nie tworzą cykli (DAG spójny)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== PIPELINE OPERATING SYSTEM — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
