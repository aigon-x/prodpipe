# FOUNDATION SEPARATION — Macierz Klasyfikacji

> **Faza:** B — UNIVERSALITY CERTIFICATION (przygotowanie)
> **Data:** 2026-08-10
> **Status:** **MACIERZ KLASYFIKACJI** — kompletna, oparta na dowodach
> **Decyzja Suwerena:** Opcja 1 — FOUNDATION SEPARATION. STOP wszelkich napraw i rozszerzeń do czasu kompletnej macierzy.
> **Zasada:** Najpierw mapa. Potem cięcie. UNKNOWN ≠ DELETE.

---

## 1. Cel

Zbudować pełną macierz klasyfikacji całego `/opt/Prod-ready`, żeby świadomie oddzielić **fundament** (uniwersalna fabryka) od **projektu AIGON** (konkretna platforma). To jest warunek wstępny dla GAP #1 (neutralny template) — nie można wyciąć AIGON-specific rzeczy, dopóki nie wiemy, co jest naprawdę fundamentem.

**Zgodnie z decyzją Suwerena: NIE naprawiam niczego. To jest mapa, nie cięcie.**

---

## 2. Metodologia

Klasyfikacja oparta na **dowodach** (nie na zgadywaniu):
- **Inventory:** pełna struktura katalogów i plików (3034 pliki, 1293 katalogi, bez `.git`).
- **AIGON detection:** `grep -ril "aigon"` per katalog + analiza kontekstu (nagłówek vs realna zależność).
- **Real vs placeholder:** rozróżnienie realnych plików od `.gitkeep` + README (ghost moduły).
- **Kategorie:** FOUNDATION / AIGON / OPTIONAL / EXPERIMENTAL / LEGACY / UNKNOWN.

**Kluczowe rozróżnienie:** "aigon" w nagłówku (linia 3: "AIGON Production Platform — Repository Certification Engine") to **kosmetyka** — nie czyni pliku AIGON-specific. "aigon" jako realna zależność (porty, nazwy usług, topologia) to **AIGON-specific**.

---

## 3. Podsumowanie ilościowe

| Kategoria | Katalogi | Pliki | Uwagi |
|-----------|----------|-------|-------|
| **FOUNDATION** | ~10 | ~150 | verify, config, scaffold, contracts (część), docs/00-foundation, docs/git, artifacts, StateStore |
| **AIGON** | ~14 | ~250 | agents, mesh, models, system (część), filesystem, business, apps, shared, deployment, operations, observability, security, governance |
| **OPTIONAL** | ~8 | ~80 | tests, data, secrets, config (część), docs (część) |
| **EXPERIMENTAL** | ~2 | ~10 | docs/audit, docs/generated |
| **LEGACY** | ~3 | ~10 | archive/legacy, archive/2025, archive/2026 |
| **UNKNOWN** | ~5 | ~20 | system/* (puste), tools/* (puste), deployment/* (puste) |

**Uwaga:** liczby są szacunkowe (per katalog top-level). Dokładne liczby per plik w sekcji 5.

---

## 4. Macierz klasyfikacji (per katalog top-level)

| Element | Klasa | Owner | SoT | Consumers | Dependencies | Destination | Evidence | Decyzja |
|---------|-------|-------|-----|-----------|--------------|------------|----------|---------|
| `tools/verify/` | **FOUNDATION** | Verify | `tools/verify/verify.sh` | wszystkie projekty | config/canonical, StateStore | `foundation/verify/` | 42 pliki z "aigon" = nagłówek (kosmetyka) | **KEEP** (przenieść do foundation) |
| `tools/scaffold/` | **FOUNDATION** | Scaffold | `tools/scaffold/scaffold.sh` | wszystkie projekty | template, manifest | `foundation/scaffold/` | nagłówek "AIGON" (kosmetyka) | **KEEP** (przenieść do foundation) |
| `tools/repository-integrity.sh` | **FOUNDATION** | Verify | plik | wszystkie projekty | git | `foundation/verify/` | nagłówek "AIGON" | **KEEP** |
| `tools/security/secret-scan.sh` | **FOUNDATION** | Security | plik | wszystkie projekty | git | `foundation/security/` | nagłówek "AIGON" | **KEEP** |
| `tools/automation/` `ci/` `migration/` `scripts/` `utilities/` `validation/` | **UNKNOWN** | — | README | — | — | — | puste (`.gitkeep`+README) | **UNKNOWN** (decyzja) |
| `config/canonical/` | **FOUNDATION** | Config | `registry.yaml` `gates.yaml` `taxonomy.yaml` | verify, wszystkie projekty | — | `foundation/config/` | CZYSTE (tylko schema.md ma "aigon") | **KEEP** |
| `config/aesthetics/` | **FOUNDATION** | Aesthetics | `golden-path.yaml` `spectral-rules.yaml` | verify/aesthetics | — | `foundation/config/` | CZYSTE | **KEEP** |
| `config/schemas/` | **FOUNDATION** | Config | `registry.schema.json` | verify/config | — | `foundation/config/` | CZYSTE | **KEEP** |
| `config/examples/` `generated/` `local/` `templates/` | **OPTIONAL** | Config | README | — | — | `foundation/config/` | puste (`.gitkeep`+README) | **OPTIONAL** |
| `contracts/scaffold/` | **FOUNDATION** | Scaffold | `contract.md` | scaffold | — | `foundation/contracts/` | CZYSTE | **KEEP** |
| `contracts/evidence/` | **FOUNDATION** | Evidence | `contract.md` `*.schema.md` | verify | — | `foundation/contracts/` | 2 pliki z "aigon" (schematy) | **KEEP** |
| `contracts/security/` | **FOUNDATION** | Security | `contract.md` | verify/security | — | `foundation/contracts/` | CZYSTE | **KEEP** |
| `contracts/agent-abi/` `api/` `capability/` `events/` `filesystem/` `identity/` `mesh/` `runtime-abi/` | **AIGON** | AIGON | `contract.md` | platforma AIGON | — | `aigon/contracts/` | AIGON-specific (agent ABI, mesh, runtime) | **MOVE** |
| `docs/00-foundation/` | **FOUNDATION** | Docs | `SOURCE-OF-TRUTH.md` `DOCUMENTATION-CONSTITUTION.md` | wszystkie projekty | — | `foundation/docs/` | CZYSTE | **KEEP** |
| `docs/git/` | **FOUNDATION** | Git | `BRANCH-POLICY.md` `COMMIT-POLICY.md` | wszystkie projekty | — | `foundation/docs/` | CZYSTE | **KEEP** |
| `docs/architecture/` | **FOUNDATION** | Architecture | `config-plane-design.md` `human-plane-design.md` | wszystkie projekty | — | `foundation/docs/` | CZYSTE | **KEEP** |
| `docs/audit/` | **EXPERIMENTAL** | Audit | `audyt-v1.md` | — | — | `foundation/docs/` | AIGON refs | **EXPERIMENTAL** |
| `docs/generated/` | **EXPERIMENTAL** | — | `canonical-state.md` | — | — | — | AIGON refs | **EXPERIMENTAL** |
| `docs/decisions/` `development/` `operations/` `reference/` `security/` `user/` | **OPTIONAL** | — | README | — | — | — | puste (README) | **OPTIONAL** |
| `system/control-plane/state/` | **FOUNDATION** | State | `lib.sh` `schema.sql` `state.sh` | verify, wszystkie projekty | SQLite | `foundation/state/` | nagłówek "AIGON" (kosmetyka) | **KEEP** (przenieść z system/) |
| `system/chaos/` `control-plane/` `data-plane/` `events/` `gateway/` `health/` `identity/` `observability/` `registry/` `router/` `runtime/` `scheduler/` `security/` `self-heal/` `telemetry/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/system/` | puste (`.gitkeep`+README) | **MOVE** (ghost moduły) |
| `agents/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/agents/` | puste (0 realnych plików) | **MOVE** |
| `mesh/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/mesh/` | puste (0 realnych plików) | **MOVE** |
| `models/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/models/` | puste (0 realnych plików) | **MOVE** |
| `filesystem/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/filesystem/` | puste (0 realnych plików) | **MOVE** |
| `business/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/business/` | puste (0 realnych plików) | **MOVE** |
| `apps/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/apps/` | puste (0 realnych plików) | **MOVE** |
| `operations/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/operations/` | puste (0 realnych plików) | **MOVE** |
| `security/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/security/` | puste (0 realnych plików) | **MOVE** |
| `shared/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/shared/` | 5 realnych plików (sync) | **MOVE** (sync → foundation?) |
| `observability/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/observability/` | 1 realny plik (health.schema) | **MOVE** |
| `governance/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/governance/` | 1 realny plik (ADR) | **MOVE** |
| `deployment/` | **AIGON** | AIGON | README | platforma AIGON | — | `aigon/deployment/` | puste (`.gitkeep`+README+`*.md`) | **MOVE** |
| `tests/` | **OPTIONAL** | Test | README | wszystkie projekty | — | `foundation/tests/` | puste (`.gitkeep`+README+`*.md`) | **OPTIONAL** |
| `data/` | **UNKNOWN** | — | README | — | — | — | puste (`.gitkeep`+README) | **UNKNOWN** |
| `secrets/` | **UNKNOWN** | — | README | — | — | — | puste (`.gitkeep`+README) | **UNKNOWN** |
| `artifacts/` | **FOUNDATION** | Evidence | `reports/` | wszystkie projekty | — | `foundation/artifacts/` | raporty (scaffold, universality-gap) | **KEEP** |
| `archive/` | **LEGACY** | — | README | — | — | `archive/` | 10 plików | **ARCHIVE** |
| `README.md` | **AIGON** | — | plik | — | — | — | "AIGON Production Platform" | **REWRITE** (neutralny) |
| `ARCHITECTURE.md` `DEPLOYMENT.md` `RECOVERY.md` `SECURITY.md` `MIGRATION.md` `OWNERSHIP.md` `SOURCE-OF-TRUTH.md` `CONTRIBUTING.md` `CODEOWNERS` `CHANGELOG.md` `LICENSE` `VERSION` | **FOUNDATION** | — | pliki | wszystkie projekty | — | `foundation/` | — | **KEEP** (neutralizacja brandingu) |

---

## 5. Kluczowe odkrycia (dowody)

### 5.1. AIGON-specific warstwa jest w 99% pusta (ghost moduły)

Prawie wszystkie AIGON-specific katalogi to **czyste placeholdery** (README + `.gitkeep`, zero realnych plików):

| Katalog | total | README | .gitkeep | realne pliki |
|---------|-------|--------|----------|--------------|
| agents | 23 | 12 | 11 | **0** |
| mesh | 21 | 11 | 10 | **0** |
| models | 15 | 8 | 7 | **0** |
| business | 15 | 8 | 7 | **0** |
| apps | 17 | 9 | 8 | **0** |
| operations | 19 | 10 | 9 | **0** |
| security | 15 | 8 | 7 | **0** |
| filesystem | 28 | 15 | 13 | **0** |
| shared | 73 | 38 | 30 | **5** (sync) |
| observability | 16 | 8 | 7 | **1** (health.schema) |
| governance | 16 | 8 | 7 | **1** (ADR) |

**Wniosek:** AIGON-specific warstwa to **deklaracje zdolności** (ghost moduły), nie implementacje. To jest dokładnie to, o czym mówiłeś: "UNKNOWN ≠ DELETE". Te katalogi deklarują zdolności platformy (agents, mesh, models, runtime), ale nie mają kodu.

### 5.2. "aigon" w nagłówku ≠ AIGON-specific

W `tools/verify/`, `tools/scaffold/`, `system/control-plane/state/` "aigon" to **wyłącznie nagłówek** (linia 3: "AIGON Production Platform — Repository Certification Engine"). To jest **kosmetyka** — nie czyni pliku AIGON-specific. Te narzędzia są **funkcjonalnie uniwersalne**.

**Jedyny wyjątek:** `tools/verify/debt/scanner.sh` ma **realną zależność** — listę legacy portów AIGON-X (17000, 11408, 8080, aigon-nats). To jest AIGON-specific wiedza w uniwersalnym module debt.

### 5.3. StateStore jest uniwersalny, ale w złym miejscu

`system/control-plane/state/` (lib.sh, schema.sql, state.sh, migrations, tests, data/canonical-state.db) to **realny, uniwersalny StateStore** (SQLite = canonical operational state). Ale jest w `system/` (AIGON-specific katalog). To jest **FOUNDATION w złym miejscu** — uniwersalny mechanizm ukryty w AIGON-specific katalogu.

### 5.4. `config/canonical/` jest czyste

`registry.yaml`, `gates.yaml`, `taxonomy.yaml`, `glossary.yaml`, `config_exemptions.yaml` — **CZYSTE** (tylko `schema.md` ma "aigon"). To jest **FOUNDATION** (config engine) bez AIGON contamination.

### 5.5. `contracts/` — podział

- **FOUNDATION:** `scaffold/`, `evidence/`, `security/`.
- **AIGON:** `agent-abi/`, `api/`, `capability/`, `events/`, `filesystem/`, `identity/`, `mesh/`, `runtime-abi/` — kontrakty konkretnej platformy.

---

## 6. Granica FOUNDATION vs AIGON

### FOUNDATION (uniwersalna fabryka)
```
foundation/
├── verify/          # tools/verify/ (verify engine, gates, profiles, evidence)
├── scaffold/        # tools/scaffold/ (scaffold engine)
├── config/          # config/canonical/, config/aesthetics/, config/schemas/
├── contracts/       # contracts/scaffold/, contracts/evidence/, contracts/security/
├── docs/            # docs/00-foundation/, docs/git/, docs/architecture/
├── state/           # system/control-plane/state/ (StateStore)
├── artifacts/       # artifacts/ (reports, evidence)
├── security/        # tools/security/secret-scan.sh
├── tests/           # tests/ (test infrastructure)
└── *.md             # README, ARCHITECTURE, SOURCE-OF-TRUTH, OWNERSHIP, etc.
```

### AIGON (projekt korzystający z fabryki)
```
aigon/
├── agents/          # ghost moduły (0 realnych plików)
├── mesh/            # ghost moduły
├── models/          # ghost moduły
├── system/          # ghost moduły (poza state/)
├── filesystem/      # ghost moduły
├── business/        # ghost moduły
├── apps/            # ghost moduły
├── shared/          # 5 realnych plików (sync)
├── deployment/      # ghost moduły
├── operations/      # ghost moduły
├── observability/   # 1 realny plik
├── security/        # ghost moduły
├── governance/      # 1 realny plik (ADR)
└── contracts/       # agent-abi, api, capability, events, filesystem, identity, mesh, runtime-abi
```

---

## 7. Decyzje do podjęcia (UNKNOWN ≠ DELETE)

### 7.1. UNKNOWN — wymagają decyzji Suwerena
| Element | Problem | Opcje |
|---------|---------|-------|
| `tools/automation/` `ci/` `migration/` `scripts/` `utilities/` `validation/` | puste placeholdery | KEEP (jako foundation) / MOVE (do aigon) / ARCHIVE |
| `data/` | puste placeholdery | KEEP / MOVE / ARCHIVE |
| `secrets/` | puste placeholdery | KEEP / MOVE / ARCHIVE |
| `system/*` (poza state/) | puste ghost moduły | MOVE (do aigon) / ARCHIVE |

### 7.2. OPTIONAL — wymagają decyzji
| Element | Problem | Opcje |
|---------|---------|-------|
| `tests/` | dokumentacyjne placeholdery (chaos, e2e, unit...) | KEEP (jako foundation) / MOVE |
| `config/examples/` `generated/` `local/` `templates/` | puste | KEEP / MOVE |
| `docs/decisions/` `development/` `operations/` `reference/` `security/` `user/` | puste README | KEEP / MOVE |

### 7.3. EXPERIMENTAL — wymagają decyzji
| Element | Problem | Opcje |
|---------|---------|-------|
| `docs/audit/` | audyt-v1, sonda-package | KEEP / ARCHIVE |
| `docs/generated/` | canonical-state, storage-model | KEEP / ARCHIVE |

### 7.4. LEGACY — wymagają decyzji
| Element | Problem | Opcje |
|---------|---------|-------|
| `archive/` | 2025, 2026, cemetery, legacy, quarantine | ARCHIVE (zostaje) / DELETE |

---

## 8. Co NIE zostało zrobione (zgodnie z decyzją)

- ❌ **NIE przeniosłem** żadnego katalogu.
- ❌ **NIE usunąłem** żadnego pliku.
- ❌ **NIE naprawiłem** GAP-ów A/C/A.
- ❌ **NIE rozszerzyłem** harnessu certyfikacji.
- ❌ **NIE uruchomiłem** T01-T10.
- ❌ **NIE zrobiłem** Prod-template.

To jest **mapa, nie cięcie**. Macierz jest kompletna i oparta na dowodach. Czekam na decyzję Suwerena co do:
1. Granicy FOUNDATION vs AIGON (sekcja 6).
2. Decyzji UNKNOWN/OPTIONAL/EXPERIMENTAL/LEGACY (sekcja 7).
3. Kolejności naprawy GAP-ów A/C/A po zatwierdzeniu macierzy.

---

## VERDICT: **MACIERZ KOMPLETNA — czekam na decyzję**

Macierz klasyfikacji jest kompletna i oparta na dowodach. Kluczowe odkrycia:
1. **AIGON-specific warstwa jest w 99% pusta** (ghost moduły — deklaracje zdolności bez implementacji).
2. **"aigon" w nagłówku ≠ AIGON-specific** (kosmetyka w verify/scaffold/state).
3. **StateStore jest uniwersalny, ale w złym miejscu** (w `system/`).
4. **`config/canonical/` jest czyste** (config engine bez AIGON contamination).
5. **Granica FOUNDATION vs AIGON jest jasna** (sekcja 6).

**Zgodnie z decyzją Suwerena: czekam na decyzję przed jakimkolwiek przenoszeniem, usuwaniem lub naprawą.**
