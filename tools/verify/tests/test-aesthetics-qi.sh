#!/usr/bin/env bash
# ============================================================================
# test-aesthetics-qi.sh — Quality Index Calculator (QI-001..005)
# ============================================================================
# Weryfikuje, że:
#   T1: QI = 100 gdy wszystkie 14 wymiarów = 1.0 (średnia geometryczna ważona)
#   T2: QI = 0 gdy jeden wymiar = 0 (średnia geometryczna — słabe ogniwo)
#   T3: Nieświeży evidence (computed_at starszy niż próg) → score = 0 (QI-003)
#   T4: Wagi z configu sumują się do 1.0 per tier (default/tier1/tier3)
#
# Użycie: ./test-aesthetics-qi.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$VERIFY_DIR/../.." && pwd)"
MIGRATIONS_DIR="$REPO_ROOT/system/control-plane/state/migrations"
QI_MODULE="$VERIFY_DIR/aesthetics/qi.sh"
WEIGHTS_FILE="$REPO_ROOT/config/aesthetics/qi-weights.yaml"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

# --- Helper: izolowana baza z migracją 0009 --------------------------------
# Tworzy tymczasową bazę, stosuje migracje 0001 + 0009 (0009 zależy od meta
# z 0001), ustawia VERIFY_STATE_DB. Zwraca ścieżkę bazy.
setup_db() {
    local db="$1"
    sqlite3 "$db" < "$MIGRATIONS_DIR/0001_initial.sql" 2>/dev/null || return 1
    sqlite3 "$db" < "$MIGRATIONS_DIR/0009_aesthetics_qi.sql" 2>/dev/null || return 1
    return 0
}

# --- Helper: wstaw 14 wymiarów z danym score i computed_at ------------------
# computed_at przekazywany jako wyrażenie SQL (np. "datetime('now')").
insert_scores() {
    local db="$1" score="$2" computed="$3"
    local i
    for i in $(seq 1 14); do
        sqlite3 "$db" "INSERT INTO quality_index (service_id, dimension, score, computed_at) VALUES ('test', 'dim$i', $score, $computed);" 2>/dev/null
    done
}

# --- Helper: wyciągnij QI z outputu modułu ----------------------------------
extract_qi() {
    grep -oE 'QI \(średnia geometryczna ważona\) = [0-9.]+' | grep -oE '[0-9.]+$'
}

echo "=== AESTHETICS QI TESTS ==="

# --- T1: QI = 100 gdy wszystkie wymiary = 1.0 -------------------------------
echo ""
echo "--- T1: QI = 100 (wszystkie 14 wymiarów = 1.0) ---"
DB1="$(mktemp)"
if ! setup_db "$DB1"; then
    t_fail "Nie udało się przygotować bazy testowej (migracje 0001+0009)"
else
    insert_scores "$DB1" "1.0" "datetime('now')"
    OUT="$(VERIFY_STATE_DB="$DB1" QI_TIER="default" bash "$QI_MODULE" 2>&1)"
    QI="$(printf '%s\n' "$OUT" | extract_qi)"
    if [ "$QI" = "100.00" ]; then
        t_pass "QI = $QI (oczekiwano 100.00)"
    else
        t_fail "QI = $QI (oczekiwano 100.00)"
    fi
fi
rm -f "$DB1"

# --- T2: QI = 0 gdy jeden wymiar = 0 ----------------------------------------
echo ""
echo "--- T2: QI = 0 (jeden wymiar = 0 — średnia geometryczna) ---"
DB2="$(mktemp)"
if ! setup_db "$DB2"; then
    t_fail "Nie udało się przygotować bazy testowej (migracje 0001+0009)"
else
    # 13 wymiarów = 1.0, dim3 (bezpieczeństwo) = 0.
    i=0
    for i in $(seq 1 14); do
        if [ "$i" -eq 3 ]; then
            sqlite3 "$DB2" "INSERT INTO quality_index (service_id, dimension, score, computed_at) VALUES ('test', 'dim3', 0.0, datetime('now'));" 2>/dev/null
        else
            sqlite3 "$DB2" "INSERT INTO quality_index (service_id, dimension, score, computed_at) VALUES ('test', 'dim$i', 1.0, datetime('now'));" 2>/dev/null
        fi
    done
    OUT="$(VERIFY_STATE_DB="$DB2" QI_TIER="default" bash "$QI_MODULE" 2>&1)"
    QI="$(printf '%s\n' "$OUT" | extract_qi)"
    if [ "$QI" = "0.00" ]; then
        t_pass "QI = $QI (oczekiwano 0.00 — słabe ogniwo zeruje indeks)"
    else
        t_fail "QI = $QI (oczekiwano 0.00 — słabe ogniwo zeruje indeks)"
    fi
fi
rm -f "$DB2"

# --- T3: Nieświeży evidence → score = 0 (QI-003) ----------------------------
echo ""
echo "--- T3: Nieświeży evidence (computed_at stary) → score = 0 ---"
DB3="$(mktemp)"
if ! setup_db "$DB3"; then
    t_fail "Nie udało się przygotować bazy testowej (migracje 0001+0009)"
else
    # Wszystkie wymiary świeże = 1.0, ale dim7 (świeżość) ma stary computed_at.
    i=0
    for i in $(seq 1 14); do
        if [ "$i" -eq 7 ]; then
            sqlite3 "$DB3" "INSERT INTO quality_index (service_id, dimension, score, computed_at) VALUES ('test', 'dim7', 1.0, datetime('now', '-30 days'));" 2>/dev/null
        else
            sqlite3 "$DB3" "INSERT INTO quality_index (service_id, dimension, score, computed_at) VALUES ('test', 'dim$i', 1.0, datetime('now'));" 2>/dev/null
        fi
    done
    OUT="$(VERIFY_STATE_DB="$DB3" QI_TIER="default" QI_FRESHNESS_DAYS="7" bash "$QI_MODULE" 2>&1)"
    QI="$(printf '%s\n' "$OUT" | extract_qi)"
    # Nieświeży wymiar → score=0 → QI=0 (średnia geometryczna).
    if [ "$QI" = "0.00" ]; then
        t_pass "Nieświeży evidence → score=0 → QI = $QI"
    else
        t_fail "Nieświeży evidence NIE wyzerował QI (QI = $QI, oczekiwano 0.00)"
    fi
    # Moduł musi zgłosić QI-003 jako FAIL (BLOCKING) — nieświeży wymiar.
    if printf '%s\n' "$OUT" | grep -q "QI-003 Świeżość evidence"; then
        t_pass "QI-003 zgłoszony (nieświeży evidence wykryty)"
    else
        t_fail "QI-003 nie zgłoszony (nieświeży evidence nie wykryty)"
    fi
fi
rm -f "$DB3"

# --- T4: Wagi z configu sumują się do 1.0 per tier --------------------------
echo ""
echo "--- T4: Wagi z configu sumują się do 1.0 (default/tier1/tier3) ---"
if [ ! -f "$WEIGHTS_FILE" ]; then
    t_fail "Brak pliku wag: $WEIGHTS_FILE"
elif ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import yaml" >/dev/null 2>&1; then
    t_fail "Brak python3/yaml — nie można zweryfikować sumy wag"
else
    RESULT="$(python3 - "$WEIGHTS_FILE" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f) or {}
weights = data.get("qi_weights") or {}
ok = True
for tier in ("default", "tier1", "tier3"):
    w = weights.get(tier) or {}
    total = sum(float(v) for v in w.values())
    # Tolerancja 0.001 (zaokrąglenia dziesiętne).
    if not (0.999 <= total <= 1.001):
        ok = False
        print(f"tier={tier} suma={total:.6f} (oczekiwano 1.0)")
    if len(w) != 14:
        ok = False
        print(f"tier={tier} liczba wymiarów={len(w)} (oczekiwano 14)")
print("OK" if ok else "FAIL")
PYEOF
)"
    if [ "$RESULT" = "OK" ]; then
        t_pass "Wagi sumują się do 1.0 dla default/tier1/tier3 (14 wymiarów każdy)"
    else
        t_fail "Wagi NIE sumują się do 1.0: $RESULT"
    fi
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== AESTHETICS QI — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
