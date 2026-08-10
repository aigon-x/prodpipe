#!/usr/bin/env bash
# ============================================================================
# state.sh — StateStore CLI (Canonical State Foundation)
# ============================================================================
# AIGON Production Platform — canonical operational state (SQLite).
#
# Użycie:
#   ./state.sh init          — utwórz pustą bazę
#   ./state.sh migrate       — zastosuj migracje
#   ./state.sh generation    — pokaż generację
#   ./state.sh bump          — zwiększ generację
#   ./state.sh hash          — pokaż state hash
#   ./state.sh snapshot      — utwórz snapshot (+ backup bazy)
#   ./state.sh backup [sid]  — zapisz backup bazy (domyślnie: manual)
#   ./state.sh restore SID   — przywróć bazę z backupu snapshotu
#   ./state.sh backup-verify SID — weryfikuj integralność backupu (F5)
#   ./state.sh backup-list   — lista backupów z metadanymi (F5)
#   ./state.sh backup-retention [N] — retention: trzymaj N najnowszych (F5)
#   ./state.sh backup-restore-test — REAL backup->restore->verify test (F5)
#   ./state.sh verify        — weryfikuj stan
#   ./state.sh status        — podsumowanie
#   ./state.sh rollback-test — REAL rollback test (F3)
#   ./state.sh rollback-negative — rollback z uszkodzonego backupu -> FAIL
#   ./state.sh help          — pomoc
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

cmd="${1:-help}"

case "$cmd" in
    init)
        state_init
        ;;
    migrate)
        state_migrate
        ;;
    generation)
        state_generation
        ;;
    bump)
        state_generation_bump
        ;;
    hash)
        state_hash
        ;;
    snapshot)
        state_snapshot
        ;;
    backup)
        state_backup "${2:-manual}"
        ;;
    restore)
        state_restore "${2:-}"
        ;;
    backup-verify)
        state_backup_verify "${2:-}"
        ;;
    backup-list)
        state_backup_list
        ;;
    backup-retention)
        state_backup_retention "${2:-5}"
        ;;
    backup-restore-test)
        state_backup_restore_test
        ;;
    verify)
        state_verify
        ;;
    status)
        state_status
        ;;
    rollback-test)
        state_rollback_test
        ;;
    rollback-negative)
        state_rollback_negative_test
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        fail "Nieznana komenda: $cmd"
        usage
        exit 1
        ;;
esac
