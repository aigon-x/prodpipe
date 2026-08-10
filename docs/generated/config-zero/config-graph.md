# CONFIG GRAPH — OPERATION CONFIG ZERO

> PHASE 30 — Graf zależności konfiguracji w `/opt/Prod-ready/`.
> Maszynowo-czytelny graf: `docs/generated/config-zero/config-graph.json`.

## 1. Cel
Przedstawić graf zależności konfiguracji — które elementy są źródłem (CANONICAL), które są wyprowadzane (GENERATED), które są narzędziami (TOOL), a które są problematyczne (MOCK/SHADOW/HARDCODED_INVALID).

## 2. Węzły grafu

### 2.1 CANONICAL (źródła prawdy)
| Węzeł | Właściciel | Konsumenci |
|-------|-----------|------------|
| `config/canonical/platform.yaml` | @aigon/architecture | kompilator, schema |
| `config/schemas/platform.schema.json` | @aigon/architecture | waliduje platform.yaml |
| `system/control-plane/state/schema.sql` | @aigon/platform | state.sh |
| `system/control-plane/state/migrations/*.sql` | @aigon/platform | state.sh |

### 2.2 TOOL (narzędzia)
| Węzeł | Właściciel | Czyta | Pisze |
|-------|-----------|-------|-------|
| `tools/config/config-compiler.sh` | @aigon/architecture | platform.yaml, schema | generated/* |
| `system/control-plane/state/state.sh` | @aigon/platform | schema.sql, migrations | state.db |
| `tools/verify/verify.sh` | @aigon/quality | moduły verify | — |

### 2.3 GENERATED (wyprowadzane)
| Węzeł | Źródło |
|-------|--------|
| `config/generated/platform.generated.yaml` | platform.yaml |
| `config/generated/MANIFEST.generated.txt` | platform.yaml |
| `system/control-plane/state/data/canonical-state.db` | schema.sql + migrations |

### 2.4 Problematyczne (MOCK/SHADOW/HARDCODED_INVALID)
| Węzeł | Typ | Problem |
|-------|-----|---------|
| `tools/verify/debt/scanner.sh` | HARDCODED_INVALID | 40 legacy wartości |
| `.git-hooks/validate-sot` | SHADOW | nie zarejestrowany |
| `.git-hooks/pre-commit` | SHADOW | nie podłączony |
| `.git-hooks/pre-push` | SHADOW | nie podłączony |
| `.github/workflows/drift.yml` | MOCK | placeholder |
| `.github/workflows/helios.yml` | MOCK | placeholder |
| `.github/workflows/release.yml` | MOCK | placeholder |
| `.github/workflows/security.yml` | MOCK | placeholder |
| `config/local/` | SHADOW | nieobecny |

## 3. Krawędzie grafu
- `platform.yaml → schema` (validated_by)
- `platform.yaml → kompilator` (read_by)
- `kompilator → generated/*` (generates)
- `schema.sql → state.sh` (read_by)
- `state.sh → state.db` (generates)
- `verify.sh → scanner.sh` (runs)
- `verify.sh → kompilator` (runs, config subcommand)

## 4. Wektory driftu (z config-graph.json)
10 wektorów — 5 wykrywalnych (V1-V4, V9), 5 niewykrywalnych (V5-V8, V10).

## 5. Wnioski
- **Graf jest zdefiniowany** — maszynowo-czytelny (JSON) + dokumentacja (MD).
- **Fundacja jest spójna** — CANONICAL → TOOL → GENERATED.
- **Problematyczne węzły** — 4 MOCK, 4 SHADOW, 1 HARDCODED_INVALID.

## 6. Rekomendacja
1. Podłączyć config-graph.json do CI (walidacja spójności grafu).
2. Przenieść legacy do config/canonical/legacy.yaml.
