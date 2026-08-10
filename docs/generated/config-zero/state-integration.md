# STATE INTEGRATION — OPERATION CONFIG ZERO

> PHASE 22 — Integracja stanu (state subsystem) w `/opt/Prod-ready/`.
> Model: **Git = desired state, SQLite = canonical operational state, Runtime = actual state.**

## 1. State subsystem

**Lokalizacja:** `system/control-plane/state/`
**Status:** ✅ LIVE (działa, schema v2, 25 tabel)

## 2. Komponenty

| Komponent | Opis |
|-----------|------|
| `schema.sql` | Canonical schema (migracyjna, wersjonowana) |
| `migrations/0001_initial.sql` | Migracja 1 (schema v1) |
| `migrations/0002_history_hash.sql` | Migracja 2 (schema v2) |
| `state.sh` | StateStore CLI (init/migrate/generation/hash/snapshot/verify/status/backup/restore/rollback) |
| `lib.sh` | Współdzielone funkcje StateStore |
| `tests/` | Testy PHASE B11 |
| `data/canonical-state.db` | Baza SQLite (GENERATED, gitignored) |

## 3. Stan bazy

```
Database ID:    aigon-canonical-state
Schema version: 2
Generation:     0
State hash:     c2129bd3d6064514f7ff89b93a5ca3df974735d5a5c61c122037433f737b5c96
```

## 4. Kluczowa tabela `configuration`

```sql
CREATE TABLE IF NOT EXISTS configuration (
    config_id       TEXT PRIMARY KEY,
    domain          TEXT NOT NULL,
    key             TEXT NOT NULL,
    value           TEXT,
    desired         TEXT,   -- DESIRED (z Git / canonical)
    effective       TEXT,   -- EFFECTIVE (zastosowana)
    observed        TEXT,   -- OBSERVED (zaobserwowana w Runtime)
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
```

## 5. Integracja z CONFIG ZERO
- **Desired/Effective/Observed** — trzy poziomy dla konfiguracji (zgodne z modelem CONFIG ZERO).
- **Provenance** — `source_type/source_ref/source_hash` (skąd pochodzi wartość).
- **Generation** — rośnie przy każdej zmianie canonical state.
- **UNKNOWN nigdy nie jest PASS** — zgodne z modelem CONFIG ZERO.

## 6. Testy state subsystem
- `state.sh init` — tworzy bazę.
- `state.sh migrate` — stosuje migracje (schema v2).
- `state.sh generation` — pokazuje generację (0).
- `state.sh hash` — pokazuje state hash.
- `state.sh verify` — weryfikuje integralność.
- `state.sh status` — podsumowanie (25 tabel, 0 wierszy).
- `state.sh rollback-test` — REAL rollback test.
- `state.sh backup-restore-test` — REAL backup->restore->verify test.

## 7. Wnioski
- **State subsystem jest LIVE** — SQLite, schema v2, 25 tabel, state hash.
- **Model Desired/Effective/Observed** jest zaimplementowany w tabeli `configuration`.
- **Provenance i generation** są śledzone.

## 8. Rekomendacja
1. Przypisać właściciela do state subsystem (README ma STATUS: UNDEFINED).
2. Podłączyć state do kompilatora (zapisywać fingerprint w tabeli configuration).
