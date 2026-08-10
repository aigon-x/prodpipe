# ADR-0001 — Risk Prediction (S7) w System Quality Gates

> **Type:** ADR
> **Status:** PROPOSED
> **Owner:** UNASSIGNED
> **Supersedes:** —
> **Superseded By:** —
> **Source of Truth:** Git (governance/decisions)

## 1. Title

Risk prediction (S7) — przewidywanie ryzyka regresji na podstawie danych z `evidence` i `gate_runs`.

## 2. Status

**PROPOSED**

Uzasadnienie: niniejszy dokument jest design doc — definiuje schemat danych treningowych, pipeline i integrację z gate'ami, ale nie jest jeszcze wdrożony. Status `PROPOSED` sygnalizuje, że decyzja wymaga akceptacji (przegląd architektoniczny) zanim stanie się wiążąca. Przejście do `ACCEPTED` nastąpi po zatwierdzeniu i rozpoczęciu implementacji.

## 3. Context

System Quality Gates (Sekcja 9 w `ARCHITECTURE.md`) definiuje gate'y G0–G8. S7 to **risk prediction** — przewidywanie ryzyka regresji/awarii na podstawie historii uruchomień gate'ów.

Zasada P0#1: każdy gate zapisuje wynik do StateStore (tabela `evidence`). Gate bez evidence = FAIL (meta-gate `VERIFY-EVIDENCE-COMPLETE`). Dane treningowe dla S7 to dokładnie to, co wpada do `evidence` i `gate_runs` — każdy dzień działania gate'ów to dane treningowe.

**Problem:** jak przewidzieć, że dany commit/PR wprowadzi regresję (fail w gate, który wcześniej passował), zanim certyfikacja się zakończy? Cel: wczesne wykrywanie ryzyka i uczenie się z historii gate'ów.

Dostępne surowce danych:

- **Tabela `evidence`** (migracja 0001): `evidence_id`, `claim`, `source_type`, `source_ref`, `generation`, `state_hash`, `recorded_at`.
- **Tabela `gate_runs`** (migracja 0003): `id`, `run_id` (np. commit SHA), `gate`, `profile`, `status` (`pass`/`fail`/`warn`/`waived`), `duration_ms`, `created_at`. Komentarz w migracji: *"gate_runs rejestruje KAŻDE uruchomienie gate'a — to jest surowiec dla risk prediction (S7), dane treningowe."*
- **`evidence_record()`** w `tools/verify/core/lib.sh` zapisuje do `evidence`: `claim`, `source_type`, `source_ref`; inkrementuje `VERIFY_EVIDENCE_COUNT`.

## 4. Problem

Brak mechanizmu przewidywania ryzyka. Obecnie certyfikacja jest reaktywna: ryzyko wykrywane jest dopiero, gdy gate failuje. S7 ma umożliwić **proaktywne** wskazanie commitów/PR-ów o podwyższonym prawdopodobieństwie regresji, na podstawie wzorców w historycznych przebiegach gate'ów.

## 5. Decision

### 5.1 Schemat danych treningowych

Zbiór treningowy budowany jest z połączenia `evidence` i `gate_runs`. Każdy **przypadek (sample)** odpowiada jednemu uruchomieniu gate'a w kontekście konkretnego `run_id` (commit).

**Cechy (features):**

| Cecha | Źródło | Typ | Uwagi |
|---|---|---|---|
| `gate` | `gate_runs.gate` | kategoryczna | nazwa gate'a (np. `SELF-001`, `G0`, `VERIFY-EVIDENCE-COMPLETE`) |
| `profile` | `gate_runs.profile` | kategoryczna | `fast`/`full`/`release`/`genesis`/… |
| `status` | `gate_runs.status` | kategoryczna | `pass`/`fail`/`warn`/`waived` |
| `duration_ms` | `gate_runs.duration_ms` | liczbowa | czas trwania; anomalie czasowe mogą sygnalizować ryzyko |
| `source_type` | `evidence.source_type` | kategoryczna | `verify`/`gate`/`module` |
| `source_ref` | `evidence.source_ref` | kategoryczna | identyfikator źródła (np. `git/integrity.sh`) |
| `generation` | `evidence.generation` | liczbowa | generacja stanu |
| `run_id` | `gate_runs.run_id` | kategoryczna | commit SHA — identyfikator przebiegu |
| `recorded_at` / `created_at` | `evidence` / `gate_runs` | czasowa | znacznik czasu; podstawa walidacji chronologicznej |
| sekwencja czasowa | agregacja po `run_id` | sekwencyjna | kolejność uruchomień gate'ów w obrębie przebiegu |

**Etykiety (labels):**

| Etykieta | Definicja | Typ |
|---|---|---|
| `regression` | 1, jeśli dany gate w danym `run_id` failuje, a w poprzednim `run_id` (dla tego samego gate'a) passował; 0 w przeciwnym razie | binarna |
| `certification_result` | końcowy wynik certyfikacji dla `run_id` (PASS/FAIL) | binarna |
| `time_to_next_fail` | czas (liczba uruchomień / dni) do kolejnego fail w danym gate | liczbowa (regresja) |

**Cel predykcji (primary):** prawdopodobieństwo, że dany commit/PR wprowadzi regresję — tj. że gate, który wcześniej passował, w tym przebiegu failuje. Model klasyfikacji binarnej na etykiecie `regression`.

**Agregacja danych:**

- **per `run_id`** — grupowanie wszystkich uruchomień gate'ów danego przebiegu (commit) w jeden wektor cech; podstawa predykcji na poziomie commita.
- **per `gate`** — historia statusów danego gate'a w czasie; podstawa wykrywania regresji (pass→fail) i trendów.
- **per commit** — łączenie cech z `gate_runs` i `evidence` dla danego `run_id`; finalny zbiór treningowy.

### 5.2 Pipeline treningowy (koncepcyjnie — NIE implementacja)

- **ETL:** `evidence` + `gate_runs` → zbiór treningowy. Ekstrakcja przez SQL (JOIN po `run_id`/`source_ref`), materializacja do formatu kolumnowego (CSV/Parquet). Agregacja per `run_id`/`gate`/commit zgodnie z §5.1.
- **Model:** klasyfikacja binarna (regresja vs nie). Proponowane podejścia (do wyboru w fazie implementacji): gradient boosting lub regresja logistyczna. Preferencja dla modeli interpretowalnych (logistyczna) przy małej ilości danych; gradient boosting przy większych zbiorach.
- **Ewaluacja:** metryki `precision`/`recall`/`AUC`. **Walidacja chronologiczna** (train na starszych `run_id`, test na nowszych) — NIE losowa, aby uniknąć przecieku czasowego i odzwierciedlić rzeczywisty scenariusz predykcji przyszłości.
- **Retraining:** przy każdej nowej partii `gate_runs` (np. po każdym przebiegu certyfikacji). Model jest odtwarzany na pełnej historii, nie inkrementalnie (na tym etapie).

### 5.3 Integracja z gate'ami

- **S7 jako gate:** jeśli model przewiduje wysokie prawdopodobieństwo regresji dla danego `run_id` → gate `FAIL` (BLOCKING) lub `WARN` (zależnie od progu).
- **Próg decyzyjny (threshold):** konfigurowalny (np. w profilu gate'a). Dwa progi: `warn_threshold` (→ `WARN`) i `fail_threshold` (→ `FAIL`).
- **Fail-closed:** jeśli model niedostępny, brak danych treningowych lub błąd predykcji → gate `FAIL` (nie `skip`). Zgodne z zasadą P0#1 — brak evidence/niepewność nie może być traktowana jako sukces.

## 6. Alternatives

| Alternatywa | Odrzucona, bo |
|---|---|
| Predykcja heurystyczna (reguły, bez modelu) | Prosta, ale nie uczy się z historii i nie skaluje do złożonych wzorców |
| Model na poziomie całego repo (bez per-gate) | Traci granularność — nie wykrywa regresji w pojedynczych gate'ach |
| Walidacja losowa (train/test split losowy) | Przeciek czasowy — model "podglądałby" przyszłość; odrzucona na rzecz walidacji chronologicznej |
| Brak S7 (reaktywna certyfikacja) | Status quo — nie rozwiązuje problemu proaktywnego wykrywania ryzyka |

## 7. Consequences

**Pozytywne:**
- Wczesne wykrywanie ryzyka regresji przed zakończeniem certyfikacji.
- Uczenie się z historii gate'ów — model poprawia się z każdym przebiegiem.
- Fail-closed gwarantuje, że brak danych nie osłabia bramki jakości.

**Negatywne:**
- **Zimny start:** wymaga zgromadzenia wystarczającej historii `gate_runs`/`evidence` zanim model będzie użyteczny.
- **Ryzyko overfittingu:** przy małej liczbie `run_id` model może dopasować się do szumu; łagodzone przez walidację chronologiczną i preferencję prostych modeli.
- **Koszt utrzymania:** pipeline ETL, retraining, monitoring jakości modelu (dryf danych).

**Kompromisy:**
- Dokładność vs prostota: gradient boosting (mocniejszy) vs regresja logistyczna (interpretowalna).
- Interpretowalność vs moc predykcyjna: prostsze modele łatwiej audytować, ale mogą być mniej dokładne.
- Czułość vs swoistość: niższy próg → więcej fałszywych alarmów (WARN/FAIL), wyższy próg → więcej przeoczonych regresji.

## 8. Evidence

- `ARCHITECTURE.md` Sekcja 9, zasada P0#1: *"Risk prediction (S7) trenuje się na danych z `evidence`/`gate_runs`."*
- Migracja `0003_gate_runs_waivers.sql`: tabela `gate_runs` — *"surowiec dla risk prediction (S7), dane treningowe."*
- Migracja `0001_initial.sql`: tabela `evidence`.
- `tools/verify/core/lib.sh`: `evidence_record()` zapisuje `claim`, `source_type`, `source_ref`.

## 9. Source of Truth

Git — `governance/decisions/ADR-0001-risk-prediction-s7.md`.

## 10. Owner

`UNASSIGNED` (do przypisania w procesie akceptacji).

## 11. Supersedes

—

## 12. Superseded By

—
