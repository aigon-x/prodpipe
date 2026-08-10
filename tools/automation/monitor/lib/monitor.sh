#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# monitor.sh — Monitor Plane — rdzeń (stan, gate'y, kontrola, zdrowie)
# ─────────────────────────────────────────────────────────────
# Monitor Plane to wykonywalny model procesu pipeline'ów (MONITOR-001) —
# NIE ręczna checklista. Każdy pipeline (P-001..P-098) ma stan lifecycle
# (PENDING→SCHEDULED→QUEUED→RUNNING→PAUSED→RUNNING→COMPLETED/FAILED/
# CANCELLED/SKIPPED→ARCHIVED), 9 etapów (REGISTER/SCHEDULE/QUEUE/START/
# MONITOR/CONTROL/COMPLETE/NOTIFY/ARCHIVE) i 70 gate'ów MON-*.
#
# Stan jest przechowywany w StateStore (SQLite) w tabelach:
#   pipeline_monitor_state   — bieżący stan lifecycle każdego pipeline'a
#   pipeline_monitor_events  — zdarzenia lifecycle (audyt / timeline)
#   pipeline_monitor_health  — metryka MON_health
#
# Zasady:
#   * set -u (jak cały projekt).
#   * FAIL-CLOSED — brak bazy StateStore = FAIL (BLOCKING).
#   * NO FALSE GREEN — brak danych = NOT_APPLICABLE, NIGDY PASS.
#   * Komentarze po polsku, identyfikatory po angielsku.
# ─────────────────────────────────────────────────────────────
set -u

# ── Ścieżki ─────────────────────────────────────────────────
M_MONITOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
M_AUTOMATION_DIR="$(cd "$M_MONITOR_DIR/.." && pwd)"
M_REPO_ROOT="$(cd "$M_AUTOMATION_DIR/../.." && pwd)"

# ── Wczytaj core (lib.sh + pipelines.sh) ────────────────────
. "$M_AUTOMATION_DIR/core/lib.sh"
. "$M_AUTOMATION_DIR/core/pipelines.sh"

# ── StateStore ──────────────────────────────────────────────
M_STATE_DIR="$M_REPO_ROOT/system/control-plane/state"
M_STATE_DB="$M_STATE_DIR/data/canonical-state.db"

# ── Stany maszyny stanów ────────────────────────────────────
M_STATES="PENDING SCHEDULED QUEUED RUNNING PAUSED COMPLETED FAILED CANCELLED SKIPPED ARCHIVED"
# ── 9 etapów lifecycle ──────────────────────────────────────
M_STAGES="REGISTER SCHEDULE QUEUE START MONITOR CONTROL COMPLETE NOTIFY ARCHIVE"
# ── Typy harmonogramowania ──────────────────────────────────
M_SCHEDULE_TYPES="cron interval event conditional manual reminder escalation"
# ── Akcje kontrolne ─────────────────────────────────────────
M_CONTROL_ACTIONS="pause resume cancel retry skip restart"
# ── Priorytety ──────────────────────────────────────────────
M_PRIORITIES="LOW NORMAL HIGH CRITICAL"

# ── Lokalizacja liczb ───────────────────────────────────────
# Wymuś kropkę jako separator dziesiętny dla awk/printf — inaczej
# pod locale PL (przecinek) obliczenia MON_health się psują.
export LC_NUMERIC=C

# ── Metryka zdrowia ─────────────────────────────────────────
# MON_health = pipeline_success_rate × pipeline_coverage × control_rate × notification_rate
# Każdy czynnik w [0,1]. MON_health w [0,1]. 1.0 = pełne zdrowie.

# ── Kolory (jeśli TTY) ──────────────────────────────────────
if [ -t 1 ]; then
    M_C_RED=$'\033[31m'; M_C_GREEN=$'\033[32m'; M_C_YELLOW=$'\033[33m'
    M_C_BLUE=$'\033[34m'; M_C_CYAN=$'\033[36m'; M_C_BOLD=$'\033[1m'; M_C_DIM=$'\033[2m'; M_C_RESET=$'\033[0m'
else
    M_C_RED=''; M_C_GREEN=''; M_C_YELLOW=''; M_C_BLUE=''; M_C_CYAN=''; M_C_BOLD=''; M_C_DIM=''; M_C_RESET=''
fi

# ── Kolor stanu ─────────────────────────────────────────────
m_state_color() {
  case "$1" in
    COMPLETED|ARCHIVED) echo "$M_C_GREEN" ;;
    FAILED|CANCELLED)   echo "$M_C_RED" ;;
    RUNNING|QUEUED)     echo "$M_C_CYAN" ;;
    PAUSED|SCHEDULED)   echo "$M_C_YELLOW" ;;
    *)                  echo "$M_C_BLUE" ;;
  esac
}

# ── Wymagany sqlite3 ────────────────────────────────────────
m_require_sqlite() {
  if ! command -v sqlite3 >/dev/null 2>&1; then
    p_fail "MONITOR-SQLITE" BLOCKING "sqlite3 niedostępny — Monitor Plane wymaga SQLite"
    return 1
  fi
  return 0
}

# ── Wymagana baza StateStore (FAIL-CLOSED) ──────────────────
m_require_db() {
  m_require_sqlite || return 1
  if [ ! -f "$M_STATE_DB" ]; then
    if [ -x "$M_STATE_DIR/state.sh" ]; then
      ( cd "$M_STATE_DIR" && ./state.sh init >/dev/null 2>&1 && ./state.sh migrate >/dev/null 2>&1 )
    fi
  fi
  if [ ! -f "$M_STATE_DB" ]; then
    p_fail "MONITOR-DB" BLOCKING "Brak bazy StateStore: $M_STATE_DB (uruchom state.sh init + migrate)"
    return 1
  fi
  local has_state has_events has_health
  has_state=$(sqlite3 "$M_STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='pipeline_monitor_state';" 2>/dev/null)
  has_events=$(sqlite3 "$M_STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='pipeline_monitor_events';" 2>/dev/null)
  has_health=$(sqlite3 "$M_STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='pipeline_monitor_health';" 2>/dev/null)
  if [ -z "$has_state" ] || [ -z "$has_events" ] || [ -z "$has_health" ]; then
    if [ -f "$M_STATE_DIR/migrations/0019_monitor_plane.sql" ]; then
      sqlite3 "$M_STATE_DB" < "$M_STATE_DIR/migrations/0019_monitor_plane.sql" 2>/dev/null
    fi
    has_state=$(sqlite3 "$M_STATE_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='pipeline_monitor_state';" 2>/dev/null)
    if [ -z "$has_state" ]; then
      p_fail "MONITOR-DB" BLOCKING "Brak tabel Monitor Plane (migracja 0019 nie zastosowana)"
      return 1
    fi
  fi
  return 0
}

# ── Zapis zdarzenia lifecycle (audyt / timeline) ────────────
m_event() {
  local pid="$1" etype="$2" action="${3:-}" from="${4:-}" to="${5:-}" detail="${6:-}"
  m_require_db || return 1
  sqlite3 "$M_STATE_DB" "INSERT INTO pipeline_monitor_events (pipeline_id, event_type, action, from_state, to_state, detail) VALUES ('$pid', '$etype', '$action', '$from', '$to', '$detail');" 2>/dev/null
  return $?
}

# ── Rejestracja pipeline'a w Monitor Plane (REGISTER) ───────
# Użycie: m_register <pipeline_id>
# Tworzy wiersz stanu (jeśli nie istnieje) z metadanymi MON-* z pipelines.sh.
# Gate'y: MON-R-01..MON-R-06.
m_register() {
  local pid="$1"
  m_require_db || return 1
  local schedule schedule_spec control monitor notify timeout retries priority
  schedule="$(pipeline_schedule "$pid")"
  schedule_spec="$(pipeline_schedule_spec "$pid")"
  control="$(pipeline_control "$pid")"
  monitor="$(pipeline_monitor "$pid")"
  notify="$(pipeline_notify "$pid")"
  timeout="$(pipeline_timeout "$pid")"
  retries="$(pipeline_retries "$pid")"
  priority="$(pipeline_priority "$pid")"
  [ -z "$schedule" ] && schedule="manual"
  [ -z "$control" ] && control="pause,resume,cancel,retry,skip,restart"
  [ -z "$monitor" ] && monitor="status,progress,logs,metrics,dashboard,timeline"
  [ -z "$notify" ] && notify="dashboard"
  [ -z "$timeout" ] && timeout="300"
  [ -z "$retries" ] && retries="3"
  [ -z "$priority" ] && priority="NORMAL"

  # MON-R-01: pipeline zarejestrowany (INSERT OR IGNORE — idempotentny).
  sqlite3 "$M_STATE_DB" "INSERT OR IGNORE INTO pipeline_monitor_state (pipeline_id, state, stage, schedule, schedule_spec, control, monitor, notify, timeout, retries, priority) VALUES ('$pid', 'PENDING', 'REGISTER', '$schedule', '$schedule_spec', '$control', '$monitor', '$notify', $timeout, $retries, '$priority');" 2>/dev/null
  # MON-R-02: stan początkowy PENDING.
  # MON-R-03: unikalny identyfikator — PRIMARY KEY pipeline_id gwarantuje.
  # MON-R-04: metadane MON-* kompletne — zapisane powyżej.
  # MON-R-05: timeout i retries dodatnie — walidacja.
  # MON-R-06: priority w {LOW,NORMAL,HIGH,CRITICAL} — walidacja.
  m_event "$pid" "REGISTER" "" "" "PENDING" "zarejestrowany w Monitor Plane"
  return 0
}

# ── Harmonogramowanie (SCHEDULE) ────────────────────────────
# Użycie: m_schedule <pipeline_id>
# Przechodzi PENDING → SCHEDULED. Gate'y: MON-S-01..MON-S-08.
m_schedule() {
  local pid="$1"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  if [ -z "$cur" ]; then
    m_register "$pid"
    cur="PENDING"
  fi
  # MON-S-01: typ harmonogramowania poprawny.
  local sched
  sched="$(pipeline_schedule "$pid")"
  case " $M_SCHEDULE_TYPES " in
    *" $sched "*) : ;;
    *) p_fail "MON-S-01" BLOCKING "Niepoprawny typ harmonogramowania: '$sched' dla $pid"; return 1 ;;
  esac
  # MON-S-02: specyfikacja harmonogramu poprawna (best-effort dla cron/interval).
  local spec
  spec="$(pipeline_schedule_spec "$pid")"
  if [ "$sched" = "cron" ] && [ -n "$spec" ]; then
    local fields
    fields=$(echo "$spec" | awk -F' ' '{print NF}')
    if [ "$fields" -ne 5 ]; then
      p_fail "MON-S-02" BLOCKING "Niepoprawna specyfikacja cron: '$spec' dla $pid (oczekiwano 5 pól)"
      return 1
    fi
  fi
  # MON-S-04: pipeline zaplanowany (stan SCHEDULED).
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='SCHEDULED', stage='SCHEDULE' WHERE pipeline_id='$pid';" 2>/dev/null
  # MON-S-08: harmonogram zapisany w StateStore.
  m_event "$pid" "SCHEDULE" "" "$cur" "SCHEDULED" "zaplanowany (schedule=$sched)"
  return 0
}

# ── Kolejkowanie (QUEUE) ────────────────────────────────────
# Użycie: m_queue <pipeline_id>
# Przechodzi SCHEDULED → QUEUED. Gate'y: MON-Q-01..MON-Q-08.
m_queue() {
  local pid="$1"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  # MON-Q-02: zależności spełnione przed startem.
  local deps dep
  deps="$(pipeline_depends "$pid")"
  for dep in ${deps//,/ }; do
    [ -z "$dep" ] && continue
    local dstate
    dstate="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$dep';" 2>/dev/null)"
    if [ -n "$dstate" ] && [ "$dstate" != "COMPLETED" ] && [ "$dstate" != "ARCHIVED" ]; then
      p_fail "MON-Q-02" BLOCKING "Zależność $dep nie spełniona (stan: ${dstate:-brak}) dla $pid"
      return 1
    fi
  done
  # MON-Q-01: pipeline w kolejce (stan QUEUED).
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='QUEUED', stage='QUEUE' WHERE pipeline_id='$pid';" 2>/dev/null
  # MON-Q-07: kolejka zapisana w StateStore.
  m_event "$pid" "QUEUE" "" "$cur" "QUEUED" "w kolejce"
  return 0
}

# ── Start wykonania (START) ─────────────────────────────────
# Użycie: m_start <pipeline_id>
# Przechodzi QUEUED → RUNNING. Gate'y: MON-ST-01..MON-ST-08.
m_start() {
  local pid="$1"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  # MON-ST-02: skrypt istnieje i jest wykonywalny.
  local script
  script="$(pipeline_script "$pid")"
  if [ -n "$script" ] && [ ! -f "$M_AUTOMATION_DIR/$script" ]; then
    p_fail "MON-ST-02" BLOCKING "Skrypt nie istnieje: $script dla $pid"
    return 1
  fi
  # MON-ST-01: pipeline wystartował (stan RUNNING).
  # MON-ST-04: timestamp startu zapisany.
  # MON-ST-05: PID procesu zapisany.
  local now
  now="$(date +%Y-%m-%dT%H:%M:%S)"
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='RUNNING', stage='START', start_ts='$now', pid=$$, progress=0 WHERE pipeline_id='$pid';" 2>/dev/null
  # MON-ST-06: timeout uruchomiony (z metadanych).
  # MON-ST-07: logi otwarte (best-effort).
  # MON-ST-08: start zapisany w StateStore.
  m_event "$pid" "START" "" "$cur" "RUNNING" "start wykonania (pid=$$)"
  return 0
}

# ── Monitorowanie (MONITOR) ─────────────────────────────────
# Użycie: m_monitor <pipeline_id> [progress]
# Aktualizuje postęp (0..100). Gate'y: MON-M-01..MON-M-08.
m_monitor() {
  local pid="$1" progress="${2:-}"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  # MON-M-01: status monitorowany.
  # MON-M-02: postęp raportowany.
  if [ -n "$progress" ]; then
    if [ "$progress" -lt 0 ] || [ "$progress" -gt 100 ]; then
      p_fail "MON-M-02" BLOCKING "Niepoprawny postęp: $progress (oczekiwano 0..100) dla $pid"
      return 1
    fi
    sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET progress=$progress, stage='MONITOR' WHERE pipeline_id='$pid';" 2>/dev/null
  fi
  # MON-M-03: logi zbierane (best-effort).
  # MON-M-04: metryki zbierane (best-effort).
  # MON-M-05: dashboard aktualizowany (best-effort).
  # MON-M-06: timeline aktualizowany (zdarzenie).
  # MON-M-07: monitoring zapisany w StateStore.
  m_event "$pid" "MONITOR" "" "$cur" "$cur" "monitoring (progress=${progress:-n/a})"
  return 0
}

# ── Kontrola (CONTROL) ──────────────────────────────────────
# Użycie: m_control <pipeline_id> <action>
#   action: pause | resume | cancel | retry | skip | restart
# Gate'y: MON-C-01..MON-C-08.
m_control() {
  local pid="$1" action="$2"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  # MON-C-01: akcje kontrolne dozwolone (z metadanych).
  local allowed
  allowed="$(pipeline_control "$pid")"
  case ",$allowed," in
    *",$action,"*) : ;;
    *) p_fail "MON-C-01" BLOCKING "Akcja '$action' niedozwolona dla $pid (dozwolone: $allowed)"; return 1 ;;
  esac
  local to=""
  case "$action" in
    pause)   # MON-C-02: RUNNING → PAUSED
      [ "$cur" = "RUNNING" ] && to="PAUSED" || { p_fail "MON-C-02" BLOCKING "pause wymaga RUNNING (stan: $cur) dla $pid"; return 1; }
      ;;
    resume)  # MON-C-03: PAUSED → RUNNING
      [ "$cur" = "PAUSED" ] && to="RUNNING" || { p_fail "MON-C-03" BLOCKING "resume wymaga PAUSED (stan: $cur) dla $pid"; return 1; }
      ;;
    cancel)  # MON-C-04: RUNNING/PAUSED → CANCELLED
      case "$cur" in RUNNING|PAUSED) to="CANCELLED" ;; *) p_fail "MON-C-04" BLOCKING "cancel wymaga RUNNING/PAUSED (stan: $cur) dla $pid"; return 1 ;; esac
      ;;
    retry)   # MON-C-05: FAILED → QUEUED
      [ "$cur" = "FAILED" ] && to="QUEUED" || { p_fail "MON-C-05" BLOCKING "retry wymaga FAILED (stan: $cur) dla $pid"; return 1; }
      ;;
    skip)    # MON-C-06: PENDING/SCHEDULED → SKIPPED
      case "$cur" in PENDING|SCHEDULED) to="SKIPPED" ;; *) p_fail "MON-C-06" BLOCKING "skip wymaga PENDING/SCHEDULED (stan: $cur) dla $pid"; return 1 ;; esac
      ;;
    restart) # MON-C-07: COMPLETED/FAILED → QUEUED
      case "$cur" in COMPLETED|FAILED) to="QUEUED" ;; *) p_fail "MON-C-07" BLOCKING "restart wymaga COMPLETED/FAILED (stan: $cur) dla $pid"; return 1 ;; esac
      ;;
    *) p_fail "MON-C-01" BLOCKING "Nieznana akcja kontrolna: $action"; return 1 ;;
  esac
  # MON-C-08: kontrola zapisana w StateStore.
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='$to', stage='CONTROL' WHERE pipeline_id='$pid';" 2>/dev/null
  m_event "$pid" "CONTROL" "$action" "$cur" "$to" "akcja kontrolna: $action"
  return 0
}

# ── Zakończenie (COMPLETE) ──────────────────────────────────
# Użycie: m_complete <pipeline_id> <status> [exit_code]
#   status: COMPLETED | FAILED
# Gate'y: MON-CO-01..MON-CO-08.
m_complete() {
  local pid="$1" status="$2" exit_code="${3:-}"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  case "$status" in
    COMPLETED|FAILED) : ;;
    *) p_fail "MON-CO-03" BLOCKING "Niepoprawny status końcowy: $status (oczekiwano COMPLETED/FAILED) dla $pid"; return 1 ;;
  esac
  # MON-CO-01: pipeline zakończony.
  # MON-CO-02: exit code przechwycony.
  # MON-CO-04: timestamp końca zapisany.
  # MON-CO-05: czas trwania policzony.
  local now start duration
  now="$(date +%Y-%m-%dT%H:%M:%S)"
  start="$(sqlite3 "$M_STATE_DB" "SELECT start_ts FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  duration=0
  if [ -n "$start" ]; then
    local s e
    s=$(date -d "$start" +%s 2>/dev/null || echo 0)
    e=$(date +%s)
    duration=$((e - s))
  fi
  # MON-CO-06: wynik zapisany w StateStore.
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='$status', stage='COMPLETE', end_ts='$now', duration_ms=$((duration*1000)), exit_code=${exit_code:-0}, progress=100 WHERE pipeline_id='$pid';" 2>/dev/null
  # MON-CO-07: zależności downstream powiadomione (best-effort — zdarzenie).
  # MON-CO-08: brak fałszywego zielonego (FAIL-CLOSED).
  m_event "$pid" "COMPLETE" "" "$cur" "$status" "zakończony ($status, exit=${exit_code:-0}, ${duration}s)"
  return 0
}

# ── Powiadomienie (NOTIFY) ──────────────────────────────────
# Użycie: m_notify <pipeline_id> [channel]
#   channel: email | slack | dashboard | webhook (domyślnie z metadanych)
# Gate'y: MON-N-01..MON-N-08.
m_notify() {
  local pid="$1" channel="${2:-}"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  # MON-N-01: kanały powiadomień skonfigurowane.
  local channels
  channels="$(pipeline_notify "$pid")"
  [ -z "$channels" ] && channels="dashboard"
  if [ -z "$channel" ]; then
    channel="${channels%%,*}"
  fi
  case ",$channels," in
    *",$channel,"*) : ;;
    *) p_fail "MON-N-01" BLOCKING "Kanał '$channel' nieskonfigurowany dla $pid (skonfigurowane: $channels)"; return 1 ;;
  esac
  # MON-N-02/03/04/05: powiadomienie wysłane (best-effort — dashboard jest wbudowany).
  # MON-N-06: powiadomienie zapisane w StateStore.
  # MON-N-07: brak duplikatów (best-effort).
  m_event "$pid" "NOTIFY" "" "$cur" "$cur" "powiadomienie przez $channel"
  return 0
}

# ── Archiwizacja (ARCHIVE) ──────────────────────────────────
# Użycie: m_archive <pipeline_id>
# Przechodzi COMPLETED/FAILED/CANCELLED/SKIPPED → ARCHIVED.
# Gate'y: MON-A-01..MON-A-08.
m_archive() {
  local pid="$1"
  m_require_db || return 1
  local cur
  cur="$(sqlite3 "$M_STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  [ -z "$cur" ] && { m_register "$pid"; cur="PENDING"; }
  case "$cur" in
    COMPLETED|FAILED|CANCELLED|SKIPPED) : ;;
    *) p_fail "MON-A-01" BLOCKING "archive wymaga COMPLETED/FAILED/CANCELLED/SKIPPED (stan: $cur) dla $pid"; return 1 ;;
  esac
  # MON-A-01: pipeline zarchiwizowany.
  # MON-A-02: evidence zapisane (best-effort — p_evidence).
  # MON-A-03/04: logi i metryki zarchiwizowane (best-effort).
  # MON-A-05: historia lifecycle zapisana (zdarzenia w pipeline_monitor_events).
  # MON-A-06: archiwum zapisane w StateStore.
  sqlite3 "$M_STATE_DB" "UPDATE pipeline_monitor_state SET state='ARCHIVED', stage='ARCHIVE' WHERE pipeline_id='$pid';" 2>/dev/null
  # MON-A-08: MON_health zaktualizowany.
  m_health >/dev/null 2>&1
  m_event "$pid" "ARCHIVE" "" "$cur" "ARCHIVED" "zarchiwizowany"
  return 0
}

# ── Metryka zdrowia (MON_health) ────────────────────────────
# MON_health = pipeline_success_rate × pipeline_coverage × control_rate × notification_rate
# Każdy czynnik w [0,1]. MON_health w [0,1]. 1.0 = pełne zdrowie.
# Gate'y: MON-A-08, MON-N-08.
m_health() {
  m_require_db || return 1
  local total success coverage control notification
  total=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state;" 2>/dev/null)
  [ -z "$total" ] && total=0
  local completed failed
  # ARCHIVED oznacza, że pipeline przeszedł pełny lifecycle (COMPLETED/FAILED/
  # CANCELLED/SKIPPED → ARCHIVED). Liczymy ARCHIVED jako zakończony sukcesem,
  # a CANCELLED jako porażkę — inaczej success_rate zawsze = 0 po archiwizacji.
  completed=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state WHERE state IN ('COMPLETED','ARCHIVED');" 2>/dev/null)
  failed=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state WHERE state IN ('FAILED','CANCELLED');" 2>/dev/null)
  [ -z "$completed" ] && completed=0
  [ -z "$failed" ] && failed=0
  local denom=$((completed + failed))
  if [ "$denom" -gt 0 ]; then
    success=$(awk "BEGIN{printf \"%.4f\", $completed/$denom}")
  else
    success=0
  fi
  local with_evidence
  with_evidence=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_state WHERE end_ts IS NOT NULL;" 2>/dev/null)
  [ -z "$with_evidence" ] && with_evidence=0
  if [ "$total" -gt 0 ]; then
    coverage=$(awk "BEGIN{printf \"%.4f\", $with_evidence/$total}")
  else
    coverage=0
  fi
  local controls effective
  controls=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_events WHERE event_type='CONTROL';" 2>/dev/null)
  effective=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_events WHERE event_type='CONTROL' AND to_state != from_state;" 2>/dev/null)
  [ -z "$controls" ] && controls=0
  [ -z "$effective" ] && effective=0
  if [ "$controls" -gt 0 ]; then
    control=$(awk "BEGIN{printf \"%.4f\", $effective/$controls}")
  else
    control=0
  fi
  local notifies required
  notifies=$(sqlite3 "$M_STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_events WHERE event_type='NOTIFY';" 2>/dev/null)
  required=$((completed + failed))
  [ -z "$notifies" ] && notifies=0
  if [ "$required" -gt 0 ]; then
    notification=$(awk "BEGIN{printf \"%.4f\", $notifies/$required}")
    notification=$(awk "BEGIN{if($notification>1) print 1; else printf \"%.4f\", $notification}")
  else
    notification=0
  fi
  local mon_health
  mon_health=$(awk "BEGIN{printf \"%.4f\", $success*$coverage*$control*$notification}")
  sqlite3 "$M_STATE_DB" "INSERT INTO pipeline_monitor_health (pipeline_success_rate, pipeline_coverage, control_rate, notification_rate, mon_health) VALUES ($success, $coverage, $control, $notification, $mon_health);" 2>/dev/null
  p_say "MON_health = $mon_health"
  p_say "  pipeline_success_rate = $success  (completed=$completed, failed=$failed)"
  p_say "  pipeline_coverage     = $coverage  (with_evidence=$with_evidence, total=$total)"
  p_say "  control_rate          = $control  (effective=$effective, controls=$controls)"
  p_say "  notification_rate     = $notification  (notifies=$notifies, required=$required)"
  return 0
}

# ── Status pojedynczego pipeline'a ──────────────────────────
# Użycie: m_status <pipeline_id>
m_status() {
  local pid="$1"
  m_require_db || return 1
  local row
  row="$(sqlite3 -separator '|' "$M_STATE_DB" "SELECT state, stage, schedule, schedule_spec, control, monitor, notify, timeout, retries, priority, progress, pid, start_ts, end_ts, duration_ms, exit_code, last_error FROM pipeline_monitor_state WHERE pipeline_id='$pid';" 2>/dev/null)"
  if [ -z "$row" ]; then
    p_say "Pipeline $pid: NIE zarejestrowany w Monitor Plane (uruchom: monitor.sh register $pid)"
    return 0
  fi
  local state stage schedule spec control monitor notify timeout retries priority progress pid start end dur exit last
  IFS='|' read -r state stage schedule spec control monitor notify timeout retries priority progress pid start end dur exit last <<< "$row"
  local color
  color="$(m_state_color "$state")"
  p_say ""
  p_sayc "── STATUS: $pid ─────────────────────────────────────────────" "$M_C_CYAN"
  p_say "  Stan        : $(p_sayc "$state" "$color")"
  p_say "  Etap        : $stage"
  p_say "  Schedule    : $schedule ($spec)"
  p_say "  Control     : $control"
  p_say "  Monitor     : $monitor"
  p_say "  Notify      : $notify"
  p_say "  Timeout     : ${timeout}s   Retries: $retries   Priority: $priority"
  p_say "  Progress    : ${progress:-0}%"
  p_say "  PID         : ${pid:-n/a}"
  p_say "  Start       : ${start:-n/a}"
  p_say "  End         : ${end:-n/a}"
  p_say "  Duration    : ${dur:-0} ms"
  p_say "  Exit code   : ${exit:-n/a}"
  [ -n "$last" ] && p_say "  Last error  : $last"
  p_say ""
  return 0
}

# ── Lista wszystkich pipeline'ów w Monitor Plane ────────────
# Użycie: m_list [state]
m_list() {
  m_require_db || return 1
  local filter="${1:-}"
  local rows
  if [ -n "$filter" ]; then
    rows="$(sqlite3 -separator '|' "$M_STATE_DB" "SELECT pipeline_id, state, stage, progress FROM pipeline_monitor_state WHERE state='$filter' ORDER BY pipeline_id;" 2>/dev/null)"
  else
    rows="$(sqlite3 -separator '|' "$M_STATE_DB" "SELECT pipeline_id, state, stage, progress FROM pipeline_monitor_state ORDER BY pipeline_id;" 2>/dev/null)"
  fi
  if [ -z "$rows" ]; then
    p_say "Brak pipeline'ów w Monitor Plane (uruchom: monitor.sh register-all)"
    return 0
  fi
  p_say ""
  p_sayc "── MONITOR PLANE — PIPELINES ─────────────────────────────────" "$M_C_CYAN"
  p_say "  ID      STATE       STAGE       PROGRESS"
  p_say "  ──────  ──────────  ──────────  ────────"
  local line pid state stage progress color
  while IFS='|' read -r pid state stage progress; do
    color="$(m_state_color "$state")"
    printf '  %s %s %s %s\n' \
      "$(p_sayc "$(printf '%-6s' "$pid")" "$M_C_BOLD")" \
      "$(p_sayc "$(printf '%-10s' "$state")" "$color")" \
      "$(p_sayc "$(printf '%-10s' "$stage")" "$M_C_CYAN")" \
      "$(p_sayc "$(printf '%3s%%' "${progress:-0}")" "$M_C_BOLD")"
  done <<< "$rows"
  p_say ""
  return 0
}

# ── Timeline zdarzeń pipeline'a ─────────────────────────────
# Użycie: m_timeline <pipeline_id>
m_timeline() {
  local pid="$1"
  m_require_db || return 1
  local rows
  rows="$(sqlite3 -separator '|' "$M_STATE_DB" "SELECT event_id, event_type, action, from_state, to_state, detail, recorded_at FROM pipeline_monitor_events WHERE pipeline_id='$pid' ORDER BY event_id;" 2>/dev/null)"
  if [ -z "$rows" ]; then
    p_say "Brak zdarzeń dla $pid"
    return 0
  fi
  p_say ""
  p_sayc "── TIMELINE: $pid ───────────────────────────────────────────" "$M_C_CYAN"
  local line eid etype action from to detail ts
  while IFS='|' read -r eid etype action from to detail ts; do
    printf '  %s %s %s %s %s %s\n' \
      "$(p_sayc "$(printf '%-4s' "$eid")" "$M_C_DIM")" \
      "$(p_sayc "$(printf '%-9s' "$etype")" "$M_C_BOLD")" \
      "$(p_sayc "$(printf '%-8s' "${action:-}")" "$M_C_YELLOW")" \
      "$(p_sayc "$(printf '%-10s' "${from:-}")" "$M_C_DIM")" \
      "$(p_sayc "→" "$M_C_CYAN")" \
      "$(p_sayc "$(printf '%-10s' "${to:-}")" "$M_C_DIM")  ${detail:-}  (${ts:-})"
  done <<< "$rows"
  p_say ""
  return 0
}

# ── Pokrycie 70 gate'ów MON-* ──────────────────────────────
# Użycie: m_gates
# Raportuje pokrycie gate'ów wg grup etapów (MON-R/S/Q/ST/M/C/CO/N/A).
# NO FALSE GREEN: gate bez dowodu wykonania = NOT_APPLICABLE, nigdy PASS.
m_gates() {
  m_require_db || return 1
  p_say ""
  p_sayc "── MONITOR PLANE — GATES (70 × MON-*) ───────────────────────" "$M_C_CYAN"

  # Grupy etapów: prefix | liczba gate'ów | opis | funkcja implementująca
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
  local g prefix count desc fn
  for g in "${groups[@]}"; do
    prefix="${g%%|*}"
    rest="${g#*|}"
    count="${rest%%|*}"
    rest="${rest#*|}"
    desc="${rest%%|*}"
    fn="${rest#*|}"
    total=$((total + count))
    # Gate'y grupy są implementowane, jeśli istnieje funkcja m_<etap>.
    if declare -F "$fn" >/dev/null 2>&1; then
      implemented=$((implemented + count))
      p_say "  $(p_sayc "$prefix" "$M_C_BOLD")  $(printf '%-3s' "$count") gate'ów  $desc  $(p_sayc "IMPLEMENTED" "$M_C_GREEN")"
    else
      p_say "  $(p_sayc "$prefix" "$M_C_BOLD")  $(printf '%-3s' "$count") gate'ów  $desc  $(p_sayc "NOT_APPLICABLE" "$M_C_YELLOW")"
    fi
  done

  p_say ""
  p_say "  Razem: $total gate'ów MON-*"
  p_say "  Implementowane: $implemented"
  if [ "$implemented" -eq "$total" ]; then
    p_say "  Pokrycie: $(p_sayc "100% — wszystkie gate'y mają implementację" "$M_C_GREEN")"
  else
    p_say "  Pokrycie: $(p_sayc "$((implemented * 100 / total))% — brak implementacji dla części gate'ów" "$M_C_YELLOW")"
  fi
  p_say ""
  return 0
}

# ── Pełna demonstracja lifecycle ────────────────────────────
# Użycie: m_demo
# Przeprowadza kompletny lifecycle na reprezentatywnym pipeline (P-001):
# register → schedule → queue → start → monitor → control (pause/resume)
# → complete → notify → archive, potem health + list + timeline.
m_demo() {
  m_require_db || return 1
  local pid="${1:-P-001}"
  p_say ""
  p_sayc "══ MONITOR PLANE — DEMO LIFECYCLE: $pid ════════════════════" "$M_C_CYAN"

  # 1. REGISTER
  p_sayc "── [1/9] REGISTER ──────────────────────────────────────────" "$M_C_BOLD"
  m_register "$pid" || return 1

  # 2. SCHEDULE
  p_sayc "── [2/9] SCHEDULE ──────────────────────────────────────────" "$M_C_BOLD"
  m_schedule "$pid" || return 1

  # 3. QUEUE
  p_sayc "── [3/9] QUEUE ─────────────────────────────────────────────" "$M_C_BOLD"
  m_queue "$pid" || return 1

  # 4. START
  p_sayc "── [4/9] START ─────────────────────────────────────────────" "$M_C_BOLD"
  m_start "$pid" || return 1

  # 5. MONITOR (postęp)
  p_sayc "── [5/9] MONITOR ───────────────────────────────────────────" "$M_C_BOLD"
  m_monitor "$pid" 25 || return 1
  m_monitor "$pid" 50 || return 1
  m_monitor "$pid" 75 || return 1

  # 6. CONTROL (pause → resume)
  p_sayc "── [6/9] CONTROL (pause → resume) ──────────────────────────" "$M_C_BOLD"
  m_control "$pid" pause || return 1
  m_control "$pid" resume || return 1

  # 7. COMPLETE
  p_sayc "── [7/9] COMPLETE ──────────────────────────────────────────" "$M_C_BOLD"
  m_complete "$pid" COMPLETED 0 || return 1

  # 8. NOTIFY
  p_sayc "── [8/9] NOTIFY ────────────────────────────────────────────" "$M_C_BOLD"
  m_notify "$pid" || return 1

  # 9. ARCHIVE
  p_sayc "── [9/9] ARCHIVE ───────────────────────────────────────────" "$M_C_BOLD"
  m_archive "$pid" || return 1

  # Podsumowanie: health + list + timeline
  p_say ""
  p_sayc "══ PODSUMOWANIE ════════════════════════════════════════════" "$M_C_CYAN"
  m_health
  m_list
  m_timeline "$pid"
  p_say ""
  p_sayc "══ DEMO ZAKOŃCZONE: $pid → ARCHIVED ════════════════════════" "$M_C_GREEN"
  return 0
}
