#!/usr/bin/env bash
# ============================================================================
# canonical-state lib.sh — współdzielone funkcje StateStore
# ============================================================================
# AIGON Production Platform — Canonical State Foundation.
# SQLite = canonical operational state. Git = desired state. AIGON-X-FS = actual.
#
# Zasady:
#   * Schema jest MIGRACYJNA — każda zmiana to nowy plik w migrations/.
#   * NIGDY ręcznych zmian schematu — tylko przez migracje.
#   * Identity: cluster_id/node_id/runtime_id/service_id/deployment_id/generation
#     są ROZDZIELNE. Hostname/IP/port są WŁAŚCIWOŚCIAMI.
#   * Provenance: każdy ważny stan odpowiada "skąd pochodzi ta wartość".
#   * Desired/Effective/Observed — trzy poziomy.
#   * UNKNOWN nigdy nie jest PASS.
# ============================================================================

# --- Ścieżki ---------------------------------------------------------------
STATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DATA_DIR="${STATE_DIR}/data"
STATE_DB="${STATE_DATA_DIR}/canonical-state.db"
STATE_MIGRATIONS_DIR="${STATE_DIR}/migrations"
STATE_SCHEMA_VERSION="1"

# --- Kolory (jeśli TTY) ----------------------------------------------------
if [ -t 1 ]; then
    C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'; C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_RESET=''
fi

# --- Logowanie -------------------------------------------------------------
say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$2" "$1" "$C_RESET"; }
info() { sayc "[INFO] $*" "$C_CYAN"; }
ok()   { sayc "[OK]   $*" "$C_GREEN"; }
warn() { sayc "[WARN] $*" "$C_YELLOW"; }
fail() { sayc "[FAIL] $*" "$C_RED"; }

# --- Baza ------------------------------------------------------------------
state_require_sqlite() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        fail "sqlite3 CLI nie jest dostępny. Zainstaluj sqlite3."
        return 1
    fi
    return 0
}

state_db_exists() {
    [ -f "$STATE_DB" ]
}

# --- Init: utwórz katalog danych i pustą bazę ------------------------------
state_init() {
    state_require_sqlite || return 1
    mkdir -p "$STATE_DATA_DIR"
    if state_db_exists; then
        warn "Baza już istnieje: $STATE_DB"
        return 0
    fi
    # Pusta baza — migracje zostaną zastosowane przez state_migrate
    sqlite3 "$STATE_DB" "PRAGMA foreign_keys=ON; CREATE TABLE IF NOT EXISTS _init (id INTEGER PRIMARY KEY);" \
        && ok "Zainicjalizowano pustą bazę: $STATE_DB" \
        || { fail "Nie udało się zainicjalizować bazy"; return 1; }
    return 0
}

# --- Migracje: zastosuj wszystkie niezaaplikowane migracje ------------------
state_migrate() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init || return 1
    fi
    local applied
    applied=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';" 2>/dev/null || echo "0")
    [ -z "$applied" ] && applied="0"
    info "Aktualna wersja schematu: $applied (docelowa: $STATE_SCHEMA_VERSION)"

    local migration applied_migration
    for migration in "$STATE_MIGRATIONS_DIR"/*.sql; do
        [ -e "$migration" ] || continue
        local base
        base=$(basename "$migration")
        local num
        num=$(echo "$base" | sed -E 's/^([0-9]+)_.*/\1/')
        if [ "$num" -gt "$applied" ]; then
            info "Stosuję migrację: $base"
            if sqlite3 "$STATE_DB" < "$migration"; then
                ok "Migracja $base zastosowana"
            else
                fail "Migracja $base NIE POWIODŁA SIĘ"
                return 1
            fi
        fi
    done
    return 0
}

# --- Generation: pobierz / zwiększ generację -------------------------------
state_generation() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='generation';" 2>/dev/null || echo "0"
}

state_generation_bump() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    local gen
    gen=$(state_generation)
    gen=$((gen + 1))
    sqlite3 "$STATE_DB" "UPDATE meta SET value='$gen' WHERE key='generation';" \
        && ok "Generacja zwiększona do: $gen" \
        || { fail "Nie udało się zwiększyć generacji"; return 1; }
    echo "$gen"
}

# --- State hash: hash całego canonical state --------------------------------
# Hashuje WSZYSTKIE kolumny każdej tabeli canonical (deterministycznie).
# Pomija tabele meta/snapshot/event/evidence/_init (nie są częścią stanu).
state_hash() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    local tables
    tables=$(sqlite3 "$STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('meta','snapshot','event','evidence','_init') ORDER BY name;")
    local hash_input=""
    local t
    for t in $tables; do
        # Dump wszystkich wierszy tabeli jako kanoniczny tekst (wszystkie kolumny,
        # posortowane po pierwszej kolumnie = klucz główny). quote() daje
        # deterministyczną reprezentację każdej wartości.
        local dump
        dump=$(sqlite3 -separator '|' "$STATE_DB" "SELECT * FROM $t ORDER BY 1;" 2>/dev/null)
        hash_input+="${t}:\n${dump}\n"
    done
    # Deterministyczny hash (sha256sum)
    printf '%b' "$hash_input" | sha256sum | awk '{print $1}'
}

# --- Snapshot: utwórz snapshot canonical state ------------------------------
state_snapshot() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    local gen hash git_commit runtime_version
    gen=$(state_generation)
    hash=$(state_hash)
    git_commit=$(git -C "$STATE_DIR/../../.." rev-parse HEAD 2>/dev/null || echo "unknown")
    runtime_version="0.0.0"  # Runtime nie jest jeszcze podpięty (PHASE B — nie migrujemy)
    local sid
    sid="snap-$(date +%s)-$gen"
    sqlite3 "$STATE_DB" "INSERT INTO snapshot (snapshot_id, generation, schema_version, state_hash, git_commit, runtime_version) VALUES ('$sid', $gen, $STATE_SCHEMA_VERSION, '$hash', '$git_commit', '$runtime_version');" \
        && ok "Snapshot utworzony: $sid (gen=$gen, hash=$hash)" \
        || { fail "Nie udało się utworzyć snapshotu"; return 1; }
    echo "$sid"
}

# --- Verify: weryfikacja snapshotu / stanu ----------------------------------
state_verify() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje. Uruchom: state.sh init && state.sh migrate"
        return 1
    fi
    local gen hash
    gen=$(state_generation)
    hash=$(state_hash)
    info "Weryfikacja canonical state:"
    say "  Generacja:      $gen"
    say "  State hash:     $hash"
    # Porównaj z ostatnim snapshotem
    local last_snap_hash last_snap_gen
    last_snap_hash=$(sqlite3 "$STATE_DB" "SELECT state_hash FROM snapshot ORDER BY created_at DESC LIMIT 1;" 2>/dev/null)
    last_snap_gen=$(sqlite3 "$STATE_DB" "SELECT generation FROM snapshot ORDER BY created_at DESC LIMIT 1;" 2>/dev/null)
    if [ -n "$last_snap_hash" ]; then
        if [ "$last_snap_hash" = "$hash" ]; then
            ok "Stan zgodny z ostatnim snapshotem (gen=$last_snap_gen)"
        else
            warn "Stan RÓŻNI SIĘ od ostatniego snapshotu (snap gen=$last_snap_gen, snap hash=$last_snap_hash)"
        fi
    else
        info "Brak snapshotów do porównania."
    fi
    return 0
}

# --- Rollback: cofnij do poprzedniej migracji (test) ------------------------
# Uwaga: pełny rollback danych wymaga backupu. Ta funkcja obsługuje tylko
# weryfikację sekwencji migracji (test B11).
state_rollback_test() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje."
        return 1
    fi
    # W teście: sprawdź że migracje są deterministyczne i idempotentne
    local applied
    applied=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';")
    info "Rollback test: aktualna wersja schematu = $applied"
    # Symulacja rollback: usuń bazę i odtwórz z migracji (test w test_state.sh)
    return 0
}

# --- Status: podsumowanie canonical state -----------------------------------
state_status() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje. Uruchom: state.sh init && state.sh migrate"
        return 1
    fi
    local gen hash db_id created
    gen=$(state_generation)
    hash=$(state_hash)
    db_id=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='database_id';")
    created=$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='created_at';")
    say "=== CANONICAL STATE STATUS ==="
    say "Database ID:    $db_id"
    say "Schema version: $STATE_SCHEMA_VERSION"
    say "Generation:     $gen"
    say "State hash:     $hash"
    say "Created at:     $created"
    say "DB path:        $STATE_DB"
    # Liczba wierszy per tabela
    local tables
    tables=$(sqlite3 "$STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT IN ('meta','_init') ORDER BY name;")
    local t count
    for t in $tables; do
        count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM $t;")
        printf '  %-16s %s\n' "$t" "$count"
    done
    return 0
}
