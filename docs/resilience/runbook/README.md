# Runbook — Indeks i przygotowanie

> **Właściciel:** Resilience Plane
> **Cel:** procedura operacyjna (runbook) do odbudowy tier-0 control plane'u z backupu — do użycia **w trakcie** awarii, jako wydrukowana checklista.

## 1. Purpose
Indeks i przygotowanie runbooka — procedury operacyjnej do odbudowy tier-0 control plane'u z backupu, do użycia w trakcie rzeczywistej awarii jako wydrukowana checklista.

## 2. Owner
`STATUS: RESILIENCE PLANE` — Resilience Plane.

## 3. Source of Truth
Git = desired state (runbook, checklisty przygotowania). Faktyczny stan odbudowy to actual state (Runtime, StateStore).

## 4. Contains
Zakres runbooka (tier-0 control plane), procedura pełnego cyklu odbudowy (diagnoza → decyzja → restore → walidacja → evidence → cleanup), metryki (RTO/RPO), relacja runbook ↔ game day, checklista przygotowania, zasady ogólne, dokument `runbook-tier0.md`.

## 5. Does Not Contain
Nie zawiera wyników ćwiczeń (te są w `docs/resilience/game-day/`), nie zawiera danych produkcyjnych, nie zawiera procedur specyficznych dla pojedynczego scenariusza ćwiczenia.

## 6. Dependencies
`state.sh` (backup/restore), `tools/resilience/restore-drill/restore-drill.sh`, `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age`), tabela `game_days` (migration 0014).

## 7. Consumers
Zespół operacyjny (wykonawcy, obserwatorzy), Suweren (decydent), Resilience Plane, uczestnicy game day'ów.

## 8. Synchronization
`CANONICAL` — runbook jest źródłem prawdy w git; aktualizowany o odstępstwa po każdym game day'u, aby odzwierciedlić faktyczny, poprawny przebieg.

## 9. Lifecycle
Powstaje przy definiowaniu procedury odbudowy, aktualizowany po każdym game day'u (odstępstwa, root cause), wycofywany gdy procedura przestaje być aktualna.

## 10. Security
Restore na produkcji **tylko** po zatwierdzeniu suwerena; awaria musi być odwracalna (backup istnieje). Separacja ról: wykonawca ≠ obserwator. "Czerwony przycisk" (warunki przerwania) znany wszystkim.

## 11. Recovery
Odzyskiwane z git (checkout). Procedura odbudowy stanu z backupu opisana w `runbook-tier0.md` (Sekcje 0–8).

## 12. Drift Detection
Drift wykrywany przez walidację: runbook nieaktualny względem faktycznego przebiegu (odstępstwa z game day'ów), klucze resilience w `config/registry.yaml` odbiegają od celów RTO/RPO.

---

## 1. Co obejmuje ten runbook

- **Zakres:** tier-0 control plane (baza stanu canonical state).
- **Procedura:** pełny cykl odbudowy — diagnoza → decyzja → restore → walidacja → evidence → cleanup.
- **Metryki:** RTO ≤ 15 min, RPO ≤ 5 min (z `config/registry.yaml` → `resilience.rto` / `resilience.rpo`).
- **Format:** print-ready — sekcje z checkboxami `[ ]`, do wydrukowania i odhaczania w trakcie awarii.

### 1.1 Dokumenty

| Dokument | Opis |
|---|---|
| [runbook-tier0.md](runbook-tier0.md) | Pełny runbook odbudowy tier-0 (Sekcje 0–8) |

---

## 2. Kiedy używać

- **Runbook** = procedura. Używasz go **w trakcie rzeczywistej awarii** tier-0 control plane'u, aby odbudować stan z backupu.
- **Game day** = ćwiczenie. Używasz go, aby **przećwiczyć** procedurę w środowisku scratch i udowodnić, że działa (RTO/RPO/evidence).

### 2.1 Relacja runbook ↔ game day

| | Runbook | Game day |
|---|---|---|
| **Kiedy** | w trakcie awarii (produkcja / scratch) | zaplanowane ćwiczenie (scratch) |
| **Cel** | odbudować usługę | udowodnić, że odbudowa działa |
| **Metryki** | RTO/RPO mierzone na żywo | RTO/RPO mierzone i zapisywane do `game_days` |
| **Dokument** | `docs/resilience/runbook/runbook-tier0.md` | `docs/resilience/game-day/game-day-01.md` |

> Game day **testuje** runbook. Jeśli w trakcie game day'u wystąpią odstępstwa — aktualizujemy runbook, aby odzwierciedlić faktyczny, poprawny przebieg.

---

## 3. Checklista przygotowania (przed awarią / przed game day'em)

### 3.1 Dokumentacja i środowisko

- [ ] Runbook wydrukowany (lub dostępny offline): `docs/resilience/runbook/runbook-tier0.md`.
- [ ] Środowisko docelowe znane (scratch / prod) i potwierdzone.
- [ ] Klucze resilience w `config/registry.yaml` (`rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier) zgodne z celami.

### 3.2 Backup

- [ ] Backup stanu wykonany: `state.sh backup` → zapisany `SID`.
- [ ] Backup zweryfikowany: `state.sh backup-verify SID` → PASS.
- [ ] `SID` ostatniego dobrego backupu znany i zapisany.

### 3.3 Narzędzia

- [ ] Pipeline `tools/resilience/restore-drill/restore-drill.sh` dostępny (lub udokumentowany fallback ręczny `state.sh restore <SID>`).
- [ ] `state.sh` dostępny i działa (`state.sh status`).

### 3.4 Role

- [ ] Suweren (decydent) wyznaczony.
- [ ] Wykonawca wyznaczony.
- [ ] Obserwator wyznaczony (nie wykonawca).
- [ ] Zasada "nikt nie łączy ról wykonawca + obserwator" potwierdzona.
- [ ] "Czerwony przycisk" (warunki przerwania) znany wszystkim.

---

## 4. Zasady ogólne

- **RULE ZERO:** każde odwołanie do "systemu" wskazuje konkretny skrypt/komendę (`state.sh`, `restore-drill.sh`).
- **NO FALSE GREEN:** zaliczenie wymaga twardych, mierzalnych kryteriów — nie "wygląda dobrze".
- **Bezpieczeństwo:** restore na produkcji **tylko** po zatwierdzeniu suwerena; awaria musi być odwracalna (backup istnieje).
- **Separacja ról:** wykonawca ≠ obserwator.
