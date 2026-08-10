#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# display-pipeline.sh — Visual Pipeline Display — CLI entrypoint
# ─────────────────────────────────────────────────────────────
# Renderuje Pipeline Operating System (P-001..P-098) jako gęsty,
# techniczny widok terminala + HTML.
#
# Użycie:
#   ./display-pipeline.sh help|families|stages|deps|gates|status|html|all
#
#   help      — pomoc
#   families  — lista 13 rodzin pipeline'ów
#   stages    — wszystkie pipeline'y P-001..P-098 z metadanymi
#   deps      — zależności jako ASCII graph
#   gates     — pokrycie gate'ów (GATE-001..GATE-042) + evidence
#   status    — status/evidence per pipeline
#   html      — renderuje statyczny HTML (dark, technical, dense)
#   all       — renderuje wszystko (terminal + HTML)
#
# Zasady:
#   * set -u (jak cały projekt).
#   * FAIL-CLOSED — brak źródła (pipelines.sh) = FAIL (BLOCKING).
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * Kończy się p_module_exit (FAIL-CLOSED).
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
D_DISPLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D_AUTOMATION_DIR="$(cd "$D_DISPLAY_DIR/.." && pwd)"
D_REPO_ROOT="$(cd "$D_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$D_AUTOMATION_DIR/core/lib.sh"
. "$D_AUTOMATION_DIR/core/pipelines.sh"
# ── Wczytaj rdzeń renderowania ──────────────────────────────
. "$D_DISPLAY_DIR/lib/display.sh"
# ── Wczytaj dashboard Monitor Plane ─────────────────────────
. "$D_DISPLAY_DIR/lib/monitor-display.sh"

# ── FAIL-CLOSED: źródło prawdy musi istnieć ─────────────────
# pipelines.sh jest GENEROWANY z pipelines.yaml. Brak = FAIL (BLOCKING),
# NIGDY cichy skip.
if [ ! -f "$D_AUTOMATION_DIR/core/pipelines.sh" ]; then
  p_fail "DISPLAY-SOURCE" BLOCKING "Brak pipelines.sh (wygeneruj przez gen-pipelines.sh)"
  p_module_exit
fi

# ── Subkomendy ──────────────────────────────────────────────
SUBCOMMAND="${1:-help}"
# rc — kod wyjścia renderera HTML (top-level, bez `local`).
rc=0

case "$SUBCOMMAND" in
  help)
    p_say "Visual Pipeline Display — Pipeline Operating System (P-001..P-098)"
    p_say ""
    p_say "Użycie: ./display-pipeline.sh <subkomenda>"
    p_say ""
    p_say "  help      — ta pomoc"
    p_say "  families  — lista 13 rodzin pipeline'ów"
    p_say "  stages    — wszystkie pipeline'y P-001..P-098 z metadanymi"
    p_say "  deps      — zależności jako ASCII graph"
    p_say "  gates     — pokrycie gate'ów (GATE-001..GATE-042) + evidence"
    p_say "  status    — status/evidence per pipeline"
    p_say "  html      — renderuje statyczny HTML (dark, technical, dense)"
    p_say "  all       — renderuje wszystko (terminal + HTML)"
    p_say ""
    p_say "  Monitor Plane (dashboard lifecycle):"
    p_say "  monitor           — pełny dashboard Monitor Plane"
    p_say "  monitor-health    — MON_health + 4 składowe"
    p_say "  monitor-states    — macierz stanów pipeline'ów"
    p_say "  monitor-timeline  — timeline zdarzeń [pipeline_id]"
    p_say "  monitor-gates     — pokrycie 70 gate'ów MON-*"
    p_say ""
    p_say "Źródło prawdy: config/canonical/pipelines.yaml → pipelines.sh"
    p_say "NO FALSE GREEN: brak danych = NOT_APPLICABLE, nigdy PASS."
    p_say ""
    exit 0
    ;;
  families)
    d_load_config
    d_render_header
    d_render_families
    ;;
  stages)
    d_load_config
    d_render_header
    d_render_stages
    ;;
  deps)
    d_load_config
    d_render_header
    d_render_deps
    ;;
  gates)
    d_load_config
    d_render_header
    d_render_gates
    ;;
  status)
    d_load_config
    d_render_header
    d_render_status
    ;;
  monitor)
    md_render_dashboard
    ;;
  monitor-health)
    md_render_health
    ;;
  monitor-states)
    md_render_states
    ;;
  monitor-timeline)
    md_render_timeline "${2:-}"
    ;;
  monitor-gates)
    md_render_gates
    ;;
  html)
    # Renderuje HTML przez display-html.sh (osobny renderer).
    bash "$D_DISPLAY_DIR/display-html.sh"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      p_fail "DISPLAY-HTML" BLOCKING "Renderowanie HTML zakończyło się kodem $rc"
      p_module_exit
    fi
    ;;
  all)
    d_load_config
    d_render_all
    # HTML na końcu (osobny renderer).
    bash "$D_DISPLAY_DIR/display-html.sh"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      p_fail "DISPLAY-HTML" BLOCKING "Renderowanie HTML zakończyło się kodem $rc"
      p_module_exit
    fi
    ;;
  *)
    p_say "Nieznana subkomenda: $SUBCOMMAND"
    p_say "Dostępne: help | families | stages | deps | gates | status | html | all | monitor | monitor-health | monitor-states | monitor-timeline | monitor-gates"
    exit 2
    ;;
esac

# ── Podsumowanie (FAIL-CLOSED) ──────────────────────────────
# p_module_exit wypisuje podsumowanie i propaguje status
# (exit 0 = PASS, exit 1 = FAIL) do procesu nadrzędnego.
p_module_exit
