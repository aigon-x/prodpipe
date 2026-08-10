-- ============================================================================
-- MIGRATION 0018 — PIPELINE OPERATING SYSTEM (Pipeline Runs)
-- ============================================================================
-- AIGON Production Platform — Pipeline Operating System.
-- Rozszerza canonical state o warstwę uruchomień pipeline'ów (P-001..P-051).
-- To jest wykonywalny model procesu pipeline'ów (PIPELINE-001) — NIE ręczna
-- checklista. Każde uruchomienie pipeline'a rejestruje się w pipeline_runs.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Pipeline Operating System domain model i są
-- zdefiniowane z wyprzedzeniem (forward-compatible schema). StateStore
-- konsumuje je INKREMENTALNIE. Tabela pipeline_runs jest świadomie
-- zdefiniowana jako kanoniczny pipeline domain model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabela jest konsumowana przez
-- tools/automation/core/lib.sh (p_register_run) i pipeline'y P-003/P-014/
-- P-040/P-043/P-051.
-- RESERVED_TABLES: pipeline_runs pipeline_evidence pipeline_contract
-- ============================================================================

PRAGMA foreign_keys = ON;

-- PIPELINE_RUN — uruchomienie pipeline'a (P-<seq>). Każde uruchomienie
-- pipeline'a rejestruje się tutaj. Konsumowane przez p_register_run w
-- tools/automation/core/lib.sh. Traceability: pipeline → run → evidence.
CREATE TABLE IF NOT EXISTS pipeline_runs (
    pipeline_id     TEXT NOT NULL,         -- P-<seq>
    status          TEXT NOT NULL DEFAULT 'PASS',  -- PASS/FAIL/ERROR/NOT_APPLICABLE
    class           TEXT,                  -- FAST/STANDARD/DEEP/RELEASE/CONTINUOUS
    duration_ms     INTEGER NOT NULL DEFAULT 0,
    evidence_id     TEXT,                  -- powiązanie z evidence (opcjonalne)
    run_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_pipeline ON pipeline_runs(pipeline_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status ON pipeline_runs(status);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_recorded ON pipeline_runs(recorded_at);

-- PIPELINE_EVIDENCE — evidence specyficzne dla pipeline'ów.
-- Łączy pipeline z evidence (P0#1: każdy pipeline zapisuje wynik do StateStore).
CREATE TABLE IF NOT EXISTS pipeline_evidence (
    evidence_id     TEXT PRIMARY KEY,      -- ev-<timestamp>-<rand>
    pipeline_id     TEXT NOT NULL,         -- P-<seq>
    claim           TEXT NOT NULL,         -- co udowodniono
    source_type     TEXT NOT NULL DEFAULT 'pipeline',
    source_ref      TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pipeline_evidence_pipeline ON pipeline_evidence(pipeline_id);

-- PIPELINE_CONTRACT — kontrakt pipeline'a (8 faz).
-- Weryfikuje, że każdy pipeline deklaruje pełny 8-fazowy kontrakt.
CREATE TABLE IF NOT EXISTS pipeline_contract (
    pipeline_id     TEXT PRIMARY KEY,      -- P-<seq>
    phases          TEXT NOT NULL,         -- DISCOVER,CONTRACT,EXECUTE,TEST,EVIDENCE,VERIFY,REGISTER,REPORT
    phase_count     INTEGER NOT NULL DEFAULT 8,
    status          TEXT NOT NULL DEFAULT 'VALID',  -- VALID/INVALID
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_pipeline_contract_status ON pipeline_contract(status);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '18' WHERE key = 'schema_version';
