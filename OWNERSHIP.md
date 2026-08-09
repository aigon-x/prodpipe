# OWNERSHIP — AIGON Production Platform

> Macierz własności domen. Każda domena ma **dokładnie jednego** właściciela (single-owner Source of Truth).
> **STATUS: UNDEFINED** — właściciele zespołów nie są jeszcze przypisani; poniżej struktura domen z CODEOWNERS.

## Zasada

- Każda domena ma **jednego** właściciela.
- **No second SoT / registry / memory** — jedna domena = jedno źródło prawdy.
- Zmiany w domenie wymagają zgody właściciela (CODEOWNERS).

## Macierz własności

| Domena | Ścieżka | Właściciel (CODEOWNERS) | SoT |
|---|---|---|---|
| Architektura | `/`, `ARCHITECTURE.md`, `OWNERSHIP.md`, `SOURCE-OF-TRUTH.md`, `README.md`, `CONTRIBUTING.md`, `CODEOWNERS`, `.gitignore`, `.gitattributes`, `LICENSE` | `@aigon/architecture` | Git |
| Platforma | `DEPLOYMENT.md`, `RECOVERY.md`, `MIGRATION.md`, `.github/`, `.git-hooks/`, `config/`, `data/`, `deployment/`, `operations/`, `tools/`, `archive/` | `@aigon/platform` | Git |
| Bezpieczeństwo | `SECURITY.md`, `security/`, `secrets/` | `@aigon/security` | Git |
| Release | `VERSION`, `artifacts/` | `@aigon/release` | Git |
| Aplikacje | `apps/` | `@aigon/apps` | Git |
| Runtime | `system/` | `@aigon/runtime` | Git |
| Filesystem | `filesystem/` | `@aigon/fs` | Git |
| Mesh | `mesh/` | `@aigon/mesh` | Git |
| Agenci | `agents/` | `@aigon/agents` | Git |
| Modele | `models/` | `@aigon/models` | Git |
| Architektura (shared) | `shared/`, `contracts/`, `governance/`, `docs/` | `@aigon/architecture` | Git |
| Obserwowalność | `observability/` | `@aigon/observability` | Git |
| Jakość | `tests/` | `@aigon/quality` | Git |
| Biznes | `business/` | `@aigon/business` | Git |

## Granice własności

- **agent → canonical state / governance**: ZABRONIONE (agent nie mutuje canonical state ani governance).
- **business → runtime internals / aigon-x-fs internals**: ZABRONIONE (business konsumuje platformę przez Public Platform Contract).
- **dashboard → database internals**: ZABRONIONE.
- **node config → global truth**: ZABRONIONE (node config nie nadpisuje globalnej prawdy).

## Status

**STATUS: UNDEFINED** — struktura domen zdefiniowana; przypisanie konkretnych osób/zespołów do `@aigon/*` w toku.
