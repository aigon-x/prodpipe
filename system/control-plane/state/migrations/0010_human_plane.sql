-- ============================================================================
-- MIGRATION 0010 — HUMAN PLANE (manual testing + UX governance domain model)
-- ============================================================================
-- AIGON Production Platform — Human Plane.
-- Rozszerza canonical state o warstwę ludzką: charters testów manualnych,
-- sesje testowe z evidence, UAT sign-off na digest artefaktu, badania
-- użyteczności (UX) i budżety tarcia (friction budgets).
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Human Plane domain model i są zdefiniowane
-- z wyprzedzeniem (forward-compatible schema). StateStore konsumuje je
-- INKREMENTALNIE. Tabele manual_charters / manual_sessions / uat_signoffs
-- / ux_studies / friction_baselines są świadomie zdefiniowane jako kanoniczny
-- kontrakt domain model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabele poniżej są świadomie
-- zdefiniowane bez bieżącego użycia w kodzie (konsumowane przez narzędzia
-- Human Plane i gate'y MAN-xx / UX-A-xx / UX-R-xx).
-- RESERVED_TABLES: agent artifact baseline capability charter configuration contract debt decision deployment document drift evidence friction_baselines game_days image journey manual_charters manual_sessions network node policy port project runtime service skill spof_findings uat_signoffs ux_studies volume
-- ============================================================================

PRAGMA foreign_keys = ON;

-- MANUAL_CHARTERS — udokumentowane charters testów manualnych (MAN-01/02).
-- Każda wymagana ścieżka ma albo test automatyczny, albo udokumentowany
-- charter manualny. coverage_type: AUTO | MANUAL.
CREATE TABLE manual_charters (
    charter_id      TEXT PRIMARY KEY,
    service_id      TEXT NOT NULL,
    journey_id      TEXT NOT NULL,      -- ścieżka użytkownika
    tier            TEXT NOT NULL,
    coverage_type   TEXT NOT NULL DEFAULT 'MANUAL',  -- AUTO | MANUAL
    status          TEXT NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | COMPLETED | ARCHIVED
    owner           TEXT NOT NULL,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- MANUAL_SESSIONS — sesje testowe z evidence (MAN-02/08).
-- Session-based testing: każda sesja ma charter + evidence. result:
-- PENDING | PASS | FAIL | FINDINGS. artifact_digest wiąże sesję z konkretnym
-- artefaktem (MAN-03). converted_test_id to MAN-06 (manual→auto conversion).
CREATE TABLE manual_sessions (
    session_id      TEXT PRIMARY KEY,
    charter_id      TEXT NOT NULL REFERENCES manual_charters(charter_id),
    tester          TEXT NOT NULL,
    started_at      TEXT NOT NULL,
    completed_at    TEXT,
    result          TEXT NOT NULL DEFAULT 'PENDING',  -- PENDING | PASS | FAIL | FINDINGS
    artifact_digest TEXT,               -- MAN-03: UAT bound to digest
    evidence_ref    TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- UAT_SIGNOFFS — akceptacja UAT na konkretny digest artefaktu (MAN-03).
-- Sign-off nie jest "na wersję ogólnie" — jest na konkretny digest.
CREATE TABLE uat_signoffs (
    signoff_id      TEXT PRIMARY KEY,
    service_id      TEXT NOT NULL,
    artifact_digest TEXT NOT NULL,
    approver        TEXT NOT NULL,
    tier            TEXT NOT NULL,
    signed_at       TEXT NOT NULL,
    evidence_ref    TEXT
);

-- UX_STUDIES — badania użyteczności (UX-R-01..08).
-- study_type: USABILITY | SUS | HEURISTIC | DOGFOOD. Mierzy task success,
-- time-on-task, SUS score — governance UX, nieautomatyzowalne.
CREATE TABLE ux_studies (
    study_id        TEXT PRIMARY KEY,
    service_id      TEXT NOT NULL,
    study_type      TEXT NOT NULL,      -- USABILITY | SUS | HEURISTIC | DOGFOOD
    tier            TEXT NOT NULL,
    task_success_rate REAL,
    time_on_task_sec REAL,
    sus_score       REAL,
    conducted_at    TEXT NOT NULL,
    evidence_ref    TEXT
);

-- FRICTION_BASELINES — budżety tarcia per journey (warstwa 150% A).
-- friction(ścieżka) = kliknięcia + pola formularza + zmiany kontekstu
-- + czas oczekiwania. Przekroczenie budżetu = FAIL.
CREATE TABLE friction_baselines (
    journey_id      TEXT PRIMARY KEY,
    service_id      TEXT NOT NULL,
    friction_budget INTEGER NOT NULL,   -- suma kliknięć+pól+kontekstów+czasu
    measured_friction INTEGER,
    status          TEXT NOT NULL DEFAULT 'WITHIN_BUDGET',  -- WITHIN_BUDGET | OVER_BUDGET
    measured_at     TEXT
);

-- Indeksy
CREATE INDEX idx_manual_charters_service ON manual_charters(service_id);
CREATE INDEX idx_manual_charters_tier ON manual_charters(tier);
CREATE INDEX idx_manual_sessions_charter ON manual_sessions(charter_id);
CREATE INDEX idx_manual_sessions_tester ON manual_sessions(tester);
CREATE INDEX idx_uat_signoffs_service ON uat_signoffs(service_id);
CREATE INDEX idx_ux_studies_service ON ux_studies(service_id);
CREATE INDEX idx_friction_journey ON friction_baselines(service_id);

-- MAN-06: findings manualne → testy automatyczne (conversion).
ALTER TABLE manual_sessions ADD COLUMN converted_test_id TEXT;

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '10' WHERE key = 'schema_version';
