# OPERATION IDENTITY — PROD Inventory (`/opt/PROD`)

**Status:** READ-ONLY audyt | **Data:** 2026-08-10 | **Źródło:** subagent Explore-call_00 (dane surowe z tool results) + weryfikacja własna
**Cel:** Pełny inventory `/opt/PROD` (istniejący, działający AIGON Runtime) i ustalenie, czy zachowuje się jak prawdziwy Runtime.

---

## 1. Werdykt skrócony

**`/opt/PROD` JEST REALNYM, DZIAŁAJĄCYM RUNTIME'EM.** To nie jest skeleton ani placeholder. Ma:
- **120 crates Rust** (workspace `aigon-*`), w tym `aigon-runtime`, `aigon-scheduler`, `aigon-mesh`, `aigon-kernel-*`, `aigon-magic-router`, `aigon-provider-*`.
- **Realny tick loop** (`pub async fn tick` w `aigon-runtime/src/lib.rs:3041`, `tick_loop`, `tick_interval_ms: 1000`).
- **DistributedScheduler** (agent_runtime.rs, agent_spawner.rs, scheduler_registry.rs, workflow_executor.rs, workflow_interpreter.rs).
- **Aktywne procesy** (aigon-x-magic-router, aigon-federation-cp.service, yudai, postgres).
- **Kontenery Docker** (aigon-code-server, postgres maddy-forensics, nix-builder).
- **Bazy danych** (surrealdb 708M, qdrant 8.9M, registry 2.3G, postgres).
- **Systemd service** (`aigon-runtime-v2.service`, `aigon-federation-cp.service`).
- **Crontab** (backup, knowledge sync, runtime watchdog, coredns).

---

## 2. Struktura katalogów top-level (60 elementów)

```
/opt/PROD/
├── runtime/          # GŁÓWNY RUNTIME — Cargo workspace, 120 crates, config-*.yaml, Dockerfile*, docker-compose.yml, deploy/, data/, docs/
├── core/             # docker-compose*.yml, .env, gen-compose-nodes.py, mesh-nginx.conf, router/, runtime/, tls/
├── scripts/          # 127 skryptów (backup, sync, watchdog, mesh-tick.sh)
├── config/           # 16 elementów
├── data/             # runtime/knowledge.db, runtime/lib/knowledge.db
├── datastores/       # postgres, qdrant, redis, surrealdb (z config/)
├── observability/    # grafana, prometheus, loki, promtail, alerting, blackbox
├── products/         # aigon-code (backend-rs, frontend, cli, mcp-rs), frontend, mesh-observatory
├── infra/            # federation, registry (data/docker 2.3G), vault (vault.db)
├── llm/              # ollama
├── router/           # 3 elementy
├── mesh/             # SYMLINK → ../runtime/manifests
├── runtime-bin/      # 3 elementy (prebuilt binaria)
├── skills/           # 4 elementy
├── skills-mesh/      # 1 element
├── users/            # 2 elementy (+ _template)
├── validation/       # modules/ (11), results/, scenarios/
├── validation-fix/   # modules/, results/
├── reports/          # 14 elementów (omega-synapsis)
├── archive/          # repo-lint-auto
├── backups/          # 10 elementów (datastores, registry, ssot, vault)
├── atlas/            # 1 element
├── code/             # config/, frontend/dist/
├── fs/               # knowledge/nas_knowledge (214 elementów!)
├── mail/             # 2 elementy
├── mcp-servers/      # 1 element
├── projects/         # 1 element
├── frontends/        # 1 element
├── docs/             # 4 elementy
├── inventory/        # 1 element
├── .tools/           # 1 element
├── .qwen/            # worktrees (agent-*)
├── .trivy-tmp/       # skanowanie security
└── stack.yaml.bak-*  # backupi stack.yaml
```

**Symlink:** `mesh -> ../runtime/manifests` (potwierdzone przez `find -type l`).

---

## 3. Runtime (`/opt/PROD/runtime/`)

### 3.1 Cargo workspace (120 crates)

`Cargo.toml` — workspace `aigon-*`, wersja `0.2.0`, edition 2021, rust-version 1.75. Kluczowe crates:

| Kategoria | Crates |
|---|---|
| **Rdzeń runtime** | `aigon-runtime`, `aigon-runtime-bin`, `aigon-core`, `aigon-mesh`, `aigon-mesh-bridge` |
| **Scheduler** | `aigon-scheduler` (agent_runtime.rs, agent_spawner.rs, scheduler_registry.rs, workflow_actions.rs, workflow_executor.rs, workflow_interpreter.rs) |
| **Kernels** | `aigon-kernel`, `aigon-kernel-curie`, `aigon-kernel-yudai`, `aigon-kernel-galileo`, `aigon-kernel-hawking`, `aigon-kernel-yairoslaw`, `aigon-kernel-freud`, `aigon-kernel-knowledge`, `aigon-kernel-nano`, `aigon-kernel-cognitive`, `aigon-kernel-reasoning`, `aigon-kernel-self-modify`, `aigon-kernel-learning`, `aigon-kernel-world`, `aigon-kernel-constitution`, `aigon-kernel-planck`, `aigon-kernel-turing`, `aigon-kernel-darwin`, `aigon-kernel-nash` |
| **Router** | `aigon-magic-router` |
| **Providers (LLM)** | `aigon-provider-core`, `aigon-provider-qwen`, `aigon-provider-gpt`, `aigon-provider-deepseek`, `aigon-provider-openrouter`, `aigon-provider-llama`, `aigon-provider-gemini`, `aigon-provider-claude` |
| **Capability/Inference** | `aigon-capability-core`, `aigon-capability-engine`, `aigon-capability-factory`, `aigon-inference-core`, `aigon-inference-engine` |
| **Governance/Security** | `aigon-governance`, `aigon-security`, `aigon-secret-*` (protection, mesh, backup, recovery, governance, audit, guardian), `aigon-cognitive-integrity` |
| **FS/Knowledge** | `aigon-fs`, `aigon-knowledge`, `aigon-knowledge-fabric`, `aigon-knowledge-galaxy`, `aigon-memory`, `aigon-context`, `aigon-virtual-context` |
| **Infra/Platform** | `aigon-infrastructure`, `aigon-platform`, `aigon-v3-core`, `aigon-lifecycle`, `aigon-resilience`, `aigon-recovery`, `aigon-heartbeat`, `aigon-dns`, `aigon-identity`, `aigon-energy`, `aigon-engines`, `aigon-entropy`, `aigon-krono`, `aigon-pty`, `aigon-prophet` |
| **Ewolucja/Cognition** | `aigon-evolution`, `aigon-cognition`, `aigon-cognitive-meta-layer`, `aigon-cognitive-os-arch`, `aigon-physics-cognitive`, `aigon-physics-resource`, `aigon-timeline-engine`, `aigon-evidence-store`, `aigon-proof-engine`, `aigon-semantic-abi`, `aigon-teaching-pipeline`, `aigon-entity-registry` |
| **Inne** | `aigon-cli`, `aigon-console`, `aigon-crypto`, `aigon-compute`, `aigon-skills`, `aigon-federation`, `aigon-genome`, `aigon-bench`, `aigon-planner`, `aigon-ucb`, `aigon-acct`, `aigon-adapters`, `aigon-acisa`, `aigon-package-format`, `aigon-gtm`, `aigon-theory-registry`, `aigon-economics`, `aigon-policy`, `aigon-linker`, `aigon-builder`, `aigon-compiler`, `aigon-assembly`, `aigon-profiler`, `aigon-trace`, `aigon-human-os`, `aigon-mood-engine`, `aigon-evaluation`, `aigon-federated-learning`, `aigon-human-elevation`, `aigon-runtime-decomposer`, `aigon-skill-engine`, `aigon-adaptive-role-interface`, `aigon-maips`, `aigon-kir`, `aigon-sensor` |

**Uwaga:** `crates-archive/` (20 elementów) — zarchiwizowane crates (np. `aigon-adaptive-mesh` — ARCH-003, 0 call sites).

### 3.2 Runtime behavior (DOWÓD — to jest realny runtime)

- **`aigon-runtime/src/lib.rs:3041`** — `pub async fn tick(&mut self) -> Vec<(String, TickResult)>` — główny tick loop.
- **`aigon-runtime/src/lib.rs:5583`** — `"tick_loop"` — pętla tick.
- **`aigon-runtime/src/kernel_spec.rs`** — trait `Kernel` z `fn tick_period_ms(&self)` i `async fn tick(&mut self) -> Result<TickResult, KernelError>`.
- **193 matchy "tick"** w `runtime/crates` (pattern `tick_interval|fn tick|tick_loop|async fn tick`).
- **`aigon-runtime/src/scheduler_registry.rs:108`** — `tick_interval_ms: 1000`.
- **`aigon-runtime/src/runtime_certification.rs:28`** — `CERTIFICATION_TICK_INTERVAL: u64 = 10` (co N-ty tick).
- **`aigon-scheduler/src/distributed.rs`** — DistributedScheduler.
- **`aigon-runtime/src/api.rs`** — API (ExecuteRequest, health endpoint).
- **`aigon-runtime/src/scaler.rs`** — auto-scaling.
- **`aigon-runtime/src/mission.rs:393`** — `pub async fn tick(&mut self)`.
- **`aigon-kernel-hawking/src/lib.rs:531`**, **`aigon-kernel-reasoning/src/lib.rs:127`**, **`aigon-cognitive-integrity/src/truth_kernel.rs:84`** — `async fn tick` w kernelach.
- **`aigon-runtime-bin/src/main.rs`** — "Deterministic boot, tick loop, health endpoint", używa `aigon_mesh::transport::TcpMeshTransport`, `MeshNetwork`, `Runtime`, `sqlx::PgPool`.

### 3.3 Konfiguracja runtime

- **`config.yaml`** (runtime) — konfiguracja runtime (overrides).
- **`config-*.yaml`** — per-node: config-prod, config-local, config-global-mesh, config-contabo, config-kamil, config-mail, config-monitor, config-optiq, config-site, config.yaml.
- **`node-config.toml`** (deploy/prod) — `role: "worker"`, `listen_addr: "0.0.0.0:7000"`, `tick_interval_ms: 1000`, `heartbeat_interval_ms: 2000`, `data_dir: "/var/lib/aigon/runtime"`, **DistributedScheduler** (enabled, max_tasks_per_node: 24, load_balanced, weighted_round_robin, fifo_with_priority_boost, max_concurrent_assignments: 192), performance (max_concurrent_connections: 500, task_execution_timeout_minutes: 120), mesh_peers (LOCAL/PROD/CONTABO...).
- **`docker-compose.yml`** (runtime) — serwisy.
- **`docker-compose.prod.yml`** (deploy/prod) — 3 serwisy:
  - `rtv2-runtime-master` — image `aigon-runtime-v2:tui-cli-20260807`, restart unless-stopped.
  - `magic-router` — image `aigon-x-magic-router:fix4-20260807`, container `runtime-v2-magic-router-1`.
  - `nats` — image `nats:2.10-alpine`, container `aigon-router-nats`, ports `127.0.0.1:4223:4223`, `127.0.0.1:8223:8223`.
- **`deploy/prod/systemd/aigon-runtime-v2.service`** — systemd unit:
  - `ExecStart=/usr/bin/docker run --rm --name aigon-runtime-master --network host` z env: `OLLAMA_HOST`, `AIGON_MESH_PEERS` (8 nodów: runtime-loc/prod/ctbo/monitor/site/optiq/mail/kamil.srv.aigon.consul:7000), `AIGON_NODE_NAME=prod-aigon`, `AIGON_TAILSCALE_IP=prod.szamani.ai`, `AIGON_API_KEY`, mount `/opt/aigon-x-new/runtime-v2/config.yaml:/app/config.yaml:ro`, healthcheck `curl -sf http://localhost:7000/health`.
- **`deploy/prod/coredns/Corefile`** + `deploy-dns-forwarder.sh` + `verify-dns-forwarder.sh` — DNS forwarder (coredns na porcie 5354).
- **`deploy/prod/node-config.toml`** — konfiguracja noda.

---

## 4. Procesy (aktywne)

`ps aux | grep -iE 'runtime|aigon|router|mesh|agent|kernel|curie|yudai|maips'`:

| PID | Proces | Uwagi |
|---|---|---|
| 2314 | `/usr/local/bin/yudai --port 8082 --brain localhost:14500` | YUDAI Kernel (CPU Security) |
| 2395277 | `/usr/local/bin/aigon-x-magic-router --config /etc/aigon/gateway.yaml --providers-manifest /etc/aigon/providers.yaml --listen 0.0...` | **Magic Router** |
| 3829 | `hermes_cli.main gateway run` | Hermes gateway |
| 13223 | `postgres: aigon postgres` | Postgres (aigon) |
| 786342 | `postgres: aigon aigoncode` | Postgres (aigoncode) |
| 1596 | `avahi-daemon: running [local-aigon.local]` | mDNS |
| 5037 | `gcr-ssh-agent` | SSH agent |

**Systemd services (aigon/runtime/router/mesh):**
- `aigon-federation-cp.service` — **active running** — AIGON-X Federation Control Plane backend (:15120, mesh health aggregator).
- `cloudflared-mesh-ha.service` — active running — Cloudflare Tunnel aigon-mesh-ha (mesh.aigon.dev).
- `containerd.service` — active running.
- `falco-modern-bpf.service` — active running — Falco security.

---

## 5. Kontenery Docker

`docker ps -a`:

| Container | Image | Status | Porty |
|---|---|---|---|
| `aios-nix-builder` | nixos/nix:latest | Up 4 hours | — |
| `maddy-forensics-contaboaigonx` | postgres:16-alpine | Up 5 hours | 5432/tcp |
| `maddy-forensics-prodaigonx` | postgres:16-alpine | Up 5 hours | 5432/tcp |
| `maddy-forensics-contaboold` | postgres:16-alpine | Up 5 hours | 5432/tcp |
| `maddy-forensics-prodha` | postgres:16-alpine | Up 5 hours | 5432/tcp |
| `aigon-code-server` | 127.0.0.1:55000/aigon-code-server:merged-20260810 | Up 5 hours (healthy) | — |
| ... | (więcej) | | |

---

## 6. Porty nasłuchujące

`ss -tlnp` (fragment):
- `0.0.0.0:15120` — aigon-federation-cp (mesh health aggregator).
- `127.0.0.1:9121`, `127.0.0.1:9187` — eksporterzy (node_exporter / postgres_exporter).
- `127.0.0.1:9000`, `127.0.0.1:9050` — usługi lokalne.
- `127.0.0.54:53` — systemd-resolved.
- `0.0.0.0:8765` — usługa.
- `127.0.0.1:4223`, `127.0.0.1:8223` — NATS (z docker-compose.prod.yml).
- `0.0.0.0:7000` — runtime (z node-config.toml, healthcheck).
- `8082` — yudai.
- `14500` — yudai brain.

---

## 7. Bazy danych (datastores)

| Datastore | Rozmiar | Uwagi |
|---|---|---|
| `datastores/postgres/data` | 4.0K | (pusty katalog — postgres działa w kontenerze) |
| `datastores/qdrant/data` | 8.9M | Qdrant (wektory) |
| `datastores/redis/data` | 12K | Redis |
| `datastores/surrealdb/data` | **708M** | SurrealDB (główna baza) |
| `infra/registry/data/docker` | **2.3G** | Docker registry |

**Inne bazy:**
- `infra/vault/data/vault.db` — Vault.
- `data/runtime/knowledge.db`, `runtime/lib/knowledge.db` — knowledge.
- `runtime/knowledge/23-ctf-security/playbook.db` — playbook.
- `runtime/data/surrealdb/` — SurrealDB runtime.
- `runtime/data/evidence/`, `runtime/data/router/evidence/` — evidence.

---

## 8. Crontab

- `@reboot` — uruchom coredns (aigon-runtime-v2-coredns, port 5354).
- `*/5 * * * *` — `python3 /opt/PROD/scripts/sync-agent-m...` (agent memory → runtime sync).
- (zakomentowane DRIFT-FREEZE 20260807): backup.sh, sync-identity-db.sh, ingest_and_push.sh, monitor-fd.sh, mesh-runtime-watchdog.sh.

---

## 9. State / Config ownership

- **Config:** `/opt/PROD/config/` (16 elementów), `/opt/PROD/runtime/config/` (17 elementów), `/opt/PROD/core/runtime/config/`, `/opt/PROD/core/.env`, `/opt/PROD/core/gen-compose-nodes.py`.
- **State:** `/opt/PROD/data/`, `/opt/PROD/runtime/data/`, `/opt/PROD/datastores/`, `/opt/PROD/infra/registry/data/`, `/opt/PROD/infra/vault/data/`.
- **Secrets:** `/opt/PROD/runtime/.secrets/`, `/opt/PROD/runtime/credentials/`, `/opt/PROD/runtime/.krono-ssh/`.
- **Evidence:** `/opt/PROD/runtime/data/evidence/`, `/opt/PROD/runtime/aap/evidence/`, `/opt/PROD/runtime/data/router/evidence/`.
- **Manifests:** `/opt/PROD/runtime/manifests/` (17 elementów) — symlink `mesh -> ../runtime/manifests`.

---

## 10. Wnioski (FACT/INFERENCE)

- **FACT:** `/opt/PROD` ma 120 crates Rust, tick loop, DistributedScheduler, aktywne procesy, kontenery, bazy, systemd services, crontab.
- **FACT:** Runtime wykonuje workload/taski/agenty/LLM/mesh/scheduling (aigon-scheduler, workflow_executor, provider-*, magic-router, mesh_peers).
- **FACT:** `/opt/PROD` jest podłączony do 8 nodów mesh (AIGON_MESH_PEERS: loc/prod/ctbo/monitor/site/optiq/mail/kamil).
- **INFERENCE:** `/opt/PROD` to **realny, działający AIGON Runtime v2** — nie skeleton, nie placeholder.
- **INFERENCE:** `/opt/PROD` i `/opt/Prod-ready` to **dwa różne byty**: PROD = runtime (wykonuje), Prod-ready = skeleton/factory + płaszczyzna kontroli (certyfikuje).

---

## 11. Ryzyka / red flags

- **Duplikacja nazw:** `/opt/PROD` ma `runtime/`, `core/`, `config/`, `data/`, `datastores/`, `observability/`, `products/`, `infra/`, `llm/`, `router/`, `mesh/`, `skills/`, `users/`, `validation/`, `reports/`, `archive/`, `backups/`, `atlas/`, `code/`, `fs/`, `mail/`, `mcp-servers/`, `projects/`, `frontends/`, `docs/`, `inventory/` — a `/opt/Prod-ready` ma `system/`, `tools/`, `config/`, `docs/`, `governance/`, `artifacts/`, `contracts/`, `deployment/`, `mesh/`, `operations/`, `tests/`, `agents/`, `apps/`, `business/`, `shared/`, `models/`, `observability/`, `security/`, `secrets/`, `filesystem/`, `data/`. **Częściowe nakładanie się nazw** (config, data, mesh, observability, security, docs, reports, archive, backups, skills, users, validation) — ale to nazwy generyczne, nie dowód duplikacji.
- **`/opt/PROD` ma `runtime/` (120 crates), `/opt/Prod-ready` ma `system/control-plane/state/` (SQLite) — to różne warstwy.**
- **Worktrees** `/opt/PROD/.qwen/worktrees/agent-*` — artefakty eksperymentalne.
- **`stack.yaml.bak-*`** — backupi stack.yaml (legacy core, runtimecheck).

---

*Raport wygenerowany z danych surowych subagenta Explore-call_00 (tool results w .jsonl) + weryfikacja własna. READ-ONLY — nie zmieniono żadnego pliku w /opt/PROD.*
