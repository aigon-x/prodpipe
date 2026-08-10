-- ============================================================================
-- MIGRATION 0003 — GATE RUNS + WAIVERS (governance/audyt)
-- RESERVED_TABLES: gate_runs
-- ============================================================================
-- P1: gate_runs rejestruje KAŻDE uruchomienie gate'a (kto, co, kiedy, wynik).
--     To jest surowiec dla risk prediction (S7) — dane treningowe.
--     waivers rejestruje WYJĄTKI (świadome odstępstwa od gate'ów).
--     Zasada: wyjątek bez expires_at jest NIELEGALNY (wyjątki wygasają).
--
-- gate_runs i waivers to governance/audyt (append-only history), analogicznie
-- do event/evidence — NIE są częścią canonical state (state_hash), ale mają
-- własny łańcuch integralności (state_history_hash).
-- ============================================================================

-- Log uruchomień gate'ów (append-only)
CREATE TABLE gate_runs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id      TEXT NOT NULL,                -- identyfikator przebiegu (np. commit SHA)
    gate        TEXT NOT NULL,                -- nazwa gate'a (np. SELF-001, G0, VERIFY-EVIDENCE-COMPLETE)
    profile     TEXT,                         -- profil (fast/full/release/genesis/...)
    status      TEXT NOT NULL CHECK (status IN ('pass','fail','warn','waived')),
    duration_ms INTEGER,                      -- czas trwania w ms
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Wyjątki (waivers) — świadome odstępstwa od gate'ów
CREATE TABLE waivers (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    check_id      TEXT NOT NULL,              -- identyfikator checka/gate'a
    scope         TEXT NOT NULL,              -- zakres wyjątku (np. 'module:architecture', 'repo:all')
    justification TEXT NOT NULL,              -- uzasadnienie (wymagane)
    approved_by   TEXT NOT NULL,              -- kto zatwierdził (wymagane)
    expires_at    TEXT NOT NULL,              -- wygaśnięcie (WYMAGANE — wyjątki wygasają)
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Indeks do sweepera wygasłych wyjątków (P1: waiver sweeper)
CREATE INDEX idx_waivers_expiry ON waivers(expires_at);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '3' WHERE key = 'schema_version';
