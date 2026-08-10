-- ============================================================================
-- MIGRATION 0014 — RESILIENCE PLANE (HA/DR/Backup domain model)
-- ============================================================================
-- AIGON Production Platform — Resilience Plane.
-- Rozszerza canonical state o warstwę odporności: backup catalog, wymagania
-- resilience (RTO/RPO/floors), game days (ćwiczenia DR) i SPOF findings.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Resilience Plane domain model i są zdefiniowane
-- z wyprzedzeniem (forward-compatible schema). StateStore konsumuje je
-- INKREMENTALNIE. Tabele backup_catalog / resilience_requirements / game_days
-- / spof_findings są świadomie zdefiniowane jako kanoniczny kontrakt domain
-- model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabele poniżej są świadomie
-- zdefiniowane bez bieżącego użycia w kodzie (konsumowane przez
-- tools/resilience/restore-drill/ i GATE-039).
-- RESERVED_TABLES: agent artifact backup_catalog baseline capability configuration contract debt decision deployment document drift game_days image network node policy port project resilience_requirements runtime service skill spof_findings volume
-- ============================================================================

PRAGMA foreign_keys = ON;

-- BACKUP_CATALOG — katalog backupów canonical state (append-only).
-- Każdy backup ma snapshot_id, ścieżkę, hash, generację i status integralności.
CREATE TABLE IF NOT EXISTS backup_catalog (
    backup_id       TEXT PRIMARY KEY,
    snapshot_id     TEXT NOT NULL,
    backup_file     TEXT NOT NULL,
    backup_hash     TEXT NOT NULL,
    generation      INTEGER NOT NULL DEFAULT 0,
    schema_version  INTEGER,
    git_commit      TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    integrity       TEXT NOT NULL DEFAULT 'UNVERIFIED',
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- RESILIENCE_REQUIREMENTS — wymagania odporności per tier (RTO/RPO/floors).
-- Kanoniczne wartości pochodzą z config/registry.yaml (sekcja resilience:).
CREATE TABLE IF NOT EXISTS resilience_requirements (
    requirement_id  TEXT PRIMARY KEY,
    tier            TEXT NOT NULL,
    rto_minutes     INTEGER NOT NULL,
    rpo_minutes     INTEGER NOT NULL,
    restore_drill_max_age_days INTEGER NOT NULL,
    dr_game_day_max_age_days   INTEGER NOT NULL,
    source          TEXT NOT NULL DEFAULT 'config/registry.yaml',
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- GAME_DAYS — rejestr Disaster Recovery game days (ćwiczenia DR).
-- Każdy game day to zaplanowane, udokumentowane ćwiczenie odzyskiwania.
CREATE TABLE IF NOT EXISTS game_days (
    game_day_id     TEXT PRIMARY KEY,
    tier            TEXT NOT NULL,
    title           TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'PLANNED',
    started_at      TEXT,
    completed_at    TEXT,
    result          TEXT,
    evidence_ref    TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- SPOF_FINDINGS — rejestr Single Point of Failure findings.
-- Każdy finding to zidentyfikowany pojedynczy punkt awarii z oceną ryzyka.
CREATE TABLE IF NOT EXISTS spof_findings (
    finding_id      TEXT PRIMARY KEY,
    component       TEXT NOT NULL,
    description     TEXT NOT NULL,
    risk            TEXT NOT NULL DEFAULT 'UNKNOWN',
    status          TEXT NOT NULL DEFAULT 'OPEN',
    mitigation      TEXT,
    evidence_ref    TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_backup_catalog_snapshot ON backup_catalog(snapshot_id);
CREATE INDEX IF NOT EXISTS idx_resilience_req_tier ON resilience_requirements(tier);
CREATE INDEX IF NOT EXISTS idx_game_days_tier ON game_days(tier);
CREATE INDEX IF NOT EXISTS idx_spof_status ON spof_findings(status);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '14' WHERE key = 'schema_version';
