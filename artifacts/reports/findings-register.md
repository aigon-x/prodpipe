# Findings Register — Kompletna lista znanych wyjątków przed zamrożeniem baseline

**Status:** KOMPLETNY (DISCOVER → CLASSIFY → RECORD)
**Data:** 2026-08-10
**Zakres:** Całe `/opt/Prod-ready/` (AIGON Production Platform)
**Cel:** Jeden pełny obraz wszystkich znanych wyjątków przed zamrożeniem baseline'u. Baseline ma znaczyć: "To jest dokładny obraz stanu, który świadomie certyfikujemy."

---

## 1. Proces

Zgodnie z dyrektywą Suwerena: **DISCOVER → CLASSIFY → RECORD → BASELINE → REMEDIATE** (a nie DISCOVER → FIX → DISCOVER → FIX).

Ten dokument jest wynikiem faz **DISCOVER + CLASSIFY + RECORD**. Faza **BASELINE** (zamrożenie) i **REMEDIATE** (naprawa) NIE są jeszcze wykonane — czekają na decyzję Suwerena.

---

## 2. Kategorie findingsów

Każdy finding ma:
- **ID** — unikalny identyfikator (F-001, F-002, ...)
- **Kategoria** — typ wyjątku
- **Lokalizacja** — plik/katalog
- **Opis** — co dokładnie jest wyjątkiem
- **Dowód** — plik źródłowy potwierdzający
- **Klasyfikacja** — FOUNDATION / AIGON-specific / MIXED / UNKNOWN
- **Priorytet** — P0 (blokuje baseline) / P1 (ważne) / P2 (kosmetyka)
- **Rekomendacja** — proponowana decyzja (KEEP/MOVE/ARCHIVE/DELETE/DEFER)

---

## 3. Pełna lista findingsów

### 3.1. Ghost moduły w tools/verify (7)

| ID | Moduł | Zadeklarowany skrypt | Stan |
|----|-------|---------------------|------|
| F-001 | `architecture` | `architecture/architecture.sh` | NIE ISTNIEJE |
| F-002 | `dependencies` | `dependencies/dependencies.sh` | NIE ISTNIEJE |
| F-003 | `reproducibility` | `reproducibility/reproducibility.sh` | NIE ISTNIEJE |
| F-004 | `deployment` | `deployment/deployment.sh` | NIE ISTNIEJE |
| F-005 | `contracts` | `contracts/contracts.sh` | NIE ISTNIEJE |
| F-006 | `migration` | `migration/migration.sh` | NIE ISTNIEJE |
| F-007 | `recovery` | `recovery/recovery.sh` | NIE ISTNIEJE |

**Dowód:** `config/canonical/gates.yaml` (źródło prawdy) deklaruje te moduły z nieistniejącymi ścieżkami skryptów. `tools/verify/core/gen-profiles.sh` wiernie kopiuje te ścieżki do `profiles.sh`. To NIE jest błąd generatora — to świadoma (lub błędna) deklaracja w źródle prawdy.

**Konsekwencja:** W profilach `full`, `release`, `genesis` te moduły są zadeklarowane jako BLOCKING. SELF-001 (`self-profile-integrity.sh`) wykrywa je jako FAIL (BLOCKING) — fail-closed anti-drift. **To znaczy, że profil `full`/`release`/`genesis` NIGDY nie przejdzie certyfikacji w obecnym stanie.**

**Klasyfikacja:** FOUNDATION (mechanizm) — ale deklaracje są niekompletne.
**Priorytet:** P0.
**Rekomendacja:** DEFER do decyzji — albo (a) usunąć ghost moduły z gates.yaml (jeśli nie są potrzebne), albo (b) zaimplementować skrypty (jeśli są potrzebne). Nie można zamrozić baseline'u z ghost modułami, bo baseline będzie permanentnie FAIL.

---

### 3.2. Shadow moduł: config/config.sh (1)

| ID | Moduł | Opis |
|----|-------|------|
| F-008 | `config/config.sh` | Realny moduł gate'ów configu (CFG-001..008), ma testy (`test-config-gates.sh`), ale NIE jest zarejestrowany w `module_script` ani w `VERIFY_MODULES` — nie jest uruchamiany przez żaden profil. |

**Dowód:** `tools/verify/config/config.sh` istnieje i jest kompletny (Jednokanałowość, Schema, Klucze, Docs, Defaulty, Waivers, Kill-switches, Konstytucja). `config/canonical/gates.yaml` NIE zawiera modułu `config`. Fail-closed: brak `registry.yaml` = FAIL (BLOCKING).

**Konsekwencja:** Moduł configu jest martwy — jego gate'y (CFG-001..008) nigdy nie są wykonywane. To jest shadow mechanism: realna zdolność, która nie jest zintegrowana z pipeline'em.

**Klasyfikacja:** FOUNDATION (mechanizm).
**Priorytet:** P0.
**Rekomendacja:** DEFER — albo (a) zarejestrować w gates.yaml (jeśli config gate'y są potrzebne), albo (b) usunąć (jeśli nie). Uwaga: `core/config.sh` (resolver) i `config/config.sh` (gate) to DWA RÓŻNE pliki — NIE duplikaty.

---

### 3.3. Orphan moduły (6)

| ID | Plik | Opis |
|----|------|------|
| F-009 | `tools/verify/git/history.sh` | Istnieje, deleguje do `security/history.sh`, ale NIE jest wywoływany przez żaden profil/module_script. |
| F-010 | `tools/verify/git/branches.sh` | Istnieje, ale NIE jest wywoływany. |
| F-011 | `tools/verify/git/tags.sh` | Istnieje, ale NIE jest wywoływany. |
| F-012 | `tools/verify/security/history.sh` | Istnieje, ale NIE jest wywoływany (ani przez git/history.sh, ani przez security/secrets.sh). |
| F-013 | `tools/verify/security/credentials.sh` | Istnieje, ale NIE jest wywoływany. |
| F-014 | `tools/repository-integrity.sh` | FOUNDATION PLACEHOLDER (STAGE 0 — GIT GENESIS integrity check). Istnieje, ale NIE jest wywoływany przez żaden profil/module_script. |

**Dowód:** `git/integrity.sh` (GIT-001..019) nie wywołuje orphan plików. `security/secrets.sh` (SEC-001..004) deleguje do `tools/security/secret-scan.sh`, nie do `security/history.sh`/`credentials.sh`. `tools/repository-integrity.sh` ma status "FOUNDATION PLACEHOLDER" w nagłówku.

**Konsekwencja:** Te pliki istnieją, ale nie są częścią żadnego profilu certyfikacji. To martwy kod — albo do zintegrowania, albo do archiwizacji.

**Klasyfikacja:** FOUNDATION (mechanizm) / MIXED.
**Priorytet:** P1.
**Rekomendacja:** DEFER — albo (a) zarejestrować w gates.yaml (jeśli potrzebne), albo (b) przenieść do `archive/` (jeśli nie).

---

### 3.4. Evidence bridge w StateStore (sprzężenie) — P0#1

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-015 | `tools/verify/core/lib.sh` | `evidence_record` zapisuje do `system/control-plane/state/data/canonical-state.db` (SQLite). `verify_evidence_complete` meta-gate wymaga evidence (moduł bez evidence = 0 punktów = FAIL). |

**Dowód:** `lib.sh` — `evidence_record()` używa `verify_root()/system/control-plane/state/data/canonical-state.db` (lub `VERIFY_STATE_DB` override). `verify_evidence_complete()` fail-closed.

**Konsekwencja:** Mechanizm certyfikacji (tools/verify) jest sprzężony ze stanem, który sam certyfikuje (StateStore w `system/control-plane/state/`). To jest OŚ 4b — ryzyko, że certyfikacja zależy od stanu, który ma być niezależnie weryfikowany. Jeśli StateStore jest uszkodzony, certyfikacja FAIL — nawet jeśli repo jest zdrowe.

**Klasyfikacja:** MIXED (mechanizm FOUNDATION, ale sprzężenie z AIGON-specific lokalizacją).
**Priorytet:** P0.
**Rekomendacja:** DEFER — rozważyć (a) przeniesienie StateStore do FOUNDATION (np. `state/` na poziomie root), (b) rozluźnienie zależności (evidence jako WARN, nie BLOCKING), (c) jawny override `VERIFY_STATE_DB`.

---

### 3.5. Debt scanner: uniwersalny mechanizm + AIGON-specific dane

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-016 | `tools/verify/debt/scanner.sh` | Uniwersalny mechanizm (14 checków DEBT-001..014, `in_dir`/`scan_pattern`/`recon_status`/`recon_record_debt`/`evidence_record`, EXCLUDE/ALLOWED_DIRS/QUARANTINE_DIRS) + **100% AIGON-specific dane zakodowane na sztywno**. |

**Dowód:** `scanner.sh` — `LEGACY_PORTS` (17000 aigon-runtime, 11408 aigon-router, 7009 maips UDP, 14008 magic-router, 8080 aigon-code-serwer, 58200 vault), `LEGACY_NAMES` (aigon-nats, aigon-runtime, aigon-router, aigon-code-serwer, aigon-code-server, aigon-infra-vault, rtv2-runtime-master, runtime-v2-magic-router), `LEGACY_HOSTS` (100.98.144.70, 100.93.112.70, contabo, aigon-dev, aigon-prod), `LEGACY_ENV` (AIGON_RUNTIME_SHARED_SECRET, AIGON_API_KEY, DEEPSEEK_API_KEY, CLOUDFLARE_TUNNEL_TOKEN), `LEGACY_NETWORKS` (aigon-nats, aigon-mesh, aigon-core), `LEGACY_CRATES` (aigon-magic-router, aigon-kernel, aigon-code-mcp), `LEGACY_CONFIGS`, `LEGACY_DOCS`, `LEGACY_SOT`.

**Konsekwencja:** Mechanizm jest uniwersalny, ale dane są AIGON-specific. To jest dokładnie wzorzec "Foundation = mechanizm + kontrakt; projekt = dane/polityka/profil", który Suweren zidentyfikował jako potencjalnie bardzo cenny.

**Klasyfikacja:** MIXED (mechanizm FOUNDATION, dane AIGON-specific).
**Priorytet:** P0.
**Rekomendacja:** DEFER — Suweren preferuje opcję A (projektowy profil konfiguracji), ale decyzja dopiero po pełnym register. Wzorzec docelowy: mechanizm w FOUNDATION, dane w profilu projektu.

---

### 3.6. Security drills: dokumentacyjny, nie behavioralny

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-017 | `tools/verify/security/drills.sh` | Zarejestrowany jako BLOCKING w `full`/`security`/`release`/`genesis`, ale **dokumentacyjny** — sprawdza README z OCZEKIWANY WYNIK/DESTROY, NIE wstrzykuje realnych defektów. |

**Dowód:** `drills.sh` — 6 faz (PRE-FLIGHT/INJECT/DETECT/WALIDACJA/EVIDENCE/DESTROY), ale INJECT/DETECT sprawdzają tylko istnienie `README.md` z sekcjami OCZEKIWANY WYNIK i DESTROY. Nie ma realnego wstrzyknięcia defektu ani weryfikacji detekcji. Domeny: detection (SEC-D-01), authorization (SEC-A-01), recovery (SEC-R-01), confidentiality (SEC-C-01).

**Konsekwencja:** To jest OŚ 1 Gates-efficacy gap — gate deklaruje zdolność (fire drills), ale nie weryfikuje behavioralnie, czy system faktycznie wykrywa/odzyskuje. To daje fałszywe poczucie bezpieczeństwa.

**Klasyfikacja:** FOUNDATION (mechanizm) — ale niekompletny.
**Priorytet:** P1.
**Rekomendacja:** DEFER — albo (a) zaimplementować realne wstrzyknięcie defektów (behavioralny drill), albo (b) obniżyć severity do WARNING/INFORMATIONAL, albo (c) usunąć z profili BLOCKING.

---

### 3.7. Fingerprint scaffolda: nieznormalizowany

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-018 | `tools/scaffold/scaffold.sh` | `template_fingerprint()` = `git ls-files | sort | xargs sha256sum | sha256sum` — nieznormalizowany (bez mode bitów, symlinków, pustych katalogów). |

**Dowód:** `scaffold.sh` — fingerprint oparty tylko na `git ls-files` (git-tracked pliki), bez uwzględnienia bitów wykonywalności, symlinków, pustych katalogów. Template Drift Guard (P0 gate) opiera się na tym fingerprint.

**Konsekwencja:** Dwa identyczne drzewa z różnymi bitami exec / symlinkami / pustymi katalogami dadzą ten sam fingerprint. Template Drift Guard może nie wykryć realnego dryfu.

**Klasyfikacja:** FOUNDATION (mechanizm).
**Priorytet:** P1.
**Rekomendacja:** DEFER — rozważyć normalizację fingerprint (uwzględnić mode bity, symlinki, puste katalogi).

---

### 3.8. Executable bits (GAP #3)

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-019 | `tools/verify/self-profile-integrity.sh` | SELF-001: `[ ! -x "$VERIFY_DIR/$script" ]` → warn "Skrypt nie jest wykonywalny (bit x)" (WARN nie BLOCKING, bo moduły uruchamiane przez `bash "$script"`). |

**Dowód:** `self-profile-integrity.sh` — brak bitu x = WARN, nie BLOCKING. To jest GAP #3 z `universality-gap.md`.

**Konsekwencja:** Skrypty bez bitu x przechodzą certyfikację (WARN), mimo że nie są przygotowane jako gate'y. To jest niespójność — jeśli moduł ma być gate'em, powinien być wykonywalny.

**Klasyfikacja:** FOUNDATION (mechanizm).
**Priorytet:** P1.
**Rekomendacja:** DEFER — rozważyć podniesienie do BLOCKING (jeśli moduły mają być wykonywalne) lub jawnie udokumentować, że `bash "$script"` jest akceptowalne.

---

### 3.9. Git/Verify boundary (GAP #2)

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-020 | `tools/verify/core/lib.sh` | `verify_root()` = `git rev-parse --show-toplevel` → "FATAL: not a git repository" exit 2. `repo_files()` operuje tylko na git-tracked plikach (nie na `find .`). |

**Dowód:** `lib.sh` — `verify_root()` wymaga .git; scaffold celowo tworzy projekt bez .git (izolacja). To jest GAP #2 z `universality-gap.md`.

**Konsekwencja:** Verify wymaga git. Projekt wygenerowany przez scaffold (bez .git) nie może być certyfikowany przez verify. To jest sprzeczność — scaffold tworzy projekt, którego verify nie może sprawdzić.

**Klasyfikacja:** FOUNDATION (mechanizm).
**Priorytet:** P0.
**Rekomendacja:** DEFER — rozważyć (a) verify bez git (operowanie na `find .`), (b) scaffold tworzący .git, (c) jawny tryb "no-git".

---

### 3.10. AIGON-specific warstwa: placeholdery (ghost moduły)

| ID | Katalog | Opis |
|----|---------|------|
| F-021 | `agents/` | Placeholder (.gitkeep + README) |
| F-022 | `mesh/` | Placeholder |
| F-023 | `models/` | Placeholder |
| F-024 | `business/` | Placeholder |
| F-025 | `apps/` | Placeholder |
| F-026 | `operations/` | Placeholder |
| F-027 | `security/` | Placeholder |
| F-028 | `filesystem/` | Placeholder |
| F-029 | `system/` (poza control-plane/state/) | 14 podkatalogów (chaos, data-plane, events, gateway, health, identity, observability, registry, router, runtime, scheduler, security, self-heal, telemetry) — wszystkie placeholdery |
| F-030 | `data/` | 6 podkatalogów (cache, session, system, temporary, tenant, user) — wszystkie placeholdery |
| F-031 | `secrets/` | 4 podkatalogi (references, rotation, schemas, templates) — wszystkie placeholdery |
| F-032 | `tools/automation/`, `tools/ci/`, `tools/migration/`, `tools/scripts/`, `tools/utilities/`, `tools/validation/` | 6 podkatalogów — wszystkie placeholdery |

**Dowód:** Wszystkie te katalogi zawierają tylko `.gitkeep` + `README.md`. To są deklaracje zdolności bez implementacji.

**Konsekwencja:** To jest AIGON-specific warstwa, która jest w 99% pusta. Suweren zatwierdził: NIE czyścić (UNKNOWN ≠ DELETE). Te katalogi deklarują zdolności, które mogą być potrzebne w przyszłości.

**Klasyfikacja:** AIGON-specific (deklaracje).
**Priorytet:** P2 (nie blokuje baseline — to świadome deklaracje).
**Rekomendacja:** KEEP (zgodnie z werdyktem Suwerena — UNKNOWN ≠ DELETE). Wymagają formalnej decyzji KEEP/MOVE/ARCHIVE/DELETE/DEFER.

---

### 3.11. "aigon" w nagłówkach (kosmetyka)

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-033 | Wiele plików w `tools/verify/`, `tools/scaffold/` | Nagłówek "AIGON Production Platform — Repository Certification Engine" (linia 3) w lib.sh, profiles.sh, integrity.sh, secrets.sh, drills.sh, scanner.sh, reconcile.sh, self-profile-integrity.sh, scaffold.sh. |

**Dowód:** Nagłówki plików. To kosmetyka, nie zależność funkcjonalna.

**Konsekwencja:** Brak wpływu funkcjonalnego. To jest AIGON leakage (GAP #1 z `universality-gap.md`), ale tylko w nagłówkach.

**Klasyfikacja:** MIXED (kosmetyka).
**Priorytet:** P2.
**Rekomendacja:** DEFER — rozważyć neutralizację nagłówków (np. "Repository Certification Engine") w fazie GAP A remediation.

---

### 3.12. StateStore w złym miejscu

| ID | Lokalizacja | Opis |
|----|-------------|------|
| F-034 | `system/control-plane/state/` | Realny StateStore (SQLite = canonical operational state) — uniwersalny mechanizm w AIGON-specific `system/`. |

**Dowód:** `system/control-plane/state/` ma lib.sh, schema.sql, state.sh, migracje 0001-0008, testy, data/canonical-state.db. To jest realny mechanizm, nie placeholder.

**Konsekwencja:** Suweren zatwierdził: `system/control-plane/state/` → FOUNDATION (realny StateStore, nie AIGON Runtime). Ale lokalizacja jest w AIGON-specific `system/`.

**Klasyfikacja:** FOUNDATION (mechanizm) w złym miejscu.
**Priorytet:** P1.
**Rekomendacja:** DEFER — rozważyć przeniesienie do FOUNDATION (np. `state/` na poziomie root) w fazie GAP remediation.

---

## 4. Podsumowanie

| Priorytet | Liczba | Findingsy |
|-----------|--------|-----------|
| **P0** (blokuje baseline) | 7 | F-001..F-007 (ghost moduły), F-008 (shadow config), F-015 (evidence bridge), F-016 (debt dane), F-020 (Git/Verify boundary) |
| **P1** (ważne) | 7 | F-009..F-014 (orphan moduły), F-017 (drills), F-018 (fingerprint), F-019 (exec bits), F-034 (StateStore miejsce) |
| **P2** (kosmetyka) | 4 | F-021..F-032 (placeholdery), F-033 (nagłówki) |

**Łącznie: 34 findingsy.**

---

## 5. Kluczowe wnioski

1. **Ghost moduły (F-001..F-007) są najpoważniejszym problemem** — profil `full`/`release`/`genesis` NIGDY nie przejdzie certyfikacji w obecnym stanie, bo SELF-001 fail-closed wykrywa 7 nieistniejących skryptów. To jest świadoma deklaracja w `gates.yaml` (źródło prawdy), nie błąd generatora.

2. **Wzorzec "Foundation = mechanizm + kontrakt; projekt = dane/polityka/profil"** jest potwierdzony przez F-016 (debt scanner: mechanizm uniwersalny, dane AIGON-specific). To jest potencjalnie najcenniejsza zasada dla całego Prod-template.

3. **Sprzężenie certyfikacji ze StateStore (F-015)** jest ryzykowne — certyfikacja zależy od stanu, który ma być niezależnie weryfikowany.

4. **AIGON-specific warstwa jest w 99% pusta** (F-021..F-032) — to deklaracje zdolności bez implementacji. Zgodnie z werdyktem Suwerena: UNKNOWN ≠ DELETE.

5. **Baseline NIE może być zamrożony z ghost modułami** — baseline ma znaczyć "świadomie certyfikujemy ten stan", a ghost moduły czynią certyfikację permanentnie FAIL.

---

## 6. Następne kroki (czekają na decyzję Suwerena)

1. **Decyzja o ghost modułach (F-001..F-007):** usunąć z gates.yaml czy zaimplementować skrypty?
2. **Decyzja o shadow config (F-008):** zarejestrować w gates.yaml czy usunąć?
3. **Decyzja o orphan modułach (F-009..F-014):** zintegrować czy archiwizować?
4. **Decyzja o evidence bridge (F-015):** przenieść StateStore, rozluźnić zależność, czy jawny override?
5. **Decyzja o debt danych (F-016):** opcja A (profil konfiguracji) czy inna?
6. **Decyzja o drills (F-017):** zaimplementować behavioralny czy obniżyć severity?
7. **Decyzja o fingerprint (F-018):** normalizować czy zostawić?
8. **Decyzja o exec bits (F-019):** podnieść do BLOCKING czy udokumentować?
9. **Decyzja o Git/Verify boundary (F-020):** verify bez git, scaffold z .git, czy tryb no-git?
10. **Decyzja o StateStore miejscu (F-034):** przenieść do FOUNDATION czy zostawić?

Po decyzjach: zamrozić baseline (macierz + findings jako evidence), potem UNKNOWN dostaje formalną decyzję (KEEP/MOVE/ARCHIVE/DELETE/DEFER), OPTIONAL nie ruszać, EXPERIMENTAL izolować logicznie, LEGACY w archive/, dopiero potem GAP A/C/A remediation.
