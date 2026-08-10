---

# HUMAN PLANE — człowiek jako oracle, proces jako gate

> Design doc — źródło specyfikacji dla implementacji HUMAN PLANE.
> Status: DESIGN (do implementacji).

## Cel

Testy manualne i UX **nie mogą być w 100% zautomatyzowane** — ale **proces, w którym człowiek jest oracle, MOŻE być w 100% zgatedowany**. HUMAN PLANE zamienia "ktoś kiedyś kliknął" w audytowalny, świeży, powtarzalny proces z evidence.

Dwie zasady kanoniczne:

> **Aktywność manualna bez evidence = nie odbyła się.**
> **Evidence manualne bez świeżości = nieważne.**

Człowiek nie jest słabym ogniwem — jest **jedynym źródłem prawdy dla tego, czego automat nie zmierzy** (czy coś jest *używalne*, nie tylko *działa*). HUMAN PLANE daje mu proces, który to udowadnia.

## Trzy rodziny gate'ów

### MAN — testy manualne (MAN-01..08)

| ID | Check | Co mierzy |
|---|---|---|
| MAN-01 | Coverage requirement → auto OR manual charter — każda wymagana ścieżka ma albo test automatyczny, albo udokumentowany charter manualny | kompletność pokrycia |
| MAN-02 | Session-based testing — testy manualne w sesjach (nie "klikam coś"), każda sesja ma charter + evidence | dyscyplina procesu |
| MAN-03 | UAT sign-off bound to artifact digest — akceptacja podpisana na konkretny digest artefaktu (nie "wersja ogólnie") | niepodrabialność akceptacji |
| MAN-04 | Release tier 1 requires fresh manual evidence — release tier-1 nie przechodzi bez świeżego dowodu manualnego | świeżość przy releasie |
| MAN-05 | Exploration cadence per tier — rytm eksploracji zależny od tieru (tier-0 częściej) | rytm, nie jednorazowość |
| MAN-06 | MANUAL→AUTO CONVERSION (serce) — findings manualne przekute na testy automatyczne; mierzone `conversion_rate` | pętla uczenia się |
| MAN-07 | Independence SoD — tester ≠ autor; separation of duties, brak self-approval | niezależność weryfikacji |
| MAN-08 | Tester evidence quality — evidence manualne kompletne (kroki, oczekiwane, faktyczne, artefakt) | jakość dowodu |

**MAN-06 conversion rate** (serce pętli):

```
conversion_rate = |findings_manual przekute na testy auto| / |findings_manual|
```

Im wyższy, tym mniej pracy manualnej w przyszłości — system sam się automatyzuje. To jest mechanizm, przez który HUMAN PLANE *kurczy się* w czasie.

### UX-A — UX automatable (UX-A-01..08, obowiązkowe)

| ID | Check | Co mierzy |
|---|---|---|
| UX-A-01 | A11y automated — axe-core/pa11y, WCAG 2.2 AA | dostępność automatyczna |
| UX-A-02 | Core Web Vitals budget — LCP/INP/CLS w budżecie | wydajność odczuwalna |
| UX-A-03 | Visual regression — snapshoty ekranów, diff w CI | brak regresji wizualnej |
| UX-A-04 | Four states of every screen — empty/loading/error/data dla każdego ekranu | kompletność stanów |
| UX-A-05 | Design tokens conformance — spina AEST-11, custom CSS = waiver | spójność wizualna |
| UX-A-06 | Error messages actionable — spina AEST-07, komunikat "co i jak naprawić" | dopracowanie powierzchni |
| UX-A-07 | i18n readiness — brak hardcoded stringów, klucze w katalogu | gotowość tłumaczeń |
| UX-A-08 | Keyboard-only journey — pełna ścieżka klawiaturą, focus order | dostępność klawiatury |

### UX-R — UX governance (UX-R-01..08, nieautomatyzowalne)

| ID | Check | Co mierzy |
|---|---|---|
| UX-R-01 | Usability study cadence — rytm badań użyteczności per tier | rytm badań |
| UX-R-02 | Task success rate — % użytkowników kończących zadanie | skuteczność |
| UX-R-03 | Time-on-task regression — czas zadania nie rośnie | wydajność |
| UX-R-04 | SUS/UMUX-Lite tracking — standardowe kwestionariusze | satysfakcja |
| UX-R-05 | RUM + session replay — rage clicks / dead clicks / u-turns | sygnały frustracji |
| UX-R-06 | Heuristic evaluation — Nielsen 10 | ekspertyza |
| UX-R-07 | A11y with humans — ~40% WCAG łapie tylko człowiek | dostępność ludzka |
| UX-R-08 | Dogfooding gate — zespół używa własnego produktu | prawdziwe użycie |

## Warstwa 150% — ponad 100% pokrycia

### A. Friction budget

```
friction(ścieżka) = kliknięcia + pola formularza + zmiany kontekstu + czas oczekiwania
```

Każda krytyczna ścieżka ma **budżet tarcia** (z configu). Przekroczenie = FAIL. Tarcie to koszt poznawczy użytkownika — mierzalny, nie opinia.

### B. Synthetic user journeys

Robot (synthetic user) **chodzi po krytycznych ścieżkach na produkcji** — nie w testach. To łapie to, czego staging nie pokaże: prawdziwe dane, prawdziwe opóźnienia, prawdziwe stany.

### C. UX escape analysis

Każda skarga użytkownika → klasyfikacja:

| Klasa | Znaczenie | Akcja |
|---|---|---|
| gate istniał i przeszedł | gate był za słaby / źle zmierzony | wzmocnij gate |
| gate nie istniał | luka w pokryciu | dodaj gate |
| waiver | świadome odstępstwo | przegląd waivera |

Escape bez `closed_at` = FAIL (wzorzec CORR-escape z wymiaru 14).

## Wymiar 15 tabeli doskonałości

```
s_15 = manual_coverage × evidence_freshness × min(1, task_success_actual/task_success_target) × conversion_rate
```

- `manual_coverage` — % wymaganych ścieżek z aktywnym charterem (auto lub manual).
- `evidence_freshness` — % świeżych evidence (w budżecie wieku per tier).
- `task_success_actual/task_success_target` — skuteczność zadań (cap na 1).
- `conversion_rate` — MAN-06.

QI aktualizuje się do **15 wymiarów**:

$$QI = 100 \times \prod_{i=1}^{15} s_i^{w_i}, \qquad \sum_i w_i = 1$$

## Migracja 0015: human plane

> **Uwaga o numeracji**: po pełnej re-numeracji chronologicznej (2026-08-10) migracja nosi numer **0015** (sekwencja 0001–0016). `STATE_SCHEMA_VERSION=16` w `lib.sh` odpowiada ostatniej migracji (0016_contracts).

```sql
-- migrations/0015_human_plane.sql
CREATE TABLE manual_charters (        -- MAN-01/02: udokumentowane charters
  charter_id      TEXT PRIMARY KEY,
  service_id      TEXT NOT NULL,
  journey_id      TEXT NOT NULL,      -- ścieżka użytkownika
  tier            TEXT NOT NULL,
  coverage_type   TEXT NOT NULL,      -- AUTO | MANUAL
  status          TEXT NOT NULL DEFAULT 'ACTIVE',
  owner           TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE manual_sessions (        -- MAN-02/08: sesje testowe z evidence
  session_id      TEXT PRIMARY KEY,
  charter_id      TEXT NOT NULL REFERENCES manual_charters(charter_id),
  tester          TEXT NOT NULL,
  started_at      TEXT NOT NULL,
  completed_at    TEXT,
  result          TEXT NOT NULL DEFAULT 'PENDING',  -- PASS | FAIL | FINDINGS
  artifact_digest TEXT,               -- MAN-03: UAT bound to digest
  evidence_ref    TEXT,
  recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE uat_signoffs (           -- MAN-03: akceptacja na digest
  signoff_id      TEXT PRIMARY KEY,
  service_id      TEXT NOT NULL,
  artifact_digest TEXT NOT NULL,
  approver        TEXT NOT NULL,
  tier            TEXT NOT NULL,
  signed_at       TEXT NOT NULL,
  evidence_ref    TEXT
);
CREATE TABLE ux_studies (             -- UX-R-01..08: badania użyteczności
  study_id        TEXT PRIMARY KEY,
  service_id      TEXT NOT NULL,
  study_type      TEXT NOT NULL,      -- USABILITY | SUS | HEURISTIC | DOGFOOD
  tier            TEXT NOT NULL,
  task_success_rate REAL,
  time_on_task_sec REAL,
  sus_score       REAL,
  conducted_at    TEXT NOT NULL,
  evidence_ref    TEXT
);
CREATE TABLE friction_baselines (     -- warstwa 150% A: budżety tarcia
  journey_id      TEXT PRIMARY KEY,
  service_id      TEXT NOT NULL,
  friction_budget INTEGER NOT NULL,   -- suma kliknięć+pól+kontekstów+czasu
  measured_friction INTEGER,
  status          TEXT NOT NULL DEFAULT 'WITHIN_BUDGET',
  measured_at     TEXT
);
-- MAN-06: findings manualne → testy automatyczne
ALTER TABLE manual_sessions ADD COLUMN converted_test_id TEXT;
```

## Kolejność wdrożenia (P0-P3)

| Faza | Zakres | Dlaczego |
|---|---|---|
| **P0** | MAN-01/03/04 + UX-A-01/02 | fundament: pokrycie, UAT na digest, świeżość przy releasie, a11y + CWV |
| **P1** | MAN-06 + UX-R-01/02 | pętla uczenia się (conversion) + rytm badań + task success |
| **P2** | Friction budgets + synthetic journeys + UX-A-04 | warstwa 150% + kompletność stanów |
| **P3** | UX escape analysis + RUM anomaly detection | domknięcie pętli skarg + sygnały frustracji |

## Trzy warianty (wdrażane równolegle)

1. **(a) charter + evidence** — pełny template charteru + format evidence sesji eksploracyjnej (gotowy do użycia).
2. **(b) friction score** — definicja pomiaru per journey z przykładem (warstwa 150% A).
3. **(c) AUDYT v1.0** — audyt na bazie SONDA + sekcja P (testy manualne i UX).

## TL;DR — dlaczego ten design jest kompletny

```
skuteczność human plane = pokrycie(chartery) × świeżość(evidence) × skuteczność(task success) × uczenie się(conversion)
```

I każdy czynnik jest **sprawdzalny przez gate'y** — MAN-01..08 pilnują procesu, UX-A-01..08 pilnują automatyzowalnej UX, UX-R-01..08 pilnują governance. HUMAN PLANE domyka pętlę: **człowiek jest oracle, proces jest gate'em, a system sam się automatyzuje**.
