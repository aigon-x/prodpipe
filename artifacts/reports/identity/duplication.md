# OPERATION IDENTITY — Duplication & Coupling Audit (`/opt/PROD` vs `/opt/Prod-ready`)

**Status:** READ-ONLY audyt | **Data:** 2026-08-10 | **Źródło:** subagent Explore-call_02 (dane surowe z tool results) + weryfikacja własna
**Cel:** Ustalić, czy `/opt/Prod-ready` jest niebezpiecznym duplikatem AIGON Runtime (`/opt/PROD`), czy uniwersalnym fundamentem (skeleton/factory). Rozdzielić 3 warstwy: UNIVERSAL FOUNDATION / PROJECT-APPLICATION / RUNTIME.

---

## 1. Werdykt skrócony

**`/opt/Prod-ready` NIE jest duplikatem `/opt/PROD`.** To dwa byty na **różnych warstwach**:

| Warstwa | `/opt/PROD` | `/opt/Prod-ready` |
|---|---|---|
| **RUNTIME** (wykonuje) | ✅ TAK — 120 crates Rust, tick loop, scheduler, agenci, LLM, mesh | ❌ NIE — 0 plików programistycznych, 0 zachowania runtime |
| **PROJECT-APPLICATION** (konfiguracja konkretnego systemu) | ✅ TAK — configs.yaml, packages.yaml, mesh.yaml, node-config.toml, docker-compose | ❌ NIE — brak configów konkretnego systemu |
| **UNIVERSAL FOUNDATION** (skeleton/factory, certyfikacja) | ❌ NIE | ✅ TAK — verify engine, config plane L0-L7, taxonomy, gates |

**Wniosek:** `/opt/Prod-ready` to **uniwersalny fundament projektowy** (skeleton/factory), a `/opt/PROD` to **konkretna aplikacja tego fundamentu** (lub byt równoległy). Nakładanie się nazw katalogów to nazwy generyczne, nie duplikacja.

---

## 2. Porównanie warstw (FACT)

### 2.1 RUNTIME — `/opt/PROD` MA, `/opt/Prod-ready` NIE MA

| Kryterium | `/opt/PROD` | `/opt/Prod-ready` |
|---|---|---|
| Pliki programistyczne (.py/.go/.rs/.ts/.js) | ✅ 120 crates Rust + Python scripts | ❌ 0 (tylko bash/YAML/SQL) |
| Tick loop / scheduler | ✅ `pub async fn tick` (lib.rs:3041), DistributedScheduler | ❌ brak |
| Wykonanie zadań/agentów/LLM | ✅ provider-*, workflow_executor, magic-router | ❌ brak |
| Mesh / peers | ✅ 8 nodów (AIGON_MESH_PEERS) | ❌ brak |
| Procesy / kontenery / porty | ✅ aktywne (7000, 15120, 8082, 4223...) | ❌ 0 |
| Bazy danych runtime | ✅ surrealdb 708M, qdrant, postgres, registry 2.3G | ❌ tylko canonical-state.db (401KB, telemetria gate'ów) |
| Systemd / daemon | ✅ aigon-runtime-v2.service, aigon-federation-cp.service | ❌ brak |

**FACT:** `/opt/Prod-ready` nie ma żadnego zachowania runtime. Nie wykonuje, nie planuje, nie łączy się z mesh, nie hostuje agentów.

### 2.2 PROJECT-APPLICATION — config konkretnego systemu

`/opt/PROD` ma **konfigurację konkretnego, działającego systemu**:
- `config/configs.yaml` — centralny rejestr configów (config configów), 8 nodów, reload routera POST /reload na 127.0.0.1:14008.
- `config/packages.yaml` — pakiety ról (agent: mcp/chat/models/runtime-api + capabilities; compute: extends agent + compute-share + compute__gpu/background_jobs/federated).
- `config/mesh.yaml` — konfiguracja mesh.
- `runtime/config-*.yaml` — per-node (prod, local, contabo, kamil, mail, monitor, optiq, site).
- `deploy/prod/node-config.toml` — role worker, listen 0.0.0.0:7000, tick_interval_ms 1000, DistributedScheduler (max_tasks_per_node 24, max_concurrent_assignments 192).
- `deploy/prod/docker-compose.prod.yml` — 3 serwisy (rtv2-runtime-master, magic-router, nats).
- `deploy/prod/systemd/aigon-runtime-v2.service` — systemd unit z AIGON_MESH_PEERS (8 nodów).

`/opt/Prod-ready` **nie ma** żadnego z tych configów — nie ma configs.yaml, packages.yaml, mesh.yaml, node-config.toml, docker-compose.prod.yml, systemd unit. Ma tylko **uniwersalne szablony** (registry.yaml, gates.yaml, taxonomy.yaml) bez wartości konkretnego systemu.

### 2.3 UNIVERSAL FOUNDATION — `/opt/Prod-ready` MA, `/opt/PROD` NIE MA

`/opt/Prod-ready` ma **uniwersalny fundament certyfikacji i configu**:
- `tools/verify/` — Repository Certification Engine (reconcile/drift/history/debt/waivers + efficiency).
- `config/canonical/registry.yaml` — Config Plane L0-L7 (defaulty, floors, profile, context rules, waivers, kill-switches, ratchet/reload/owner/tier/doc).
- `config/canonical/gates.yaml` — metadata-driven definicje gate'ów (module/script/profiles/severity), generator profiles.sh.
- `config/canonical/taxonomy.yaml` — 32 wymiary, 218+ checków, applicability_matrix, qi_formula.
- `system/control-plane/state/` — Canonical State Foundation (SQLite, migracyjna, wersjonowana, provenance, desired/effective/observed).
- `contracts/`, `governance/`, `deployment/`, `operations/`, `agents/`, `apps/`, `business/`, `shared/`, `models/`, `observability/`, `security/`, `secrets/`, `filesystem/`, `data/` — uniwersalne warstwy.

`/opt/PROD` **nie ma** żadnego z tych mechanizmów — nie ma verify engine, config plane L0-L7, taxonomy, canonical state. Ma własne, ad-hoc skrypty (scripts/ 127, aigon-config.py) i własne configi (configs.yaml, packages.yaml).

---

## 3. AIGON Coupling Test (płytki vs głęboki)

Coupling `/opt/Prod-ready` do AIGON jest **płytki** — głównie nazwy/branding, nie logika:

| Element | Wartość | Głębokość |
|---|---|---|
| `database_id` | `aigon-canonical-state` | Płytki (nazwa) |
| `registry.schema.json` `$id` | `https://aigon.pl/schemas/...` | Płytki (nazwa) |
| Nazwy katalogów | `system/`, `tools/`, `config/`, `mesh/`, `observability/` | Płytkie (generyczne) |
| `contracts/runtime-abi`, `contracts/mesh` | definicje ABI | Płytkie (kontrakty, nie implementacja) |
| `agents/`, `apps/`, `business/` | uniwersalne warstwy | Brak (generyczne) |

**FACT:** Żaden mechanizm `/opt/Prod-ready` nie wymaga działającego AIGON Runtime. Verify engine, config plane, taxonomy, canonical state działają niezależnie — certyfikują repo, nie wykonują workload.

**INFERENCE:** `/opt/Prod-ready` mógłby być używany jako fundament dla **dowolnego** projektu (nie tylko AIGON) — branding AIGON jest kosmetyczny.

---

## 4. Universality Test (czy fundament jest uniwersalny?)

| Test | Wynik | Dowód |
|---|---|---|
| Zero hardcoded assumptions | ⚠️ CZĘŚCIOWO | registry.yaml/gates.yaml/taxonomy.yaml są generyczne; ale `database_id: aigon-canonical-state`, `$id: aigon.pl` to branding |
| Project Profile | ⚠️ BRAK | brak mechanizmu Project Profile (per-projekt) |
| Capability Matrix | ⚠️ BRAK | taxonomy ma applicability_matrix, ale nie ma Capability Matrix per projekt |
| Structure Adaptability | ⚠️ NIEPOTWIERDZONE | nie testowano na świeżym projekcie |
| Configuration Boundary | ✅ TAK | registry.yaml L0-L7 + waivers + kill-switches + exemptions |
| Generated vs Handwritten | ✅ TAK | profiles.sh generowany z gates.yaml (gen-profiles.sh) |
| Extension Point Test | ⚠️ NIEPOTWIERDZONE | brak testu dodawania nowego modułu |
| No Template Pollution | ⚠️ NIEPOTWIERDZONE | brak testu |
| Reverse Test | ⚠️ NIEPOTWIERDZONE | brak testu |
| Migration Test (dry-run) | ⚠️ NIEPOTWIERDZONE | brak testu |
| Universal Skeleton Score | ⚠️ NIE OBLICZONO | wymaga certyfikacji |
| FRESH PROJECT TEST | ⚠️ NIEPOTWIERDZONE | brak testu na świeżym projekcie |

**INFERENCE:** Fundament jest **architektonicznie uniwersalny** (config plane, verify engine, taxonomy są generyczne), ale **nie przeszedł jeszcze certyfikacji uniwersalności** (brak 10 projektów testowych, brak Project Profile, brak Capability Matrix). To jest dokładnie to, co ma dostarczyć **TEMPLATE UNIVERSALITY / ADAPTABILITY CERTIFICATION** przed zamrożeniem.

---

## 5. Runtime Behavior Test (czy Prod-ready zachowuje się jak runtime?)

**NIE.** `/opt/Prod-ready` nie ma:
- tick loop / scheduler / worker pools / daemon / systemd
- wykonania zadań / agentów / LLM / mesh
- procesów / kontenerów / portów
- baz danych runtime (tylko canonical-state.db — telemetria gate'ów)

**FACT:** `/opt/Prod-ready` to **płaszczyzna kontroli (control plane)** — certyfikuje, nie wykonuje. `/opt/PROD` to **płaszczyzna danych (data plane)** — wykonuje.

---

## 6. Migration Possibility Test (czy można przenieść Runtime do Prod-ready?)

**NIE zalecane.** `/opt/PROD` to działający, złożony system (120 crates, 8 nodów mesh, bazy, systemd, kontenery). Przenoszenie go do `/opt/Prod-ready` (które nie ma runtime) wymagałoby:
1. Zbudowania runtime od nowa w Prod-ready (druga implementacja — dokładnie to, czego Suweren chce uniknąć).
2. Migracji 120 crates, configów, baz, systemd, kontenerów.
3. Ryzyka utraty działającego systemu.

**Zalecenie:** Zachować `/opt/PROD` jako działający Runtime. Używać `/opt/Prod-ready` jako fundamentu dla **nowych** projektów (template), nie jako zamiennika Runtime.

---

## 7. Duplication Audit (nakładanie się nazw katalogów)

| Katalog | `/opt/PROD` | `/opt/Prod-ready` | Duplikacja? |
|---|---|---|---|
| `config/` | configs.yaml, packages.yaml, mesh.yaml (konkretny system) | canonical/registry.yaml, gates.yaml, taxonomy.yaml (uniwersalne) | ❌ różne warstwy |
| `data/` | runtime/knowledge.db, surrealdb | system/tenant, data/system | ❌ różne |
| `mesh/` | symlink → runtime/manifests | control/data/discovery/health/... | ❌ PROD=konkret, Prod-ready=uniwersalne |
| `observability/` | grafana, prometheus, loki (konkretne) | alerts, audit, dashboards, health (uniwersalne) | ❌ |
| `security/` | (brak top-level) | audit, keys, policies, scanning | ❌ |
| `docs/` | 4 elementy | pełna dokumentacja | ❌ |
| `reports/` | omega-synapsis | artifacts/reports | ❌ |
| `archive/` | repo-lint-auto | archive/ | ❌ |
| `backups/` | datastores, registry, ssot, vault | deployment/backup, operations/backup | ❌ |
| `skills/` | 4 elementy | (brak top-level) | ❌ |
| `users/` | 2 elementy | business/tenants, business/users | ❌ |
| `validation/` | modules, results, scenarios | tools/validation | ❌ |

**FACT:** Nakładanie się nazw to **nazwy generyczne** (config, data, mesh, observability, security, docs, reports, archive, backups, skills, users, validation) — nie dowód duplikacji. Zawartość jest na różnych warstwach (konkretny system vs uniwersalny fundament).

---

## 8. Reimplementation Risk (ryzyko drugiej implementacji)

**Ryzyko JEST REALNE, ale nie z powodu duplikacji — z powodu pokusy.**

- `/opt/Prod-ready` ma `system/control-plane/state/` (SQLite canonical state) — to **nie jest** runtime, to telemetria gate'ów.
- `/opt/Prod-ready` ma `contracts/runtime-abi`, `contracts/mesh` — to **kontrakty**, nie implementacja.
- `/opt/Prod-ready` ma `system/runtime/`, `system/scheduler/`, `system/self-heal/` — ale to **placeholdery** (README + .gitkeep, STATUS: UNDEFINED).

**Ryzyko:** Ktoś mógłby zobaczyć `system/runtime/`, `system/scheduler/`, `system/self-heal/` w Prod-ready i pomyśleć, że to zaczątki runtime — i zacząć budować drugi runtime. **To jest niebezpieczny duplikat potencjalny, nie aktualny.**

**Zalecenie:** W TEMPLATE FREEZE oznaczyć `system/runtime/`, `system/scheduler/`, `system/self-heal/` jako **placeholdery (STATUS: UNDEFINED)** i NIE rozwijać ich w Prod-ready. Runtime żyje w `/opt/PROD`.

---

## 9. Red Flags

1. **Placeholdery runtime w Prod-ready** (`system/runtime/`, `system/scheduler/`, `system/self-heal/`) — STATUS: UNDEFINED, mogą sugerować drugi runtime.
2. **Ghost moduły** — 6 zadeklarowanych w gates.yaml bez skryptów (dependencies, reproducibility, deployment, contracts, migration, recovery).
3. **Branding AIGON** w uniwersalnym fundamencie (`database_id: aigon-canonical-state`, `$id: aigon.pl`) — utrudnia uniwersalność.
4. **Brak certyfikacji uniwersalności** — fundament architektonicznie uniwersalny, ale nie przetestowany na świeżych projektach.
5. **Worktrees** (`/opt/PROD/.qwen/worktrees/agent-*`, `/opt/Prod-ready/.qwen/worktrees/`) — artefakty eksperymentalne.

---

## 10. Final Matrix

| Warstwa | `/opt/PROD` | `/opt/Prod-ready` | Werdykt |
|---|---|---|---|
| RUNTIME | ✅ realny | ❌ brak | Rozdzielone |
| PROJECT-APPLICATION | ✅ konkretny system | ❌ brak | Rozdzielone |
| UNIVERSAL FOUNDATION | ❌ brak | ✅ uniwersalny | Rozdzielone |
| Duplikacja | — | — | ❌ NIE jest duplikatem |
| Coupling AIGON | — | płytki (nazwy) | ✅ bezpieczny |
| Uniwersalność | — | architektonicznie TAK, niecertyfikowana | ⚠️ wymaga certyfikacji |

---

## 11. Final Verdict Box

```
╔══════════════════════════════════════════════════════════════════════╗
║  OPERATION IDENTITY — DUPLICATION AUDIT                              ║
║                                                                      ║
║  /opt/Prod-ready NIE jest duplikatem /opt/PROD.                      ║
║                                                                      ║
║  • /opt/PROD      = RUNTIME (wykonuje) — 120 crates, tick, mesh      ║
║  • /opt/Prod-ready= UNIVERSAL FOUNDATION (certyfikuje) — verify,     ║
║                     config plane L0-L7, taxonomy, canonical state    ║
║                                                                      ║
║  Coupling AIGON: PŁYTKI (nazwy/branding), nie logika.                ║
║  Uniwersalność: architektonicznie TAK, NIEcertyfikowana.             ║
║                                                                      ║
║  RYZYKO: placeholdery system/runtime|scheduler|self-heal mogą        ║
║          sugerować drugi runtime. NIE rozwijać ich w Prod-ready.     ║
║                                                                      ║
║  REKOMENDACJA: Zachować /opt/PROD jako działający Runtime.           ║
║  Używać /opt/Prod-ready jako uniwersalnego fundamentu (template)     ║
║  dla NOWYCH projektów. NIE przenosić Runtime do Prod-ready.          ║
║                                                                      ║
║  NASTĘPNY KROK: TEMPLATE UNIVERSALITY / ADAPTABILITY CERTIFICATION   ║
║  (10 projektów testowych) przed zamrożeniem.                         ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

*Raport wygenerowany z danych surowych subagenta Explore-call_02 (tool results w .jsonl) + weryfikacja własna. READ-ONLY — nie zmieniono żadnego pliku w /opt/PROD ani /opt/Prod-ready.*
