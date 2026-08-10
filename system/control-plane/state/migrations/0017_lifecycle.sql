-- ============================================================================
-- MIGRATION 0017 — LIFECYCLE PLANE (Evidence-Driven Software Lifecycle)
-- ============================================================================
-- AIGON Production Platform — Lifecycle Plane.
-- Rozszerza canonical state o warstwę cyklu życia oprogramowania: wymagania,
-- zmiany, weryfikacje i release'y. To jest wykonywalny model procesu
-- tworzenia oprogramowania (LIFECYCLE-001) — NIE ręczna checklista.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Lifecycle Plane domain model i są zdefiniowane
-- z wyprzedzeniem (forward-compatible schema). StateStore konsumuje je
-- INKREMENTALNIE. Tabele requirement/change/verification/release są świadomie
-- zdefiniowane jako kanoniczny lifecycle domain model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabele są konsumowane przez
-- tools/verify/lifecycle/lifecycle.sh i gate'y LIFECYCLE-xx.
-- RESERVED_TABLES: agent artifact backup_catalog baseline capability change configuration contract contracts debt decision deployment document drift evidence friction_baselines game_days image journey manual_charters manual_sessions network node policy port project release requirement resilience_requirements runtime service skill spof_findings uat_signoffs ux_studies verification volume
-- ============================================================================

PRAGMA foreign_keys = ON;

-- REQUIREMENT — wymaganie (REQ-<seq>). Źródło: PRD/SPEC. Traceability:
-- requirement → contract → design → code → test → gate → evidence → verification.
CREATE TABLE IF NOT EXISTS requirement (
    requirement_id  TEXT PRIMARY KEY,      -- REQ-<seq>
    change_id       TEXT,                  -- CHG-<seq> (opcjonalne powiązanie ze zmianą)
    title           TEXT NOT NULL,
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'DEFINED',  -- IDEA/DISCOVERING/DEFINED/CONTRACTED/DESIGNED/IMPLEMENTING/VERIFYING/INTEGRATING/HARDENING/RELEASING/STAGING/CERTIFIED/CANARY/PRODUCTION/OPERATING/DEPRECATED/RETIRED/BLOCKED
    priority        TEXT,                  -- P0/P1/P2/P3
    owner           TEXT,
    source_type     TEXT,                  -- 'prd' | 'spec' | 'rfc' | 'adr'
    source_ref      TEXT,                  -- ścieżka do dokumentu źródłowego
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_requirement_status ON requirement(status);
CREATE INDEX IF NOT EXISTS idx_requirement_change ON requirement(change_id);

-- CHANGE — zmiana (CHG-<seq>). Uniwersalny artefakt zmiany w lifecycle.
CREATE TABLE IF NOT EXISTS change (
    change_id       TEXT PRIMARY KEY,      -- CHG-<seq>
    title           TEXT NOT NULL,
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'IDEA',  -- stany jak w requirement
    phase           TEXT,                  -- F00..F17
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_change_status ON change(status);
CREATE INDEX IF NOT EXISTS idx_change_phase ON change(phase);

-- VERIFICATION — weryfikacja (VER-<seq>). Dowód, że kontrakt jest spełniony.
-- Łączy artefakt (requirement/contract/code/release) z evidence.
CREATE TABLE IF NOT EXISTS verification (
    verification_id TEXT PRIMARY KEY,      -- VER-<seq>
    artifact_type   TEXT NOT NULL,         -- requirement/contract/design/code/test/gate/build/artifact/release/deployment/runtime
    artifact_id     TEXT NOT NULL,         -- REQ-xxx / CONTRACT-xxx / ...
    gate_id         TEXT,                  -- G0..G17 lub GATE-xxx
    evidence_id     TEXT,                  -- EVIDENCE-<seq> (powiązanie z evidence)
    status          TEXT NOT NULL DEFAULT 'PENDING',  -- PENDING/PASS/FAIL/ERROR/NOT_APPLICABLE
    verifier        TEXT,                  -- kto/co zweryfikował
    verified_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_verification_artifact ON verification(artifact_type, artifact_id);
CREATE INDEX IF NOT EXISTS idx_verification_status ON verification(status);

-- RELEASE — release (REL-<seq>). Ciągnie tylko zweryfikowane artefakty.
CREATE TABLE IF NOT EXISTS release (
    release_id      TEXT PRIMARY KEY,      -- REL-<seq>
    version         TEXT NOT NULL,         -- semver (X.Y.Z)
    status          TEXT NOT NULL DEFAULT 'RELEASING',  -- RELEASING/STAGING/CERTIFIED/CANARY/PRODUCTION/OPERATING/DEPRECATED/RETIRED/BLOCKED
    baseline_id     TEXT,                  -- powiązanie z baseline
    git_commit      TEXT,
    sbom_ref        TEXT,                  -- SBOM/SLSA artefakt
    owner           TEXT,
    source_type     TEXT,
    source_ref      TEXT,
    source_hash     TEXT,
    observed_at     TEXT,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now')),
    generation      INTEGER NOT NULL DEFAULT 0
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_release_status ON release(status);
CREATE INDEX IF NOT EXISTS idx_release_version ON release(version);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '17' WHERE key = 'schema_version';
