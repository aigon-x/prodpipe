# OWNERSHIP — OPERATION CONFIG ZERO

> PHASE 18 — Macierz własności dla `/opt/Prod-ready/`.
> Zasada: **każdy element ma właściciela (single-owner). Unowned critical config → max 5/10 w score modelu.**

## 1. Właściciele (13 domen)

| Właściciel | Domeny |
|------------|--------|
| `@aigon/architecture` | Architektura, SoT, config/canonical |
| `@aigon/platform` | Platforma, deployment |
| `@aigon/security` | Bezpieczeństwo, sekrety |
| `@aigon/release` | Release, wersjonowanie |
| `@aigon/apps` | Aplikacje |
| `@aigon/runtime` | Runtime |
| `@aigon/fs` | AIGON-X-FS |
| `@aigon/mesh` | Mesh |
| `@aigon/agents` | Agenci |
| `@aigon/models` | Modele |
| `@aigon/observability` | Obserwowalność |
| `@aigon/quality` | Jakość, verify |
| `@aigon/business` | Business |

## 2. Granice własności (z OWNERSHIP.md)
- **agent → canonical FORBIDDEN** — agenci nie mogą pisać do `config/canonical/` ani `governance/`.
- **business → runtime FORBIDDEN** — business nie może dotykać wewnętrznych runtime.
- **dashboard → database FORBIDDEN** — dashboard nie może pisać do bazy.
- **node config → global truth FORBIDDEN** — konfiguracja noda nie jest globalną prawdą.

## 3. Macierz własności elementów CONFIG ZERO

| Element | Właściciel | Status |
|---------|-----------|--------|
| `config/canonical/platform.yaml` | `@aigon/architecture` | ✅ OWNED |
| `config/schemas/platform.schema.json` | `@aigon/architecture` | ✅ OWNED |
| `tools/config/config-compiler.sh` | `@aigon/architecture` | ✅ OWNED |
| `config/README.md` | `@aigon/architecture` | ✅ OWNED |
| `config/canonical/README.md` | `@aigon/architecture` | ✅ OWNED |
| `config/schemas/schema.md` | `@aigon/architecture` | ✅ OWNED |
| `config/templates/template.md` | `@aigon/architecture` | ✅ OWNED |
| `config/examples/example.md` | `@aigon/architecture` | ✅ OWNED |
| `system/control-plane/state/` | `@aigon/platform` | ⚠️ UNDEFINED (README: STATUS: UNDEFINED) |
| `tools/verify/` | `@aigon/quality` | ✅ OWNED (verify engine) |
| `tools/verify/debt/scanner.sh` | `@aigon/quality` | ✅ OWNED (ale 40 HARDCODED_INVALID) |
| `.git-hooks/*` | `@aigon/quality` | ⚠️ SHADOW (nie zarejestrowane) |
| `.github/workflows/*.yml` | `@aigon/quality` | ⚠️ MOCK (placeholdery) |
| `SOURCE-OF-TRUTH.md` | `@aigon/architecture` | ✅ OWNED |
| `OWNERSHIP.md` | `@aigon/architecture` | ✅ OWNED |
| `MIGRATION.md` | `@aigon/architecture` | ✅ OWNED |

## 4. Unowned / UNDEFINED elementy

| Element | Problem |
|---------|---------|
| `system/control-plane/state/` | README ma `STATUS: UNDEFINED` — właściciel nie przypisany |
| `config/local/` | Zadeklarowany w kompilatorze, ale nieobecny — brak właściciela |
| `.git-hooks/*` | Shadow — nie zarejestrowane, brak właściciela w config |

## 5. Wnioski
- **Większość elementów CONFIG ZERO jest OWNED** — config/canonical, schemas, compiler, verify.
- **3 elementy UNDEFINED/SHADOW** — state subsystem (STATUS: UNDEFINED), config/local (nieobecny), git hooks (shadow).
- **Unowned critical config → max 5/10** w score modelu.

## 6. Rekomendacja
1. Przypisać właściciela do `system/control-plane/state/` (np. `@aigon/platform`).
2. Zarejestrować git hooks w config z właścicielem.
3. Utworzyć `config/local/` z właścicielem lub usunąć z deklaracji.
