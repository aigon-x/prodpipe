-- ============================================================================
-- MIGRATION 0009 — OBSERVABILITY BASELINE (SLO + ALERTS)
-- ============================================================================
-- OBS-BASELINE: szablon rodzi obserwowalne projekty. Ta migracja tworzy
-- fundament operacyjności w StateStore:
--
--   * slo     — rejestr Service Level Objectives (service_id, sli, target,
--               window, alert_ref). Każde SLO ma cel (target 0..1), okno
--               pomiarowe (window) i referencję do alertu (alert_ref).
--               SLO bez alertu to "cel bez alarmu" (OBS-14 = FAIL).
--   * alerts  — rejestr alertów (alert_id, severity, runbook_ref, owner,
--               status). Każdy alert ma runbook (OBS-05), owner (OBS-11)
--               i severity (OBS-12). Alert bez runbooka/ownera to "alert,
--               który nikt nie odbierze".
--
-- Zasady (z ADR-0011-observability-baseline.md):
--   * SLO i alerty są częścią canonical state — źródło prawdy w git.
--   * alert_ref w SLO wskazuje na alert_id w alerts (korelacja cel→alarm).
--   * severity dozwolone: critical | warning | info (OBS-12).
--   * status alertu: ACTIVE | ACKNOWLEDGED | RESOLVED | DISABLED.
-- ============================================================================

-- Rejestr SLO (Service Level Objectives)
CREATE TABLE slo (
    id          INTEGER PRIMARY KEY,
    service_id  TEXT NOT NULL,            -- service_id z .skeleton.yaml
    sli         TEXT NOT NULL,            -- nazwa wskaźnika (availability, latency_p99, ...)
    target      REAL NOT NULL,            -- cel 0..1 (0.99 = 99%)
    window      TEXT NOT NULL,            -- okno pomiarowe (30d, 7d, ...)
    alert_ref   TEXT,                     -- referencja do alertu (OBS-14: WYMAGANE)
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(service_id, sli)
);

-- Rejestr alertów
CREATE TABLE alerts (
    id          INTEGER PRIMARY KEY,
    alert_id    TEXT NOT NULL UNIQUE,     -- unikalny identyfikator alertu
    severity    TEXT NOT NULL,            -- critical | warning | info (OBS-12)
    runbook_ref TEXT NOT NULL,            -- ścieżka do runbooka (OBS-05: WYMAGANE)
    owner       TEXT NOT NULL,            -- zespół/osoba odpowiedzialna (OBS-11: WYMAGANE)
    status      TEXT NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | ACKNOWLEDGED | RESOLVED | DISABLED
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeksy pomocnicze
CREATE INDEX idx_slo_service ON slo(service_id);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(status);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '9' WHERE key = 'schema_version';
