-- ============================================================================
-- CANONICAL STATE SCHEMA — AIGON Production Platform
-- ============================================================================
-- Canonical operational state (SQLite). Git = desired state, SQLite = canonical
-- operational state, AIGON-X-FS = actual state (artifact plane, przyszłość).
--
-- Zasady:
--   * Schema jest MIGRACYJNA — każda zmiana to nowy plik w migrations/.
--   * NIGDY ręcznych zmian schematu — tylko przez migracje.
--   * Identity: cluster_id / node_id / runtime_id / service_id / deployment_id
--     / generation są ROZDZIELNE. Hostname/IP/port są WŁAŚCIWOŚCIAMI, nie tożsamością.
--   * Provenance: każdy ważny stan odpowiada "skąd pochodzi ta wartość".
--   * Desired / Effective / Observed — trzy poziomy dla konfiguracji i deployment.
--   * UNKNOWN nigdy nie jest PASS.
--
-- Schema version: 1 (migracja 0001_initial.sql)
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- META — tożsamość bazy, wersja schematu, generacja, hash
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meta (
    key         TEXT PRIMARY KEY,          -- 'schema_version' | 'generation' | 'state_hash' | 'database_id' | 'created_at' | 'git_commit' | 'runtime_version'
    value       TEXT NOT NULL
);

-- ---------------------------------------------------------------------------
-- CLUSTER — tożsamość klastra
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cluster (
    cluster_id      TEXT PRIMARY KEY,      -- kanoniczny identyfikator klastra
    name            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'CURRENT',  -- CURRENT/CANONICAL/DEPRECATED/QUARANTINED/ARCHIVED/ALLOWED_LEGACY/UNKNOWN/DRIFT
    owner           TEXT,                  -- single-owner domeny
    source_type     TEXT,                  -- provenance: 'git' | 'manual' | 'runtime' | 'migration'
    source_ref      TEXT,                  -- provenance: commit / ref / dokument
    source_hash     TEXT,                  -- provenance: hash źródła
    observed_at     TEXT,                  -- ISO-8601
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- NODE — tożsamość noda (hostname/IP są właściwościami, nie tożsamością)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS node (
    node_id         TEXT PRIMARY KEY,      -- kanoniczny identyfikator noda
    cluster_id      TEXT NOT NULL REFERENCES cluster(cluster_id),
    hostname        TEXT,                  -- WŁAŚCIWOŚĆ, nie tożsamość
    ip_address      TEXT,                  -- WŁAŚCIWOŚĆ, nie tożsamość
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- RUNTIME — tożsamość runtime'u (container_id jest właściwością)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS runtime (
    runtime_id      TEXT PRIMARY KEY,      -- kanoniczny identyfikator runtime
    node_id         TEXT NOT NULL REFERENCES node(node_id),
    name            TEXT,
    version         TEXT,
    container_id    TEXT,                  -- WŁAŚCIWOŚĆ, nie tożsamość
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- SERVICE — tożsamość usługi (service_name jest właściwością)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service (
    service_id      TEXT PRIMARY KEY,      -- kanoniczny identyfikator usługi
    runtime_id      TEXT REFERENCES runtime(runtime_id),
    name            TEXT,                  -- WŁAŚCIWOŚĆ, nie tożsamość
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- IMAGE — obraz kontenera z pełnym pochodzeniem
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS image (
    image_id        TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    tag             TEXT,
    canonical_sha   TEXT,                  -- kanoniczny hash obrazu
    source_git_commit TEXT,                -- provenance: commit, z którego zbudowano
    observed_node   TEXT,                  -- provenance: node, na którym zaobserwowano
    observed_at     TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- NETWORK — sieć Docker / mesh
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS network (
    network_id      TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    cluster_id      TEXT REFERENCES cluster(cluster_id),
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- PORT — port (właściwość, nie tożsamość)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS port (
    port_id         TEXT PRIMARY KEY,
    service_id      TEXT REFERENCES service(service_id),
    node_id         TEXT REFERENCES node(node_id),
    number          INTEGER NOT NULL,
    protocol        TEXT DEFAULT 'tcp',
    status          TEXT NOT NULL DEFAULT 'CURRENT',  -- CURRENT/DEPRECATED/DRIFT/UNKNOWN
    owner           TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- VOLUME — wolumen
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS volume (
    volume_id       TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    node_id         TEXT REFERENCES node(node_id),
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- AGENT — tożsamość agenta
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent (
    agent_id        TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    runtime_id      TEXT REFERENCES runtime(runtime_id),
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- SKILL — umiejętność agenta
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS skill (
    skill_id        TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    agent_id        TEXT REFERENCES agent(agent_id),
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- PROJECT — projekt
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS project (
    project_id      TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- CAPABILITY — zdolność platformy
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS capability (
    capability_id   TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- CONFIGURATION — konfiguracja z trzema poziomami DESIRED/EFFECTIVE/OBSERVED
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS configuration (
    config_id       TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,          -- np. 'runtime', 'router', 'mesh'
    key             TEXT NOT NULL,
    value           TEXT,
    desired         TEXT,                   -- DESIRED (z Git / canonical)
    effective       TEXT,                   -- EFFECTIVE (zastosowana)
    observed        TEXT,                   -- OBSERVED (zaobserwowana w Runtime)
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0,
    UNIQUE (domain, key)
);

-- ---------------------------------------------------------------------------
-- POLICY — polityka
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS policy (
    policy_id       TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    domain          TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- CONTRACT — kontrakt (ABI, API, capability, ...)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contract (
    contract_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    kind            TEXT,                   -- 'agent-abi' | 'api' | 'capability' | 'events' | 'evidence' | 'filesystem' | 'identity' | 'mesh' | 'runtime-abi' | 'security'
    version         TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- DEPLOYMENT — deployment z trzema poziomami DESIRED/EFFECTIVE/OBSERVED
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS deployment (
    deployment_id   TEXT PRIMARY KEY,
    service_id      TEXT REFERENCES service(service_id),
    node_id         TEXT REFERENCES node(node_id),
    image_id        TEXT REFERENCES image(image_id),
    desired         TEXT,                   -- DESIRED
    effective       TEXT,                   -- EFFECTIVE
    observed        TEXT,                   -- OBSERVED
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- BASELINE — punkt odniesienia (np. BASELINE-0.1.0)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS baseline (
    baseline_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,          -- np. 'BASELINE-0.1.0'
    git_commit      TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    status          TEXT NOT NULL DEFAULT 'CURRENT'
);

-- ---------------------------------------------------------------------------
-- SNAPSHOT — snapshot canonical state
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS snapshot (
    snapshot_id     TEXT PRIMARY KEY,
    generation      INTEGER NOT NULL,
    schema_version  INTEGER NOT NULL,
    state_hash      TEXT NOT NULL,
    git_commit      TEXT,
    runtime_version TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    status          TEXT NOT NULL DEFAULT 'CURRENT'
);

-- ---------------------------------------------------------------------------
-- EVENT — zdarzenie
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event (
    event_id        TEXT PRIMARY KEY,
    kind            TEXT NOT NULL,          -- np. 'state_change' | 'deployment' | 'drift' | 'snapshot'
    entity_type     TEXT,
    entity_id       TEXT,
    payload         TEXT,
    generation      INTEGER,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- EVIDENCE — dowód (claim → source → generation)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evidence (
    evidence_id     TEXT PRIMARY KEY,
    claim           TEXT NOT NULL,
    source_type     TEXT,
    source_ref      TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- DRIFT — wykryty drift
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drift (
    drift_id        TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    drift_type      TEXT,                   -- SOURCE/CONFIG/SCHEMA/IMAGE/VERSION/HOST/IP/PORT/NODE/RUNTIME/SERVICE/AGENT/SKILL/MEMORY/PROJECT/ARTIFACT/FILESYSTEM/DEPLOYMENT/DOCUMENTATION/SECURITY/HISTORICAL
    expected        TEXT,
    observed        TEXT,
    status          TEXT NOT NULL DEFAULT 'DRIFT',  -- PASS/DRIFT/FAIL/UNKNOWN/NOT_APPLICABLE
    source          TEXT,
    generation      INTEGER,
    evidence_ref    TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- DEBT — dług (świadomy vs ukryty)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS debt (
    debt_id         TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    description     TEXT NOT NULL,
    kind            TEXT NOT NULL DEFAULT 'HIDDEN',  -- CONSCIOUS / HIDDEN
    status          TEXT NOT NULL DEFAULT 'CURRENT', -- CURRENT/CANONICAL/DEPRECATED/QUARANTINED/ARCHIVED/ALLOWED_LEGACY/UNKNOWN/DRIFT
    owner           TEXT,
    repayment_deadline TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- DECISION — decyzja architektoniczna / operacyjna
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS decision (
    decision_id     TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    domain          TEXT,
    rationale       TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- ARTIFACT — artefakt (metadata/referencja; payload w AIGON-X-FS, przyszłość)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS artifact (
    artifact_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    kind            TEXT,                   -- 'manifest' | 'digest' | 'evidence' | 'report' | 'backup'
    digest          TEXT,
    store           TEXT,                   -- 'local' | 'aigon-x-fs' (przyszłość)
    store_ref       TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- DOCUMENT — dokument (klasy HUMAN_SOURCE/GENERATED/HISTORICAL/ARCHIVED)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document (
    document_id     TEXT PRIMARY KEY,
    path            TEXT NOT NULL,
    kind            TEXT NOT NULL DEFAULT 'HUMAN_SOURCE',  -- HUMAN_SOURCE/GENERATED/HISTORICAL/ARCHIVED
    generated_at    TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    generator_version TEXT,
    source_commit   TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------------
-- Indeksy
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_node_cluster ON node(cluster_id);
CREATE INDEX IF NOT EXISTS idx_runtime_node ON runtime(node_id);
CREATE INDEX IF NOT EXISTS idx_service_runtime ON service(runtime_id);
CREATE INDEX IF NOT EXISTS idx_port_service ON port(service_id);
CREATE INDEX IF NOT EXISTS idx_deployment_service ON deployment(service_id);
CREATE INDEX IF NOT EXISTS idx_drift_domain ON drift(domain);
CREATE INDEX IF NOT EXISTS idx_debt_domain ON debt(domain);
CREATE INDEX IF NOT EXISTS idx_evidence_generation ON evidence(generation);
CREATE INDEX IF NOT EXISTS idx_event_generation ON event(generation);
