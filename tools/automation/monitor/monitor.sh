#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# monitor.sh — MONITOR PLANE — Pipeline Operating System CLI
# ─────────────────────────────────────────────────────────────
# Kontroluje lifecycle pipeline'ów (P-001..P-098) jako proces
# ze stanem, a nie skrypt, który się uruchamia.
#
# 9 etapów:  REGISTER → SCHEDULE → QUEUE → START → MONITOR
#            → CONTROL → COMPLETE → NOTIFY → ARCHIVE
# 10 stanów: PENDING SCHEDULED QUEUED RUNNING PAUSED COMPLETED
#            FAILED CANCELLED SKIPPED ARCHIVED
# 70 gate'ów MON-* (MON-R/S/Q/ST/M/C/CO/N/A × 8).
#
# Użycie:
#   ./monitor.sh <subkomenda> [args]
#
#   help                          — pomoc
#   register <pid>                — REGISTER (MON-R-01..06)
#   register-all                  — rejestruje wszystkie pipeline'y
#   schedule <pid>                — SCHEDULE (MON-S-01..08)
#   queue <pid>                   — QUEUE (MON-Q-01..08)
#   start <pid>                   — START (MON-ST-01..08)
#   monitor <pid> [progress]      — MONITOR (MON-M-01..08)
#   control <pid> <action>        — CONTROL (MON-C-01..08)
#   complete <pid> <status> [exit]— COMPLETE (MON-CO-01..08)
#   notify <pid> [channel]        — NOTIFY (MON-N-01..08)
#   archive <pid>                 — ARCHIVE (MON-A-01..08)
#   status <pid>                  — szczegóły pojedynczego pipeline'a
#   list [state]                  — lista pipeline'ów (opcjonalny filtr)
#   timeline <pid>                — historia zdarzeń pipeline'a
#   health                        — MON_health (metryka zdrowia)
#   gates                         — pokrycie 70 gate'ów MON-*
#   all                           — pełna demonstracja lifecycle
#
# Zasady:
#   * set -u (jak cały projekt).
#   * FAIL-CLOSED — brak źródła (pipelines.sh / monitor.sh lib) = FAIL.
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * Kończy się p_module_exit (FAIL-CLOSED).
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
M_CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M_AUTOMATION_DIR="$(cd "$M_CLI_DIR/.." && pwd)"
M_REPO_ROOT="$(cd "$M_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$M_AUTOMATION_DIR/core/lib.sh"
. "$M_AUTOMATION_DIR/core/pipelines.sh"
# ── Wczytaj rdzeń Monitor Plane ─────────────────────────────
. "$M_CLI_DIR/lib/monitor.sh"

# ── FAIL-CLOSED: źródło prawdy musi istnieć ─────────────────
if [ ! -f "$M_AUTOMATION_DIR/core/pipelines.sh" ]; then
  p_fail "MONITOR-SOURCE" BLOCKING "Brak pipelines.sh (wygeneruj przez gen-pipelines.sh)"
  p_module_exit
fi
if [ ! -f "$M_CLI_DIR/lib/monitor.sh" ]; then
  p_fail "MONITOR-LIB" BLOCKING "Brak lib/monitor.sh (rdzeń Monitor Plane)"
  p_module_exit
fi

# ── Subkomendy ──────────────────────────────────────────────
SUBCOMMAND="${1:-help}"
shift 2>/dev/null || true

case "$SUBCOMMAND" in
  help)
    p_say "MONITOR PLANE — Pipeline Operating System (P-001..P-098)"
    p_say ""
    p_say "Użycie: ./monitor.sh <subkomenda> [args]"
    p_say ""
    p_say "  help                          — ta pomoc"
    p_say "  register <pid>                — REGISTER (MON-R-01..06)"
    p_say "  register-all                  — rejestruje wszystkie pipeline'y"
    p_say "  schedule <pid>                — SCHEDULE (MON-S-01..08)"
    p_say "  queue <pid>                   — QUEUE (MON-Q-01..08)"
    p_say "  start <pid>                   — START (MON-ST-01..08)"
    p_say "  monitor <pid> [progress]      — MONITOR (MON-M-01..08)"
    p_say "  control <pid> <action>        — CONTROL (MON-C-01..08)"
    p_say "  complete <pid> <status> [exit]— COMPLETE (MON-CO-01..08)"
    p_say "  notify <pid> [channel]        — NOTIFY (MON-N-01..08)"
    p_say "  archive <pid>                 — ARCHIVE (MON-A-01..08)"
    p_say "  status <pid>                  — szczegóły pojedynczego pipeline'a"
    p_say "  list [state]                  — lista pipeline'ów (opcjonalny filtr)"
    p_say "  timeline <pid>                — historia zdarzeń pipeline'a"
    p_say "  health                        — MON_health (metryka zdrowia)"
    p_say "  gates                         — pokrycie 70 gate'ów MON-*"
    p_say "  all                           — pełna demonstracja lifecycle"
    p_say ""
    p_say "Stany: PENDING SCHEDULED QUEUED RUNNING PAUSED COMPLETED"
    p_say "       FAILED CANCELLED SKIPPED ARCHIVED"
    p_say "Etapy: REGISTER SCHEDULE QUEUE START MONITOR CONTROL"
    p_say "       COMPLETE NOTIFY ARCHIVE"
    p_say "Akcje kontrolne: pause resume cancel retry skip restart"
    p_say ""
    p_say "Źródło prawdy: config/canonical/pipelines.yaml → pipelines.sh"
    p_say "StateStore: system/control-plane/state/data/canonical-state.db"
    p_say "NO FALSE GREEN: brak danych = NOT_APPLICABLE, nigdy PASS."
    p_say ""
    exit 0
    ;;
  register)
    m_register "${1:?Brak pipeline_id}"
    ;;
  register-all)
    # Rejestruje wszystkie pipeline'y z PIPELINES (P-001..P-098).
    # Uwaga: `local` jest niedozwolone na poziomie top-level case,
    # dlatego używamy zwykłej zmiennej (jak rc w display-pipeline.sh).
    pid=""
    for entry in "${PIPELINES[@]}"; do
      pid="${entry%%|*}"
      m_register "$pid"
    done
    p_say "Zarejestrowano wszystkie pipeline'y w Monitor Plane."
    ;;
  schedule)
    m_schedule "${1:?Brak pipeline_id}"
    ;;
  queue)
    m_queue "${1:?Brak pipeline_id}"
    ;;
  start)
    m_start "${1:?Brak pipeline_id}"
    ;;
  monitor)
    m_monitor "${1:?Brak pipeline_id}" "${2:-}"
    ;;
  control)
    m_control "${1:?Brak pipeline_id}" "${2:?Brak akcji (pause|resume|cancel|retry|skip|restart)}"
    ;;
  complete)
    m_complete "${1:?Brak pipeline_id}" "${2:?Brak statusu (COMPLETED|FAILED)}" "${3:-}"
    ;;
  notify)
    m_notify "${1:?Brak pipeline_id}" "${2:-}"
    ;;
  archive)
    m_archive "${1:?Brak pipeline_id}"
    ;;
  status)
    m_status "${1:?Brak pipeline_id}"
    ;;
  list)
    m_list "${1:-}"
    ;;
  timeline)
    m_timeline "${1:?Brak pipeline_id}"
    ;;
  health)
    m_health
    ;;
  gates)
    m_gates
    ;;
  all)
    m_demo
    ;;
  *)
    p_say "Nieznana subkomenda: $SUBCOMMAND"
    p_say "Dostępne: help | register | register-all | schedule | queue | start |"
    p_say "         monitor | control | complete | notify | archive | status |"
    p_say "         list | timeline | health | gates | all"
    exit 2
    ;;
esac

# ── Podsumowanie (FAIL-CLOSED) ──────────────────────────────
p_module_exit
