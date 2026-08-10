# SOURCE OF TRUTH — OPERATION CONFIG ZERO

> PHASE 18 — Definicja Source of Truth (SoT) dla `/opt/Prod-ready/`.
> Zasada: **Git = desired state, Runtime = actual state. `config/canonical/` = jedyny SoT dla konfiguracji kanonicznej.**

## 1. Definicja SoT

| Warstwa | SoT | Opis |
|---------|-----|------|
| **Desired state** | Git (repo) | Pożądany stan platformy — konfiguracja deklaratywna |
| **Canonical config** | `config/canonical/` | Jedyny SoT dla konfiguracji kanonicznej |
| **Canonical operational state** | SQLite (`state/data/canonical-state.db`) | Stan operacyjny (desired/effective/observed) |
| **Actual state** | Runtime | Faktyczny stan w runtime (przyszłość: AIGON-X-FS) |

## 2. Single-owner principle
Każda domena ma **dokładnie jednego właściciela** (bez drugiego SoT/registry/memory). Zasada wymuszana przez `validate-sot` (CI) i `OWNERSHIP.md`.

## 3. Klasy synchronizacji

| Klasa | Opis | Przykład |
|-------|------|----------|
| `CANONICAL` | Jedyny SoT — synchronizowane z Git | `config/canonical/platform.yaml` |
| `REPLICATED` | Kopie kanonicznej (dozwolone, ale nie SoT) | — |
| `GENERATED` | Deterministycznie wyprowadzane z kanonicznej | `config/generated/platform.generated.yaml` |
| `CACHE` | Pamięć podręczna (odtwarzalna) | — |
| `SESSION` | Stan sesji (efemeryczny) | — |
| `EPHEMERAL` | Efemeryczny (nie trwały) | — |

## 4. Hierarchia override
```
DEFAULT → PROFILE → CANONICAL → ENVIRONMENT → NODE → LOCAL → RUNTIME OVERRIDE
```
Każdy poziom nadpisuje poprzedni. `CANONICAL` jest źródłem prawdy; `LOCAL` i `RUNTIME OVERRIDE` są efemeryczne (nie commitowane).

## 5. Pipeline konfiguracji
```
CANONICAL → VALIDATED → NORMALIZED → EFFECTIVE → GENERATED → OBSERVED
```
- **CANONICAL** — `config/canonical/platform.yaml` (jedyny SoT).
- **VALIDATED** — JSON Schema (`config/schemas/platform.schema.json`).
- **NORMALIZED** — posortowany, bez komentarzy (deterministyczny).
- **EFFECTIVE** — zastosowana konfiguracja.
- **GENERATED** — `config/generated/platform.generated.yaml` (artefakt).
- **OBSERVED** — zaobserwowana w runtime.

## 6. Granice SoT (z OWNERSHIP.md)
- **agent → canonical FORBIDDEN** — agenci nie mogą pisać do `config/canonical/` ani `governance/`.
- **business → runtime FORBIDDEN** — business nie może dotykać wewnętrznych runtime.
- **dashboard → database FORBIDDEN** — dashboard nie może pisać do bazy.
- **node config → global truth FORBIDDEN** — konfiguracja noda nie jest globalną prawdą.

## 7. Właściciele (13)
`@aigon/architecture`, `@aigon/platform`, `@aigon/security`, `@aigon/release`, `@aigon/apps`, `@aigon/runtime`, `@aigon/fs`, `@aigon/mesh`, `@aigon/agents`, `@aigon/models`, `@aigon/observability`, `@aigon/quality`, `@aigon/business`.

## 8. Weryfikacja SoT
- `tools/verify/reconcile` — 4-warstwowy model (CANON/DRIFT/HISTORY/DEBT).
- `tools/config/config-compiler.sh validate` — walidacja kanonicznej (schema, brak sekretów, brak hardcoded IP).
- `validate-sot` (CI) — single-owner, brak duplikatów, brak sekretów, brak latest image.

## 9. Status SoT w repo

| Element | Status | Uwagi |
|---------|--------|-------|
| `config/canonical/platform.yaml` | ✅ CANONICAL | Jedyny SoT konfiguracji kanonicznej |
| `config/schemas/platform.schema.json` | ✅ CANONICAL | Schema walidująca |
| `config/generated/` | ✅ GENERATED | Artefakty kompilatora (gitignored) |
| `state/data/canonical-state.db` | ✅ GENERATED | Baza SQLite (gitignored) |
| `tools/verify/debt/scanner.sh` | ⚠️ HARDCODED_INVALID | 40 legacy wartości w skrypcie (nie w config) |
| `.git-hooks/*` | ⚠️ SHADOW | Nie zarejestrowane w config |
| `tools/verify/git|security|structure/*` | ⚠️ GHOST | Nie wykonywane przez verify.sh |

## 10. Wnioski
- **SoT jest zdefiniowany** — `config/canonical/` = jedyny SoT konfiguracji kanonicznej.
- **Kompilator działa** — deterministyczny fingerprint, walidacja, generacja.
- **State subsystem działa** — SQLite, schema v2, state hash.
- **Luki:** 40 legacy wartości w skrypcie (nie w config), shadow hooks, ghost modules, CI mock drift.

## 11. Rekomendacja
1. Przenieść 40 legacy wartości z `scanner.sh` do `config/canonical/legacy.yaml`.
2. Zarejestrować git hooks w config.
3. Podłączyć ghost modules do verify.sh.
4. Wypełnić CI drift mock.
