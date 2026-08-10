# PHASE 01 — Complete Configuration Inventory

> OPERATION CONFIG ZERO — pełny inwentarz elementów konfiguracyjnych.
> Worktree: `/opt/Prod-ready/.qwen/worktrees/config-zero` | Branch: `worktree-config-zero`

## 1. Metodologia

Skan całego repozytorium (534 plików) pod kątem elementów konfiguracyjnych:
- Pliki konfiguracyjne (YAML/JSON/TOML/INI/ENV/CFG/CONF/PROPERTIES)
- Hardcoded wartości w skryptach shell (IP, porty, hostname, node counts, service names, endpointy, env vars)
- Katalogi konfiguracyjne (`config/`)
- Stan/konfiguracja w `system/` (subsystem state)
- Konfiguracja deployment/contracts/governance
- Referencje sekretów (`secrets/`)
- Konfiguracja deklarowana w README

## 2. Statystyki

| Metryka | Wartość |
|---|---|
| Pliki (poza .git) | 534 |
| Skrypty `.sh` | 24 |
| Pliki YAML | 9 (wszystkie GitHub Actions/Dependabot) |
| Pliki JSON | 0 |
| Pliki `.env` | 0 |
| Pliki TOML/INI/CFG/CONF/PROPERTIES | 0 |
| Katalogi konfiguracyjne | 8 (config/canonical, generated, local, schemas, templates, examples + README) |

## 3. Katalogi konfiguracyjne (`config/`)

| Ścieżka | STATUS | Klasa | Rola |
|---|---|---|---|
| `config/README.md` | FOUNDATION PLACEHOLDER | CANONICAL | Deklaratywna konfiguracja platformy |
| `config/canonical/schema.md` | UNDEFINED | CANONICAL | Model CANONICAL/GENERATED/LOCAL |
| `config/canonical/README.md` | UNDEFINED | CANONICAL | Jedyne źródło prawdy konfiguracji |
| `config/generated/` | — | GENERATED | Pochodna, NIGDY ręcznie edytowana |
| `config/local/README.md` | UNDEFINED | LOCAL | Maszynowa, NIGDY commitowana |
| `config/schemas/schema.md` | UNDEFINED | SCHEMA | Definicje schematów konfiguracji |
| `config/templates/template.md` | UNDEFINED | TEMPLATE | Szablony config |
| `config/examples/example.md` | UNDEFINED | EXAMPLE | Przykłady config |

## 4. Pliki konfiguracyjne (YAML)

### 4.1 `.github/dependabot.yml`
- `package-ecosystem: cargo` (weekly, monday 05:17, limit 10, labels dependencies+security)
- `package-ecosystem: github-actions` (weekly, 06:23, labels dependencies+ci)

### 4.2 `.github/workflows/*.yml` (8 plików)
| Plik | Trigger | Kluczowa konfiguracja |
|---|---|---|
| `ci.yml` | PR/push | concurrency, granice architektury (agent→canonical, business→runtime, hardcoded IP, sekrety, `:latest`) |
| `drift.yml` | PR/push/cron 03:17 | wykrywanie driftu |
| `feature.yml` | PR | dozwolone prefiksy branchy |
| `helios.yml` | — | placeholder final gate |
| `regression.yml` | push main | regresja |
| `release.yml` | tag v* | odczyt VERSION |
| `security.yml` | cron 04:23 | secret scan |
| `sot.yml` | push main | validate-sot |

## 5. Hardcoded wartości w skryptach shell

### 5.1 `tools/verify/debt/scanner.sh` — master lista legacy
- **Legacy porty:** 17000 (aigon-runtime), 11408 (aigon-router), 7009 (maips UDP), 14008 (magic-router), 8080 (aigon-code-serwer), 58200 (vault)
- **Legacy nazwy usług:** aigon-nats, aigon-runtime, aigon-router, aigon-code-serwer, aigon-code-server, aigon-infra-vault, rtv2-runtime-master, runtime-v2-magic-router
- **Legacy hosty:** 100.98.144.70, 100.93.112.70, contabo, aigon-dev, aigon-prod
- **Legacy endpointy:** /v1/chat, /api/v1, /mcp, /health, /report
- **Legacy ENV:** AIGON_RUNTIME_SHARED_SECRET, AIGON_API_KEY, DEEPSEEK_API_KEY, CLOUDFLARE_TUNNEL_TOKEN
- **Legacy sieci:** aigon-nats, aigon-mesh, aigon-core
- **Legacy crate'y:** aigon-magic-router, aigon-kernel, aigon-code-mcp
- **Legacy configi:** agent-models.yaml, packages.yaml, gateway.yaml, stack.yaml
- **Legacy docs:** QWEN.md, AGENTS.md, KANON.md, MAP.md
- **Legacy SoT:** SOURCE-OF-TRUTH, OWNERSHIP, VERSION
- **Katalogi:** EXCLUDE='./.git/ ./archive/ ./tools/verify/', ALLOWED_DIRS='./archive/', QUARANTINE_DIRS='./archive/quarantine/'

### 5.2 `system/control-plane/state/lib.sh` — StateStore
- `STATE_DB="canonical-state.db"`, `STATE_SCHEMA_VERSION="2"`, `STATE_BACKUP_DIR`, `STATE_MIGRATIONS_DIR`, `STATE_DATA_DIR`

### 5.3 `tools/verify/reconcile/baseline.sh`
- `BASELINE_TAG="BASELINE-0.1.0"`, `ALLOWED_PATHS="tools/verify/ docs/00-foundation/"`

### 5.4 `tools/verify/core/profiles.sh` — VERIFY_MODULES
- 10 profili × 4 poziomy (fast/full/genesis) × severity (BLOCKING/WARNING)

### 5.5 `tools/verify/security/credentials.sh` — wzorce sekretów
- AWS `AKIA[0-9A-Z]{16}`, GCP `AIza...`, Azure `AccountKey=...`, DB URLs, LLM keys `sk-...`, Docker registry, Tailscale `tskey-...`, JWT `eyJ`

### 5.6 `tools/verify/git/*` — reguły git
- `main` kanoniczna, prefiksy branchy `feature/*|fix/*|migration/*|security/*|release/*`, prefiksy tagów `^(baseline-|v[0-9]|milestone-|release-|recovery-)`

### 5.7 `tools/repository-integrity.sh`
- Legacy ścieżki: /opt/aigon, /opt/projects/aigon-x, /opt/archive/aigon-x
- Próg dużych plików: +50M
- Wymagane pliki: .gitignore, .gitattributes, CODEOWNERS, VERSION, LICENSE, README.md, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md
- Wymagane katalogi: docs, governance, contracts, config, deployment, tests, tools, artifacts, archive

### 5.8 `system/control-plane/state/state.sh` — StateStore CLI
- 17 komend, `backup-retention "${2:-5}"` (domyślny retention 5)

## 6. Stan/konfiguracja w `system/`

### 6.1 `system/control-plane/state/schema.sql` — 25 tabel
- meta, cluster, node, runtime, service, image, network, port, volume, agent, skill, project, capability, configuration, policy, contract, deployment, baseline, snapshot, event, evidence, drift, debt, decision, artifact, document
- Statusy: CURRENT/CANONICAL/DEPRECATED/QUARANTINED/ARCHIVED/ALLOWED_LEGACY/UNKNOWN/DRIFT
- source_type: git/manual/runtime/migration

### 6.2 Migracje
- `0001_initial.sql` (schema v1), `0002_history_hash.sql` (schema v2)

### 6.3 State DB (GENERATED, gitignored)
- `canonical-state.db` — database_id `aigon-canonical-state`, schema v2, generation 0

## 7. Konfiguracja deployment/contracts/governance

Wszystkie STATUS: UNDEFINED / FOUNDATION PLACEHOLDER. Kluczowe deklaracje:
- **deployment/rings/rings.md**: RING 0-3 (development/staging/production/canary), immutable digests (bez `:latest`), compose profiles, promotion gate
- **deployment/images/images.md**: zakaz `:latest` w produkcji
- **deployment/secrets/secrets.md**: referencje sekretów (NIE same sekrety), rotation policy, Vault integration
- **contracts/**: evidence (cluster-health, health-evidence), mesh, runtime-abi, api — wszystkie UNDEFINED
- **governance/**: polityki, procedury, role, uprawnienia, decyzje

## 8. Referencje sekretów (`secrets/`)

- `secrets/README.md` — STATUS: FOUNDATION PLACEHOLDER, klasa CANONICAL, NIGDY nie przechowuje rzeczywistych sekretów
- `.gitignore` — blokada `*.env`, `*.pem`, `*.key`, `*.crt`, `*.p12`, `*.pfx`, `*.jks`, `secrets/**/*.secret/json/yaml/yml`
- Wzorce sekretów w `tools/verify/security/credentials.sh` (SEC-201..208)

## 9. Konfiguracja deklarowana w README

- **README.md**: Git=desired, Runtime=actual; 4 drzewa git; model gałęzi (main chroniona, bez develop); prefiksy branchy; łańcuch merge; granice architektury; 22 katalogi
- **DEPLOYMENT.md**: RING 0-3, immutable digests, compose profiles
- **SOURCE-OF-TRUTH.md**: Git=desired, single-owner, config/canonical=jedyny SoT, klasy sync (CANONICAL/REPLICATED/GENERATED/CACHE/SESSION/EPHEMERAL), validate-sot
- **OWNERSHIP.md**: 13 właścicieli (@aigon/architecture, platform, security, release, apps, runtime, fs, mesh, agents, models, observability, quality, business), granice własności
- **ARCHITECTURE.md**: warstwy business/apps/agents+models/system

## 10. Kluczowe wnioski (napędzają fazy 02-05)

1. **Brak plików JSON/ENV/TOML** — cała konfiguracja jest w shell scripts i README (nie w dedykowanych plikach config).
2. **`config/` jest pusty** — wszystkie STATUS: UNDEFINED. To jest główny cel OPERATION CONFIG ZERO.
3. **Master lista legacy** w `debt/scanner.sh` jest jedynym scentralizowanym źródłem wartości legacy.
4. **State subsystem** jest LIVE (SQLite, schema v2) — to jest fundament dla canonical operational state.
5. **Wzorce sekretów** są zdefiniowane w `credentials.sh` (SEC-201..208) — brak rzeczywistych sekretów w repo.
6. **README deklarują** model konfiguracji (CANONICAL/GENERATED/LOCAL, klasy sync, single-owner) — ale nie są zaimplementowane.
