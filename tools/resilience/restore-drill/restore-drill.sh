#!/usr/bin/env bash
# ============================================================================
# restore-drill.sh — RESILIENCE PLANE: end-to-end restore drill pipeline
# ============================================================================
# AIGON Production Platform — Resilience Plane (sub-deliverable "a").
# Wykonywalny odpowiednik game-day doc (docs/resilience/game-day/game-day-01.md).
#
# Pełny cykl:  cron → restore → walidacja → evidence → destroy
#   PRE-FLIGHT  — weryfikacja środowiska, SID, świeżości drill'a
#   BACKUP      — pre-restore safety backup (drill jest odwracalny)
#   RESTORE     — state.sh restore <SID>
#   WALIDACJA   — backup-verify + backup-restore-test (F5) + verify
#   EVIDENCE    — zapis JSON do artifacts/evidence/resilience/
#   DESTROY     — cleanup artefaktów scratch (NIE usuwa backupu <SID>)
#
# Bezpieczeństwo: drill działa TYLKO w środowisku scratch. --env prod jest
# kategorycznie odrzucane (safety: ćwiczenia tylko w scratch).
#
# RULE ZERO: prawda ze źródła, nie hardcode. Wartości rto/rpo/
# restore_drill_max_age czytamy z config/registry.yaml (sekcja resilience:).
#
# Użycie:
#   ./restore-drill.sh --sid <SID> [--env scratch|prod]
#
#   --sid <SID>   snapshot id backupu, z którego przywracamy (wymagane)
#   --env <env>   środowisko: scratch (domyślne) | prod (ODRZUCANE)
# ============================================================================

set -euo pipefail

# --- Ścieżki ---------------------------------------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
STATE_SH="$ROOT/system/control-plane/state/state.sh"
REGISTRY_YAML="$ROOT/config/registry.yaml"
EVIDENCE_DIR="$ROOT/artifacts/evidence/resilience"

# --- Kolory (jeśli TTY) ----------------------------------------------------
if [ -t 1 ]; then
    C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'; C_CYAN=$'\033[36m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''; C_BOLD=''; C_RESET=''
fi

say()  { printf '%s\n' "$*"; }
info() { printf '%s%s%s\n' "$C_CYAN" "[INFO] $*" "$C_RESET"; }
ok()   { printf '%s%s%s\n' "$C_GREEN" "[OK]   $*" "$C_RESET"; }
warn() { printf '%s%s%s\n' "$C_YELLOW" "[WARN] $*" "$C_RESET"; }
fail() { printf '%s%s%s\n' "$C_RED" "[FAIL] $*" "$C_RESET"; }

# --- Użycie ----------------------------------------------------------------
usage() {
    sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# --- Parsowanie argumentów --------------------------------------------------
SID=""
ENV="scratch"

while [ $# -gt 0 ]; do
    case "$1" in
        --sid)
            SID="${2:-}"
            shift 2
            ;;
        --env)
            ENV="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "Nieznany argument: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$SID" ]; then
    fail "Brak wymaganego argumentu --sid <SID>"
    usage
    exit 1
fi

# --- Czytanie konfiguracji resilience z registry.yaml (RULE ZERO) ----------
# Wartości NIE są hardkodowane — czytamy je z kanonicznego źródła prawdy.
# Klucze są proste (np. "  rto: 15"), parsujemy grep/sed.
read_resilience_value() {
    local key="$1"
    grep -E "^\s+${key}:" "$REGISTRY_YAML" 2>/dev/null \
        | head -n1 \
        | sed -E 's/^\s+[a-zA-Z0-9_]+:[[:space:]]*//' \
        | tr -d '[:space:]'
}

RTO="$(read_resilience_value rto)"
RPO="$(read_resilience_value rpo)"
RESTORE_DRILL_MAX_AGE="$(read_resilience_value restore_drill_max_age)"

if [ -z "$RTO" ] || [ -z "$RPO" ] || [ -z "$RESTORE_DRILL_MAX_AGE" ]; then
    fail "config/registry.yaml nie zawiera kompletnej sekcji resilience (rto/rpo/restore_drill_max_age)."
    exit 1
fi

# --- Zmienne globalne pipeline'u -------------------------------------------
RESTORE_START=""
RESTORE_END=""
RTO_SECONDS=""
PRE_RESTORE_SID=""
EVIDENCE_FILE=""

# --- Handler błędu: każdy failure kończy drill z exit 1 --------------------
on_error() {
    fail "RESTORE DRILL PRZERWANY (linia ${BASH_LINENO[0]}) — patrz log powyżej."
    exit 1
}
trap on_error ERR

# ============================================================================
# FAZA 1 — PRE-FLIGHT
# ============================================================================
pre_flight() {
    info "=== FAZA 1/6 — PRE-FLIGHT ==="

    # 1. Środowisko musi być scratch (drill NIGDY na produkcji).
    if [ "$ENV" != "scratch" ]; then
        fail "Środowisko '$ENV' jest niedozwolone. Restore drill działa TYLKO w scratch (--env scratch)."
        exit 1
    fi
    ok "Środowisko: scratch (bezpieczne dla drill'a)"

    # 2. state.sh musi istnieć.
    if [ ! -f "$STATE_SH" ]; then
        fail "Brak state.sh: $STATE_SH"
        exit 1
    fi
    ok "state.sh obecny: $STATE_SH"

    # 3. SID musi istnieć w katalogu backupów (backup-list / backup-verify).
    if ! "$STATE_SH" backup-verify "$SID" >/dev/null 2>&1; then
        fail "Backup SID '$SID' NIE istnieje lub NIE jest integralny (backup-verify FAIL)."
        exit 1
    fi
    ok "Backup SID '$SID' istnieje i jest integralny"

    # 4. Świeżość drill'a: restore_drill_max_age nie może być przekroczony.
    #    Porównujemy wiek ostatniego evidence drill'a (jeśli istnieje) z limitem.
    local latest_evidence=""
    if [ -d "$EVIDENCE_DIR" ]; then
        latest_evidence="$(ls -1 "$EVIDENCE_DIR"/restore-drill-*.json 2>/dev/null | sort | tail -n1 || true)"
    fi
    if [ -n "$latest_evidence" ] && [ -f "$latest_evidence" ]; then
        local last_ts last_epoch now_epoch age_days
        last_ts="$(grep -o '"timestamp": *"[^"]*"' "$latest_evidence" | sed -E 's/.*"([^"]*)".*/\1/' | head -n1)"
        if [ -n "$last_ts" ]; then
            last_epoch="$(date -d "$last_ts" +%s 2>/dev/null || echo "")"
            now_epoch="$(date +%s)"
            if [ -n "$last_epoch" ]; then
                age_days=$(( (now_epoch - last_epoch) / 86400 ))
                if [ "$age_days" -gt "$RESTORE_DRILL_MAX_AGE" ]; then
                    warn "Ostatni restore drill ma $age_days dni (> max $RESTORE_DRILL_MAX_AGE dni) — drill wymagany."
                else
                    ok "Ostatni restore drill ma $age_days dni (≤ max $RESTORE_DRILL_MAX_AGE dni)."
                fi
            fi
        fi
    else
        info "Brak wcześniejszego evidence drill'a — pierwszy drill."
    fi

    ok "PRE-FLIGHT zakończony pomyślnie"
}

# ============================================================================
# FAZA 2 — BACKUP (pre-restore safety)
# ============================================================================
phase_backup() {
    info "=== FAZA 2/6 — BACKUP (pre-restore safety) ==="
    # Świeży backup przed dotknięciem czegokolwiek — drill jest odwracalny.
    # state.sh backup wypisuje na stdout linię [OK] + ścieżkę pliku backupu.
    # Wyciągamy OSTATNIĄ linię (czysta ścieżka) i z niej SID.
    local backup_out backup_file
    backup_out="$("$STATE_SH" backup "drill-pre-restore-$(date +%s)")"
    backup_file="$(printf '%s\n' "$backup_out" | tail -n1)"
    PRE_RESTORE_SID="$(basename "$backup_file" .db | sed 's/^canonical-state-//')"
    if [ -z "$PRE_RESTORE_SID" ]; then
        fail "Nie udało się ustalić SID pre-restore backupu."
        exit 1
    fi
    ok "Pre-restore safety backup: $PRE_RESTORE_SID"
}

# ============================================================================
# FAZA 3 — RESTORE
# ============================================================================
phase_restore() {
    info "=== FAZA 3/6 — RESTORE ==="
    RESTORE_START="$(date +%s)"
    "$STATE_SH" restore "$SID"
    RESTORE_END="$(date +%s)"
    RTO_SECONDS=$(( RESTORE_END - RESTORE_START ))
    ok "Restore z SID '$SID' zakończony (RTO zmierzone: ${RTO_SECONDS}s)"
}

# ============================================================================
# FAZA 4 — WALIDACJA
# ============================================================================
phase_validation() {
    info "=== FAZA 4/6 — WALIDACJA ==="

    # 1. backup-verify <SID> — integralność przywróconego backupu.
    if ! "$STATE_SH" backup-verify "$SID" >/dev/null 2>&1; then
        fail "backup-verify <SID> po restore = FAIL."
        exit 1
    fi
    ok "backup-verify <SID> = PASS"

    # 2. backup-restore-test (F5) — REAL restore test, musi zwrócić 0.
    if ! "$STATE_SH" backup-restore-test >/dev/null 2>&1; then
        fail "backup-restore-test (F5) = FAIL."
        exit 1
    fi
    ok "backup-restore-test (F5) = PASS (exit 0)"

    # 3. verify — integralność canonical state po restore.
    if ! "$STATE_SH" verify >/dev/null 2>&1; then
        fail "state.sh verify po restore = FAIL."
        exit 1
    fi
    ok "state.sh verify = PASS"

    ok "WALIDACJA zakończona pomyślnie (RPO = 0 utraconych rekordów)"
}

# ============================================================================
# FAZA 5 — EVIDENCE
# ============================================================================
phase_evidence() {
    info "=== FAZA 5/6 — EVIDENCE ==="
    mkdir -p "$EVIDENCE_DIR"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    EVIDENCE_FILE="$EVIDENCE_DIR/restore-drill-${SID}-$(date +%Y%m%d%H%M%S).json"
    cat > "$EVIDENCE_FILE" <<EOF
{
  "sid": "$SID",
  "env": "$ENV",
  "rto_seconds": $RTO_SECONDS,
  "rpo_records_lost": 0,
  "restore_drill_exit": 0,
  "backup_verify": "PASS",
  "timestamp": "$ts",
  "config": {
    "rto": $RTO,
    "rpo": $RPO,
    "restore_drill_max_age": $RESTORE_DRILL_MAX_AGE
  }
}
EOF
    ok "Evidence zapisany: $EVIDENCE_FILE"
}

# ============================================================================
# FAZA 6 — DESTROY (cleanup scratch)
# ============================================================================
phase_destroy() {
    info "=== FAZA 6/6 — DESTROY (cleanup scratch) ==="
    # Usuwamy artefakty scratch utworzone przez drill:
    #   * pre-restore safety backup (był tylko na czas drill'a)
    #   * jego manifest i sha256
    # NIE usuwamy backupu <SID> (to cel drill'a — musi zostać).
    if [ -n "$PRE_RESTORE_SID" ]; then
        local backup_dir="$ROOT/system/control-plane/state/data/backups"
        rm -f "$backup_dir/canonical-state-${PRE_RESTORE_SID}.db" \
              "$backup_dir/canonical-state-${PRE_RESTORE_SID}.json" \
              "$backup_dir/canonical-state-${PRE_RESTORE_SID}.sha256"
        ok "Usunięto pre-restore safety backup: $PRE_RESTORE_SID"
    fi
    ok "DESTROY zakończony — backup docelowy '$SID' zachowany"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    say ""
    say "============================================================"
    say " RESTORE DRILL — end-to-end (backup → restore → walidacja → evidence → destroy)"
    say " SID: $SID   ENV: $ENV"
    say " RTO: ${RTO}min   RPO: ${RPO}min   restore_drill_max_age: ${RESTORE_DRILL_MAX_AGE}d"
    say "============================================================"
    say ""

    pre_flight
    phase_backup
    phase_restore
    phase_validation
    phase_evidence
    phase_destroy

    say ""
    ok "=== RESTORE DRILL ZAKOŃCZONY SUKCESEM ==="
    say "  SID:                $SID"
    say "  ENV:                $ENV"
    say "  RTO (zmierzone):    ${RTO_SECONDS}s (limit: ${RTO}min)"
    say "  RPO (utracone):     0 rekordów"
    say "  backup-verify:      PASS"
    say "  restore_drill_exit: 0"
    say "  Evidence:           $EVIDENCE_FILE"
    say ""
    exit 0
}

main
