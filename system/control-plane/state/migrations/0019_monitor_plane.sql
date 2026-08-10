-- ============================================================================
-- MIGRATION 0019 — MONITOR PLANE (Pipeline Monitoring / Control / Scheduling)
-- ============================================================================
-- AIGON Production Platform — Monitor Plane.
-- Rozszerza canonical state o warstwę monitorowania, kontroli i harmonogramowania
-- pipeline'ów (P-001..P-098). To jest wykonywalny model procesu pipeline'ów
-- (MONITOR-001) — NIE ręczna checklista. Każdy pipeline ma stan lifecycle
-- (PENDING→SCHEDULED→QUEUED→RUNNING→PAUSED→RUNNING→COMPLETED/FAILED/
-- CANCELLED/SKIPPED→ARCHIVED), 9 etapów (REGISTER/SCHEDULE/QUEUE/START/
-- MONITOR/CONTROL/COMPLETE/NOTIFY/ARCHIVE) i 70 gate'ów MON-*.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Monitor Plane domain model i są zdefiniowane
-- z wyprzedzeniem (forward-compatible schema). StateStore konsumuje je
-- INKREMENTALNIE. Tabele pipeline_monitor_state / pipeline_monitor_events /
-- pipeline_monitor_health są świadomie zdefiniowane jako kanoniczny monitor
-- domain model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabele są konsumowane przez
-- tools/automation/monitor/monitor.sh (CLI Monitor Plane).
-- RESERVED_TABLES: pipeline_monitor_state pipeline_monitor_events pipeline_monitor_health
-- ============================================================================

PRAGMA foreign_keys = ON;

-- PIPELINE_MONITOR_STATE — bieżący stan lifecycle pipeline'a w Monitor Plane.
-- Każdy pipeline (P-<seq>) ma dokładnie jeden wiersz stanu. Stan przechodzi
-- przez maszynę stanów: PENDING→SCHEDULED→QUEUED→RUNNING→PAUSED→RUNNING→
-- COMPLETED/FAILED/CANCELLED/SKIPPED→ARCHIVED.
CREATE TABLE IF NOT EXISTS pipeline_monitor_state (
    pipeline_id     TEXT PRIMARY KEY,      -- P-<seq>
    state           TEXT NOT NULL DEFAULT 'PENDING',  -- PENDING/SCHEDULED/QUEUED/RUNNING/PAUSED/COMPLETED/FAILED/CANCELLED/SKIPPED/ARCHIVED
    stage           TEXT NOT NULL DEFAULT 'REGISTER', -- REGISTER/SCHEDULE/QUEUE/START/MONITOR/CONTROL/COMPLETE/NOTIFY/ARCHIVE
    schedule        TEXT NOT NULL DEFAULT 'manual',   -- cron/interval/event/conditional/manual/reminder/escalation
    schedule_spec   TEXT NOT NULL DEFAULT '',
    control         TEXT NOT NULL DEFAULT 'pause,resume,cancel,retry,skip,restart',
    monitor         TEXT NOT NULL DEFAULT 'status,progress,logs,metrics,dashboard,timeline',
    notify          TEXT NOT NULL DEFAULT 'dashboard',
    timeout         INTEGER NOT NULL DEFAULT 300,
    retries         INTEGER NOT NULL DEFAULT 3,
    priority        TEXT NOT NULL DEFAULT 'NORMAL',   -- LOW/NORMAL/HIGH/CRITICAL
    progress        INTEGER NOT NULL DEFAULT 0,       -- 0..100
    pid             INTEGER,                          -- PID procesu (RUNNING)
    start_ts        TEXT,                             -- timestamp startu (ISO-8601)
    end_ts          TEXT,                             -- timestamp końca (ISO-8601)
    duration_ms     INTEGER NOT NULL DEFAULT 0,
    exit_code       INTEGER,                          -- exit code wykonania
    last_error      TEXT,                             -- ostatni błąd
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pms_state ON pipeline_monitor_state(state);
CREATE INDEX IF NOT EXISTS idx_pms_priority ON pipeline_monitor_state(priority);

-- PIPELINE_MONITOR_EVENTS — zdarzenia lifecycle pipeline'a (audyt / timeline).
-- Każda zmiana stanu / akcja kontrolna / powiadomienie rejestruje się tutaj.
CREATE TABLE IF NOT EXISTS pipeline_monitor_events (
    event_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_id     TEXT NOT NULL,         -- P-<seq>
    event_type      TEXT NOT NULL,         -- REGISTER/SCHEDULE/QUEUE/START/MONITOR/CONTROL/COMPLETE/NOTIFY/ARCHIVE
    action          TEXT,                  -- pause/resume/cancel/retry/skip/restart (dla CONTROL)
    from_state      TEXT,
    to_state        TEXT,
    detail          TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pme_pipeline ON pipeline_monitor_events(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pme_recorded ON pipeline_monitor_events(recorded_at);

-- PIPELINE_MONITOR_HEALTH — metryka zdrowia Monitor Plane.
-- MON_health = pipeline_success_rate × pipeline_coverage × control_rate ×
-- notification_rate. Każdy czynnik w [0,1]. MON_health w [0,1]. 1.0 = pełne zdrowie.
CREATE TABLE IF NOT EXISTS pipeline_monitor_health (
    health_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    pipeline_success_rate REAL NOT NULL DEFAULT 0,   -- udane / wszystkie
    pipeline_coverage     REAL NOT NULL DEFAULT 0,   -- z evidence / wszystkie
    control_rate          REAL NOT NULL DEFAULT 0,   -- skuteczne / wszystkie
    notification_rate     REAL NOT NULL DEFAULT 0,   -- wysłane / wymagane
    mon_health            REAL NOT NULL DEFAULT 0,   -- iloczyn 4 czynników
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pmh_recorded ON pipeline_monitor_health(recorded_at);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '19' WHERE key = 'schema_version';
