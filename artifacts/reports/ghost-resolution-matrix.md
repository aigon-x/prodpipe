# GHOST RESOLUTION MATRIX — F-001..F-007

**Status:** ZATWIERDZONY — decyzje Suwerena podjęte (2026-08-10)
**Data:** 2026-08-10
**Źródło prawdy:** `config/canonical/gates.yaml` (metadata-driven, generuje `profiles.sh`)
**Zasada:** NIE usuwać automatycznie. To canonical inconsistency (gates.yaml mówi BLOCKING, filesystem mówi brak). Dla każdego modułu: CONTRACT → IMPLEMENTATION → TEST → REGISTRATION.

---

## 0. Decyzje Suwerena (ZATWIERDZONE 2026-08-10)

| Finding | Decyzja | Uwagi |
|---------|---------|-------|
| **F-001..F-007** (ghost modules) | **IMPLEMENT** (wszystkie 7) | Nie usuwamy z gates.yaml. Registry obiecuje 7 capability — implementujemy kontrakt, nie "jakikolwiek skrypt, żeby zniknął czerwony". Kolejność: architecture → contracts → migration → recovery → deployment → dependencies → reproducibility. |
| **F-009..F-014** (orphan modules) | **REGISTER** | git/history, git/branches, git/tags, security/history, security/credentials → wchodzą do właściwych profili. **Przed rejestracją:** usunąć/połączyć rzeczywiste nakładanie checków (pełne pokrycie + zero niepotrzebnej duplikacji, nie "więcej checków = lepiej"). |
| **F-017** (security drills) | **ADVISORY/PLANNED** (nie BLOCKING) | Dopóki nie są prawdziwymi drillami (INJECT → DETECT → EVIDENCE → RECOVER → CLEANUP w bezpiecznym, izolowanym środowisku), to jest DOCUMENTATION CHECK, nie SECURITY DRILL. Nie udajemy P1 gate. |
| **F-018** (fingerprint) | **Naprawić — jawny kontrakt** | Minimum: ścieżka, zawartość, mode, symlink target, typ obiektu, deterministyczna kolejność. Zdefiniować obsługę pustych katalogów. Jawny kontrakt fingerprintu, nie przypadkowy shell pipeline. |
| **F-015** (evidence bridge) | **P0-3 — najważniejszy architektonicznie** | Rozdzielić obserwację od dowodu od certyfikacji. Inaczej: "PASS, bo w mojej bazie jest zapisane PASS". |

**Nowa zasada projektu (dopisana przez Suwerena):** Każdy element w `gates.yaml` musi spełniać:

> **REGISTERED + IMPLEMENTED + EXECUTED + TESTED + EVIDENCE**

Brak któregokolwiek → **FAIL**. To zabezpiecza przed powtórzeniem sytuacji z ghost modules. Największym zagrożeniem nie jest brak skryptu, ale **system, który twierdzi, że coś kontroluje, podczas gdy w rzeczywistości tego nie kontroluje.**

**Kolejność remediacji (zatwierdzona):**
- **P0:** 1) Ghost resolution, 2) Shadow config, 3) Evidence independence, 4) Debt scanner → project profile, 5) Git/Verify boundary.
- **P1:** orphan modules → REGISTER, real drills albo ADVISORY, normalized fingerprint, executable bits, StateStore placement.
- **P2:** placeholdery, kosmetyczne AIGON headers, dokumentacyjne porządki.
- **Po remediacji:** REBASELINE (nie "baseline teraz") → Remediation → full verify → evidence → zero unexpected drift → nowy baseline → Universal Certification T01-T10 → clean-room test → Template Freeze → `/opt/Prod-template`.

---

## 1. Korekta obrazu (ważne odkrycia w tej sesji)

Przed matrycą — trzy korekty do wcześniejszego findings register:

1. **`i18n` i `efficiency` NIE są ghost modułami.** Istnieją jako kompletne skrypty (`tools/verify/i18n/i18n.sh`, `tools/verify/efficiency/efficiency.sh`) i są zarejestrowane w gates.yaml. **Nie dodawać ich jako F-035/F-036** — to fałszywy alarm. (Wcześniejsze założenie było błędne.)
2. **Ghost moduły to całkowicie nieistniejące moduły w `tools/verify/`**, nie "katalogi z brakującym skryptem". Dla 6 z 7 modułów (dependencies, reproducibility, deployment, contracts, migration, recovery) **nie ma nawet katalogu** w `tools/verify/`.
3. **`architecture/` jest wyjątkiem** — katalog istnieje (z `semantics.sh` i `taxonomy.sh`), ale główny moduł `architecture.sh` **nie istnieje**. Jedyny `architecture.sh` w repo jest w `.qwen/worktrees/gateforge/` (worktree, nie główne repo).

---

## 2. GHOST RESOLUTION MATRIX

| Module | Declared (gates.yaml) | Exists (filesystem) | Used | Duplicate | Required | Evidence | Decision |
|--------|----------------------|---------------------|------|-----------|----------|----------|----------|
| **architecture** | BLOCKING w full/release/genesis | Katalog `architecture/` jest (semantics.sh, taxonomy.sh), ale **brak `architecture.sh`** | Nie | Brak | **TAK** — wymiar jakości architektury jest fundamentalny | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **dependencies** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** | Nie | Brak | **TAK** — wymiar zależności (Cargo.toml/package.json) | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **reproducibility** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** | Nie | Brak | **TAK** — wymiar reprodukowalności (determinizm build) | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **deployment** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** w tools/verify/ (root `deployment/` to dokumentacja, nie moduł) | Nie | Root `deployment/` to placeholdery (README.md, .gitkeep) — NIE duplikat | **TAK** — wymiar deployment (manifests, terraform, helm) | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **contracts** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** w tools/verify/ (root `contracts/` to kontrakty, nie moduł) | Nie | Root `contracts/` to kontrakty (contract.md, schemas) — NIE duplikat | **TAK** — wymiar kontraktów (scaffold DRAFT, evidence/security UNDEFINED) | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **migration** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** | Nie | Brak | **TAK** — wymiar migracji (StateStore migracje 0001-0008) | Brak skryptu → brak gate'u | **IMPLEMENT** |
| **recovery** | WARNING w full, BLOCKING w release/genesis | **Brak katalogu** | Nie | Brak | **TAK** — wymiar recovery (RECOVERY.md, backup/restore) | Brak skryptu → brak gate'u | **IMPLEMENT** |

**Wniosek:** Wszystkie 7 modułów to **rzeczywiście wymagane wymiary jakości** (nie redundantne, nie przyszłe capability, nie błędne wpisy). Żaden nie ma duplikatu. Wszystkie są **niezaimplementowane** — to canonical inconsistency: gates.yaml deklaruje BLOCKING, filesystem nie ma skryptu.

**Decyzja Suwerena (ZATWIERDZONA):** **IMPLEMENT dla wszystkich 7.** Nie usuwamy z gates.yaml. Registry obiecuje 7 capability — implementujemy kontrakt, nie "jakikolwiek skrypt, żeby zniknął czerwony". Żaden nie kwalifikuje się do DEREGISTER (wymiar jakości jest realny) ani ARCHIVE (nie ma czego archiwizować — brak kodu).

---

## 3. Proces dla każdego ghost modułu (CONTRACT → IMPLEMENTATION → TEST → PROFILE REGISTRATION → EXECUTION → EVIDENCE)

Dla każdego z 7 modułów, wg dyrektywy Suwerena:

1. **CONTRACT** — zdefiniować kontrakt modułu (co gate'uje, jakie checki, jaka severity, jakie profile). Wzorzec: `contracts/<module>/contract.md`.
2. **IMPLEMENTATION** — napisać `tools/verify/<module>/<module>.sh` (fail-closed, evidence_record, verify_module_exit). Wzorzec: istniejące moduły (i18n, efficiency, security).
3. **TEST** — napisać `tools/verify/tests/test-<module>.sh` (wzorzec: test-i18n.sh, test-efficiency.sh).
4. **PROFILE REGISTRATION** — moduł już jest w gates.yaml (to jest źródło problemu — deklaracja bez implementacji). Po implementacji: uruchomić `gen-profiles.sh` → zregenerować `profiles.sh` → zweryfikować że moduł się wykonuje.
5. **EXECUTION** — uruchomić moduł w profilu, potwierdzić że się wykonuje i produkuje wynik.
6. **EVIDENCE** — moduł zapisuje evidence (evidence_record) do StateStore.

**Dopiero po pełnym łańcuchu moduł może być `BLOCKING`.** Zasada Suwerena: **REGISTERED + IMPLEMENTED + EXECUTED + TESTED + EVIDENCE** — brak któregokolwiek → FAIL.

---

## 4. Priorytet implementacji (ZATWIERDZONY przez Suwerena)

| Priorytet | Moduł | Uzasadnienie |
|-----------|-------|--------------|
| 1 | **architecture** | Katalog już istnieje (semantics.sh, taxonomy.sh) — brakuje tylko głównego skryptu. Najmniejszy wysiłek, największy wymiar. |
| 2 | **contracts** | Powiązany z P0-3 (evidence bridge) — kontrakty evidence/security są UNDEFINED. |
| 3 | **migration** | Powiązany z StateStore (F-034) — migracje 0001-0008 istnieją, brak gate'u. |
| 4 | **recovery** | Powiązany z RECOVERY.md i backup/restore (state.sh). |
| 5 | **deployment** | Root `deployment/` ma strukturę (manifests, terraform, helm) — brak gate'u. |
| 6 | **dependencies** | Wymiar zależności — brak plików zależności w repo (Cargo.toml/package.json). |
| 7 | **reproducibility** | Wymiar determinizmu build — powiązany z fingerprint (F-018). |

---

## 5. Powiązania z innymi P0/P1

| Ghost moduł | Powiązany finding | Zależność |
|-------------|-------------------|-----------|
| architecture | F-018 fingerprint | architecture.sh powinien używać znormalizowanego fingerprintu |
| contracts | F-015 evidence bridge | contracts/evidence/contract.md UNDEFINED — powiązany z poziomami Observed/Evidence/Derived/Certified |
| migration | F-034 StateStore | migracje StateStore istnieją, brak gate'u |
| recovery | F-034 StateStore | backup/restore w state.sh, brak gate'u |
| reproducibility | F-018 fingerprint | determinizm build = fingerprint |

---

## 6. Plan remediacji (pełna kolejność wg dyrektywy Suwerena)

### P0 — Krytyczne (dotyczy samego mechanizmu certyfikacji)

**P0-1: Ghost modules / canonical gate registry**
- Zbudować GHOST RESOLUTION MATRIX (ten raport).
- Dla każdego z 7 modułów: CONTRACT → IMPLEMENTATION → TEST → REGISTRATION.
- Po implementacji: zregenerować profiles.sh, zweryfikować że wszystkie moduły się wykonują.
- **Do decyzji Suwerena:** Decision dla każdego modułu (IMPLEMENT / MERGE / DEREGISTER / ARCHIVE).

**P0-2: Shadow config**
- `tools/verify/config/config.sh` to kompletny moduł CFG-001..008 (Jednokanałowość, Schema, Klucze, Docs, Defaulty, Waivers, Kill-switches, Konstytucja), fail-closed, z evidence_record.
- **NIE jest duplikatem** `core/config.sh` (to resolver configu, tamten to gate).
- Status: **ACTIVE** (niezarejestrowany). Każdy mechanizm → jednoznaczny status: ACTIVE / OPTIONAL / EXPERIMENTAL / ARCHIVED.
- ACTIVE musi mieć ścieżkę: REGISTERED → EXECUTED → RESULT → EVIDENCE → GATE.
- **Akcja:** zarejestrować config/config.sh w gates.yaml (lub nadać status OPTIONAL/EXPERIMENTAL).

**P0-3: Evidence independence / circular trust**
- Potwierdzone: `evidence_record()` zapisuje do StateStore, `verify_evidence_complete()` meta-gate fail-closed.
- **Circular trust:** VERIFY zapisuje evidence do StateStore i używa StateStore jako dowodu własnej poprawności.
- **Docelowe poziomy:** Observed / Evidence / Derived / Certified. Certyfikat nie może być jedynym dowodem samego siebie.
- **Akcja:** zdefiniować poziomy dowodu, rozdzielić źródło evidence od źródła weryfikacji.

**P0-4: Debt data → project profile**
- `tools/verify/debt/scanner.sh` — mechanizm uniwersalny (14 checków DEBT-001..014, in_dir/scan_pattern/recon_status/recon_record_debt).
- **100% AIGON-specific dane** zakodowane na sztywno: LEGACY_PORTS (17000/11408/7009/14008/8080/58200), LEGACY_NAMES, LEGACY_HOSTS, LEGACY_ENV, LEGACY_NETWORKS, LEGACY_CRATES, LEGACY_CONFIGS, LEGACY_DOCS, LEGACY_SOT.
- **Akcja:** wydzielić dane do profilu projektu (config). Foundation = mechanizm + kontrakt; projekt = dane + polityka + profil. To test Config Foundation.

**P0-5: Git/Verify boundary**
- `verify_root()` wymaga git (F-020), `repo_files()` tylko git-tracked.
- **Akcja:** ustalić granicę — co jest odpowiedzialnością git, co verify. Naprawić po ustaleniu architektury.

### P1 — Ważne

- **Orphans (F-009..F-014):** to kompletne, wartościowe moduły (git/history, branches, tags, security/history, credentials, repository-integrity) — **NIE martwy kod, tylko niezarejestrowane**. Rekomendacja: **zarejestrować, nie archiwizować**. Consumer graph: sprawdzić kto je wywołuje.

#### Consumer graph orphan modułów (zbadany 2026-08-10)

**Kluczowe ustalenie:** Żaden z 5 orphan modułów (git/history, git/branches, git/tags, security/history, security/credentials) **nie jest wywoływany** — nie ma ich w gates.yaml (zero dopasowań), nie ma ich w `run_module` w verify.sh, nie są delegowane z integrity.sh/secrets.sh. Są **całkowicie odłączone od łańcucha wykonania**. To nie duplikaty — każdy ma unikalny wymiar jakości, choć `git/integrity.sh` i `security/secrets.sh` częściowo pokrywają ich tematykę (informational).

| Moduł | Checki | Wywoływany? | Duplikat? | Wniosek |
|-------|--------|-------------|-----------|---------|
| `git/history.sh` | GIT-101..108 (huge commits, binary, secrets-delegated, generated state, mass changes, merge bombs, force push, commit msg) | **NIE** | Częściowo pokryty przez `git/integrity.sh` GIT-007/017 (informational) | Wartościowy, unikalny wymiar (jakość historii) |
| `git/branches.sh` | GIT-201..203 (branch prefix, main canonical, no direct push) | **NIE** | Częściowo pokryty przez `git/integrity.sh` GIT-018 (protected branches) | Wartościowy, unikalny wymiar (polityka gałęzi) |
| `git/tags.sh` | GIT-301..303 (tag naming, annotated, prod immutable) | **NIE** | Częściowo pokryty przez `git/integrity.sh` GIT-017 (tag immutability) | Wartościowy, unikalny wymiar (polityka tagów) |
| `security/history.sh` | SEC-101..102 (gitleaks cała historia) | **NIE** | `security/secrets.sh` deleguje do `tools/security/secret-scan.sh`, NIE do history.sh | Wartościowy — gitleaks na całej historii ≠ working tree |
| `security/credentials.sh` | SEC-201..208 (AWS/GCP/Azure/DB/LLM/Docker/Tailscale/JWT) | **NIE** | `security/secrets.sh` SEC-001..004 (working tree/staged/.env/keys) — częściowo pokrywa | Wartościowy — rozszerza secrets o credentials |

**Rekomendacja:** **REGISTER** (nie ARCHIVE, nie MERGE) — dodać do gates.yaml jako moduły w odpowiednich profilach. Zgodne z dyrektywą Suwerena: "potrzebny → podpinamy". Uwaga: `git/integrity.sh` GIT-007/009/017/018 częściowo pokrywa tematykę — przy rejestracji rozważyć, czy nie zduplikować checków (MERGE częściowy) czy zostawić jako osobne moduły (REGISTER).
- **Real drills (F-017):** `security/drills.sh` jest dokumentacyjny (INJECT/DETECT sprawdzają tylko istnienie README.md z sekcjami OCZEKIWANY WYNIK i DESTROY). **Albo realny drill + mierzalny wynik + evidence, albo REPORT/ADVISORY.** Nie "udajemy gate".
- **Normalized fingerprint (F-018):** `template_fingerprint()` = `git ls-files | sort | xargs sha256sum | sha256sum` (nieznormalizowany). **Akcja:** content, mode, symlink target, ścieżka, puste katalogi.
- **Executable bits (F-019):** self-profile-integrity.sh — exec bits WARN.
- **StateStore placement (F-034):** nie przenosić mechanicznie. Osobny refactoring strukturalny po ustaleniu granic.

### P2 — Kosmetyka

- Placeholdery / branding / kosmetyka.

### Po remediacji

- BASELINE → Universal Certification → T01-T10 → Clean Room → Template Freeze → /opt/Prod-template.

---

## 7. Pozytywna konstatacja

34 findingsy ≠ 34 katastrofy. Sam proces audytowy zadziałał — wszystko jest wykrywalne. Celem: każdy problem ma dokładnie jedną właściwą ścieżkę do rozwiązania, po remediacji nie zostaje żaden ghost/shadow/orphan.
