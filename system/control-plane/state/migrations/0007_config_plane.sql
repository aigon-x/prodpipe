-- ============================================================================
-- MIGRATION 0007 — CONFIG PLANE (snapshoty, ratchet, kill-switches)
-- ============================================================================
-- Config Plane to warstwa, która pozwala systemowi konfigurować sam siebie
-- i sam to sprawdzać (self-hosting). Ta migracja tworzy fundament audytowalności
-- configu:
--
--   * config_snapshots  — materializowany effective config per run (hash + git_sha
--                         + wersja waiverów + pełny JSON). Każda decyzja configu
--                         jest REPRODUKOWALNA — wiemy dokładnie, jaki config
--                         podjął decyzję.
--   * evidence.snapshot_id — każdy wynik gate'a wskazuje DOKŁADNY snapshot
--                         configu, który podjął decyzję (brak "w połowie
--                         pipeline'u config się zmienił").
--   * config_ratchet     — anti-entropy: per serwis/klucz ostatnia osiągnięta
--                         wartość. Nowy config NIE może jej obniżyć bez waivera
--                         (system sam się dokręca).
--   * config_kill_switches — L7: awaryjne wyłączniki z pełnym audytem
--                         (kto, dlaczego, do kiedy). Nawet kill-switch WYGASA.
--
-- Zasady (z design doc):
--   * Tighten zawsze przechodzi; Relax wymaga waivera.
--   * Wyjątki wygasają (expires_at WYMAGANE).
--   * Każda decyzja ma trace (snapshot + snapshot_id w evidence).
-- ============================================================================

-- Materializowany effective config per run (reprodukowalność decyzji)
CREATE TABLE IF NOT EXISTS config_snapshots (
    id                  INTEGER PRIMARY KEY,
    hash                TEXT NOT NULL UNIQUE,   -- hash zmaterializowanego effective configu
    git_sha             TEXT NOT NULL,          -- wersja źródeł configu
    waiver_set_version  INTEGER NOT NULL,       -- wersja zbioru aktywnych waiverów
    effective_json      TEXT NOT NULL,          -- pełny effective config (JSON)
    created_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Każdy wynik gate'a wskazuje DOKŁADNY config, który podjął decyzję.
-- SQLite pozwala dodać kolumnę z REFERENCES tylko gdy domyślna wartość to NULL
-- (co jest OK — snapshot_id jest opcjonalny i wypełniany przez resolver).
ALTER TABLE evidence ADD COLUMN snapshot_id INTEGER REFERENCES config_snapshots(id);

-- Stan ratchetingu per serwis/klucz (anti-entropy: wartość może TYLKO rosnąć)
CREATE TABLE IF NOT EXISTS config_ratchet (
    service_id      TEXT NOT NULL,
    key             TEXT NOT NULL,
    achieved_value  REAL NOT NULL,              -- ostatnia osiągnięta wartość
    updated_at      TEXT NOT NULL,
    PRIMARY KEY (service_id, key)
);

-- L7: awaryjne kill-switche z pełnym audytem (nawet one wygasają)
CREATE TABLE IF NOT EXISTS config_kill_switches (
    id          INTEGER PRIMARY KEY,
    key         TEXT NOT NULL,
    value       TEXT NOT NULL,
    activated_by TEXT NOT NULL,                 -- kto aktywował (audyt)
    reason      TEXT NOT NULL,                  -- dlaczego (audyt)
    expires_at  TEXT NOT NULL,                  -- WYMAGANE — nawet kill-switch wygasa
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Zaktualizuj wersję schematu
UPDATE meta SET value = '7' WHERE key = 'schema_version';
