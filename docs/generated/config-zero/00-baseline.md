# PHASE 00 — Immutable Baseline Snapshot

> OPERATION CONFIG ZERO — zrzut stanu przed jakimikolwiek zmianami.
> Data: 2026-08-10 | Worktree: `/opt/Prod-ready/.qwen/worktrees/config-zero` | Branch: `worktree-config-zero`

## 1. Cel

Utrwalenie niezmiennego punktu odniesienia (baseline) przed rozpoczęciem 46 faz OPERATION CONFIG ZERO.
Każda późniejsza zmiana jest mierzona względem tego zrzutu. Baseline jest **immutable** — nie modyfikowany
po utworzeniu; ewentualne korekty tworzą nowe wpisy w historii, nie nadpisują tego pliku.

## 2. Stan repozytorium (baseline)

| Atrybut | Wartość |
|---|---|
| Branch | `worktree-config-zero` |
| HEAD commit | `78587fd` — fix(state,verify): F5 backup-restore-test + verify_module_exit + migration 0002 |
| Baseline tag | `BASELINE-0.1.0` |
| Liczba plików (poza .git) | 534 |
| Working tree | czysty (przed zmianami) |
| VERSION | 0.1.0 |

## 3. Stan weryfikacji (baseline `verify.sh reconcile`)

Wynik: **CERTIFICATION: FAIL** (exit=1). 16 checks, 10 PASS, 6 FAIL.

### Failujące moduły / checks

| Check | Opis | Klasa |
|---|---|---|
| DEBT-002 | Legacy nazwy usług (aigon-nats, aigon-runtime, aigon-router, aigon-code-serwer, aigon-code-server, aigon-infra-vault, rtv2-runtime-master, runtime-v2-magic-router) | DRIFT |
| DEBT-005 | Legacy hostname / node ID (100.98.144.70, 100.93.112.70, contabo, aigon-dev, aigon-prod) | DRIFT |
| DEBT-006 | Legacy endpointy (/v1/chat, /api/v1, /mcp, /health, /report) | DRIFT |
| DEBT-007 | Legacy ENV (AIGON_RUNTIME_SHARED_SECRET, AIGON_API_KEY, DEEPSEEK_API_KEY, CLOUDFLARE_TUNNEL_TOKEN) | DRIFT |
| DEBT-012 | Legacy API / SoT (SOURCE-OF-TRUTH, OWNERSHIP, VERSION) | DRIFT |
| DEBT-014 | Status UNKNOWN — pliki bez klasyfikacji (.git-hooks/*, .git, state/schema.sql, migrations/*.sql) | UNKNOWN |

### Warnings (nie blokują, ale istotne)

| Check | Opis |
|---|---|
| BASE-002 | Branch `worktree-config-zero` (oczekiwano `main`) |
| DRIFT-004 | README z nieznaną sekcją: `docs/00-foundation/README.md` (`## Status`) |
| DRIFT-007 | Shadow system: `.git-hooks/validate-sot` — duplikacja logiki weryfikacji poza `tools/verify` |
| DRIFT-008 | 7 CI workflow z placeholderami (security, feature, regression, release, helios, drift, ci) |
| DRIFT-009 | pre-push blokuje main bez remote |
| DEBT-106 | 1 plik deprecated bez terminu spłaty |

## 4. Stan subsystemu state (baseline)

| Atrybut | Wartość |
|---|---|
| Database ID | `aigon-canonical-state` |
| Schema version | 2 |
| Generation | 0 |
| State hash | `c2129bd3d6064514f7ff89b93a5ca3df974735d5a5c61c122037433f737b5c96` |
| DB path | `system/control-plane/state/data/canonical-state.db` (GENERATED, gitignored) |
| Tabele | 25 (agent, artifact, baseline, capability, cluster, configuration, contract, debt, decision, deployment, document, drift, event, evidence, image, network, node, policy, port, project, runtime, service, skill, snapshot, volume) — wszystkie puste |

## 5. Stan konfiguracji (baseline)

| Obszar | STATUS |
|---|---|
| `config/canonical/schema.md` | UNDEFINED |
| `config/canonical/README.md` | UNDEFINED |
| `config/README.md` | FOUNDATION PLACEHOLDER |
| `SOURCE-OF-TRUTH.md` | UNDEFINED |
| `OWNERSHIP.md` | UNDEFINED |
| `MIGRATION.md` | UNDEFINED |

## 6. Znane problemy baseline (napędzają fazy)

1. **FALSE GATE** — 8 orphaned modułów verify (git/*, security/*, structure/readme.sh) kończy się `say ""`
   zamiast `verify_module_exit`; ich FAIL nie propaguje do procesu rodzica. Penalty: FALSE GATE → max 4/10.
2. **verify.sh nie uruchamia** modułów git/security/structure (tylko reconcile/drift/history/debt).
3. **verify_profile_modules** w `profiles.sh` nigdy nie wywoływany (GHOST).
4. **DEBT-014 UNKNOWN** — pliki bez klasyfikacji (git-hooks, state schema/migrations).
5. **Shadow system** — `.git-hooks/validate-sot` duplikuje logikę weryfikacji.
6. **config/ STATUS: UNDEFINED** — brak zdefiniowanego źródła konfiguracji.
7. **State DB** — zainicjalizowany w PHASE 00 (był nieistniejący).

## 7. Zmiany wprowadzone w PHASE 00

| Plik | Zmiana | Klasa |
|---|---|---|
| `.gitignore` | Dodano wyjątek `!docs/generated/config-zero/**` — deliverable CONFIG ZERO muszą być tracked | CONFIG |
| `system/control-plane/state/data/canonical-state.db` | Zainicjalizowano + zmigrowano do schema v2 (GENERATED, gitignored) | GENERATED |
| `docs/generated/config-zero/00-baseline.md` | Ten plik — baseline snapshot | DOCUMENT |

## 8. Weryfikacja po PHASE 00

`bash tools/verify/verify.sh reconcile` — wynik identyczny z baseline (CERTIFICATION: FAIL, te same 6 failów).
Żadna zmiana PHASE 00 nie wprowadziła nowych failów. (Zweryfikowano: `.gitignore` i `docs/generated/` nie są
w ALLOWED_PATHS baseline, więc nie zmieniają wyniku reconcile.)
