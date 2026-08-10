-- ============================================================================
-- MIGRATION 0011 — CONTRACTS PLANE (API contract governance domain model)
-- ============================================================================
-- AIGON Production Platform — Contracts Plane.
-- Rozszerza canonical state o warstwę kontraktów: rejestr kontraktów API
-- (OpenAPI/Spectral), wersjonowanie semver, schematy walidacji, testy
-- kontraktowe i wykrywanie breaking changes.
--
-- Zasada: schema jest MIGRACYJNA. Każda zmiana to nowy plik w migrations/.
-- NIGDY ręcznych zmian schematu — tylko przez migracje.
--
-- DECLARED-INTENT (rezerwacja schematu):
-- Poniższe tabele są częścią Contracts Plane domain model i są zdefiniowane
-- z wyprzedzeniem (forward-compatible schema). StateStore konsumuje je
-- INKREMENTALNIE. Tabela contracts jest świadomie zdefiniowana jako kanoniczny
-- kontrakt domain model — NIE usuwać.
-- Marker dla INTEG-006 (defined→consumed): tabela contracts jest świadomie
-- zdefiniowana bez bieżącego użycia w kodzie (konsumowana przez
-- tools/verify/contracts/contracts.sh i gate'y CONTRACT-xx).
-- RESERVED_TABLES: agent artifact backup_catalog baseline capability configuration contract contracts debt decision deployment document drift evidence friction_baselines game_days image journey manual_charters manual_sessions network node policy port project resilience_requirements runtime service skill spof_findings uat_signoffs ux_studies volume
-- ============================================================================

PRAGMA foreign_keys = ON;

-- CONTRACTS — rejestr kontraktów API/platformy (CONTRACT-001..006).
-- Każdy kontrakt ma identyfikator, wersję semver, ścieżkę, status integralności
-- i znacznik czasu ostatniej weryfikacji. status: ACTIVE | UNDEFINED | ARCHIVED.
CREATE TABLE contracts (
    contract_id     TEXT PRIMARY KEY,
    version         TEXT NOT NULL,      -- semver (X.Y.Z)
    path            TEXT NOT NULL,      -- ścieżka do pliku kontraktu
    status          TEXT NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | UNDEFINED | ARCHIVED
    checked_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeksy
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_version ON contracts(version);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '11' WHERE key = 'schema_version';
