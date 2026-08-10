-- ============================================================================
-- MIGRATION 0003 — SYSTEM TWIN / CANONICAL STATE GRAPH (F5: self-proving)
-- ============================================================================
-- AIGON-X SYSTEM TWIN — żywy, wykonywalny model systemu.
-- "MODEL OUTPUT IS A CLAIM, NOT A FACT."
-- "Never trust a component's claim about its own state. Verify externally."
--
-- Tabela system_twin_node: każdy node w grafie stanu (komponent/usługa).
--   node_id      — unikalny identyfikator noda (np. runtime, router, state)
--   node_type    — typ noda (service | component | datastore | agent)
--   declared     — stan deklarowany (z configu)
--   effective    — stan faktyczny (co działa)
--   observed     — stan zaobserwowany zewnętrznie (dowód)
--   last_verified— timestamp ostatniej zewnętrznej weryfikacji
--   status       — PASS | FAIL | UNKNOWN | NOT_APPLICABLE
--
-- Tabela system_twin_edge: każda krawędź = realna zależność między nodami.
--   edge_id      — unikalny identyfikator krawędzi
--   from_node    — node źródłowy
--   to_node      — node docelowy
--   edge_type    — typ zależności (depends_on | requires | feeds | controls)
--   verified     — czy zależność została zewnętrznie zweryfikowana (0/1)
--
-- Zasada: gate SYSTEM-TWIN-GATE weryfikuje że każdy node w grafie ma żywy
-- odpowiednik w rzeczywistości i każdy edge ma realną zależność.
-- ============================================================================

CREATE TABLE IF NOT EXISTS system_twin_node (
    node_id       TEXT PRIMARY KEY,
    node_type     TEXT NOT NULL DEFAULT 'service',
    declared      TEXT,
    effective     TEXT,
    observed      TEXT,
    last_verified TEXT,
    status        TEXT NOT NULL DEFAULT 'UNKNOWN'
);

CREATE TABLE IF NOT EXISTS system_twin_edge (
    edge_id   TEXT PRIMARY KEY,
    from_node TEXT NOT NULL REFERENCES system_twin_node(node_id),
    to_node   TEXT NOT NULL REFERENCES system_twin_node(node_id),
    edge_type TEXT NOT NULL DEFAULT 'depends_on',
    verified  INTEGER NOT NULL DEFAULT 0
);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '3' WHERE key = 'schema_version';
