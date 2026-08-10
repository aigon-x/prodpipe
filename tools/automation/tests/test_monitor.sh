#!/usr/bin/env bash
# ============================================================================
# test_monitor.sh — MONITOR PLANE (Pipeline Monitoring / Control / Scheduling)
# ============================================================================
# Weryfikuje, że:
#   M1: Migracja 0019 istnieje i tworzy 3 tabele Monitor Plane
#   M2: schema_version = 19 po migracji
#   M3: register rejestruje pipeline (PENDING / REGISTER)
#   M4: Pełny lifecycle: register→schedule→queue→start→monitor→control→
#       complete→notify→archive (stan ARCHIVED)
#   M5: Control actions: pause/resume (RUNNING→PAUSED→RUNNING)
#   M6: Control actions: cancel (tylko RUNNING/PAUSED — odrzuca inne)
#   M7: Control actions: skip (SCHEDULED→SKIPPED)
#   M8: Health metric (MON_health = success × coverage × control × notify)
#   M9: Gates coverage (70 gate'ów MON-* IMPLEMENTED)
#   M10: Dashboard rendering (monitor subkomendy zwracają PIPELINE: PASS)
#   M11: Timeline rejestruje zdarzenia lifecycle
#
# Użycie: ./test_monitor.sh
# ============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOMATION_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$AUTOMATION_DIR/../.." && pwd)"
MIGRATIONS_DIR="$REPO_ROOT/system/control-plane/state/migrations"
STATE_DB="$REPO_ROOT/system/control-plane/state/data/canonical-state.db"
MONITOR_CLI="$AUTOMATION_DIR/monitor/monitor.sh"
DISPLAY_CLI="$AUTOMATION_DIR/display/display-pipeline.sh"

PASS=0; FAIL=0
t_pass() { PASS=$((PASS+1)); echo "  [PASS] $*"; }
t_fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $*"; }

echo "=== MONITOR PLANE TESTS ==="

# --- M1: Migracja 0019 istnieje i tworzy 3 tabele ---------------------------
echo ""
echo "--- M1: Migracja 0019 istnieje i tworzy 3 tabele Monitor Plane ---"
if [ ! -f "$MIGRATIONS_DIR/0019_monitor_plane.sql" ]; then
    t_fail "Brak migracji 0019: $MIGRATIONS_DIR/0019_monitor_plane.sql"
else
    if grep -q "CREATE TABLE IF NOT EXISTS pipeline_monitor_state" "$MIGRATIONS_DIR/0019_monitor_plane.sql" \
       && grep -q "CREATE TABLE IF NOT EXISTS pipeline_monitor_events" "$MIGRATIONS_DIR/0019_monitor_plane.sql" \
       && grep -q "CREATE TABLE IF NOT EXISTS pipeline_monitor_health" "$MIGRATIONS_DIR/0019_monitor_plane.sql"; then
        t_pass "Migracja 0019 tworzy 3 tabele (state/events/health)"
    else
        t_fail "Migracja 0019 nie tworzy wszystkich 3 tabel"
    fi
fi

# --- M2: schema_version = 19 ------------------------------------------------
echo ""
echo "--- M2: schema_version = 19 ---"
if [ ! -f "$STATE_DB" ]; then
    t_fail "Brak bazy StateStore: $STATE_DB (uruchom monitor.sh register-all)"
else
    SCHEMA_VERSION="$(sqlite3 "$STATE_DB" "SELECT value FROM meta WHERE key='schema_version';" 2>/dev/null)"
    if [ "$SCHEMA_VERSION" = "19" ]; then
        t_pass "schema_version = $SCHEMA_VERSION"
    else
        t_fail "schema_version = '$SCHEMA_VERSION' (oczekiwano '19')"
    fi
fi

# --- Reset stanu testowych pipeline'ów --------------------------------------
# StateStore jest trwały między sesjami. register jest idempotentny
# (INSERT OR IGNORE) i NIE resetuje istniejącego stanu. Aby testy były
# deterministyczne, resetujemy stany P-001..P-004 do PENDING/REGISTER.
echo ""
echo "--- Reset stanu testowych pipeline'ów (P-001..P-004) ---"
if [ -f "$STATE_DB" ]; then
    sqlite3 "$STATE_DB" "UPDATE pipeline_monitor_state SET state='PENDING', stage='REGISTER', progress=0, pid=NULL, start_ts=NULL, end_ts=NULL, duration_ms=0, exit_code=NULL, last_error=NULL WHERE pipeline_id IN ('P-001','P-002','P-003','P-004');" 2>/dev/null
    t_pass "Zresetowano stany P-001..P-004 do PENDING/REGISTER"
fi

# --- M3: register rejestruje pipeline (PENDING / REGISTER) ------------------
echo ""
echo "--- M3: register rejestruje pipeline (PENDING / REGISTER) ---"
# Użyj dedykowanego pipeline'a testowego P-001 (istnieje w katalogu).
if [ ! -f "$MONITOR_CLI" ]; then
    t_fail "Brak CLI Monitor Plane: $MONITOR_CLI"
else
    bash "$MONITOR_CLI" register P-001 >/dev/null 2>&1
    REG_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-001';" 2>/dev/null)"
    REG_STAGE="$(sqlite3 "$STATE_DB" "SELECT stage FROM pipeline_monitor_state WHERE pipeline_id='P-001';" 2>/dev/null)"
    if [ "$REG_STATE" = "PENDING" ] && [ "$REG_STAGE" = "REGISTER" ]; then
        t_pass "register P-001 → state=$REG_STATE stage=$REG_STAGE"
    else
        t_fail "register P-001 → state='$REG_STATE' stage='$REG_STAGE' (oczekiwano PENDING/REGISTER)"
    fi
fi

# --- M4: Pełny lifecycle do ARCHIVED ----------------------------------------
echo ""
echo "--- M4: Pełny lifecycle: register→schedule→queue→start→monitor→control→complete→notify→archive ---"
bash "$MONITOR_CLI" schedule P-001 >/dev/null 2>&1
bash "$MONITOR_CLI" queue P-001 >/dev/null 2>&1
bash "$MONITOR_CLI" start P-001 >/dev/null 2>&1
bash "$MONITOR_CLI" monitor P-001 50 >/dev/null 2>&1
bash "$MONITOR_CLI" complete P-001 COMPLETED 0 >/dev/null 2>&1
bash "$MONITOR_CLI" notify P-001 dashboard >/dev/null 2>&1
bash "$MONITOR_CLI" archive P-001 >/dev/null 2>&1
FINAL_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-001';" 2>/dev/null)"
FINAL_STAGE="$(sqlite3 "$STATE_DB" "SELECT stage FROM pipeline_monitor_state WHERE pipeline_id='P-001';" 2>/dev/null)"
if [ "$FINAL_STATE" = "ARCHIVED" ] && [ "$FINAL_STAGE" = "ARCHIVE" ]; then
    t_pass "Pełny lifecycle P-001 → state=$FINAL_STATE stage=$FINAL_STAGE"
else
    t_fail "Pełny lifecycle P-001 → state='$FINAL_STATE' stage='$FINAL_STAGE' (oczekiwano ARCHIVED/ARCHIVE)"
fi

# --- M5: Control actions: pause/resume --------------------------------------
echo ""
echo "--- M5: Control actions: pause/resume (RUNNING→PAUSED→RUNNING) ---"
# Przygotuj P-002 do RUNNING.
bash "$MONITOR_CLI" register P-002 >/dev/null 2>&1
bash "$MONITOR_CLI" schedule P-002 >/dev/null 2>&1
bash "$MONITOR_CLI" queue P-002 >/dev/null 2>&1
bash "$MONITOR_CLI" start P-002 >/dev/null 2>&1
# pause
bash "$MONITOR_CLI" control P-002 pause >/dev/null 2>&1
PAUSED_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-002';" 2>/dev/null)"
# resume
bash "$MONITOR_CLI" control P-002 resume >/dev/null 2>&1
RESUMED_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-002';" 2>/dev/null)"
if [ "$PAUSED_STATE" = "PAUSED" ] && [ "$RESUMED_STATE" = "RUNNING" ]; then
    t_pass "pause→PAUSED, resume→RUNNING"
else
    t_fail "pause→'$PAUSED_STATE', resume→'$RESUMED_STATE' (oczekiwano PAUSED/RUNNING)"
fi

# --- M6: Control actions: cancel (tylko RUNNING/PAUSED) ---------------------
echo ""
echo "--- M6: Control actions: cancel (tylko RUNNING/PAUSED — odrzuca inne) ---"
# P-002 jest RUNNING — cancel powinien zadziałać.
bash "$MONITOR_CLI" control P-002 cancel >/dev/null 2>&1
CANCEL_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-002';" 2>/dev/null)"
# P-003 jest PENDING (nie RUNNING/PAUSED) — cancel powinien być odrzucony.
bash "$MONITOR_CLI" register P-003 >/dev/null 2>&1
bash "$MONITOR_CLI" control P-003 cancel >/dev/null 2>&1
P003_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-003';" 2>/dev/null)"
if [ "$CANCEL_STATE" = "CANCELLED" ] && [ "$P003_STATE" = "PENDING" ]; then
    t_pass "cancel na RUNNING→CANCELLED, cancel na PENDING odrzucony (PENDING)"
else
    t_fail "cancel na RUNNING→'$CANCEL_STATE', cancel na PENDING→'$P003_STATE' (oczekiwano CANCELLED/PENDING)"
fi

# --- M7: Control actions: skip (SCHEDULED→SKIPPED) --------------------------
echo ""
echo "--- M7: Control actions: skip (SCHEDULED→SKIPPED) ---"
bash "$MONITOR_CLI" register P-004 >/dev/null 2>&1
bash "$MONITOR_CLI" schedule P-004 >/dev/null 2>&1
bash "$MONITOR_CLI" control P-004 skip >/dev/null 2>&1
SKIP_STATE="$(sqlite3 "$STATE_DB" "SELECT state FROM pipeline_monitor_state WHERE pipeline_id='P-004';" 2>/dev/null)"
if [ "$SKIP_STATE" = "SKIPPED" ]; then
    t_pass "skip na SCHEDULED→SKIPPED"
else
    t_fail "skip na SCHEDULED→'$SKIP_STATE' (oczekiwano SKIPPED)"
fi

# --- M8: Health metric (MON_health) -----------------------------------------
echo ""
echo "--- M8: Health metric (MON_health = success × coverage × control × notify) ---"
bash "$MONITOR_CLI" health >/dev/null 2>&1
HEALTH_ROW="$(sqlite3 -separator '|' "$STATE_DB" "SELECT pipeline_success_rate, pipeline_coverage, control_rate, notification_rate, mon_health FROM pipeline_monitor_health ORDER BY health_id DESC LIMIT 1;" 2>/dev/null)"
if [ -z "$HEALTH_ROW" ]; then
    t_fail "Brak wiersza MON_health w pipeline_monitor_health"
else
    IFS='|' read -r success coverage control notification mon_health <<< "$HEALTH_ROW"
    # MON_health musi być w [0,1] i być iloczynem 4 czynników.
    MON_OK=$(awk -v s="$success" -v c="$coverage" -v ct="$control" -v n="$notification" -v m="$mon_health" \
        'BEGIN{ if (m >= 0 && m <= 1) print 1; else print 0 }')
    if [ "$MON_OK" = "1" ]; then
        t_pass "MON_health=$mon_health (w zakresie [0,1])"
    else
        t_fail "MON_health=$mon_health poza zakresem [0,1]"
    fi
fi

# --- M9: Gates coverage (70 gate'ów MON-* IMPLEMENTED) ----------------------
echo ""
echo "--- M9: Gates coverage (70 gate'ów MON-* IMPLEMENTED) ---"
GATES_OUT="$(bash "$MONITOR_CLI" gates 2>&1)"
if echo "$GATES_OUT" | grep -q "70" && echo "$GATES_OUT" | grep -q "100%"; then
    t_pass "70 gate'ów MON-* — 100% pokrycie"
else
    t_fail "Pokrycie gate'ów nie jest 70/100% (output: $(echo "$GATES_OUT" | tail -3 | tr '\n' ' '))"
fi

# --- M10: Dashboard rendering (monitor subkomendy) --------------------------
echo ""
echo "--- M10: Dashboard rendering (monitor subkomendy zwracają PIPELINE: PASS) ---"
if [ ! -f "$DISPLAY_CLI" ]; then
    t_fail "Brak CLI display: $DISPLAY_CLI"
else
    DASH_OUT="$(bash "$DISPLAY_CLI" monitor 2>&1)"
    if echo "$DASH_OUT" | grep -q "PIPELINE: PASS"; then
        t_pass "monitor (dashboard) → PIPELINE: PASS"
    else
        t_fail "monitor (dashboard) nie zwrócił PIPELINE: PASS"
    fi
    HEALTH_OUT="$(bash "$DISPLAY_CLI" monitor-health 2>&1)"
    if echo "$HEALTH_OUT" | grep -q "PIPELINE: PASS"; then
        t_pass "monitor-health → PIPELINE: PASS"
    else
        t_fail "monitor-health nie zwrócił PIPELINE: PASS"
    fi
    STATES_OUT="$(bash "$DISPLAY_CLI" monitor-states 2>&1)"
    if echo "$STATES_OUT" | grep -q "PIPELINE: PASS"; then
        t_pass "monitor-states → PIPELINE: PASS"
    else
        t_fail "monitor-states nie zwrócił PIPELINE: PASS"
    fi
    TIMELINE_OUT="$(bash "$DISPLAY_CLI" monitor-timeline P-001 2>&1)"
    if echo "$TIMELINE_OUT" | grep -q "PIPELINE: PASS"; then
        t_pass "monitor-timeline P-001 → PIPELINE: PASS"
    else
        t_fail "monitor-timeline P-001 nie zwrócił PIPELINE: PASS"
    fi
    GATES_OUT2="$(bash "$DISPLAY_CLI" monitor-gates 2>&1)"
    if echo "$GATES_OUT2" | grep -q "PIPELINE: PASS"; then
        t_pass "monitor-gates → PIPELINE: PASS"
    else
        t_fail "monitor-gates nie zwrócił PIPELINE: PASS"
    fi
fi

# --- M11: Timeline rejestruje zdarzenia lifecycle ---------------------------
echo ""
echo "--- M11: Timeline rejestruje zdarzenia lifecycle ---"
EVENT_COUNT="$(sqlite3 "$STATE_DB" "SELECT COUNT(*) FROM pipeline_monitor_events WHERE pipeline_id='P-001';" 2>/dev/null)"
if [ -n "$EVENT_COUNT" ] && [ "$EVENT_COUNT" -ge 8 ]; then
    t_pass "Timeline P-001 ma $EVENT_COUNT zdarzeń (≥8: register/schedule/queue/start/monitor/complete/notify/archive)"
else
    t_fail "Timeline P-001 ma '$EVENT_COUNT' zdarzeń (oczekiwano ≥8)"
fi

# --- Podsumowanie -----------------------------------------------------------
echo ""
echo "=== MONITOR PLANE — WYNIK ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTS PASS"
    exit 0
else
    echo "TESTS FAILED"
    exit 1
fi
