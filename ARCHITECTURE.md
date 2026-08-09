# ARCHITECTURE — AIGON Production Platform

> **STATUS: UNDEFINED** — architektura w fazie genesis. Ten dokument definiuje ramy i zasady; szczegóły implementacyjne są `STATUS: UNDEFINED` dopóki nie zostaną zbudowane.

## 1. Zasada nadrzędna: Git = desired, Runtime = actual

- **Git** = kod, kontrakty, schematy, konfiguracja deklaratywna, deployment, testy, polityki-as-code, dokumentacja, manifesty, artefakty źródłowe.
- **Runtime** = stan faktyczny, discovery, topologia, health, tick, rejestry, evidence, capability, tożsamość nodów, stan deploymentu.
- **Reconciliation**: Git (desired) VS Runtime (actual) → **PASS / DRIFT**.

Git nie jest drugim SoT. Runtime nie jest miejscem na kod.

## 2. Warstwy

```
┌─────────────────────────────────────────────┐
│  business/   (warstwa biznesowa)            │
│  konsumuje platformę przez Public Contract  │
├─────────────────────────────────────────────┤
│  apps/       (aplikacje)                    │
├─────────────────────────────────────────────┤
│  agents/     (definicje agentów)            │
│  models/     (modele)                       │
├─────────────────────────────────────────────┤
│  system/     (runtime, router, gateway, ...)│
│  mesh/       (warstwa mesh)                 │
├─────────────────────────────────────────────┤
│  filesystem/aigon-x-fs/  (RUNTIME DATA)     │
└─────────────────────────────────────────────┘
```

## 3. Source of Truth — single-owner

Każda domena ma **dokładnie jednego** właściciela i **jedno** źródło prawdy. Zasada: **no second SoT / registry / memory**. Zobacz [SOURCE-OF-TRUTH.md](SOURCE-OF-TRUTH.md) i [OWNERSHIP.md](OWNERSHIP.md).

## 4. Agent fingerprint (AgentFingerprint)

Agent jest definiowany przez swój fingerprint, nie przez hardcoded config:

- Runtime ABI
- Agent ABI
- Ontology
- Genome
- PolicyPack
- SkillPack
- MemorySchema
- PromptPack
- ToolPack
- ConfigSchema

## 5. Model konfiguracji

- **CANONICAL** — jedyne źródło prawdy dla konfiguracji (w `config/canonical/`)
- **GENERATED** — pochodna, generowana z canonical (w `config/generated/`)
- **LOCAL** — specyficzna dla maszyny, NIGDY nie commitowana (w `config/local/`)

Brak ręcznych `node01.env` itp.

## 6. Deployment

- **RING 0-3** — pierścienie wdrożeniowe
- **Immutable image digests** — brak `:latest` w produkcji
- **Compose profiles** — profile wdrożeniowe

## 7. Synchronizacja

Klasy synchronizacji: **CANONICAL / REPLICATED / GENERATED / CACHE / SESSION / EPHEMERAL**.

`shared/` = kanoniczna materializacja + replikacja + płaszczyzna sync. **NIE jest drugim SoT.**

## 8. Health / Evidence

- **HealthEvidence** — dowód zdrowia komponentu
- **ClusterHealth** — zdrowie klastra
- **One-tick health contract**
- **Canonicality matrix**, **sync matrix**, **drift catalog**, **reconciliation engine**

## 9. Granice architektury (CI odrzuca)

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

## 10. Klasyfikacja danych

**SYSTEM / TENANT / USER / SESSION / CACHE / TEMPORARY**

Runtime data żyje w AIGON-X-FS, nie w gicie.

## 11. Status

**STATUS: UNDEFINED** — ramy architektoniczne zdefiniowane; implementacja w fazie genesis.
