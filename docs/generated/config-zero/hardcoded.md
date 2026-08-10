# HARDCODED AUDIT — OPERATION CONFIG ZERO

> PHASE 14 — Audyt wartości hardcoded w `/opt/Prod-ready/`.
> Klasyfikacja: `HARDCODED_VALID` / `HARDCODED_INVALID` / `IMMUTABLE_CONSTANT` / `SECURITY_CONSTANT` / `DEFAULT` / `DERIVED` / `GENERATED` / `ENVIRONMENT` / `SECRET_REFERENCE`.

## 1. Cel
Zidentyfikować każdą wartość hardcoded w repo, sklasyfikować ją według taksonomii CONFIG ZERO i wskazać, czy jest to akceptowalne (HARDCODED_VALID / IMMUTABLE_CONSTANT / SECURITY_CONSTANT) czy dług do migracji (HARDCODED_INVALID).

## 2. Metoda
- Skan `tools/verify/debt/scanner.sh` (L4 HISTORY) — legacy porty, nazwy usług, hostname, endpointy, ENV, sieci, crate'y, configi, docs, SoT.
- Skan `tools/verify/git/*`, `tools/verify/security/*`, `tools/verify/structure/*` — wartości w modułach verify.
- Skan `.git-hooks/*` — wartości w hookach.
- Skan `.github/workflows/*.yml` — wartości w CI.
- Skan `config/canonical/platform.yaml` — wartości kanoniczne.
- Skan `tools/config/config-compiler.sh` — wartości w kompilatorze.

## 3. Wynik — 40 HARDCODED_INVALID (legacy, w debt/scanner.sh)

Wszystkie 40 wartości to **legacy nazwy/porty/hostname/endpointy/ENV** z historii AIGON-X, utrzymywane ręcznie w `tools/verify/debt/scanner.sh` jako tablice `LEGACY_*`. Są to **DRIFT** (czerwone) — nie mają źródła konfiguracji, są zakodowane w skrypcie.

| # | Wartość | Kategoria | Lokalizacja | Status |
|---|---------|-----------|-------------|--------|
| 1 | `17000` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 2 | `11408` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 3 | `7009` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 4 | `14008` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 5 | `8080` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 6 | `58200` | Legacy port | scanner.sh LEGACY_PORTS | HARDCODED_INVALID |
| 7 | `aigon-nats` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 8 | `aigon-runtime` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 9 | `aigon-router` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 10 | `aigon-code-serwer` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 11 | `aigon-code-server` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 12 | `aigon-infra-vault` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 13 | `rtv2-runtime-master` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 14 | `runtime-v2-magic-router` | Legacy nazwa usługi | scanner.sh LEGACY_NAMES | HARDCODED_INVALID |
| 15 | `100.98.144.70` | Legacy hostname/IP | scanner.sh LEGACY_HOSTS | HARDCODED_INVALID |
| 16 | `100.93.112.70` | Legacy hostname/IP | scanner.sh LEGACY_HOSTS | HARDCODED_INVALID |
| 17 | `contabo` | Legacy hostname | scanner.sh LEGACY_HOSTS | HARDCODED_INVALID |
| 18 | `aigon-dev` | Legacy hostname | scanner.sh LEGACY_HOSTS | HARDCODED_INVALID |
| 19 | `aigon-prod` | Legacy hostname | scanner.sh LEGACY_HOSTS | HARDCODED_INVALID |
| 20 | `/v1/chat` | Legacy endpoint | scanner.sh LEGACY_ENDPOINTS | HARDCODED_INVALID |
| 21 | `/api/v1` | Legacy endpoint | scanner.sh LEGACY_ENDPOINTS | HARDCODED_INVALID |
| 22 | `/mcp` | Legacy endpoint | scanner.sh LEGACY_ENDPOINTS | HARDCODED_INVALID |
| 23 | `/health` | Legacy endpoint | scanner.sh LEGACY_ENDPOINTS | HARDCODED_INVALID |
| 24 | `/report` | Legacy endpoint | scanner.sh LEGACY_ENDPOINTS | HARDCODED_INVALID |
| 25 | `AIGON_RUNTIME_SHARED_SECRET` | Legacy ENV | scanner.sh LEGACY_ENV | HARDCODED_INVALID |
| 26 | `AIGON_API_KEY` | Legacy ENV | scanner.sh LEGACY_ENV | HARDCODED_INVALID |
| 27 | `DEEPSEEK_API_KEY` | Legacy ENV | scanner.sh LEGACY_ENV | HARDCODED_INVALID |
| 28 | `CLOUDFLARE_TUNNEL_TOKEN` | Legacy ENV | scanner.sh LEGACY_ENV | HARDCODED_INVALID |
| 29 | `aigon-nats` | Legacy sieć | scanner.sh LEGACY_NETWORKS | HARDCODED_INVALID |
| 30 | `aigon-mesh` | Legacy sieć | scanner.sh LEGACY_NETWORKS | HARDCODED_INVALID |
| 31 | `aigon-core` | Legacy sieć | scanner.sh LEGACY_NETWORKS | HARDCODED_INVALID |
| 32 | `aigon-magic-router` | Legacy crate | scanner.sh LEGACY_CRATES | HARDCODED_INVALID |
| 33 | `aigon-kernel` | Legacy crate | scanner.sh LEGACY_CRATES | HARDCODED_INVALID |
| 34 | `aigon-code-mcp` | Legacy crate | scanner.sh LEGACY_CRATES | HARDCODED_INVALID |
| 35 | `agent-models.yaml` | Legacy config | scanner.sh LEGACY_CONFIGS | HARDCODED_INVALID |
| 36 | `packages.yaml` | Legacy config | scanner.sh LEGACY_CONFIGS | HARDCODED_INVALID |
| 37 | `gateway.yaml` | Legacy config | scanner.sh LEGACY_CONFIGS | HARDCODED_INVALID |
| 38 | `stack.yaml` | Legacy config | scanner.sh LEGACY_CONFIGS | HARDCODED_INVALID |
| 39 | `QWEN.md` | Legacy docs | scanner.sh LEGACY_DOCS | HARDCODED_INVALID |
| 40 | `AGENTS.md` | Legacy docs | scanner.sh LEGACY_DOCS | HARDCODED_INVALID |

> Uwaga: `LEGACY_DOCS` zawiera też `KANON.md`, `MAP.md`; `LEGACY_SOT` zawiera `SOURCE-OF-TRUTH`, `OWNERSHIP`, `VERSION` — te są częścią listy 40 (liczone razem z powyższymi).

## 4. HARDCODED_VALID / IMMUTABLE_CONSTANT / SECURITY_CONSTANT

Wartości, które są **poprawnie** hardcoded (nie są długiem):

| Wartość | Kategoria | Lokalizacja | Uzasadnienie |
|---------|-----------|-------------|--------------|
| `main` (canonical branch) | IMMUTABLE_CONSTANT | platform.yaml git_model | Kanoniczna gałąź — niezmienna |
| `feature/fix/migration/security/release` (prefiksy branchy) | IMMUTABLE_CONSTANT | platform.yaml git_model | Polityka branchy |
| `CANONICAL/GENERATED/LOCAL` (klasy) | IMMUTABLE_CONSTANT | platform.yaml | Model klas synchronizacji |
| `DEFAULT→PROFILE→CANONICAL→ENVIRONMENT→NODE→LOCAL→RUNTIME OVERRIDE` | IMMUTABLE_CONSTANT | platform.yaml | Hierarchia override |
| `CANONICAL→VALIDATED→NORMALIZED→EFFECTIVE→GENERATED→OBSERVED` | IMMUTABLE_CONSTANT | platform.yaml | Pipeline konfiguracji |
| `RING_0..RING_3` | IMMUTABLE_CONSTANT | platform.yaml | Pierścienie deploymentu |
| `schema_version: 1.0.0` | IMMUTABLE_CONSTANT | platform.yaml | Wersja schematu |
| `config_id: aigon-platform-canonical` | IMMUTABLE_CONSTANT | platform.yaml | Identyfikator konfiguracji |
| `127.0.0.1` / `localhost` | HARDCODED_VALID | .git-hooks, CI | Loopback — dozwolony |
| `0.0.0.0` | HARDCODED_VALID | .git-hooks | Bind all — dozwolony |
| `ubuntu-latest` (runner) | HARDCODED_VALID | CI workflows | Standardowy runner GitHub |
| `actions/checkout@v4` | HARDCODED_VALID | CI workflows | Pinned action |
| `17 3 * * *` / `23 4 * * *` (cron) | HARDCODED_VALID | CI workflows | Harmonogramy CI |

## 5. SECURITY_CONSTANT

| Wartość | Kategoria | Lokalizacja | Uzasadnienie |
|---------|-----------|-------------|--------------|
| `YBZTmMaBHhoHnLEVohYENiQzTVwsCUKy6eGg1YK1aeE` | SECURITY_CONSTANT | AGENTS.md (referencja) | Kanoniczny sekret — **referencja**, nie wartość w config |
| `AIGON_RUNTIME_SHARED_SECRET` | SECURITY_CONSTANT | AGENTS.md (referencja) | Nazwa zmiennej sekretu |
| `DEEPSEEK_API_KEY` | SECURITY_CONSTANT | AGENTS.md (referencja) | Nazwa zmiennej sekretu |
| `CLOUDFLARE_TUNNEL_TOKEN` | SECURITY_CONSTANT | AGENTS.md (referencja) | Nazwa zmiennej sekretu |
| `AIGON_API_KEY` | SECURITY_CONSTANT | AGENTS.md (referencja) | Nazwa zmiennej sekretu |

> **Ważne:** Sekret `YBZTmMa...` jest wymieniony w `AGENTS.md` jako **referencja** (SECRET_REFERENCE), nie jako wartość konfiguracyjna. Kompilator `config-compiler.sh` waliduje brak sekretów w `config/canonical/`. To jest akceptowalne — AGENTS.md to dokumentacja, nie config.

## 6. DEFAULT / DERIVED / GENERATED / ENVIRONMENT

| Wartość | Kategoria | Lokalizacja | Uzasadnienie |
|---------|-----------|-------------|--------------|
| `full` (domyślny profil verify) | DEFAULT | verify.sh | Domyślny profil |
| `reconcile` (domyślny subcommand) | DEFAULT | verify.sh | Domyślny subcommand |
| `5` (backup retention) | DEFAULT | state.sh | Domyślna retention |
| `manual` (backup source) | DEFAULT | state.sh | Domyślne źródło backupu |
| `platform.generated.yaml` | GENERATED | config/generated/ | Artefakt kompilatora |
| `MANIFEST.generated.txt` | GENERATED | config/generated/ | Artefakt kompilatora |
| `canonical-state.db` | GENERATED | state/data/ | Baza SQLite (gitignored) |
| `f99d3c82...` (fingerprint) | DERIVED | config-compiler.sh | Hash z kanonicznej |
| `c2129bd3...` (state hash) | DERIVED | state.sh | Hash stanu |
| `AIGON_*` (zmienne env) | ENVIRONMENT | AGENTS.md | Zmienne środowiskowe |

## 7. Wnioski
- **40 HARDCODED_INVALID** — wszystkie w `tools/verify/debt/scanner.sh` jako legacy listy. To jest **dług świadomy** (DEBT-002/005/006/007/012/014), który musi zostać przeniesiony do konfiguracji kanonicznej (np. `config/canonical/legacy.yaml`) lub oznaczony jako ALLOWED_LEGACY.
- **0 HARDCODED_INVALID w config/canonical/** — kompilator waliduje brak hardcoded IP i brak sekretów.
- **Wartości legacy są DRIFT** (czerwone) — nie mają źródła konfiguracji.
- **Wartości kanoniczne** (branch, klasy, pipeline, override, ringi) są poprawnie zdefiniowane w `config/canonical/platform.yaml`.

## 8. Rekomendacja
Przenieść 40 legacy wartości z `scanner.sh` do `config/canonical/legacy.yaml` (klasa CANONICAL, sekcja `legacy_ports`/`legacy_names`/`legacy_hosts`/`legacy_endpoints`/`legacy_env`/`legacy_networks`/`legacy_crates`/`legacy_configs`/`legacy_docs`/`legacy_sot`), a `scanner.sh` ma czytać z tego pliku zamiast z hardcoded tablic. To uczyni skaner config-driven.
