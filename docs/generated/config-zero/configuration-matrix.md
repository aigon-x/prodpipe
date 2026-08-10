# Configuration Matrix — Value Classification

> OPERATION CONFIG ZERO — macierz klasyfikacji wartości konfiguracyjnych.
> Klasyfikacja: CANONICAL_CONFIG / DERIVED / IMMUTABLE_CONSTANT / SECURITY_CONSTANT / TEST_FIXTURE / DEFAULT / LOCAL / ENVIRONMENT / SECRET_REFERENCE / GENERATED / HARDCODED_VALID / HARDCODED_INVALID / MOCK / SHADOW / UNKNOWN

## 1. Taksonomia wartości

| Klasa | Definicja | Przykład |
|---|---|---|
| CANONICAL_CONFIG | Jedyne źródło prawdy konfiguracji | `config/canonical/` |
| DERIVED | Pochodna z canonical, NIGDY ręcznie edytowana | `config/generated/` |
| IMMUTABLE_CONSTANT | Stała niezmienna (nie konfiguracja) | `STATE_SCHEMA_VERSION="2"` |
| SECURITY_CONSTANT | Stała bezpieczeństwa (wzorzec, nie sekret) | regex `AKIA[0-9A-Z]{16}` |
| TEST_FIXTURE | Fixture testowe | `tests/` fixtures |
| DEFAULT | Wartość domyślna (nadpisywalna) | `backup-retention "${2:-5}"` |
| LOCAL | Specyficzna dla maszyny, NIGDY commitowana | `config/local/` |
| ENVIRONMENT | Zmienna środowiskowa | `AIGON_API_KEY` |
| SECRET_REFERENCE | Referencja do sekretu (nie sam sekret) | `secrets/templates/` |
| GENERATED | Wygenerowany artefakt | `canonical-state.db` |
| HARDCODED_VALID | Hardcoded, ale poprawny (stała) | `STATE_SCHEMA_VERSION` |
| HARDCODED_INVALID | Hardcoded, niepoprawny (drift) | legacy port `17000` |
| MOCK | Atrapa (nieprodukcyjna) | placeholder CI |
| SHADOW | Duplikacja logiki poza SoT | `.git-hooks/validate-sot` |
| UNKNOWN | Brak klasyfikacji | pliki bez statusu |

## 2. Macierz wartości konfiguracyjnych

### 2.1 Legacy wartości (z `tools/verify/debt/scanner.sh`)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| Port `17000` (aigon-runtime) | HARDCODED_INVALID | Legacy port, DRIFT |
| Port `11408` (aigon-router) | HARDCODED_INVALID | Legacy port, DRIFT |
| Port `7009` (maips UDP) | HARDCODED_INVALID | Legacy port, DRIFT |
| Port `14008` (magic-router) | HARDCODED_INVALID | Legacy port, DRIFT |
| Port `8080` (aigon-code-serwer) | HARDCODED_INVALID | Legacy port, DRIFT |
| Port `58200` (vault) | HARDCODED_INVALID | Legacy port, DRIFT |
| `aigon-nats` | HARDCODED_INVALID | Legacy service, DRIFT |
| `aigon-runtime` | HARDCODED_INVALID | Legacy service, DRIFT |
| `aigon-router` | HARDCODED_INVALID | Legacy service, DRIFT |
| `aigon-code-serwer` | HARDCODED_INVALID | Legacy service, DRIFT |
| `aigon-code-server` | HARDCODED_INVALID | Legacy service, DRIFT |
| `aigon-infra-vault` | HARDCODED_INVALID | Legacy service, DRIFT |
| `rtv2-runtime-master` | HARDCODED_INVALID | Legacy service, DRIFT |
| `runtime-v2-magic-router` | HARDCODED_INVALID | Legacy service, DRIFT |
| `100.98.144.70` | HARDCODED_INVALID | Legacy host, DRIFT |
| `100.93.112.70` | HARDCODED_INVALID | Legacy host, DRIFT |
| `contabo` | HARDCODED_INVALID | Legacy host, DRIFT |
| `aigon-dev` | HARDCODED_INVALID | Legacy host, DRIFT |
| `aigon-prod` | HARDCODED_INVALID | Legacy host, DRIFT |
| `/v1/chat` | HARDCODED_INVALID | Legacy endpoint, DRIFT |
| `/api/v1` | HARDCODED_INVALID | Legacy endpoint, DRIFT |
| `/mcp` | HARDCODED_INVALID | Legacy endpoint, DRIFT |
| `/health` | HARDCODED_INVALID | Legacy endpoint, DRIFT |
| `/report` | HARDCODED_INVALID | Legacy endpoint, DRIFT |
| `AIGON_RUNTIME_SHARED_SECRET` | ENVIRONMENT | Legacy env name |
| `AIGON_API_KEY` | ENVIRONMENT | Legacy env name |
| `DEEPSEEK_API_KEY` | ENVIRONMENT | Legacy env name |
| `CLOUDFLARE_TUNNEL_TOKEN` | ENVIRONMENT | Legacy env name |
| `aigon-nats` (sieć) | HARDCODED_INVALID | Legacy network |
| `aigon-mesh` (sieć) | HARDCODED_INVALID | Legacy network |
| `aigon-core` (sieć) | HARDCODED_INVALID | Legacy network |
| `aigon-magic-router` (crate) | HARDCODED_INVALID | Legacy crate |
| `aigon-kernel` (crate) | HARDCODED_INVALID | Legacy crate |
| `aigon-code-mcp` (crate) | HARDCODED_INVALID | Legacy crate |
| `agent-models.yaml` | HARDCODED_INVALID | Legacy config |
| `packages.yaml` | HARDCODED_INVALID | Legacy config |
| `gateway.yaml` | HARDCODED_INVALID | Legacy config |
| `stack.yaml` | HARDCODED_INVALID | Legacy config |
| `QWEN.md` | HARDCODED_INVALID | Legacy doc |
| `AGENTS.md` | HARDCODED_INVALID | Legacy doc |
| `KANON.md` | HARDCODED_INVALID | Legacy doc |
| `MAP.md` | HARDCODED_INVALID | Legacy doc |
| `SOURCE-OF-TRUTH` | HARDCODED_INVALID | Legacy SoT |
| `OWNERSHIP` | HARDCODED_INVALID | Legacy SoT |
| `VERSION` | HARDCODED_INVALID | Legacy SoT |

### 2.2 State subsystem (`system/control-plane/state/`)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `STATE_DB="canonical-state.db"` | IMMUTABLE_CONSTANT | Stała ścieżka |
| `STATE_SCHEMA_VERSION="2"` | IMMUTABLE_CONSTANT | Stała wersji schematu |
| `STATE_BACKUP_DIR` | DERIVED | Pochodna z STATE_DIR |
| `STATE_MIGRATIONS_DIR` | DERIVED | Pochodna z STATE_DIR |
| `STATE_DATA_DIR` | DERIVED | Pochodna z STATE_DIR |
| `canonical-state.db` | GENERATED | SQLite, gitignored |
| `backup-retention "${2:-5}"` | DEFAULT | Domyślny retention 5 |

### 2.3 Verify engine (`tools/verify/`)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `BASELINE_TAG="BASELINE-0.1.0"` | CANONICAL_CONFIG | Tag baseline |
| `ALLOWED_PATHS="tools/verify/ docs/00-foundation/"` | CANONICAL_CONFIG | Dozwolone ścieżki |
| `VERIFY_MODULES` (10 profili) | CANONICAL_CONFIG | Definicja modułów |
| `main` (kanoniczna gałąź) | IMMUTABLE_CONSTANT | Stała git |
| Prefiksy branchy `feature/*|fix/*|...` | CANONICAL_CONFIG | Reguła git |
| Prefiksy tagów `^(baseline-|v[0-9]|...)` | CANONICAL_CONFIG | Reguła git |
| 12 sekcji README | CANONICAL_CONFIG | Kontrakt README |
| `EXCLUDE='./.git/ ./archive/ ./tools/verify/'` | CANONICAL_CONFIG | Katalogi wykluczone |

### 2.4 Wzorce sekretów (`tools/verify/security/credentials.sh`)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `AKIA[0-9A-Z]{16}` | SECURITY_CONSTANT | Wzorzec AWS (nie sekret) |
| `AIza[0-9A-Za-z_-]{35}` | SECURITY_CONSTANT | Wzorzec GCP |
| `AccountKey=[A-Za-z0-9+/=]{40,}` | SECURITY_CONSTANT | Wzorzec Azure |
| `sk-[A-Za-z0-9]{20,}` | SECURITY_CONSTANT | Wzorzec LLM key |
| `tskey-[A-Za-z0-9_-]{20,}` | SECURITY_CONSTANT | Wzorzec Tailscale |
| `eyJ` (JWT) | SECURITY_CONSTANT | Wzorzec JWT |

### 2.5 CI workflows (`.github/workflows/`)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `cron: '17 3 * * *'` | CANONICAL_CONFIG | Harmonogram drift |
| `cron: '23 4 * * *'` | CANONICAL_CONFIG | Harmonogram security |
| `runs-on: ubuntu-latest` | CANONICAL_CONFIG | Runner |
| `concurrency: group: ci-${{ github.ref }}` | CANONICAL_CONFIG | Grupa concurrency |
| `image:.*:latest` (zakaz) | CANONICAL_CONFIG | Reguła prod |
| 7 workflow z placeholderami | MOCK | Placeholdery CI |

### 2.6 README-deklarowana konfiguracja

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| Git=desired, Runtime=actual | CANONICAL_CONFIG | Zasada nadrzędna |
| `config/canonical/` = jedyny SoT | CANONICAL_CONFIG | SoT config |
| Klasy sync (CANONICAL/REPLICATED/GENERATED/CACHE/SESSION/EPHEMERAL) | CANONICAL_CONFIG | Model sync |
| 13 właścicieli `@aigon/*` | CANONICAL_CONFIG | Macierz własności |
| RING 0-3 | CANONICAL_CONFIG | Pierścienie deployment |
| Zakaz `:latest` w prod | CANONICAL_CONFIG | Reguła deployment |

### 2.7 Shadow system

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `.git-hooks/validate-sot` | SHADOW | Duplikacja logiki weryfikacji poza tools/verify |
| `.git-hooks/pre-commit` | SHADOW | Duplikacja guardrails |
| `.git-hooks/pre-push` | SHADOW | Duplikacja reguł push |

### 2.8 UNKNOWN (bez klasyfikacji)

| Wartość | Klasa | Uzasadnienie |
|---|---|---|
| `.git-hooks/pre-push` | UNKNOWN | Brak klasyfikacji (DEBT-014) |
| `.git-hooks/pre-commit` | UNKNOWN | Brak klasyfikacji |
| `.git-hooks/validate-sot` | UNKNOWN | Brak klasyfikacji |
| `.git` | UNKNOWN | Brak klasyfikacji |
| `system/control-plane/state/schema.sql` | UNKNOWN | Brak klasyfikacji |
| `system/control-plane/state/migrations/*.sql` | UNKNOWN | Brak klasyfikacji |

## 3. Podsumowanie klasyfikacji

| Klasa | Liczba | Uwagi |
|---|---|---|
| HARDCODED_INVALID | 40 | Legacy wartości (DRIFT) |
| CANONICAL_CONFIG | 20 | Reguły, kontrakty, SoT |
| IMMUTABLE_CONSTANT | 4 | Stałe state subsystem |
| SECURITY_CONSTANT | 6 | Wzorce sekretów |
| DEFAULT | 1 | backup-retention |
| DERIVED | 3 | Ścieżki pochodne |
| GENERATED | 1 | canonical-state.db |
| ENVIRONMENT | 4 | Legacy env names |
| MOCK | 7 | Placeholdery CI |
| SHADOW | 3 | Duplikacja logiki |
| UNKNOWN | 6 | Brak klasyfikacji |

## 4. Kluczowe wnioski

1. **40 HARDCODED_INVALID** — legacy wartości w `debt/scanner.sh` to największa grupa. To są wartości DRIFT, które muszą być przeniesione do canonical config lub oznaczone jako ARCHIVED.
2. **6 UNKNOWN** — pliki bez klasyfikacji (DEBT-014). Muszą dostać klasyfikację.
3. **3 SHADOW** — `.git-hooks/*` duplikują logikę weryfikacji. Muszą być zintegrowane z `tools/verify` lub oznaczone.
4. **7 MOCK** — placeholdery CI. Muszą być oznaczone jako TEST_FIXTURE lub zaimplementowane.
5. **config/ jest pusty** — wszystkie STATUS: UNDEFINED. To jest główny cel: zdefiniować canonical config.
