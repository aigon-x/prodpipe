# SONDA — Bezstratna kartografia szkieletu AIGON Production Platform

> Pakiet kontekstowy (read-only) wygenerowany przez subagenta Explore.
> Źródło dla AUDYT v1.0. Repo: `/opt/Prod-ready/` — 43 elementy na poziomie root.
> Tryb: READ-ONLY (Z1) — zero modyfikacji, zero zapisu kodu.
> Metoda: cytowanie ścieżek + identyfikatorów checków + konkretnych fragmentów (Z2); ABSENT z dowodem (Z3); PARTIAL z dowodem co jest vs czego brak (Z4); self-check per sekcja (Z5); żadna sekcja nie pominięta (Z6).

---

## A. INTEG — integralność git

**Mechanizmy z dowodami:**

- **`tools/verify/git/integrity.sh`** — moduł GIT INTEGRITY, checki **GIT-001..019** (nagłówek pliku, linie 8-27):
  - `GIT-001 Git initialized`, `GIT-002 main branch exists`, `GIT-003 Working tree clean (informational)`, `GIT-004 No nested git repositories`, `GIT-005 No submodules`, `GIT-006 Not detached HEAD`, `GIT-007 No orphan branches`, `GIT-008 No untracked files`, `GIT-009 No accidental executable bits`, `GIT-010 No symlinks`, `GIT-011 No case collisions`, `GIT-012 Git attributes present`, `GIT-013 Git config sanity`, `GIT-014 Hooks integrity`, `GIT-015 No branch divergence`, `GIT-016 Remote mismatch`, `GIT-017 Tag immutability`, `GIT-018 Protected branches`, `GIT-019 No force-push policy violation`.
  - Fragment: `pass "GIT-001 Git initialized"` / `fail "GIT-001 Git initialized" BLOCKING "Brak katalogu .git — repo nie jest zainicjalizowane."`
- **`tools/verify/git/branches.sh`** — checki **GIT-201..203**: `GIT-201 Branch prefix policy` (dozwolone prefiksy `feature/*, fix/*, migration/*, security/*, release/*`), `GIT-202 main is canonical`, `GIT-203 No direct push to main`.
- **`tools/verify/git/history.sh`** — checki **GIT-101..108** (historia git).
- **`tools/verify/git/tags.sh`** — checki **GIT-301..303**: `GIT-301 Tag naming policy`, `GIT-302 Tags are annotated`, `GIT-303 Prod tags immutable`.
- **`.git-hooks/pre-commit`** — secret scan, hardcoded IP, `:latest` image.
- **`.git-hooks/pre-push`** — branch prefix policy, no direct push to main, local bare repo exception.
- **`.git-hooks/validate-sot`** — SoT duplicates, hardcoded IP, secrets, `:latest`, unmarked data.
- **`.gitattributes`** — LF normalization, binary, `merge=union`.
- **`.gitignore`** — secrets, build artifacts, `.qwen/`, canonical state DB, AIGON-X-FS data.

**Self-check: COMPLETE** — wszystkie checki GIT-001..019, GIT-101..108, GIT-201..203, GIT-301..303 zidentyfikowane z konkretnymi fragmentami; haki git i pliki konfiguracyjne potwierdzone.

---

## B. StateStore / PERM / RES

**Mechanizmy z dowodami:**

- **`system/control-plane/state/schema.sql`** — 24 encje + meta. `CREATE TABLE` dla: `meta`, `cluster`, `node`, `runtime`, `service`, `image`, `network`, `port`, `volume`, `agent`, `skill`, `project`, `capability`, `configuration`, `policy`, `contract`, `deployment`, `baseline`, `snapshot`, `event`, `evidence`, `drift`, `debt`, `decision`, `artifact`, `document` (26 trafień `CREATE TABLE`).
- **`system/control-plane/state/lib.sh`** — `STATE_SCHEMA_VERSION="16"` (linia 24); funkcje `state_init`, `state_migrate`, `state_generation`, `state_hash`, `state_history_hash`, `state_snapshot`, `state_backup_*`, `state_restore`, `state_verify`, `state_rollback_*`.
- **`system/control-plane/state/state.sh`** — komendy `init/migrate/generation/bump/hash/snapshot/backup/restore/verify/status/rollback`.
- **Migracje** (`system/control-plane/state/migrations/`): `0001_initial.sql`, `0002_history_hash.sql`, `0003_gate_runs_waivers.sql`, `0007_config_plane.sql`. **0004 i 0005 ABSENT** (glob `migrations/*.sql` → tylko 4 pliki).
- **`system/control-plane/state/tests/test_state.sh`** — testy **T1-T15**: fresh db, migration, idempotency, duplicate identity, invalid schema, generation, state hashing, snapshot, verify, rollback, history hash, tamper detection **F4**, backup manifest **F5**, restore test, retention.

**PERM / RES:** patrz sekcje L i K — checki `PERM-*` i `RES-*` ABSENT (dowód w sekcji L/K).

**Self-check: COMPLETE** (StateStore) — schema 24+ encji, wersja 6, 4 migracje, funkcje lib.sh, testy T1-T15 potwierdzone. **PARTIAL** (PERM/RES) — patrz sekcje L/K.

---

## C. SELF-001 / G-gates / VV

**Mechanizmy z dowodami:**

- **`tools/verify/self-profile-integrity.sh`** — **SELF-001** Profile Integrity Gate (META-GATE). Fragment: `fail "SELF-001 module $module" BLOCKING "Brak skryptu: $script (ghost moduł)"`. Ghost detection fail-closed: moduł zadeklarowany w `VERIFY_MODULES` bez skryptu = FAIL (BLOCKING), nigdy skip. Na końcu `evidence_record "verify:self-profile-integrity:PASS/FAIL..."`.
- **`tools/verify/core/lib.sh`** — `evidence_record` (evidence bridge P0#1), `verify_evidence_complete` (meta-gate **VERIFY-EVIDENCE-COMPLETE**). Fragment: `fail "VERIFY-EVIDENCE-COMPLETE" BLOCKING "Zapisano $VERIFY_EVIDENCE_COUNT/$expected evidence (oczekiwano $expected) — gate bez evidence = 0 punktów"`.
- **`tools/verify/verify.sh`** — SELF-001 zawsze uruchamiany pierwszy; subkomendy `reconcile/drift/history/debt/waivers`; `run_module` agreguje FAIL-y.
- **`tools/verify/core/profiles.sh`** — `VERIFY_MODULES` (34 wpisy), `verify_profile_modules`, `verify_module_severity`, `module_script`. GENERATED FILE — edytuj `config/canonical/gates.yaml` + `gen-profiles.sh`.
- **`tools/verify/core/gen-profiles.sh`** — generator profiles.sh z gates.yaml (metadata-driven).
- **`tools/verify/core/report.sh`** — `verify_header`, `verify_module_report`, `verify_block_message`, `verify_success_message`.
- **`tools/verify/structure/readme.sh`** — checki **STR-001..003**.

**G-gates (G0-G8)** — mapa w `ARCHITECTURE.md` sekcja 9.2 (linie 90-102):
- G0 pre-commit **REALNY** (blokujący), G1 pre-push **REALNY**, G2 build **MISSING**, G3 commit-msg/signed **CZĘŚCIOWO**, G4 SBOM/SLSA **PLACEHOLDER**, G5 anti-drift **PLACEHOLDER**, G6 anti-shadow **MISSING**, G7 anti-entropy **MISSING**, G8 governance **SZKIELET**, META SELF-001 **REALNY**, META VERIFY-EVIDENCE-COMPLETE **REALNY**.

**VV (verification/validation):** patrz sekcja I (testy) — brak osobnego modułu VV; testy w `tools/verify/tests/`.

**Self-check: COMPLETE** — SELF-001, VERIFY-EVIDENCE-COMPLETE, profiles.sh, gen-profiles.sh, report.sh, STR-001..003, mapa G0-G8 z ARCHITECTURE.md 9.2 potwierdzone.

---

## D. G0-G8 / SEC-D / SoD

**Mechanizmy z dowodami:**

- **G0-G8:** mapa w `ARCHITECTURE.md` sekcja 9.2 (szczegóły w sekcji C). Status: PARTIAL — G0/G1 REALNY, G2/G6/G7 MISSING, G4/G5 PLACEHOLDER, G3 CZĘŚCIOWO, G8 SZKIELET.
- **SEC-D / SoD (separation of duties):** **ABSENT**. Grep `SEC-A|SEC-D|SoD|separation.of.duties` w `/opt/Prod-ready` → **No matches found**. Jedyny kontekst "SEC D/A/R/C" pojawia się w `docs/architecture/aesthetics-plane-design.md` (wiersz 89: "3 niezależne domeny zaufania") jako wymiar doskonałości #3, ale bez implementacji checków SEC-D.

**Self-check: PARTIAL** — G0-G8 udokumentowane w ARCHITECTURE.md 9.2 (dowód: tabela linie 94-102); SEC-D/SoD ABSENT (dowód: grep brak wyników).

---

## E. META / CORR

**Mechanizmy z dowodami:**

- **META:** `ARCHITECTURE.md` sekcja 9.2 — META SELF-001 **REALNY**, META VERIFY-EVIDENCE-COMPLETE **REALNY** (dowód w sekcji C). `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #13 "Dowodliwość | META | System dowodzi sam siebie: fire drills, assurance case, VERIFY-SYSTEM" — ale to **design doc**, nie implementacja.
- **CORR (uczenie się / korekty):** **ABSENT** jako check ID. Grep `CORR-[0-9]{3}` → **No matches found**. Jedyny kontekst: `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #14 "Uczenie się | CORR + escape | Każdy incydent → waiver/gap/missing-gate → backlog sam się pisze" — design doc, bez implementacji.

**Self-check: PARTIAL** — META SELF-001 + VERIFY-EVIDENCE-COMPLETE REALNY (dowód: self-profile-integrity.sh, lib.sh); CORR ABSENT jako check ID (dowód: grep brak wyników), obecny tylko jako wymiar w design doc.

---

## F. Check ID registry / waiver hygiene

**Mechanizmy z dowodami:**

- **Reconciliation engine** (`tools/verify/core/reconcile.sh`): model 4 warstw CANON/DRIFT/HISTORY/DEBT; statusy CURRENT/CANONICAL/DEPRECATED/QUARANTINED/ARCHIVED/ALLOWED_LEGACY/UNKNOWN/DRIFT; poziomy L0-L4; funkcje `recon_begin/cell/end/print_table/status/baseline_diff/reset/db/record_debt`. Fragment: `fail "RECON-UNKNOWN $name" BLOCKING "Status UNKNOWN (czerwony): $detail"`.
- **`tools/verify/debt/scanner.sh`** — checki **DEBT-001..014** (legacy porty, nazwy usług, kontenery, tagi obrazów, hostname, endpointy, ENV, sieci Docker, crate'y, configi, docs, API/SoT, backupi/symlinki, Status UNKNOWN).
- **`tools/verify/debt/debt.sh`** — checki **DEBT-101..106** (dług świadomy, ukryty, w archive/, w quarantine/, bez właściciela, bez terminu spłaty).
- **`tools/verify/waivers/sweeper.sh`** — checki **WAIVER-101..103**: `WAIVER-101 Wygasłe waivery usunięte (sweep)`, `WAIVER-102 Waiver bez expires_at — NIELEGALNY (konstytucja)`, `WAIVER-103 Tabela waivers istnieje`.
- **`tools/verify/drift/drift.sh`** — checki **DRIFT-001..009** (README sections, SoT STATUS, OWNERSHIP STATUS, shadow system, CI placeholders, pre-push/remote).
- **`tools/verify/history/history.sh`** — checki **HIST-001..007** (archive struktura, archive README, migracje, stale refs, deprecated markery, CHANGELOG, VERSION).
- **`tools/verify/reconcile/baseline.sh`** — checki **BASE-001..006** (tag BASELINE-0.1.0, HEAD na main, working tree czysty, zmiany oczekiwane/nieoczekiwane, nowe pliki).
- **`tools/verify/reconcile/reconcile.sh`** — orkiestrator **RECON-CANON/DRIFT/HISTORY/DEBT/BASELINE** (deleguje do warstw).
- **Waiver hygiene (konstytucja):** `config/canonical/registry.yaml` — waivers `wv-e2e-legacy-suite` (expires 2026-09-01), `wv-deps-outdated-q3` (expires 2026-09-30); kill_switches `ks-deploy-freeze` (expires 2026-08-12), `ks-migration-hold` (expires 2026-08-13). Fragment: `waivers:` sekcja — każdy waiver ma `expires_at`. `config/canonical/config_exemptions.yaml` — `waivers.expiry_mandatory` (niekonfigurowalne).

**Self-check: COMPLETE** — pełny rejestr check ID (DEBT-001..014, DEBT-101..106, WAIVER-101..103, DRIFT-001..009, HIST-001..007, BASE-001..006, RECON-*), waiver hygiene z expires_at potwierdzona w registry.yaml.

---

## G. CFG-001..008

**Mechanizmy z dowodami:**

- **`tools/verify/config/config.sh`** (432 linie) — checki **CFG-001..008**:
  - `CFG-001 Jednokanałowość` — zakaz getenv/jq poza lib/config.sh (BLOCKING).
  - `CFG-002 Schema` — registry.yaml zgodny z registry.schema.json (BLOCKING, fail-closed przy braku registry).
  - `CFG-003 Klucze` — każdy klucz ma floor, owner, tier, doc, reload (BLOCKING).
  - `CFG-004 Docs` — każdy klucz ma doc (WARNING).
  - `CFG-005 Defaulty` — każdy default >= floor (BLOCKING).
  - `CFG-006 Waivers` — każdy waiver ma expires_at (BLOCKING).
  - `CFG-007 Kill-switches` — każdy kill-switch ma expires_at (BLOCKING).
  - `CFG-008 Konstytucja` — klucze niekonfigurowalne nie są konfigurowalne (BLOCKING).
  - Fragment: `fail "CFG-002 Schema" BLOCKING "Brak źródła prawdy: $REGISTRY — registry.yaml nie istnieje (fail-closed)."` — przy braku registry wszystkie CFG-003..008 FAIL.
- **`tools/verify/core/config.sh`** (1159 linii) — resolver L0-L7: `config_resolve`, `config_get`, `config_trace`, `config_simulate`, `config_ratchet_update`, `config_kill_switch_check`, `config_exemption_check`, `config_load_registry`, `config_classify_context`, `config_apply_layers`, `config_floor_direction`, `config_has_waiver`, `config_validate_final`, `config_materialize_snapshot`, `config_fatal`, `config_require_sqlite`, `config_state_db`.
- **`config/canonical/registry.yaml`** (380 linii) — `schema_version: 1`; ~25 kluczy gates (git/security/structure/architecture/dependencies/reproducibility/deployment/contracts/migration/recovery + cfg.*); profiles; context_rules (hotfix-narrow-scope, migration-touch, tier1-critical, legacy-deps-relax); waivers; kill_switches.
- **`config/canonical/config_exemptions.yaml`** — exemptions: `evidence.persist_to_db`, `self.fail_closed`, `waivers.expiry_mandatory`, `floors.enforcement`, `config.load_validation`, `config.single_channel_get`; root_bootstrap: `bootstrap.db_path`, `bootstrap.registry_path`.
- **`config/schemas/registry.schema.json`** — JSON Schema draft-07.
- **`config/examples/registry.example.yaml`** — przykład.
- **`config/canonical/gates.yaml`** — 10 modułów + profiles (metadata-driven źródło dla profiles.sh).
- **`docs/architecture/config-plane-design.md`** — design doc: warstwy L0-L7, 4 prawa configu, CFG-SIM, self-hosting.

**Self-check: COMPLETE** — CFG-001..008 z fragmentami, resolver L0-L7, registry.yaml, config_exemptions.yaml, schema.json, gates.yaml, design doc potwierdzone.

---

## H. docs-plane / CONS-06

**Mechanizmy z dowodami:**

- **`docs/00-foundation/`** (10 plików): `DOCUMENTATION-CONSTITUTION.md`, `DOCUMENT-TYPES.md`, `DOCUMENT-LIFECYCLE.md`, `DOCUMENT-METADATA.md`, `SOURCE-OF-TRUTH.md`, `DOCUMENTATION-AGENT-BOUNDARY.md`, `DOCUMENTATION-FS-BOUNDARY.md`, `GIT-DOCUMENTATION-BOUNDARY.md`, `RUNTIME-DOCUMENTATION-BOUNDARY.md`, `README.md`. Wszystkie `STATUS: FOUNDATION PLACEHOLDER`, `Owner: UNASSIGNED`.
  - `DOCUMENT-TYPES.md` — 20 kanonicznych typów dokumentów (README, SPEC, PRD, RFC, DESIGN, ARCHITECTURE, ADR, POLICY, CONTRACT, SCHEMA, RUNBOOK, SOP, TEST-PLAN, TEST-REPORT, THREAT-MODEL, MIGRATION, INCIDENT, POSTMORTEM, BASELINE, RELEASE-NOTES).
  - `DOCUMENT-LIFECYCLE.md` — statusy DRAFT/PROPOSED/ACTIVE/STALE/SUPERSEDED/DEPRECATED/ARCHIVED + dozwolone/zabronione przejścia.
  - `DOCUMENT-METADATA.md` — front matter kontrakt (id, type, title, status, owner, source_of_truth, created, updated, version, supersedes, superseded_by, consumers).
  - `DOCUMENTATION-CONSTITUTION.md` — hierarchia źródeł prawdy L0-L6, "Search before create", "Nie twórz dokumentacyjnego legacy".
- **`docs/architecture/`** — `config-plane-design.md`, `aesthetics-plane-design.md`, `README.md`.
- **`docs/decisions/README.md`** — katalog decyzji; `STATUS: UNDEFINED`; rejestr ADR kanoniczny w `governance/decisions/`.
- **`docs/git`, `docs/operations`, `docs/reference`, `docs/security`, `docs/user`, `docs/development`, `docs/generated`** — katalogi docs.
- **CONS-06:** **ABSENT** jako check ID. Grep `CONS-[0-9]{3}` → **No matches found**. Jedyny kontekst: `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #11 "Spójność | CONS | Jeden styl org-wide: layout, API, logi, błędy, docs" — design doc, bez implementacji checków CONS-*.

**Self-check: PARTIAL** — docs-plane kompletny (10 plików foundation + katalogi docs, wszystkie FOUNDATION PLACEHOLDER); CONS-06 ABSENT jako check ID (dowód: grep brak wyników), obecny tylko jako wymiar w design doc.

---

## I. VV matrix

**Mechanizmy z dowodami:**

- **`tools/verify/tests/test-config-gates.sh`** — testy **T1-T4** (CFG-002/005/006/008).
- **`tools/verify/tests/test-config-resolver.sh`** — testy **T1-T15** (config_resolve, config_get, config_fatal exit 2, tighten/relax, THRESHOLD_LOOSENED, tier parsing).
- **`tools/verify/tests/test-evidence-completeness.sh`** — testy **T1-T4** (SELF-001 ghost detection, evidence bridge, VERIFY-EVIDENCE-COMPLETE).
- **`tools/verify/tests/test-metadata-driven.sh`** — testy **T1-T5** (gen-profiles.sh → profiles.sh).
- **`tools/verify/tests/test-waiver-sweeper.sh`** — testy **T1-T4** (expired/active/no-expiry waivers).
- **`system/control-plane/state/tests/test_state.sh`** — testy **T1-T15** (szczegóły w sekcji B).

**VV matrix:** brak osobnego modułu VV; `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #2 "Poprawność | G0–G5 + VV | Każdy check ma test pozytywny + negatywny + mutation score | VV coverage = 100% × mutation ≥ próg" — design doc, bez implementacji macierzy VV.

**Self-check: PARTIAL** — 5 plików testowych (T1-T15, T1-T4, T1-T4, T1-T5, T1-T4) + test_state.sh (T1-T15) potwierdzone; macierz VV jako taka (coverage × mutation) ABSENT — tylko design doc.

---

## J. CUR / OPT / supply chain

**Mechanizmy z dowodami:**

- **CI workflows** (`/opt/Prod-ready/.github/workflows/`): `ci.yml`, `drift.yml`, `feature.yml`, `helios.yml`, `regression.yml`, `release.yml`, `security.yml`, `sot.yml` — wszystkie **placeholdery** (potwierdzone przez `tools/verify/drift/drift.sh` check `DRIFT-008 CI placeholders`).
- **`tools/`** — katalogi: `automation`, `ci`, `migration`, `scripts`, `security`, `utilities`, `validation`, `verify`, `README.md`, `repository-integrity.sh`. Katalogi `automation/ci/migration/scripts/utilities/validation` zawierają tylko `.gitkeep` + `README.md` (placeholdery, `STATUS: UNDEFINED`).
- **`tools/security/secret-scan.sh`** — gitleaks/trufflehog/git-secrets/heuristic fallback.
- **`tools/repository-integrity.sh`** — narzędzie integrity.
- **CUR / OPT:** **ABSENT** jako check ID. Grep `CUR-[0-9]{3}|OPT-[0-9]{3}` → **No matches found** (jedyne trafienia to ADR-0001, niezwiązane). Kontekst design doc: `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #7 "Świeżość | CUR | Nic nie EOL; lag wersji w budżecie" i #8 "Optymalność | OPT + EFF | Każda decyzja tech w TDR z revisit_trigger".
- **Supply chain:** brak SBOM/SLSA (G4 PLACEHOLDER w ARCHITECTURE.md 9.2); `dependencies` moduł zadeklarowany w profiles.sh/gates.yaml, ale skrypt `dependencies/dependencies.sh` — patrz sekcja N (nie potwierdzono istnienia).

**Self-check: PARTIAL** — CI workflows (8 plików, placeholdery), tools/ (placeholdery), secret-scan.sh, repository-integrity.sh potwierdzone; CUR/OPT ABSENT jako check ID (dowód: grep brak wyników), supply chain (SBOM/SLSA) PLACEHOLDER.

---

## K. SEC-A / RES / DR

**Mechanizmy z dowodami:**

- **SECURITY module** (`tools/verify/security/`):
  - `secrets.sh` — **SEC-001..004** (working tree, staged diff, .env files, private key files).
  - `history.sh` — **SEC-101..102** (secrets in entire history, recent commits).
  - `credentials.sh` — **SEC-201..208** (AWS, GCP, Azure, DB URLs, LLM provider keys, Docker registry, Tailscale, JWT).
- **`tools/security/secret-scan.sh`** — gitleaks/trufflehog/git-secrets/heuristic.
- **`security/`** — katalogi: `audit`, `incidents`, `keys`, `policies`, `rotation`, `scanning`, `threat-model`, `README.md`.
- **`secrets/`** — katalogi: `references`, `rotation`, `schemas`, `templates`, `README.md`.
- **`SECURITY.md`, `RECOVERY.md`, `DEPLOYMENT.md`, `MIGRATION.md`** — wszystkie `STATUS: UNDEFINED`.
- **SEC-A / RES / DR:** **ABSENT** jako check ID. Grep `SEC-A|SEC-D|RES-[0-9]{3}|DR-[0-9]{3}` → **No matches found**. Kontekst design doc: `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #3 "Bezpieczeństwo | SEC D/A/R/C | 3 niezależne domeny zaufania" i #4 "Odporność | RES B/D/H | Każda domena awarii ma świeży dowód przeżycia" — design doc, bez implementacji.

**Self-check: PARTIAL** — SEC-001..004, SEC-101..102, SEC-201..208, secret-scan.sh, katalogi security/secrets potwierdzone; SEC-A/RES/DR ABSENT jako check ID (dowód: grep brak wyników), obecne tylko jako wymiary w design doc.

---

## L. PERM-001..012

**Mechanizmy z dowodami:**

- **PERM-001..012:** **ABSENT**. Grep `PERM-[0-9]{3}` w `/opt/Prod-ready` → **No matches found**.
- Jedyny kontekst: `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #5 "Uprawnienia | PERM | Minimalne I wystarczające — mierzone z obu stron | perm_health → 1.0; grants bez ścieżki = 0" — design doc, bez implementacji checków PERM-*.

**Self-check: ABSENT** (dowód: grep `PERM-[0-9]{3}` → No matches found; jedyny ślad to wymiar #5 w design doc, bez checków).

---

## M. Fire drills / assurance / CORR

**Mechanizmy z dowodami:**

- **Fire drills / assurance / CORR:** **ABSENT** jako implementacja. Grep `fire.?drill|assurance` → trafienia tylko w `docs/architecture/aesthetics-plane-design.md` wiersz 89: wymiar #13 "Dowodliwość | META | System dowodzi sam siebie: fire drills, assurance case, VERIFY-SYSTEM" — design doc, bez implementacji.
- **CORR:** **ABSENT** jako check ID (grep `CORR-[0-9]{3}` → No matches found); wymiar #14 "Uczenie się | CORR + escape" w design doc.

**Self-check: ABSENT** (dowód: grep `fire.?drill|assurance` → tylko design doc aesthetics-plane-design.md; grep `CORR-[0-9]{3}` → No matches found; brak skryptów fire drill / assurance case / VERIFY-SYSTEM).

---

## N. Nieznane / niepotwierdzone

- **Moduły zadeklarowane w `profiles.sh`/`gates.yaml`, ale skrypty niepotwierdzone w tym przeglądzie:** `architecture/architecture.sh`, `dependencies/dependencies.sh`, `reproducibility/reproducibility.sh`, `deployment/deployment.sh`, `contracts/contracts.sh`, `migration/migration.sh`, `recovery/recovery.sh`. `module_script` w `profiles.sh` mapuje je, ale istnienie plików nie zostało zweryfikowane w tej sesji (SELF-001 ma to wykrywać jako ghost moduły). **Uwaga:** glob `tools/verify/**/*.sh` zwrócił 29 plików — wśród nich NIE ma `architecture/architecture.sh`, `dependencies/dependencies.sh`, `reproducibility/reproducibility.sh`, `deployment/deployment.sh`, `contracts/contracts.sh`, `migration/migration.sh`, `recovery/recovery.sh`. To sugeruje, że te moduły są **ghost modułami** (zadeklarowane, ale nieistniejące) — SELF-001 powinien je wykryć jako FAIL (BLOCKING).
- **`tools/verify/core/config.sh`** (1159 linii) — resolver L0-L7 potwierdzony przez grep funkcji, ale pełna treść nie została w całości odczytana w tej sesji (funkcje zidentyfikowane przez grep).
- **`tools/verify/git/history.sh`** (GIT-101..108) — check ID potwierdzone przez grep, pełna treść nie odczytana.
- **`tools/verify/reconcile/reconcile.sh`** — orkiestrator RECON-* potwierdzony przez grep, pełna treść nie odczytana.
- **`system/control-plane/state/state.sh`** — komendy potwierdzone, pełna treść nie odczytana.
- **`config/schemas/registry.schema.json`** — istnienie potwierdzone, treść nie odczytana.
- **`config/examples/registry.example.yaml`** — istnienie potwierdzone, treść nie odczytana.
- **`docs/architecture/README.md`, `docs/git`, `docs/operations`, `docs/reference`, `docs/security`, `docs/user`, `docs/development`, `docs/generated`** — katalogi docs, zawartość nie przeglądana w tej sesji.
- **`governance/decisions/ADR-0001-risk-prediction-s7.md`** — ADR-0001 Risk Prediction (S7), status **PROPOSED** (potwierdzony w `governance/decisions/README.md` linia 21).

---

## O. Ograniczenia metody

1. **Tryb READ-ONLY (Z1):** nie uruchamiano żadnych skryptów verify, nie wykonywano `state.sh`, nie testowano gate'ów — wszystkie wnioski oparte na statycznej analizie treści plików.
2. **Ghost moduły:** 7 modułów zadeklarowanych w `profiles.sh`/`gates.yaml` (architecture, dependencies, reproducibility, deployment, contracts, migration, recovery) nie ma odpowiadających plików w glob `tools/verify/**/*.sh` — to hipoteza oparta na braku plików, nie na uruchomieniu SELF-001.
3. **Pliki nieodczytane w całości:** `tools/verify/core/config.sh` (1159 linii), `tools/verify/git/history.sh`, `tools/verify/reconcile/reconcile.sh`, `system/control-plane/state/state.sh`, `config/schemas/registry.schema.json`, `config/examples/registry.example.yaml` — check ID/funkcje potwierdzone przez grep, pełna treść nie zweryfikowana.
4. **Katalogi docs nieprzeglądane:** `docs/git`, `docs/operations`, `docs/reference`, `docs/security`, `docs/user`, `docs/development`, `docs/generated` — zawartość nie sprawdzona.
5. **ABSENT oparty na grep:** sekcje L, M, SEC-D/SoD, SEC-A/RES/DR, CUR/OPT, CONS-06, CORR oparte na braku dopasowań regex — możliwe, że check ID istnieją w plikach nieobjętych wzorcem (np. inny format identyfikatora), ale wzorzec `[A-Z]+-[0-9]{3}` jest spójny z resztą repo.
6. **Statusy UNDEFINED:** README.md, SOURCE-OF-TRUTH.md, OWNERSHIP.md, SECURITY.md, RECOVERY.md, DEPLOYMENT.md, MIGRATION.md mają `STATUS: UNDEFINED` — to stan repo, nie błąd metody.
7. **Design doc vs implementacja:** `docs/architecture/aesthetics-plane-design.md` i `config-plane-design.md` opisują wymiary (SEC D/A/R/C, RES B/D/H, PERM, CUR, OPT, CONS, CORR, fire drills, assurance) jako cele, ale bez odpowiadających checków w `tools/verify/` — rozróżnienie design doc (cel) vs implementacja (check ID) jest kluczowe dla AUDYT v1.0.
