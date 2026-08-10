-- ============================================================================
-- MIGRATION 0007 — AESTHETICS PLANE + QUALITY INDEX
-- ============================================================================
-- AESTHETICS PLANE to warstwa "piękna jako mierzalne właściwości". Ta migracja
-- tworzy fundament mierzalności doskonałości:
--
--   * aest_findings  — rejestr findingów estetycznych (AEST-xx / MOD-xx /
--                      CONS-xx / DX-xx) z opcjonalnym expires_at (AEST-04:
--                      wieczne TODO = FAIL — wyjątki wygasają).
--   * quality_index  — materializowany Quality Index per serwis/wymiar.
--                      QI = 100 × ∏ s_i^{w_i} (średnia geometryczna ważona).
--                      Reguła: dimension score bez świeżego evidence = 0
--                      (nie NULL — ZERO). Jeden wymiar na zero → cały indeks
--                      na zero.
--
-- Zasady (z design doc docs/architecture/aesthetics-plane-design.md):
--   * Średnia geometryczna, nie arytmetyczna — nie da się "nadrobić"
--     dziurawego bezpieczeństwa pięknym kodem.
--   * Dimension score bez świeżego evidence = 0 (nie NULL — ZERO).
--   * Wagi w_i z configu (tier 1 ma inne wagi niż tier 3).
--   * Metryka konkurencyjna: ΔQI tydzień do tygodnia.
-- ============================================================================

-- Rejestr findingów estetycznych (AEST-xx / MOD-xx / CONS-xx / DX-xx)
CREATE TABLE aest_findings (
    id          INTEGER PRIMARY KEY,
    service_id  TEXT NOT NULL,
    check_id    TEXT NOT NULL,            -- AEST-xx / MOD-xx / CONS-xx / DX-xx
    subject     TEXT NOT NULL,            -- plik/symbol/API
    detail_json TEXT,
    expires_at  TEXT,                     -- AEST-04: TODO wygasa
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Materializowany Quality Index per serwis/wymiar (0..1, wyliczony z evidence)
CREATE TABLE quality_index (
    id          INTEGER PRIMARY KEY,
    service_id  TEXT NOT NULL,
    dimension   TEXT NOT NULL,            -- 14 wymiarów doskonałości
    score       REAL NOT NULL,            -- 0..1, wyliczone z evidence
    computed_at TEXT NOT NULL,
    UNIQUE(service_id, dimension, computed_at)
);

-- Indeksy pomocnicze
CREATE INDEX idx_aest_findings_service ON aest_findings(service_id);
CREATE INDEX idx_quality_index_service ON quality_index(service_id);
CREATE INDEX idx_quality_index_computed ON quality_index(computed_at);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '7' WHERE key = 'schema_version';
