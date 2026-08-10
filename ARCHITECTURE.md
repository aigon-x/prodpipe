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

## 9. System Quality Gates

> **STATUS: PARTIAL** — fundament (evidence bridge + SELF-001 + fail-closed) wdrożony w tym PR; G2/G6/G7 missing, G4/G5 placeholdery. Pełna mapa w 9.2, priorytety w 9.3.

### 9.1 Zasady nadrzędne

1. **Evidence → baza (P0#1)** — każdy gate zapisuje wynik do StateStore (tabela `evidence`). Mechanizm bez evidence = 0 punktów. Risk prediction (S7) trenuje się na danych z `evidence`/`gate_runs` — każdy dzień działania gate'ów to dane treningowe.
2. **Fail-closed** — moduł zadeklarowany w profilu, a nieistniejący = **FAIL (BLOCKING)**, nigdy skip. Ghost moduł blokuje certyfikację, dopóki nie zostanie zaimplementowany (nie usunięty). Chroni przed FALSE GATE na zawsze.
3. **Wyjątki wygasają** — waiver bez `expires_at` jest nielegalny. Wyjątek to świadome, ograniczone czasowo odstępstwo, nie trwałe obejście.
4. **Metadata-driven (cel P0)** — definicje gate'ów żyją w configu/bazie, nie w kodzie pipeline'u. Pipeline generowany z definicji, nie hardcoded.
5. **Metryka pokrycia** — mechanizm liczy się jako wdrożony **wyłącznie**, gdy produkuje evidence w bazie. Placeholder/szkielet = 0 punktów. Pokrycie = (mechanizmy z evidence) / (mechanizmy zadeklarowane).

### 9.2 Mapa gate'ów infrastrukturalnych → stan

> **Numeracja:** gate'y infrastrukturalne mają identyfikatory **GATE-XXX** z
> `tools/verify/gates/registry.sh` (jedyny SoT). Numeracja **G0-G17** jest
> zarezerwowana wyłącznie dla gate'ów **jakościowych** cyklu życia
> (LIFECYCLE.md §4, po jednym na fazę F00-F17). Nie ma kolizji: G0-G17 ≠ GATE-XXX.

| Gate (registry) | Nazwa | Stan | Evidence |
|------|------|------|----------|
| GATE-018 | pre-commit / pre-push / commit-msg / signed (GIT-HOOKS) | **REALNY** (blokujący) | tak |
| GATE-017 | build / CI | **CZĘŚCIOWO** (workflow CI wywołują verify.sh gates) | częściowo |
| GATE-002 | SoT git == desired state | **REALNY** (blokujący) | tak |
| GATE-003 | canonicality (config/canonical jedyne SoT) | **REALNY** | tak |
| GATE-004 | configuration (każdy element ma źródło konfiguracji) | **REALNY** | tak |
| GATE-005 | security (brak hardcoded sekretów) | **REALNY** | tak |
| GATE-021 | anti-entropy / system-twin (SYSTEM-TWIN) | **REALNY** | tak |
| GATE-025 | anti-drift / effective-config | **REALNY** | tak |
| GATE-026 | behavioral-drift | **PROPOSED** (brak implementacji) | nie |
| GATE-006..016 | structure/architecture/deps/reproducibility/deployment/contracts/migration/recovery/testing/performance/documentation | **REALNY** | tak |
| GATE-019 | state (StateStore spójny, schema_version zgodna) | **REALNY** | tak |
| GATE-020 | evidence (każdy gate ma evidence) | **REALNY** | tak |
| GATE-040 | lifecycle (LIFECYCLE PLANE) | **REALNY** | tak |
| META SELF-001 | registry==implemented==wired==executed | **REALNY** (od tego PR) | tak |
| META VERIFY-EVIDENCE-COMPLETE | każdy gate ma evidence | **REALNY** (od tego PR) | tak |

> **Uwaga:** G2 build, G4 SBOM/SLSA, G6 anti-shadow z dawnej mapy G0-G8 nie mają
> bezpośredniego odpowiednika GATE-XXX — są pokryte przez GATE-017 (CI) i
> GATE-026 (behavioral-drift, PROPOSED). SBOM/SLSA i anti-shadow pozostają
> otwartymi pozycjami (patrz 9.3).

### 9.3 Priorytety (Definition of Done)

- **P0** — evidence bridge (DONE w tym PR) → metadata-driven pipeline → build (GATE-017).
- **P1** — `gate_runs`/`waivers` + waiver sweeper → SBOM/SLSA → anti-drift (GATE-025/026).
- **P2** — anti-shadow → ożywienie `debt` (INSERT INTO debt) → docs gate.
- **P3** — start wyłącznie po P0, wymaga ADR-0001; wejście danych = historia `evidence`/`gate_runs` od P0.

### 9.4 Kontrakt modułu verify

Każdy moduł `tools/verify/<kategoria>/<nazwa>.sh` MUSI:

1. **Istnieć** — moduł zadeklarowany w `VERIFY_MODULES` (profiles.sh) bez skryptu = FAIL (SELF-001).
2. **Być wykonywalny** — brak bitu `x` = WARN (moduły uruchamiane przez `bash`, ale brak `x` to sygnał, że plik nie był przygotowany jako gate).
3. **Zapisywać evidence** — każdy uruchomiony gate kończy się `evidence_record` do StateStore. Moduł bez evidence = 0 punktów (VERIFY-EVIDENCE-COMPLETE).

## 10. Granice architektury (CI odrzuca)

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

## 11. Klasyfikacja danych

**SYSTEM / TENANT / USER / SESSION / CACHE / TEMPORARY**

Runtime data żyje w AIGON-X-FS, nie w gicie.

## 12. Status

**STATUS: UNDEFINED** — ramy architektoniczne zdefiniowane; implementacja w fazie genesis.
