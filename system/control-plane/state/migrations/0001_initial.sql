-- ============================================================================
-- MIGRATION 0001 — INITIAL CANONICAL STATE SCHEMA
-- ============================================================================
-- AIGON Production Platform — Canonical State Foundation.
-- Tworzy pełny domain model canonical operational state.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- META — tożsamość bazy, wersja schematu, generacja, hash
CREATE TABLE meta (
    key         TEXT PRIMARY KEY,
    value       TEXT NOT NULL
);

-- CLUSTER
CREATE TABLE cluster (
    cluster_id      TEXT PRIMARY KEY,
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

-- NODE
CREATE TABLE node (
    node_id         TEXT PRIMARY KEY,
    cluster_id      TEXT NOT NULL REFERENCES cluster(cluster_id),
    hostname        TEXT,
    ip_address      TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- RUNTIME
CREATE TABLE runtime (
    runtime_id      TEXT PRIMARY KEY,
    node_id         TEXT NOT NULL REFERENCES node(node_id),
    name            TEXT,
    version         TEXT,
    container_id    TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- SERVICE
CREATE TABLE service (
    service_id      TEXT PRIMARY KEY,
    runtime_id      TEXT REFERENCES runtime(runtime_id),
    name            TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- IMAGE
CREATE TABLE image (
    image_id        TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    tag             TEXT,
    canonical_sha   TEXT,
    source_git_commit TEXT,
    observed_node   TEXT,
    observed_at     TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- NETWORK
CREATE TABLE network (
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

-- PORT
CREATE TABLE port (
    port_id         TEXT PRIMARY KEY,
    service_id      TEXT REFERENCES service(service_id),
    node_id         TEXT REFERENCES node(node_id),
    number          INTEGER NOT NULL,
    protocol        TEXT DEFAULT 'tcp',
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- VOLUME
CREATE TABLE volume (
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

-- AGENT
CREATE TABLE agent (
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

-- SKILL
CREATE TABLE skill (
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

-- PROJECT
CREATE TABLE project (
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

-- CAPABILITY
CREATE TABLE capability (
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

-- CONFIGURATION (DESIRED/EFFECTIVE/OBSERVED)
CREATE TABLE configuration (
    config_id       TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    key             TEXT NOT NULL,
    value           TEXT,
    desired         TEXT,
    effective       TEXT,
    observed        TEXT,
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

-- POLICY
CREATE TABLE policy (
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

-- CONTRACT
CREATE TABLE contract (
    contract_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    kind            TEXT,
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

-- DEPLOYMENT (DESIRED/EFFECTIVE/OBSERVED)
CREATE TABLE deployment (
    deployment_id   TEXT PRIMARY KEY,
    service_id      TEXT REFERENCES service(service_id),
    node_id         TEXT REFERENCES node(node_id),
    image_id        TEXT REFERENCES image(image_id),
    desired         TEXT,
    effective       TEXT,
    observed        TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- BASELINE
CREATE TABLE baseline (
    baseline_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    git_commit      TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    status          TEXT NOT NULL DEFAULT 'CURRENT'
);

-- SNAPSHOT
CREATE TABLE snapshot (
    snapshot_id     TEXT PRIMARY KEY,
    generation      INTEGER NOT NULL,
    schema_version  INTEGER NOT NULL,
    state_hash      TEXT NOT NULL,
    git_commit      TEXT,
    runtime_version TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    status          TEXT NOT NULL DEFAULT 'CURRENT'
);

-- EVENT
CREATE TABLE event (
    event_id        TEXT PRIMARY KEY,
    kind            TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    payload         TEXT,
    generation      INTEGER,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- EVIDENCE
CREATE TABLE evidence (
    evidence_id     TEXT PRIMARY KEY,
    claim           TEXT NOT NULL,
    source_type     TEXT,
    source_ref      TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- DRIFT
CREATE TABLE drift (
    drift_id        TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    drift_type      TEXT,
    expected        TEXT,
    observed        TEXT,
    status          TEXT NOT NULL DEFAULT 'DRIFT',
    source          TEXT,
    generation      INTEGER,
    evidence_ref    TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- DEBT
CREATE TABLE debt (
    debt_id         TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    description     TEXT NOT NULL,
    kind            TEXT NOT NULL DEFAULT 'HIDDEN',
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    repayment_deadline TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- DECISION
CREATE TABLE decision (
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

-- ARTIFACT
CREATE TABLE artifact (
    artifact_id     TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    kind            TEXT,
    digest          TEXT,
    store           TEXT,
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

-- DOCUMENT
CREATE TABLE document (
    document_id     TEXT PRIMARY KEY,
    path            TEXT NOT NULL,
    kind            TEXT NOT NULL DEFAULT 'HUMAN_SOURCE',
    generated_at    TEXT,
    generation      INTEGER,
    state_hash      TEXT,
    generator_version TEXT,
    source_commit   TEXT,
    status          TEXT NOT NULL DEFAULT 'CURRENT',
    owner           TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeksy
CREATE INDEX idx_node_cluster ON node(cluster_id);
CREATE INDEX idx_runtime_node ON runtime(node_id);
CREATE INDEX idx_service_runtime ON service(runtime_id);
CREATE INDEX idx_port_service ON port(service_id);
CREATE INDEX idx_deployment_service ON deployment(service_id);
CREATE INDEX idx_drift_domain ON drift(domain);
CREATE INDEX idx_debt_domain ON debt(domain);
CREATE INDEX idx_evidence_generation ON evidence(generation);
CREATE INDEX idx_event_generation ON event(generation);

-- Inicjalizacja meta
INSERT INTO meta (key, value) VALUES ('schema_version', '1');
INSERT INTO meta (key, value) VALUES ('generation', '0');
INSERT INTO meta (key, value) VALUES ('database_id', 'aigon-canonical-state');
INSERT INTO meta (key, value) VALUES ('created_at', datetime('now'));
