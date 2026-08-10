# SCHEMAS — OPERATION CONFIG ZERO

> PHASE 19 — Schematy konfiguracji w `/opt/Prod-ready/`.
> Zasada: **każda konfiguracja kanoniczna ma JSON Schema walidującą.**

## 1. Schematy w repo

| Schema | Plik | Waliduje | Status |
|--------|------|----------|--------|
| Platform schema | `config/schemas/platform.schema.json` | `config/canonical/platform.yaml` | ✅ CANONICAL |
| State schema | `system/control-plane/state/schema.sql` | SQLite canonical state | ✅ CANONICAL |
| Schema doc | `config/schemas/schema.md` | Dokumentacja schematów | ✅ CANONICAL |

## 2. Platform JSON Schema (`platform.schema.json`)

- **Format:** JSON Schema draft-07.
- **Wymagane pola:** `schema_version`, `config_id`, `status`, `platform`.
- **Walidacja:** `tools/config/config-compiler.sh validate` (jsonschema, gdy dostępny).

### Struktura `platform.yaml` (walidowana przez schema):
```yaml
schema_version: "1.0.0"
config_id: "aigon-platform-canonical"
status: CANONICAL
platform:
  identity: {...}
  pipeline: {...}
  override_hierarchy: {...}
  classification: {...}
  state_subsystem: {...}
  verify_engine: {...}
  deployment_rings: {...}
  git_model: {...}
  readme_contract: {...}
  ownership: {...}
  sync_classes: {...}
  secrets_policy: {...}
```

## 3. State schema (`schema.sql`)

- **Format:** SQL (SQLite).
- **Wersja:** 2 (migracja 0001_initial.sql + 0002_history_hash.sql).
- **Tabele:** 25 (meta, cluster, node, runtime, service, deployment, configuration, policy, contract, decision, drift, event, evidence, image, network, port, project, skill, capability, artifact, baseline, debt, document, agent, ...).
- **Kluczowa tabela `configuration`:** `config_id, domain, key, value, desired, effective, observed, status, owner, source_type, source_ref, source_hash, observed_at, recorded_at, generation, UNIQUE(domain,key)`.
- **Zasada:** schema jest migracyjna — każda zmiana to nowy plik w `migrations/`. NIGDY ręcznych zmian.

## 4. Walidacja

### 4.1 Kompilator (`config-compiler.sh validate`)
- Sprawdza: schema istnieje, YAML jest poprawny, JSON Schema (gdy jsonschema dostępny), brak sekretów, brak hardcoded IP.
- Wynik: `validate PASS` (0 FAIL, 1 WARN gdy jsonschema niedostępny).

### 4.2 State (`state.sh verify`)
- Weryfikuje integralność bazy SQLite, schema version, state hash.

## 5. Wnioski
- **Platform schema** — zdefiniowana i walidująca `platform.yaml`.
- **State schema** — zdefiniowana (25 tabel, schema v2).
- **Walidacja działa** — kompilator + state verify.

## 6. Rekomendacja
1. Dodać JSON Schema dla `config/canonical/legacy.yaml` (gdy powstanie).
2. Podłączyć walidację schema do CI (wypełnić mock).
