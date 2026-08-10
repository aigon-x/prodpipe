-- ============================================================================
-- MIGRATION 0011 — CHANGE INTELLIGENCE / ENGINEERING EFFICIENCY GATE
-- RESERVED_TABLES: fingerprint_cache change_proposals prediction_accuracy change_scope duplicate_work
-- ============================================================================
-- Warstwa "inteligencji zmiany" — mierzy i uczy się kosztu/ryzyka zmian,
-- wykrywa duplikację pracy i pilnuje minimalnego zakresu (Minimal Change Gate).
-- Wszystkie tabele to TELEMETRIA / GOVERNANCE (append-only history), NIE stan
-- canonical — analogicznie do event/evidence/gate_runs/waivers. Nie wchodzą
-- do state_hash (stan), ale mają własny łańcuch integralności
-- (state_history_hash), aby manipulacja audytem efficiency była wykrywalna.
--
--   * fingerprint_cache   — dowodowy cache build (CACHE HIT = udowodnione
--                           identyczne wejścia: source/dependency/compiler/
--                           toolchain/config/flags/target/environment).
--   * change_proposals    — CHANGE PROPOSAL (predicted affected set + expected
--                           czas/ryzyko) PRZED zmianą.
--   * prediction_accuracy — PREDICTED vs ACTUAL po zmianie (pipeline się uczy).
--   * change_scope        — log analizy minimalnego zakresu (Minimal Change Gate).
--   * duplicate_work      — log REQUEST -> CAN I REUSE? -> YES/NO
--                           (Duplicate Work Gate).
-- ============================================================================

-- Dowodowy cache build (CACHE HIT = udowodnione identyczne wejścia)
CREATE TABLE IF NOT EXISTS fingerprint_cache (
    fingerprint_id  TEXT PRIMARY KEY,
    artifact_path   TEXT NOT NULL,
    source_hash     TEXT NOT NULL,
    dependency_hash TEXT,
    compiler_hash   TEXT,
    toolchain_hash  TEXT,
    config_hash     TEXT,
    build_flags     TEXT,
    target          TEXT,
    environment     TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (artifact_path, source_hash, dependency_hash, compiler_hash, toolchain_hash, config_hash, build_flags, target, environment)
);

-- CHANGE PROPOSAL (predicted affected set + expected czas/ryzyko) PRZED zmianą
CREATE TABLE IF NOT EXISTS change_proposals (
    proposal_id     TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    description     TEXT,
    predicted_files TEXT,
    predicted_crates TEXT,
    predicted_services TEXT,
    predicted_tests TEXT,
    predicted_configs TEXT,
    predicted_docs TEXT,
    predicted_deployments TEXT,
    predicted_nodes TEXT,
    expected_build_time_ms INTEGER,
    expected_test_time_ms INTEGER,
    expected_risk     TEXT,
    expected_performance TEXT,
    status          TEXT NOT NULL DEFAULT 'PROPOSED',
    owner           TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- PREDICTED vs ACTUAL po zmianie (pipeline się uczy)
CREATE TABLE IF NOT EXISTS prediction_accuracy (
    accuracy_id     TEXT PRIMARY KEY,
    proposal_id     TEXT REFERENCES change_proposals(proposal_id),
    actual_files    INTEGER,
    predicted_files INTEGER,
    actual_build_time_ms INTEGER,
    expected_build_time_ms INTEGER,
    actual_test_time_ms INTEGER,
    expected_test_time_ms INTEGER,
    accuracy_score  REAL,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Log analizy minimalnego zakresu (Minimal Change Gate)
CREATE TABLE IF NOT EXISTS change_scope (
    scope_id        TEXT PRIMARY KEY,
    change_ref      TEXT NOT NULL,
    files_changed   INTEGER,
    lines_changed   INTEGER,
    components_changed INTEGER,
    dependencies_changed INTEGER,
    configs_changed  INTEGER,
    tests_changed   INTEGER,
    docs_changed    INTEGER,
    scope_anomaly   TEXT,
    justification   TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Log REQUEST -> CAN I REUSE? -> YES/NO (Duplicate Work Gate)
CREATE TABLE IF NOT EXISTS duplicate_work (
    request_id      TEXT PRIMARY KEY,
    request_desc    TEXT NOT NULL,
    can_reuse       TEXT NOT NULL DEFAULT 'UNKNOWN',
    reuse_evidence  TEXT,
    decision        TEXT NOT NULL DEFAULT 'EXECUTE',
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeksy pomocnicze
CREATE INDEX IF NOT EXISTS idx_fingerprint_artifact ON fingerprint_cache(artifact_path);
CREATE INDEX IF NOT EXISTS idx_prediction_proposal ON prediction_accuracy(proposal_id);
CREATE INDEX IF NOT EXISTS idx_scope_change ON change_scope(change_ref);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '11' WHERE key = 'schema_version';
