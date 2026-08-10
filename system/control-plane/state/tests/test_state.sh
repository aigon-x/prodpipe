#!/usr/bin/env bash
# ============================================================================
# test_state.sh — PHASE B11 TESTS (Canonical State Foundation)
# ============================================================================
# Pokrycie wymagane przez masterprompt PHASE B11:
#   fresh database, migration, migration sequence, duplicate identity,
#   invalid schema, generation handling, state hashing, snapshot creation,
#   snapshot verification, rollback migration.
#
# Użycie: ./test_state.sh
# ============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=lib.sh
source "${STATE_DIR}/lib.sh"

# --- Liczniki --------------------------------------------------------------
PASS=0; FAIL=0

t_pass() { PASS=$((PASS+1)); printf '  %s%s%s\n' "$C_GREEN" "[PASS] $*" "$C_RESET"; }
t_fail() { FAIL=$((FAIL+1)); printf '  %s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Izolacja: użyj tymczasowej bazy ---------------------------------------
TEST_DATA_DIR="$(mktemp -d)"
STATE_DATA_DIR="$TEST_DATA_DIR"
STATE_DB="$TEST_DATA_DIR/canonical-state.db"
export STATE_DATA_DIR STATE_DB

cleanup() { rm -rf "$TEST_DATA_DIR"; }
trap cleanup EXIT

echo "=== PHASE B11 — CANONICAL STATE TESTS ==="
echo "Test DB: $STATE_DB"

# --- T1: Fresh database ----------------------------------------------------
echo ""
echo "--- T1: Fresh database (init) ---"
if state_init >/dev/null 2>&1 && [ -f "$STATE_DB" ]; then
    t_pass "Fresh database utworzona"
else
    t_fail "Fresh database NIE utworzona"
fi

# --- T2: Migration ---------------------------------------------------------
echo ""
echo "--- T2: Migration (0001_initial + 0002_history_hash) ---"
if state_migrate >/dev/null 2>&1; then
    sv=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';")
    if [ "$sv" = "$STATE_SCHEMA_VERSION" ]; then
        t_pass "Migracja zastosowana, schema_version=$sv"
    else
        t_fail "schema_version=$sv (oczekiwano $STATE_SCHEMA_VERSION)"
    fi
else
    t_fail "Migracja NIE powiodła się"
fi

# --- T3: Migration sequence (idempotentność) -------------------------------
echo ""
echo "--- T3: Migration sequence (idempotentność) ---"
if state_migrate >/dev/null 2>&1; then
    t_pass "Ponowna migracja idempotentna (bez błędu)"
else
    t_fail "Ponowna migracja NIE idempotentna"
fi

# --- T4: Duplicate identity ------------------------------------------------
echo ""
echo "--- T4: Duplicate identity (PRIMARY KEY) ---"
if sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name) VALUES ('c1','test');" 2>/dev/null; then
    if sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name) VALUES ('c1','dup');" 2>/dev/null; then
        t_fail "Duplicate cluster_id ZAAKCEPTOWANY (powinien być odrzucony)"
    else
        t_pass "Duplicate cluster_id odrzucony (PRIMARY KEY)"
    fi
else
    t_fail "Nie udało się wstawić pierwszego cluster"
fi

# --- T5: Invalid schema ----------------------------------------------------
echo ""
echo "--- T5: Invalid schema (nieznana kolumna) ---"
if sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name, nonexistent_col) VALUES ('c2','x','y');" 2>/dev/null; then
    t_fail "Invalid schema ZAAKCEPTOWANY (nieznana kolumna)"
else
    t_pass "Invalid schema odrzucony (nieznana kolumna)"
fi

# --- T6: Generation handling ------------------------------------------------
echo ""
echo "--- T6: Generation handling ---"
g0=$(state_generation)
if [ "$g0" = "0" ]; then
    t_pass "Początkowa generacja = 0"
else
    t_fail "Początkowa generacja = $g0 (oczekiwano 0)"
fi
g1=$(state_generation_bump >/dev/null 2>&1; state_generation)
if [ "$g1" = "1" ]; then
    t_pass "Generacja zwiększona do 1"
else
    t_fail "Generacja po bump = $g1 (oczekiwano 1)"
fi

# --- T7: State hashing ------------------------------------------------------
echo ""
echo "--- T7: State hashing ---"
h1=$(state_hash)
h2=$(state_hash)
if [ -n "$h1" ] && [ "$h1" = "$h2" ]; then
    t_pass "State hash deterministyczny: $h1"
else
    t_fail "State hash NIE deterministyczny: '$h1' vs '$h2'"
fi
# Zmiana stanu powinna zmienić hash
sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name) VALUES ('c3','hash-test');" 2>/dev/null
h3=$(state_hash)
if [ "$h1" != "$h3" ]; then
    t_pass "State hash zmienia się po zmianie stanu"
else
    t_fail "State hash NIE zmienił się po zmianie stanu"
fi

# --- T8: Snapshot creation --------------------------------------------------
echo ""
echo "--- T8: Snapshot creation ---"
sid=$(state_snapshot 2>/dev/null)
if [ -n "$sid" ]; then
    t_pass "Snapshot utworzony: $sid"
else
    t_fail "Snapshot NIE utworzony"
fi

# --- T9: Snapshot verification ----------------------------------------------
echo ""
echo "--- T9: Snapshot verification ---"
if state_verify >/dev/null 2>&1; then
    t_pass "Verify zakończony bez błędu"
else
    t_fail "Verify zakończony z błędem"
fi
# Sprawdź że snapshot ma poprawny hash
snap_hash=$(sqlite3 "$STATE_DB" "SELECT state_hash FROM snapshot ORDER BY created_at DESC LIMIT 1;")
cur_hash=$(state_hash)
if [ "$snap_hash" = "$cur_hash" ]; then
    t_pass "Snapshot hash zgodny z bieżącym stanem"
else
    t_fail "Snapshot hash ($snap_hash) != bieżący stan ($cur_hash)"
fi

# --- T10: Rollback migration ------------------------------------------------
echo ""
echo "--- T10: Rollback migration (odtworzenie z migracji) ---"
# Symulacja: usuń bazę, odtwórz z migracji, sprawdź że schema_version=docelowa
rm -f "$STATE_DB"
if state_init >/dev/null 2>&1 && state_migrate >/dev/null 2>&1; then
    sv2=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';")
    if [ "$sv2" = "$STATE_SCHEMA_VERSION" ]; then
        t_pass "Rollback/odtworzenie z migracji OK (schema_version=$sv2)"
    else
        t_fail "Rollback schema_version=$sv2 (oczekiwano $STATE_SCHEMA_VERSION)"
    fi
else
    t_fail "Rollback/odtworzenie NIE powiodło się"
fi

# --- T11: History hash deterministyczny (F4) --------------------------------
echo ""
echo "--- T11: History hash deterministyczny (F4) ---"
# Wstaw event + evidence, potem sprawdź że history_hash jest deterministyczny
sqlite3 "$STATE_DB" "INSERT INTO event (event_id, kind, entity_type, entity_id, payload) VALUES ('e1','test','cluster','c1','{}');" 2>/dev/null
sqlite3 "$STATE_DB" "INSERT INTO evidence (evidence_id, claim, source_type, source_ref) VALUES ('ev1','test-claim','manual','none');" 2>/dev/null
hh1=$(state_history_hash)
hh2=$(state_history_hash)
if [ -n "$hh1" ] && [ "$hh1" = "$hh2" ]; then
    t_pass "History hash deterministyczny: $hh1"
else
    t_fail "History hash NIE deterministyczny: '$hh1' vs '$hh2'"
fi

# --- T12: Manipulacja historią -> FAIL (F4) ---------------------------------
echo ""
echo "--- T12: Manipulacja historią (event/evidence) -> FAIL (F4) ---"
# 1. Utwórz snapshot (zapisuje history_hash)
sid_f4=$(state_snapshot 2>/dev/null)
if [ -z "$sid_f4" ]; then
    t_fail "Nie udało się utworzyć snapshotu bazowego dla T12"
else
    # 2. Manipuluj historią (audyt) — dodaj fałszywy event
    sqlite3 "$STATE_DB" "INSERT INTO event (event_id, kind, entity_type, entity_id, payload) VALUES ('e-fake','tamper','cluster','c1','{\"fake\":true}');" 2>/dev/null
    # 3. state_verify musi wykryć drift historii -> FAIL (exit != 0)
    if state_verify >/dev/null 2>&1; then
        t_fail "Manipulacja historią NIE wykryta (verify zwrócił 0)"
    else
        t_pass "Manipulacja historią wykryta (verify zwrócił != 0)"
    fi
    # 4. Usuń fałszywy event, przywróć integralność
    sqlite3 "$STATE_DB" "DELETE FROM event WHERE event_id='e-fake';" 2>/dev/null
    if state_verify >/dev/null 2>&1; then
        t_pass "Po usunięciu manipulacji verify wraca do PASS"
    else
        t_fail "Po usunięciu manipulacji verify NIE wrócił do PASS"
    fi
fi

# --- T13: Backup manifest + verify (F5) -------------------------------------
echo ""
echo "--- T13: Backup manifest + verify (F5) ---"
# Utwórz snapshot (tworzy backup z manifestem), potem zweryfikuj integralność.
sid_f5=$(state_snapshot 2>/dev/null)
if [ -z "$sid_f5" ]; then
    t_fail "Nie udało się utworzyć snapshotu dla T13"
else
    # Manifest powinien istnieć i zawierać backup_hash.
    manifest_f5="$STATE_BACKUP_DIR/canonical-state-$sid_f5.json"
    if [ -f "$manifest_f5" ] && grep -q '"backup_hash"' "$manifest_f5"; then
        t_pass "Manifest backupu utworzony: $manifest_f5"
    else
        t_fail "Manifest backupu NIE utworzony"
    fi
    # backup-verify musi przejść (integralny backup).
    if state_backup_verify "$sid_f5" >/dev/null 2>&1; then
        t_pass "Backup verify: INTEGRALNY"
    else
        t_fail "Backup verify: NIE przeszedł"
    fi
fi

# --- T14: Backup restore test (F5) ------------------------------------------
echo ""
echo "--- T14: Backup restore test (F5) ---"
if state_backup_restore_test >/dev/null 2>&1; then
    t_pass "Backup restore test: PASS (real restore)"
else
    t_fail "Backup restore test: FAIL"
fi

# --- T15: Backup retention (F5) ---------------------------------------------
echo ""
echo "--- T15: Backup retention (F5) ---"
# Utwórz kilka backupów, retention=2 powinno zostawić 2 najnowsze.
for i in 1 2 3; do
    state_snapshot >/dev/null 2>&1
done
before_count=$(ls "$STATE_BACKUP_DIR"/canonical-state-*.db 2>/dev/null | wc -l)
state_backup_retention 2 >/dev/null 2>&1
after_count=$(ls "$STATE_BACKUP_DIR"/canonical-state-*.db 2>/dev/null | wc -l)
if [ "$after_count" -le 2 ]; then
    t_pass "Retention: $before_count -> $after_count backupów (keep=2)"
else
    t_fail "Retention: $before_count -> $after_count (oczekiwano <=2)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== PHASE B11 — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
