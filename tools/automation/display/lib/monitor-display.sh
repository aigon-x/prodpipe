#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# monitor-display.sh — Monitor Plane — dashboard (terminal ANSI)
# ─────────────────────────────────────────────────────────────
# Renderuje Monitor Plane (P-001..P-098) jako gęsty, techniczny
# dashboard terminala. Czyta stan lifecycle z StateStore (SQLite):
#   pipeline_monitor_state   — bieżący stan każdego pipeline'a
#   pipeline_monitor_events  — zdarzenia lifecycle (timeline)
#   pipeline_monitor_health  — metryka MON_health
#
# Funkcje (wszystkie wypisują na stdout):
#   md_render_dashboard      — pełny dashboard (health + stany + gates)
#   md_render_health         — MON_health + 4 składowe
#   md_render_states         — macierz stanów pipeline'ów
#   md_render_timeline       — timeline zdarzeń (opcjonalnie per pipeline)
#   md_render_gates          — pokrycie 70 gate'ów MON-*
#
# Zasady:
#   * set -u (jak cały projekt).
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * FAIL-CLOSED — brak bazy StateStore = FAIL (BLOCKING).
#   * Komentarze po polsku, identyfikatory po angielsku.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
# monitor-display.sh jest w lib/, więc:
#   BASH_SOURCE[0] = lib/monitor-display.sh
#   dirname        = lib
#   ..             = display (katalog narzędzia)
#   ../..          = automation
MD_DISPLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MD_AUTOMATION_DIR="$(cd "$MD_DISPLAY_DIR/.." && pwd)"
MD_REPO_ROOT="$(cd "$MD_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$MD_AUTOMATION_DIR/core/lib.sh"
. "$MD_AUTOMATION_DIR/core/pipelines.sh"
# ── Wczytaj paletę kolorów ──────────────────────────────────
. "$MD_DISPLAY_DIR/lib/colors.sh"
# ── Wczytaj rdzeń Monitor Plane (m_* — implementacje gate'ów) ─
# Potrzebne do pokrycia gate'ów MON-* (declare -F m_register itd.).
# monitor.sh definiuje tylko funkcje/zmienne — bezpieczne do źródłowania.
. "$MD_AUTOMATION_DIR/monitor/lib/monitor.sh"

# ── StateStore ──────────────────────────────────────────────
MD_STATE_DIR="$MD_REPO_ROOT/system/control-plane/state"
MD_STATE_DB="$MD_STATE_DIR/data/canonical-state.db"

# ── Stany maszyny stanów ────────────────────────────────────
MD_STATES="PENDING SCHEDULED QUEUED RUNNING PAUSED COMPLETED FAILED CANCELLED SKIPPED ARCHIVED"
# ── 9 etapów lifecycle ──────────────────────────────────────
MD_STAGES="REGISTER SCHEDULE QUEUE START MONITOR CONTROL COMPLETE NOTIFY ARCHIVE"

# ── Wymagana baza StateStore (FAIL-CLOSED) ──────────────────
# Brak bazy = FAIL (BLOCKING). NO FALSE GREEN — nie raportujemy PASS
# bez danych. Zwraca 0 jeśli baza istnieje, 1 w przeciwnym razie.
md_require_db() {
  if ! command -v sqlite3 >/dev/null 2>&1; then
    p_fail "MONITOR-DISPLAY-SQLITE" BLOCKING "sqlite3 niedostępny — dashboard Monitor Plane wymaga SQLite"
    return 1
  fi
  if [ ! -f "$MD_STATE_DB" ]; then
    p_fail "MONITOR-DISPLAY-DB" BLOCKING "Brak bazy StateStore: $MD_STATE_DB (uruchom monitor.sh register-all)"
    return 1
  fi
  local has_state
  has_state=$(sqlite3 "$MD_STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='pipeline_monitor_state';" 2>/dev/null)
  if [ -z "$has_state" ]; then
    p_fail "MONITOR-DISPLAY-DB" BLOCKING "Brak tabel Monitor Plane w StateStore (migracja 0019 nie zastosowana)"
    return 1
  fi
  return 0
}

# ── Kolor stanu lifecycle ───────────────────────────────────
md_state_color() {
  case "$1" in
    COMPLETED|ARCHIVED) echo "$D_C_BRIGHT_GREEN" ;;
    FAILED|CANCELLED)   echo "$D_C_BRIGHT_RED" ;;
    RUNNING|QUEUED)     echo "$D_C_BRIGHT_CYAN" ;;
    PAUSED|SCHEDULED)   echo "$D_C_BRIGHT_YELLOW" ;;
    *)                  echo "$D_C_BRIGHT_BLUE" ;;
  esac
}

# ── Kolor etapu lifecycle ───────────────────────────────────
md_stage_color() {
  case "$1" in
    REGISTER) echo "$D_C_BRIGHT_CYAN" ;;
    SCHEDULE) echo "$D_C_BRIGHT_BLUE" ;;
    QUEUE)    echo "$D_C_BRIGHT_GREEN" ;;
    START)    echo "$D_C_BRIGHT_YELLOW" ;;
    MONITOR)  echo "$D_C_BRIGHT_MAGENTA" ;;
    CONTROL)  echo "$D_C_BRIGHT_RED" ;;
    COMPLETE) echo "$D_C_CYAN" ;;
    NOTIFY)   echo "$D_C_BRIGHT_WHITE" ;;
    ARCHIVE)  echo "$D_C_DIM" ;;
    *)        echo "$D_C_WHITE" ;;
  esac
}

# ── Kolor wartości MON_health ───────────────────────────────
# 1.0 = pełne zdrowie (zielony), < 0.5 = krytyczne (czerwony).
md_health_color() {
  local h="$1"
  awk -v h="$h" 'BEGIN{
    if (h >= 0.9) print "\033[92m";       # bright green
    else if (h >= 0.5) print "\033[93m";  # bright yellow
    else print "\033[91m";                # bright red
  }'
}

# ── Renderowanie MON_health ─────────────────────────────────
# MON_health = pipeline_success_rate × pipeline_coverage × control_rate × notification_rate
# Czyta ostatni wiersz z pipeline_monitor_health (best-effort).
# NO FALSE GREEN: brak wiersza = NOT_APPLICABLE, nigdy PASS.
md_render_health() {
  md_require_db || return 1
  p_say ""
  p_sayc "── MONITOR PLANE — HEALTH (MON_health) ──────────────────────" "$D_C_CYAN"
  local row
  row="$(sqlite3 -separator '|' "$MD_STATE_DB" "SELECT pipeline_success_rate, pipeline_coverage, control_rate, notification_rate, mon_health FROM pipeline_monitor_health ORDER BY health_id DESC LIMIT 1;" 2>/dev/null)"
  if [ -z "$row" ]; then
    p_say "  $(d_paint "$D_C_BRIGHT_YELLOW" "NOT_APPLICABLE") — brak pomiaru MON_health (uruchom: monitor.sh health)"
    p_say ""
    return 0
  fi
  local success coverage control notification mon_health
  IFS='|' read -r success coverage control notification mon_health <<< "$row"
  local hcolor
  hcolor="$(md_health_color "$mon_health")"
  p_say "  MON_health = $(d_paint "$hcolor" "$mon_health")"
  p_say ""
  p_say "  pipeline_success_rate = $(d_paint "$D_C_BRIGHT_WHITE" "$success")"
  p_say "  pipeline_coverage     = $(d_paint "$D_C_BRIGHT_WHITE" "$coverage")"
  p_say "  control_rate          = $(d_paint "$D_C_BRIGHT_WHITE" "$control")"
  p_say "  notification_rate     = $(d_paint "$D_C_BRIGHT_WHITE" "$notification")"
  p_say ""
  p_say "  MON_health = success_rate × coverage × control_rate × notification_rate"
  p_say "  1.0 = pełne zdrowie | < 0.5 = krytyczne"
  p_say ""
  return 0
}

# ── Renderowanie macierzy stanów ────────────────────────────
# Liczy pipeline'y w każdym stanie (PENDING..ARCHIVED) + pokazuje
# rozkład etapów. NO FALSE GREEN: brak pipeline'ów = NOT_APPLICABLE.
md_render_states() {
  md_require_db || return 1
  p_say ""
  p_sayc "── MONITOR PLANE — PIPELINE STATES ──────────────────────────" "$D_C_CYAN"
  local total
  total="$(sqlite3 "$MD_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state;" 2>/dev/null)"
  [ -z "$total" ] && total=0
  if [ "$total" -eq 0 ]; then
    p_say "  $(d_paint "$D_C_BRIGHT_YELLOW" "NOT_APPLICABLE") — brak pipeline'ów w Monitor Plane (uruchom: monitor.sh register-all)"
    p_say ""
    return 0
  fi
  p_say "  Total pipeline'ów w Monitor Plane: $(d_paint "$D_C_BRIGHT_WHITE" "$total")"
  p_say ""
  p_say "  STAN        LICZBA"
  p_say "  ──────────  ──────"
  local state count color
  for state in $MD_STATES; do
    count="$(sqlite3 "$MD_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state WHERE state='$state';" 2>/dev/null)"
    [ -z "$count" ] && count=0
    color="$(md_state_color "$state")"
    printf '  %s %s\n' \
      "$(d_paint "$color" "$(printf '%-10s' "$state")")" \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%5d' "$count")")"
  done
  p_say ""
  p_say "  ETAP        LICZBA"
  p_say "  ──────────  ──────"
  local stage
  for stage in $MD_STAGES; do
    count="$(sqlite3 "$MD_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state WHERE stage='$stage';" 2>/dev/null)"
    [ -z "$count" ] && count=0
    color="$(md_stage_color "$stage")"
    printf '  %s %s\n' \
      "$(d_paint "$color" "$(printf '%-10s' "$stage")")" \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%5d' "$count")")"
  done
  p_say ""
  return 0
}

# ── Renderowanie timeline zdarzeń ───────────────────────────
# Użycie: md_render_timeline [pipeline_id]
# Bez argumentu — ostatnie 20 zdarzeń wszystkich pipeline'ów.
# Z argumentem — pełna historia danego pipeline'a.
md_render_timeline() {
  md_require_db || return 1
  local pid="${1:-}"
  local rows
  if [ -n "$pid" ]; then
    rows="$(sqlite3 -separator '|' "$MD_STATE_DB" "SELECT pipeline_id, event_type, action, from_state, to_state, detail, recorded_at FROM pipeline_monitor_events WHERE pipeline_id='$pid' ORDER BY event_id;" 2>/dev/null)"
  else
    rows="$(sqlite3 -separator '|' "$MD_STATE_DB" "SELECT pipeline_id, event_type, action, from_state, to_state, detail, recorded_at FROM pipeline_monitor_events ORDER BY event_id DESC LIMIT 20;" 2>/dev/null)"
  fi
  if [ -z "$rows" ]; then
    p_say "  $(d_paint "$D_C_BRIGHT_YELLOW" "NOT_APPLICABLE") — brak zdarzeń${pid:+ dla $pid}"
    p_say ""
    return 0
  fi
  p_say ""
  p_sayc "── MONITOR PLANE — TIMELINE${pid:+: $pid} ─────────────────────" "$D_C_CYAN"
  p_say "  ID      EVENT     ACTION    FROM        → TO          DETAIL"
  p_say "  ──────  ────────  ────────  ──────────  ──────────  ─────────────────────────────"
  local line eid etype action from to detail ts
  while IFS='|' read -r eid etype action from to detail ts; do
    printf '  %s %s %s %s %s %s\n' \
      "$(d_paint "$D_C_BRIGHT_WHITE" "$(printf '%-6s' "$eid")")" \
      "$(d_paint "$D_C_BOLD" "$(printf '%-8s' "$etype")")" \
      "$(d_paint "$D_C_BRIGHT_YELLOW" "$(printf '%-8s' "${action:-}")")" \
      "$(d_paint "$D_C_DIM" "$(printf '%-10s' "${from:-}")")" \
      "$(d_paint "$D_C_CYAN" "→")" \
      "$(d_paint "$D_C_DIM" "$(printf '%-10s' "${to:-}")")  ${detail:-}  (${ts:-})"
  done <<< "$rows"
  p_say ""
  return 0
}

# ── Renderowanie pokrycia 70 gate'ów MON-* ─────────────────
# Grupy etapów: prefix | liczba | opis | funkcja implementująca.
# NO FALSE GREEN: gate bez implementacji = NOT_APPLICABLE, nigdy PASS.
md_render_gates() {
  md_require_db || return 1
  p_say ""
  p_sayc "── MONITOR PLANE — GATES (70 × MON-*) ───────────────────────" "$D_C_CYAN"
  local groups=(
    "MON-R|6|REGISTER|m_register"
    "MON-S|8|SCHEDULE|m_schedule"
    "MON-Q|8|QUEUE|m_queue"
    "MON-ST|8|START|m_start"
    "MON-M|8|MONITOR|m_monitor"
    "MON-C|8|CONTROL|m_control"
    "MON-CO|8|COMPLETE|m_complete"
    "MON-N|8|NOTIFY|m_notify"
    "MON-A|8|ARCHIVE|m_archive"
  )
  local total=0 implemented=0
  local g prefix count desc fn rest
  for g in "${groups[@]}"; do
    prefix="${g%%|*}"
    rest="${g#*|}"
    count="${rest%%|*}"
    rest="${rest#*|}"
    desc="${rest%%|*}"
    fn="${rest#*|}"
    total=$((total + count))
    if declare -F "$fn" >/dev/null 2>&1; then
      implemented=$((implemented + count))
      printf '  %s %s %s %s\n' \
        "$(d_paint "$D_C_BOLD" "$(printf '%-7s' "$prefix")")" \
        "$(d_paint "$D_C_DIM" "$(printf '%3s' "$count") gate'ów")" \
        "$(d_paint "$D_C_DIM" "$(printf '%-10s' "$desc")")" \
        "$(d_paint "$D_C_BRIGHT_GREEN" "IMPLEMENTED")"
    else
      printf '  %s %s %s %s\n' \
        "$(d_paint "$D_C_BOLD" "$(printf '%-7s' "$prefix")")" \
        "$(d_paint "$D_C_DIM" "$(printf '%3s' "$count") gate'ów")" \
        "$(d_paint "$D_C_DIM" "$(printf '%-10s' "$desc")")" \
        "$(d_paint "$D_C_BRIGHT_YELLOW" "NOT_APPLICABLE")"
    fi
  done
  p_say ""
  p_say "  Razem: $total gate'ów MON-*"
  p_say "  Implementowane: $implemented"
  if [ "$implemented" -eq "$total" ]; then
    p_say "  Pokrycie: $(d_paint "$D_C_BRIGHT_GREEN" "100% — wszystkie gate'y mają implementację")"
  else
    p_say "  Pokrycie: $(d_paint "$D_C_BRIGHT_YELLOW" "$((implemented * 100 / total))% — brak implementacji dla części gate'ów")"
  fi
  p_say ""
  return 0
}

# ── Renderowanie pełnego dashboardu ─────────────────────────
md_render_dashboard() {
  md_require_db || return 1
  p_say ""
  p_sayc "╔══════════════════════════════════════════════════════════════════╗" "$D_C_CYAN"
  p_sayc "║  MONITOR PLANE — DASHBOARD                                        ║" "$D_C_CYAN"
  p_sayc "║  Pipeline Operating System — stan lifecycle (P-001..P-098)        ║" "$D_C_CYAN"
  p_sayc "╚══════════════════════════════════════════════════════════════════╝" "$D_C_CYAN"
  p_say ""
  p_say "  StateStore : system/control-plane/state/data/canonical-state.db"
  p_say "  Stany      : PENDING SCHEDULED QUEUED RUNNING PAUSED COMPLETED"
  p_say "               FAILED CANCELLED SKIPPED ARCHIVED"
  p_say "  Etapy      : REGISTER SCHEDULE QUEUE START MONITOR CONTROL"
  p_say "               COMPLETE NOTIFY ARCHIVE"
  p_say "  NO FALSE GREEN: brak danych = NOT_APPLICABLE, nigdy PASS."
  p_say ""
  md_render_health
  md_render_states
  md_render_gates
  md_render_timeline
  return 0
}
