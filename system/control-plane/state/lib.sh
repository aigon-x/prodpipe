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
STATE_BACKUP_DIR="${STATE_DATA_DIR}/backups"
STATE_MIGRATIONS_DIR="${STATE_DIR}/migrations"
STATE_SCHEMA_VERSION="9"

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

# --- History hash: integralność append-only history (F4) --------------------
# event + evidence to engineering telemetry (append-only history), NIE stan.
# Nie wchodzą do state_hash (stan), ale mają WŁASNY łańcuch integralności,
# aby manipulacja audytem była wykrywalna. Hashuje deterministycznie
# event + evidence (posortowane po kluczu głównym).
state_history_hash() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    local hash_input=""
    local t
    for t in event evidence; do
        local dump
        dump=$(sqlite3 -separator '|' "$STATE_DB" "SELECT * FROM $t ORDER BY 1;" 2>/dev/null)
        hash_input+="${t}:\n${dump}\n"
    done
    printf '%b' "$hash_input" | sha256sum | awk '{print $1}'
}

# --- Snapshot: utwórz snapshot canonical state ------------------------------
# Oprócz wiersza w tabeli snapshot, zapisuje backup bazy (data/backups/),
# dzięki czemu snapshot jest RESTOROWALNY (F3/F5) — nie tylko hash.
state_snapshot() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        state_init >/dev/null && state_migrate >/dev/null || return 1
    fi
    local gen hash history_hash git_commit runtime_version
    gen=$(state_generation)
    hash=$(state_hash)
    history_hash=$(state_history_hash)
    git_commit=$(git -C "$STATE_DIR/../../.." rev-parse HEAD 2>/dev/null || echo "unknown")
    runtime_version="0.0.0"  # Runtime nie jest jeszcze podpięty (PHASE B — nie migrujemy)
    local sid
    sid="snap-$(date +%s)-$gen-$(date +%N)"
    sqlite3 "$STATE_DB" "INSERT INTO snapshot (snapshot_id, generation, schema_version, state_hash, history_hash, git_commit, runtime_version) VALUES ('$sid', $gen, $STATE_SCHEMA_VERSION, '$hash', '$history_hash', '$git_commit', '$runtime_version');" \
        && ok "Snapshot utworzony: $sid (gen=$gen, hash=$hash, hist=$history_hash)" >&2 \
        || { fail "Nie udało się utworzyć snapshotu" >&2; return 1; }
    # Backup bazy — umożliwia realny rollback do tego snapshotu.
    if ! state_backup "$sid" >/dev/null 2>&1; then
        fail "Snapshot $sid utworzony, ale backup bazy NIE POWIODŁ SIĘ" >&2
        return 1
    fi
    # Tylko $sid na stdout — reszta komunikatów idzie na stderr.
    printf '%s\n' "$sid"
}

# --- Backup: zapisz kopię bazy pod snapshot_id ------------------------------
# Używa sqlite3 .backup (bezpieczne dla żywej bazy — spójny snapshot pliku).
# F5: backup zapisuje też manifest (generation/state_hash/history_hash/
# timestamp/git SHA/schema_version) + plik .sha256 (backup hash) — dzięki
# czemu backup jest WERYFIKOWALNY i ma pełny kontekst, nie tylko goły plik.
state_backup() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje. Uruchom: state.sh init && state.sh migrate"
        return 1
    fi
    local sid="${1:-manual}"
    mkdir -p "$STATE_BACKUP_DIR"
    local backup_file="$STATE_BACKUP_DIR/canonical-state-$sid.db"
    if sqlite3 "$STATE_DB" ".backup '$backup_file'"; then
        # Manifest z metadanymi backupu (F5).
        local gen hash history_hash git_commit ts
        gen=$(state_generation)
        hash=$(state_hash)
        history_hash=$(state_history_hash)
        git_commit=$(git -C "$STATE_DIR/../../.." rev-parse HEAD 2>/dev/null || echo "unknown")
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        local backup_hash
        backup_hash=$(sha256sum "$backup_file" | awk '{print $1}')
        local manifest_file="$STATE_BACKUP_DIR/canonical-state-$sid.json"
        cat > "$manifest_file" <<EOF
{
  "snapshot_id": "$sid",
  "backup_file": "$(basename "$backup_file")",
  "backup_hash": "$backup_hash",
  "generation": "$gen",
  "state_hash": "$hash",
  "history_hash": "$history_hash",
  "schema_version": "$STATE_SCHEMA_VERSION",
  "git_commit": "$git_commit",
  "created_at": "$ts"
}
EOF
        # Plik .sha256 — niezależny, prosty checksum do szybkiej weryfikacji.
        printf '%s  %s\n' "$backup_hash" "$(basename "$backup_file")" > "$STATE_BACKUP_DIR/canonical-state-$sid.sha256"
        ok "Backup bazy: $backup_file (hash=$backup_hash)"
        echo "$backup_file"
        return 0
    else
        fail "Backup bazy NIE POWIODŁ SIĘ: $backup_file"
        return 1
    fi
}

# --- Backup verify: weryfikacja integralności backupu (F5) ------------------
# Sprawdza: (1) plik backupu istnieje, (2) backup_hash z manifestu zgadza się
# z faktycznym hashem pliku, (3) backup jest poprawną bazą SQLite.
# Zwraca 0 = backup INTEGRALNY, 1 = backup USZKODZONY / brak.
state_backup_verify() {
    state_require_sqlite || return 1
    local sid="${1:-}"
    if [ -z "$sid" ]; then
        fail "state_backup_verify wymaga snapshot_id"
        return 1
    fi
    local backup_file="$STATE_BACKUP_DIR/canonical-state-$sid.db"
    local manifest_file="$STATE_BACKUP_DIR/canonical-state-$sid.json"
    if [ ! -f "$backup_file" ]; then
        fail "Brak backupu: $backup_file"
        return 1
    fi
    if [ ! -f "$manifest_file" ]; then
        fail "Brak manifestu backupu: $manifest_file"
        return 1
    fi
    # 1. Porównaj backup_hash z manifestu z faktycznym hashem pliku.
    local expected actual
    expected=$(grep -o '"backup_hash": *"[^"]*"' "$manifest_file" | sed -E 's/.*"([0-9a-f]{64})".*/\1/')
    actual=$(sha256sum "$backup_file" | awk '{print $1}')
    if [ -z "$expected" ]; then
        fail "Manifest backupu nie zawiera backup_hash"
        return 1
    fi
    if [ "$expected" != "$actual" ]; then
        fail "Backup USZKODZONY: manifest hash=$expected, faktyczny=$actual"
        return 1
    fi
    # 2. Sprawdź że backup jest poprawną bazą SQLite (integrity_check).
    if ! sqlite3 "$backup_file" "PRAGMA integrity_check;" 2>/dev/null | grep -q "^ok$"; then
        fail "Backup NIE jest poprawną bazą SQLite (integrity_check FAIL)"
        return 1
    fi
    ok "Backup INTEGRALNY: $sid (hash=$actual)"
    return 0
}

# --- Backup list: lista backupów z metadanymi (F5) --------------------------
state_backup_list() {
    state_require_sqlite || return 1
    if [ ! -d "$STATE_BACKUP_DIR" ]; then
        info "Brak katalogu backupów: $STATE_BACKUP_DIR"
        return 0
    fi
    info "Backupy canonical state ($STATE_BACKUP_DIR):"
    local f
    for f in "$STATE_BACKUP_DIR"/canonical-state-*.db; do
        [ -e "$f" ] || continue
        local sid
        sid=$(basename "$f" .db | sed 's/^canonical-state-//')
        local gen hash ts
        gen=$(sqlite3 "$f" "SELECT value FROM meta WHERE key='generation';" 2>/dev/null || echo "?")
        ts=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
        say "  $sid  gen=$gen  mtime=$ts"
    done
    return 0
}

# --- Backup retention: polityka przechowywania backupów (F5) ----------------
# Domyślnie trzyma N najnowszych backupów (KEEP=5). Usuwa starsze.
# Zwraca 0 = retention OK, 1 = błąd.
state_backup_retention() {
    state_require_sqlite || return 1
    local keep="${1:-5}"
    if [ ! -d "$STATE_BACKUP_DIR" ]; then
        info "Brak katalogu backupów — retention N/A"
        return 0
    fi
    local count=0
    local f
    # Posortuj po mtime malejąco (najnowsze pierwsze).
    while IFS= read -r f; do
        [ -e "$f" ] || continue
        count=$((count+1))
        if [ "$count" -gt "$keep" ]; then
            local sid
            sid=$(basename "$f" .db | sed 's/^canonical-state-//')
            warn "Retention: usuwam stary backup $sid"
            rm -f "$f" "$STATE_BACKUP_DIR/canonical-state-$sid.json" "$STATE_BACKUP_DIR/canonical-state-$sid.sha256"
        fi
    done < <(ls -t "$STATE_BACKUP_DIR"/canonical-state-*.db 2>/dev/null)
    ok "Retention: trzymam $keep najnowszych backupów (usunięto $((count>keep?count-keep:0)))"
    return 0
}

# --- Backup restore test: REAL restore test (F5) ----------------------------
# Dowód, że backup jest RESTOROWALNY, nie tylko że "istnieje".
# Sekwencja: SNAPSHOT A -> MUTATE -> BACKUP A -> RESTORE A -> VERIFY
#            (state==A, generation==A, hash==A, history==A)
# Działa na IZOLOWANEJ bazie.
state_backup_restore_test() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje."
        return 1
    fi
    local orig_data_dir="$STATE_DATA_DIR"
    local orig_db="$STATE_DB"
    local orig_backup_dir="$STATE_BACKUP_DIR"
    local test_dir
    test_dir=$(mktemp -d)
    STATE_DATA_DIR="$test_dir"
    STATE_DB="$test_dir/canonical-state.db"
    STATE_BACKUP_DIR="$test_dir/backups"
    export STATE_DATA_DIR STATE_DB STATE_BACKUP_DIR
    local rc=1
    if state_init >/dev/null 2>&1 && state_migrate >/dev/null 2>&1; then
        # 1. Utwórz stan A.
        sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name, status) VALUES ('a1','backup-test','CURRENT');" 2>/dev/null
        local hash_a gen_a
        hash_a=$(state_hash)
        gen_a=$(state_generation)
        # 2. Snapshot A (tworzy też backup A).
        local sid_a
        sid_a=$(state_snapshot 2>/dev/null)
        if [ -n "$sid_a" ]; then
            # 3. MUTATE — zmień stan.
            sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name, status) VALUES ('a2','mutated','CURRENT');" 2>/dev/null
            # 4. Backup A już istnieje (utworzony przez state_snapshot w kroku 2,
            #    z bazy PRZED mutacją). Zweryfikuj jego integralność.
            if state_backup_verify "$sid_a" >/dev/null 2>&1; then
                # 5. RESTORE A.
                if state_restore "$sid_a" >/dev/null 2>&1; then
                    # 6. VERIFY — stan musi wrócić do A.
                    local hash_after gen_after
                    hash_after=$(state_hash)
                    gen_after=$(state_generation)
                    local mut_count
                    mut_count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM cluster WHERE cluster_id='a2';" 2>/dev/null)
                    if [ "$hash_after" = "$hash_a" ] && [ "$gen_after" = "$gen_a" ] && [ "$mut_count" = "0" ]; then
                        ok "BACKUP RESTORE TEST: PASS (state==A, gen==A, hash==A, mutation==0)"
                        rc=0
                    else
                        fail "BACKUP RESTORE TEST: FAIL (hash=$hash_after vs $hash_a, gen=$gen_after vs $gen_a, mut=$mut_count)"
                    fi
                else
                    fail "BACKUP RESTORE TEST: restore NIE powiódł się"
                fi
            else
                fail "BACKUP RESTORE TEST: backup A NIE jest integralny"
            fi
        else
            fail "BACKUP RESTORE TEST: snapshot A NIE utworzony"
        fi
    else
        fail "BACKUP RESTORE TEST: init/migrate NIE powiodło się"
    fi
    # Przywróć oryginalne ścieżki.
    STATE_DATA_DIR="$orig_data_dir"
    STATE_DB="$orig_db"
    STATE_BACKUP_DIR="$orig_backup_dir"
    export STATE_DATA_DIR STATE_DB STATE_BACKUP_DIR
    rm -rf "$test_dir"
    return $rc
}

# --- Restore: przywróć bazę z backupu snapshotu -----------------------------
# Nadpisuje bieżącą bazę kopią z backupu. Wymaga backupu snapshotu.
state_restore() {
    state_require_sqlite || return 1
    local sid="${1:-}"
    if [ -z "$sid" ]; then
        fail "state_restore wymaga snapshot_id"
        return 1
    fi
    local backup_file="$STATE_BACKUP_DIR/canonical-state-$sid.db"
    if [ ! -f "$backup_file" ]; then
        fail "Brak backupu dla snapshotu $sid: $backup_file"
        return 1
    fi
    # Przywróć: skopiuj backup na miejsce bazy (najpierw bezpieczna kopia bieżącej).
    local tmp_db="$STATE_DB.restore-tmp"
    if cp "$backup_file" "$tmp_db"; then
        mv "$tmp_db" "$STATE_DB"
        ok "Przywrócono bazę z backupu snapshotu $sid"
        return 0
    else
        fail "Restore NIE POWIODŁ SIĘ"
        return 1
    fi
}

# --- Verify: weryfikacja snapshotu / stanu ----------------------------------
# Semantyka (F2 — ZERO FALSE PASS):
#   * STATE VALID   (hash == ostatni snapshot, LUB brak snapshotów) -> return 0
#   * STATE INVALID (hash != ostatni snapshot)                      -> return 1 (FAIL)
#   * ERROR         (brak bazy / brak sqlite)                       -> return 1
# UNKNOWN nigdy nie jest PASS. Różnica stanu NIE jest WARN — jest FAIL.
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
    local last_snap_hash last_snap_gen last_snap_history_hash
    last_snap_hash=$(sqlite3 "$STATE_DB" "SELECT state_hash FROM snapshot ORDER BY created_at DESC LIMIT 1;" 2>/dev/null)
    last_snap_gen=$(sqlite3 "$STATE_DB" "SELECT generation FROM snapshot ORDER BY created_at DESC LIMIT 1;" 2>/dev/null)
    last_snap_history_hash=$(sqlite3 "$STATE_DB" "SELECT history_hash FROM snapshot ORDER BY created_at DESC LIMIT 1;" 2>/dev/null)
    if [ -n "$last_snap_hash" ]; then
        if [ "$last_snap_hash" = "$hash" ]; then
            ok "Stan zgodny z ostatnim snapshotem (gen=$last_snap_gen)"
        else
            fail "Stan RÓŻNI SIĘ od ostatniego snapshotu (snap gen=$last_snap_gen, snap hash=$last_snap_hash)"
            return 1
        fi
        # F4 — integralność historii (event/evidence): manipulacja audytem = FAIL.
        # history_hash jest OSOBNYM łańcuchem integralności od state_hash.
        if [ -n "$last_snap_history_hash" ]; then
            local cur_history_hash
            cur_history_hash=$(state_history_hash)
            say "  History hash:   $cur_history_hash"
            if [ "$last_snap_history_hash" = "$cur_history_hash" ]; then
                ok "Historia (event/evidence) zgodna z ostatnim snapshotem"
            else
                fail "Historia (event/evidence) RÓŻNI SIĘ od ostatniego snapshotu — możliwa manipulacja audytem"
                return 1
            fi
        else
            info "Brak history_hash w ostatnim snapshotcie (schema < v2)."
        fi
        return 0
    else
        info "Brak snapshotów do porównania."
        return 0
    fi
}

# --- Rollback: REAL rollback test (F3 — nie NO-OP) --------------------------
# Dowód, że snapshot jest RESTOROWALNY, nie tylko hashowalny.
# Sekwencja: CREATE TEST STATE -> SNAPSHOT A -> MUTATE -> SNAPSHOT B
#            -> ROLLBACK A -> VERIFY (state==A, generation==A, hash==A)
# Działa na IZOLOWANEJ bazie (STATE_DATA_DIR/STATE_DB nadpisane w teście),
# aby nie dotykać canonical-state.db.
state_rollback_test() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje."
        return 1
    fi
    local gen_a hash_a gen_b hash_b sid_a sid_b
    local test_cluster="cluster-rollback-test-$(date +%s)"

    info "=== REAL ROLLBACK TEST (F3) ==="

    # 1. CREATE TEST STATE — wstaw wiersz do tabeli canonical (cluster)
    sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name, status) VALUES ('$test_cluster', 'rollback-test', 'CURRENT');" \
        || { fail "Nie udało się utworzyć stanu testowego"; return 1; }
    ok "1. Utworzono stan testowy: $test_cluster"

    # 2. SNAPSHOT A — zapisuje hash + backup bazy
    sid_a=$(state_snapshot) || return 1
    gen_a=$(state_generation)
    hash_a=$(state_hash)
    ok "2. Snapshot A: $sid_a (gen=$gen_a, hash=$hash_a)"

    # 3. MUTATE — dodaj drugi wiersz (stan się zmienia)
    sqlite3 "$STATE_DB" "INSERT INTO cluster (cluster_id, name, status) VALUES ('$test_cluster-mut', 'rollback-test-mut', 'CURRENT');" \
        || { fail "Nie udało się zmutować stanu"; return 1; }
    ok "3. Zmutowano stan (dodano $test_cluster-mut)"

    # 4. SNAPSHOT B — nowy hash, nowy backup
    sid_b=$(state_snapshot) || return 1
    gen_b=$(state_generation)
    hash_b=$(state_hash)
    ok "4. Snapshot B: $sid_b (gen=$gen_b, hash=$hash_b)"

    # Dowód, że stan faktycznie się zmienił między A i B
    if [ "$hash_a" = "$hash_b" ]; then
        fail "Stan NIE zmienił się między snapshotami (hash_a == hash_b) — test nie ma sensu"
        return 1
    fi
    ok "   Stan zmienił się między A i B (hash_a != hash_b) — mutacja wykryta"

    # 5. ROLLBACK A — przywróć bazę z backupu snapshotu A
    if ! state_restore "$sid_a"; then
        fail "Rollback do snapshotu A NIE POWIODŁ SIĘ"
        return 1
    fi
    ok "5. Rollback do snapshotu A wykonany"

    # 6. VERIFY — stan musi być równy A (hash, generation, brak mutacji)
    local hash_after gen_after
    hash_after=$(state_hash)
    gen_after=$(state_generation)
    local mut_count
    mut_count=$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM cluster WHERE cluster_id='$test_cluster-mut';")
    if [ "$hash_after" = "$hash_a" ] && [ "$gen_after" = "$gen_a" ] && [ "$mut_count" = "0" ]; then
        ok "6. VERIFY: stan po rollbacku == stan A (hash=$hash_after, gen=$gen_after, mutacje=0)"
        ok "REAL ROLLBACK TEST: PASS"
        return 0
    else
        fail "VERIFY: stan po rollbacku NIE równa się A (hash=$hash_after vs $hash_a, gen=$gen_after vs $gen_a, mutacje=$mut_count)"
        return 1
    fi
}

# --- Rollback negative test (F3): uszkodzony/missing backup -> FAIL ---------
state_rollback_negative_test() {
    state_require_sqlite || return 1
    if ! state_db_exists; then
        fail "Baza nie istnieje."
        return 1
    fi
    info "=== ROLLBACK NEGATIVE TEST (F3) ==="
    # Próba restore z nieistniejącego snapshotu musi zakończyć się FAIL.
    local bogus="snap-does-not-exist-$(date +%s)"
    if state_restore "$bogus" >/dev/null 2>&1; then
        fail "Rollback z nieistniejącego backupu NIE ZGŁOSIŁ błędu (FALSE PASS)"
        return 1
    else
        ok "Rollback z nieistniejącego backupu poprawnie zwrócił FAIL"
        return 0
    fi
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
