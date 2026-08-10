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
#   ./state.sh snapshot      — utwórz snapshot
#   ./state.sh verify        — weryfikuj stan
#   ./state.sh status        — podsumowanie
#   ./state.sh rollback-test — test rollback (B11)
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
    verify)
        state_verify
        ;;
    status)
        state_status
        ;;
    rollback-test)
        state_rollback_test
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
