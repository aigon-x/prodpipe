# AIGON Production Platform

> Kanoniczny workspace produkcyjny dla całego ekosystemu AIGON.
> **STATUS: UNDEFINED** — repozytorium w fazie genesis (PHASE 0-10 OPERATION FOUNDATION). Żaden komponent nie jest jeszcze zaimplementowany.

## Zasada nadrzędna

**Git = desired state. Runtime = actual state.**

- **Git** mówi, co zbudowaliśmy: kod, kontrakty, schematy, konfiguracja deklaratywna, deployment, testy, polityki-as-code, dokumentacja, manifesty, artefakty źródłowe.
- **Runtime** mówi, co naprawdę istnieje: stan faktyczny, discovery, topologia, health, tick, rejestry, evidence, capability, tożsamość nodów, stan deploymentu.
- **Reconciliation**: Git (desired) VS Runtime (actual) → **PASS / DRIFT**.

Git **NIE jest** drugim Source of Truth. Runtime **NIE jest** miejscem, gdzie leży kod.

## Struktura repozytorium

| Katalog | Rola |
|---|---|
| `apps/` | Aplikacje (console, landing, portal, agent, dashboard, api, worker, cli) |
| `system/` | Komponenty systemowe (runtime, router, gateway, registry, identity, events, ...) |
| `filesystem/aigon-x-fs/` | Warstwa przechowywania (RUNTIME DATA — nie git) |
| `mesh/` | Warstwa mesh (control, data, transport, discovery, topology, ...) |
| `agents/` | Definicje agentów (runtime, abi, ontology, genome, policy, skills, ...) |
| `models/` | Modele (registry, catalog, weights, adapters, benchmarks, ...) |
| `shared/` | Kanoniczna materializacja + replikacja + płaszczyzna sync (NIE drugi SoT) |
| `config/` | Konfiguracja (canonical / generated / local) |
| `contracts/` | Kontrakty (runtime-abi, agent-abi, capability, mesh, filesystem, evidence, api, events) |
| `data/` | Klasyfikacja danych (system / tenant / user / session / cache / temporary) |
| `deployment/` | Deployment (rings, profiles, images, manifests, helm, terraform, ...) |
| `observability/` | Obserwowalność (metrics, logs, traces, dashboards, alerts, health, audit) |
| `operations/` | Operacje (runbooks, playbooks, scripts, incidents, oncall, ...) |
| `tests/` | Testy (unit, integration, regression, e2e, contract, performance, security, chaos) |
| `governance/` | Zarządzanie (policies, standards, approvals, audit, decisions, ownership, compliance) |
| `business/` | Warstwa biznesowa (contracts, tenants, users, billing, reporting, analytics, notifications) |
| `security/` | Bezpieczeństwo (policies, scanning, audit, incidents, keys, rotation, threat-model) |
| `secrets/` | Sekrety — TYLKO schematy/templates/referencje (NIGDY wartości) |
| `docs/` | Dokumentacja (architecture, operations, development, user, security, reference, decisions) |
| `tools/` | Narzędzia (scripts, utilities, ci, automation, migration, validation) |
| `artifacts/` | Artefakty (manifests, digests, evidence, reports, backups) |
| `archive/` | Archiwum (2026, 2025, legacy, quarantine) |

## Cztery drzewa git

1. **Source** — `system/`, `filesystem/`, `mesh/`, `agents/`, `models/`, `apps/`, `business/`
2. **Configuration** — `config/`
3. **Deployment** — `deployment/`
4. **Evidence/artifact** — `artifacts/`

## Model gałęzi

- `main` — chroniona, jedyna gałąź bazowa (bez `develop`)
- `feature/*`, `fix/*`, `migration/*`, `security/*`, `release/*`

**Łańcuch merge**: PR → Build → Unit → Integration → Regression → SOT → Drift → Feature → Three Witnesses → HELIOS → BASELINE → MERGE

## Granice architektury (CI odrzuca)

- agent → canonical state
- agent → governance mutation
- business → runtime internals
- business → aigon-x-fs internals
- dashboard → database internals
- node config → global truth
- hardcoded IP / hostname / node count / kernel count
- duplicate registry / SoT
- secret w repo
- `:latest` image
- unowned crate / config

## Git vs AIGON-X-FS — ostra granica

| Git | AIGON-X-FS |
|---|---|
| SOURCE / CONTRACTS / DECLARATIONS / SCHEMAS / DEPLOYMENT / POLICIES / TESTS | RUNTIME DATA / KNOWLEDGE / MEMORY / ARTIFACTS / EVENTS / EVIDENCE / USER DATA / TENANT DATA / SNAPSHOTS |

Nie wkładaj runtime state do gita. Nie rób z AIGON-X-FS drugiego repo.

## Dokumentacja

- [ARCHITECTURE.md](ARCHITECTURE.md) — architektura
- [OWNERSHIP.md](OWNERSHIP.md) — własność domen
- [SOURCE-OF-TRUTH.md](SOURCE-OF-TRUTH.md) — źródła prawdy
- [DEPLOYMENT.md](DEPLOYMENT.md) — deployment
- [SECURITY.md](SECURITY.md) — bezpieczeństwo
- [RECOVERY.md](RECOVERY.md) — odzyskiwanie
- [MIGRATION.md](MIGRATION.md) — migracja
- [CONTRIBUTING.md](CONTRIBUTING.md) — jak współtworzyć

## Status

**STATUS: UNDEFINED** — repozytorium w fazie genesis. Zobacz `docs/decisions/` i `governance/decisions/` dla historii decyzji.
