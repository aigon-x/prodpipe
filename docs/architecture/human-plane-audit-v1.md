# HUMAN PLANE — AUDYT v1.0

> Audyt gotowości HUMAN PLANE na bazie SONDA + sekcja P (testy manualne i UX).
> Deliverable (c) wariantu 3 design doc `human-plane-design.md`.
> Status: AUDYT v1.0 (pierwszy formalny przebieg).

---

## 1. Metodologia audytu

### 1.1 Co ocenia AUDYT v1.0

AUDYT v1.0 ocenia **gotowość HUMAN PLANE** w dwóch warstwach:

1. **Sekcja P SONDA** — 9 pozycji P-01..P-09 (testy manualne i UX), każda powiązana z gate'em rodziny `MAN-xx` / `UX-A-xx` / `UX-R-xx`.
2. **Infrastruktura wspierająca** — migracja 0015, wymiar 15 tabeli doskonałości, definicja friction score, template charteru, sekcja `human:` w config registry.

### 1.2 Zakres audytu

**W ZAKRESIE:**
- Status 9 pozycji P-01..P-09 (COMPLETE / ABSENT / PARTIAL).
- Istnienie i zastosowanie infrastruktury: migracja `0015_human_plane.sql`, wymiar 15 w tabeli `quality_index`, definicja `s_15`, template charteru, sekcja `human:` w `config/canonical/registry.yaml`.
- Wyliczenie wymiaru 15 (`s_15`) dla stanu bieżącego.

**POZA ZAKRESEM:**
- Ocena poprawności merytorycznej samych gate'ów (MAN/UX-A/UX-R) — to domena design doc.
- Uruchamianie skryptów verify / gate'ów (tryb READ-ONLY, zgodnie z metodą SONDA Z1).
- Ocena pozostałych wymiarów doskonałości (1-14) — poza HUMAN PLANE.

### 1.3 Reguły dowodowe (RULE ZERO)

> **Prawda ze źródła, nie z README.**

Każdy status musi być poparty dowodem:

- **COMPLETE** — mechanizm istnieje w źródle (plik, tabela, check ID) i jest zastosowany.
- **ABSENT(dowód)** — mechanizmu nie ma; dowód to brak dopasowania (grep/glob) lub brak pliku. Wymaga dowodu, że nieobecność jest akceptowalna (np. design doc jako cel) **albo** że jest to luka do domknięcia.
- **PARTIAL(lista)** — mechanizm istnieje częściowo; lista tego, co jest vs czego brak.

Metoda dowodowa: cytowanie ścieżek + identyfikatorów + konkretnych fragmentów (Z2), ABSENT z dowodem (Z3), PARTIAL z listą (Z4), self-check per sekcja (Z5).

### 1.4 Metadane audytu

| Pole | Wartość |
|---|---|
| **Wersja** | v1.0 |
| **Data audytu** | 2026-08-10 |
| **Audytor** | Agent (subagent Explore / Qwen) |
| **Źródła** | `docs/audit/sonda-package.md` (SONDA), `docs/architecture/human-plane-design.md` (design), `docs/architecture/aesthetics-plane-design.md` (wymiar 15), `system/control-plane/state/migrations/` (migracje), `config/canonical/registry.yaml` (config) |
| **Tryb** | READ-ONLY (Z1) — zero modyfikacji, zero zapisu kodu |

### 1.5 ZNAJDOWISKO METODYCZNE — DWIE SONDA, SEKCJA P W NOWEJ

> **W repo istnieją DWIE SONDA o różnych formatach i lokalizacjach.**

1. **`docs/audit/sonda-package.md`** (246 linii) — **kartografia** (bezstratna kartografia szkieletu), wygenerowana przez subagenta Explore. Sekcje **A-O** (A. INTEG, B. StateStore, C. SELF-001/G-gates, D. G0-G8/SEC-D, E. META/CORR, F. Check ID registry, G. CFG-001..008, H. docs-plane, I. VV matrix, J. CUR/OPT, K. SEC-A/RES/DR, L. PERM, M. Fire drills, N. Nieznane, O. Ograniczenia). **Brak sekcji P** — to jest kartografia, nie checklista diagnostyczna.
2. **`docs/00-foundation/SONDA.md`** — **diagnostyczna SONDA** (Self-ONboarding Diagnostic Audit), utworzona w ramach HUMAN PLANE. Format: checklista z statusami `COMPLETE | ABSENT(dowód) | PARTIAL(lista)`. Sekcje **A-O** (14 wymiarów) **+ SEKCJA P** (TESTY MANUALNE I UX, pozycje P-01..P-09).

**Dowód:** `grep -n "^## " docs/audit/sonda-package.md` → ostatnia sekcja to `## O. Ograniczenia metody` (linia 237), brak P. `grep -n "^## " docs/00-foundation/SONDA.md` → zawiera `## SEKCJA P — TESTY MANUALNE I UX` z pozycjami P-01..P-09.

**Konsekwencja:** pozycje P-01..P-09 są zdefiniowane w **nowej** SONDA (`docs/00-foundation/SONDA.md`), nie w kartografii (`docs/audit/sonda-package.md`). AUDYT v1.0 ocenia pozycje P-01..P-09 z nowej SONDA. **Pozostaje luka spójności:** dwie SONDA o różnych formatach — kartografia (audit) vs diagnostyczna (00-foundation). Rekomendacja: ujednolicić (patrz Rekomendacje, P0-1) — albo dodać sekcję P do kartografii, albo wskazać nową SONDA jako kanoniczną dla HUMAN PLANE.

---

## 2. Wynik audytu — tabela P-01..P-09

> Pozycje P-01..P-09 pochodzą z **sekcji P nowej SONDA** (`docs/00-foundation/SONDA.md`, P-01..P-09) — patrz §1.5. Każda pozycja mapuje na gate'y rodziny MAN / UX-A / UX-R.

| ID | Nazwa | Powiązany gate | STATUS | Dowód / lista braków | Rekomendacja |
|---|---|---|---|---|---|
| **P-01** | Pokrycie charterami (coverage) | MAN-01, MAN-02 | **ABSENT** | Tabela `manual_charters` **istnieje** (migracja 0015), ale **0 wierszy** — brak aktywnych charterów. Template charteru **istnieje** (`human-plane-charter-template.md`), ale nie wypełniono żadnego. Brak checków MAN-01/02 w `tools/verify/`. | P0: wypełnij chartere + checki MAN-01/02. |
| **P-02** | UAT sign-off na digest artefaktu | MAN-03 | **ABSENT** | Tabela `uat_signoffs` **istnieje** (migracja 0015), ale **0 wierszy**. Brak checków MAN-03. Brak mechanizmu wiązania akceptacji z `artifact_digest`. | P0: check MAN-03 + pierwszy sign-off. |
| **P-03** | Świeżość evidence przy releasie + rytm eksploracji | MAN-04, MAN-05 | **ABSENT** | Tabela `manual_sessions` **istnieje** (migracja 0015, `recorded_at`), ale **0 wierszy**. Brak checków MAN-04/05. Budżet wieku evidence per tier **istnieje** w config (`human.manual_evidence_max_age: 14`, `human.floors`), ale nie jest egzekwowany. | P0: checki MAN-04/05. |
| **P-04** | MANUAL→AUTO conversion (pętla uczenia się) | MAN-06 | **ABSENT** | Kolumna `converted_test_id` **istnieje** (migracja 0015), ale **0 wierszy**. Brak definicji `conversion_rate` w kodzie (tylko design doc). | P1: check MAN-06 + metryka `conversion_rate`. |
| **P-05** | Niezależność SoD + jakość evidence | MAN-07, MAN-08 | **ABSENT** | Brak checków MAN-07 (separation of duties) i MAN-08 (kompletność evidence). Format evidence sesji **istnieje** (`human-plane-charter-template.md`), ale nie jest egzekwowany. Kontekst SoD w repo: tylko wymiar #3 w `aesthetics-plane-design.md` (design doc, bez checków SEC-D). | P1: checki MAN-07/08. |
| **P-06** | UX automatable (a11y, CWV, visual regression, stany, tokens, błędy, i18n, klawiatura) | UX-A-01..08 | **ABSENT** | Brak checków UX-A-01..08 w `tools/verify/`. Brak integracji axe-core/pa11y, CWV budget, visual regression, design tokens conformance. Tabela `ux_studies` **istnieje** (migracja 0015), ale **0 wierszy**. | P0 (UX-A-01/02) / P2 (UX-A-04): dodaj checki UX-A-01..08. |
| **P-07** | Badania użyteczności + task success + time-on-task + SUS | UX-R-01..04 | **ABSENT** | Tabela `ux_studies` **istnieje** (migracja 0015, `task_success_rate`, `time_on_task_sec`, `sus_score`), ale **0 wierszy**. Brak checków UX-R-01..04. Brak rytmu badań per tier. | P1: checki UX-R-01..04. |
| **P-08** | RUM + heuristic + a11y z człowiekiem + dogfooding | UX-R-05..08 | **ABSENT** | Brak checków UX-R-05..08. Brak RUM/session replay, heuristic evaluation (Nielsen 10), a11y z człowiekiem, dogfooding gate. | P3: checki UX-R-05..08 + RUM anomaly detection. |
| **P-09** | Warstwa 150%: friction budget + synthetic journeys + UX escape | (warstwa 150% A/B/C) | **ABSENT** | Tabela `friction_baselines` **istnieje** (migracja 0015), ale **0 wierszy**. Definicja friction score **istnieje** (`human-plane-friction-score.md`, wariant (b)), ale brak implementacji. Brak synthetic user journeys i UX escape analysis. | P2: checki friction + synthetic journeys. |

**Self-check sekcji 2: COMPLETE** — wszystkie 9 pozycji P-01..P-09 ocenione z dowodami (grep/glob/brak plików). Wszystkie ABSENT — zgodnie z oczekiwaniem dla świeżego szkieletu.

---

## 3. Ocena infrastruktury

> **Aktualizacja po domknięciu równoległych deliverabli (2026-08-10):** migracja 0015, sekcja `human:` w config, template charteru i wymiar 15 w design doc zostały utworzone. Poniższa tabela odzwierciedla stan **po** tych zmianach.

| Element | Oczekiwane | Stan faktyczny | STATUS |
|---|---|---|---|
| **Migracja 0015** (`0015_human_plane.sql`) | Tabele `manual_charters`, `manual_sessions`, `uat_signoffs`, `ux_studies`, `friction_baselines` + `converted_test_id` | **ISTNIEJE.** `system/control-plane/state/migrations/0015_human_plane.sql` (worktree gateforge). Zawiera 5 tabel + `ALTER TABLE manual_sessions ADD COLUMN converted_test_id TEXT` + `UPDATE meta SET value='15'`. Zastosowana: `schema_version=15`, wszystkie 5 tabel + kolumna `converted_test_id` zweryfikowane w `canonical-state.db`. | **COMPLETE** |
| **Wymiar 15 w tabeli doskonałości** | Wiersz 15 w tabeli `quality_index` | **ISTNIEJE W DESIGN DOC.** `aesthetics-plane-design.md:91` — wiersz 15 (Jakość ludzka, MAN+UX-A+UX-R, `s_15` formula). QI zaktualizowane do `prod_{i=1}^{15}` (linia 95). Brak wiersza 15 w migracji `0009_aesthetics_qi.sql` (tworzy `quality_index` z komentarzem "14 wymiarów") — wymaga aktualizacji migracji. | **PARTIAL** (design doc OK, migracja 0009 do aktualizacji) |
| **Definicja friction score** | Definicja pomiaru per journey | **ISTNIEJE W DESIGN DOC.** `human-plane-design.md:73`: `friction(ścieżka) = kliknięcia + pola formularza + zmiany kontekstu + czas oczekiwania`. Osobny doc `human-plane-friction-score.md` (wariant (b)) z pełną definicją, normalizacją, budżetem i worked example. Brak implementacji (brak checków, brak synthetic journeys). | **PARTIAL** (design doc + definicja, bez implementacji) |
| **Template charteru** | Template charteru + format evidence sesji | **ISTNIEJE.** `human-plane-charter-template.md` (wariant (a)) — pełny template charteru (MAN-01/02), format evidence sesji eksploracyjnej (MAN-02/08), template UAT sign-off (MAN-03), wypełniony przykład. | **COMPLETE** |
| **Config registry `human:` section** | Sekcja `human:` w `config/canonical/registry.yaml` | **ISTNIEJE.** Sekcja `human:` dodana w `config/registry.yaml` (worktree gateforge): `manual_evidence_max_age: 14`, `exploration_cadence_days: 30`, `task_success_target: 0.95`, `conversion_rate_target: 0.8`, `friction_budget_default: 20`, `floors:` per tier (tier-0..3). | **COMPLETE** |

**Self-check sekcji 3: COMPLETE** — 5 elementów infrastruktury ocenionych z dowodami (glob migracji, grep registry.yaml, glob charter, treść migracji 0007). Migracja 0015, sekcja `human:` i template charteru **COMPLETE**; wymiar 15 i friction score **PARTIAL** (design doc, bez implementacji checków).

---

## 4. Wymiar 15 — wyliczenie `s_15`

### 4.1 Wzór (z design doc)

```
s_15 = manual_coverage × evidence_freshness × min(1, task_success_actual/task_success_target) × conversion_rate
```

### 4.2 Wyliczenie dla stanu bieżącego (szkielet)

| Czynnik | Definicja | Wartość bieżąca | Dowód |
|---|---|---|---|
| `manual_coverage` | % wymaganych ścieżek z aktywnym charterem | **0** | Tabela `manual_charters` **istnieje** (migracja 0015), ale **0 wierszy** — brak aktywnych charterów. Template charteru istnieje (`human-plane-charter-template.md`), ale nie wypełniono żadnego. |
| `evidence_freshness` | % świeżych evidence (w budżecie wieku per tier) | **0** | Tabela `manual_sessions` **istnieje**, ale **0 wierszy** — brak sesji, brak evidence. |
| `min(1, task_success_actual/task_success_target)` | skuteczność zadań (cap na 1) | **0** | Tabela `ux_studies` **istnieje**, ale **0 wierszy** — brak pomiaru task success. |
| `conversion_rate` | MAN-06: findings → testy auto | **0** | Kolumna `converted_test_id` **istnieje** (migracja 0015), ale **0 wierszy** — brak findings, brak checków MAN-06. |

### 4.3 Wynik

```
s_15 = 0 × 0 × 0 × 0 = 0
```

**Zgodnie z regułą z migracji 0007:** *"Dimension score bez świeżego evidence = 0 (nie NULL — ZERO)."* Wymiar 15 bez świeżego evidence = **0**, nie NULL. Ponieważ QI to średnia geometryczna ważona (`QI = 100 × ∏ s_i^{w_i}`), **jeden wymiar na zero → cały indeks na zero**. Dopóki HUMAN PLANE nie dostarczy świeżego evidence, QI pozostaje 0 niezależnie od pozostałych 14 wymiarów.

**Self-check sekcji 4: COMPLETE** — wyliczenie `s_15 = 0` z pełnym rozpisaniem czynników i dowodami.

---

## 5. Rekomendacje i plan

### 5.1 Priorytetyzacja (P0-P3, wg design doc)

| Priorytet | Zakres | Pozycje P | Akcja |
|---|---|---|---|
| **P0** | Fundament: pokrycie, UAT na digest, świeżość przy releasie, a11y + CWV | P-01, P-02, P-03, P-06 (UX-A-01/02) | Migracja 0015 + template charteru + checki MAN-01/03/04 + UX-A-01/02 |
| **P1** | Pętla uczenia się (conversion) + rytm badań + task success | P-04, P-05, P-07 | Kolumna `converted_test_id` + checki MAN-06/07/08 + tabela `ux_studies` + UX-R-01..04 |
| **P2** | Warstwa 150% + kompletność stanów | P-06 (UX-A-04), P-09 | Tabela `friction_baselines` + definicja friction score + synthetic journeys + UX-A-04 |
| **P3** | Domknięcie pętli skarg + sygnały frustracji | P-08 | UX escape analysis + RUM anomaly detection + UX-R-05..08 |

### 5.2 Konkretne kroki (ABSENT/PARTIAL → COMPLETE)

> **Aktualizacja po domknięciu równoległych deliverabli (2026-08-10):** kroki P0-2, P0-4, P0-5 zostały **zrealizowane** w tej sesji. Poniżej oznaczono je `[DONE]`. Pozostałe kroki (P0-1, P0-3, P1-P3) pozostają otwarte.

1. **P0-1 (metodyczny):** Dodaj **sekcję P** do SONDA (`docs/audit/sonda-package.md`) z pozycjami P-01..P-09 — obecnie sekcja P nie istnieje (patrz §1.5). To warunek wstępny dla wiarygodności kolejnych audytów. **Uwaga:** sekcja P **już istnieje** w `docs/00-foundation/SONDA.md` (P-01..P-09, utworzona w tej sesji) — pozostaje **ujednolicić** dwie SONDA (kartografia `docs/audit/sonda-package.md` vs diagnostyczna `docs/00-foundation/SONDA.md`), patrz §1.5.
2. **P0-2 `[DONE]`:** Utworzono migrację `system/control-plane/state/migrations/0015_human_plane.sql` (tabele `manual_charters`, `manual_sessions`, `uat_signoffs`, `ux_studies`, `friction_baselines` + `ALTER TABLE manual_sessions ADD COLUMN converted_test_id`). Zaktualizowano `STATE_SCHEMA_VERSION` w `system/control-plane/state/lib.sh` (9 → 15). Migracja zastosowana: `schema_version=15`, 5 tabel + kolumna zweryfikowane w `canonical-state.db`.
3. **P0-3:** Dodaj wymiar 15 do tabeli `quality_index` (migracja 0009 komentuje "14 wymiarów" — wymaga aktualizacji do 15) + wiersz 15 w design doc `aesthetics-plane-design.md` (**już istnieje**, linia 91, QI `prod_{i=1}^{15}` linia 95).
4. **P0-4 `[DONE]`:** Utworzono template charteru + format evidence sesji eksploracyjnej (`human-plane-charter-template.md`, wariant (a) design doc) — pełny template charteru (MAN-01/02), format evidence sesji (MAN-02/08), template UAT sign-off (MAN-03), wypełniony przykład.
5. **P0-5 `[DONE]`:** Dodano sekcję `human:` do `config/registry.yaml` (klucze `human.manual_evidence_max_age`, `human.exploration_cadence_days`, `human.task_success_target`, `human.conversion_rate_target`, `human.friction_budget_default`, `human.floors` per tier) — zgodnie z CFG-001..008 (jednokanałowość, schema, klucze z floor/owner/tier/doc).
6. **P1:** Dodaj checki MAN-06/07/08 + UX-R-01..04 do `tools/verify/` (moduł `human` w `config/canonical/gates.yaml` + `gen-profiles.sh`).
7. **P2:** Zdefiniuj friction score per journey (wariant (b)) + synthetic user journeys.
8. **P3:** UX escape analysis + RUM anomaly detection.

### 5.3 Kryterium domknięcia

Pozycja P-xx przechodzi z ABSENT/PARTIAL na COMPLETE, gdy:
- istnieje check ID w `tools/verify/` (np. `MAN-01`, `UX-A-01`),
- check ma test pozytywny + negatywny (wzorzec VV z wymiaru #2),
- istnieje świeże evidence w tabelach migracji 0015,
- `s_15 > 0` (wymiar 15 przestaje zerować QI).

---

## TL;DR

AUDYT v1.0 stwierdza: **HUMAN PLANE jest na etapie design doc + infrastruktura, zero evidence.** Wszystkie 9 pozycji P-01..P-09 to **ABSENT** (brak checków i evidence), ale infrastruktura została **zrealizowana w tej sesji**: migracja 0015 (5 tabel + `converted_test_id`, `schema_version=15`), sekcja `human:` w config, template charteru (`human-plane-charter-template.md`), wymiar 15 w design doc (QI `prod_{i=1}^{15}`). `s_15 = 0` (zeruje cały QI) — tabele istnieją, ale **0 wierszy evidence**. Znalezisko metodyczne: **istnieją DWIE SONDA** — kartografia `docs/audit/sonda-package.md` (bez sekcji P) vs diagnostyczna `docs/00-foundation/SONDA.md` (z sekcją P-01..P-09) — wymagają ujednolicenia. To oczekiwany stan świeżego szkieletu; plan P0-P3 domyka luki w kolejności: fundament (P0) → pętla uczenia się (P1) → warstwa 150% (P2) → domknięcie skarg (P3). Kroki P0-2/4/5 zrealizowane; otwarte: P0-1 (ujednolicenie SONDA), P0-3 (wiersz 15 w migracji 0009), P1-P3.
