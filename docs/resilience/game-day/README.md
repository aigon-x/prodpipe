# Game Day — Indeks i przygotowanie

> **Właściciel:** Resilience Plane (sub-deliverable b)
> **Cel:** udowodnienie, że restore drill i procedury awaryjne działają end-to-end, z twardymi metrykami (RTO/RPO) i zapisanym evidence.

## 1. Purpose
Indeks i przygotowanie game day'ów — zaplanowanych ćwiczeń awaryjnych, które udowadniają, że restore drill i procedury odbudowy działają end-to-end, z twardymi metrykami (RTO/RPO) i zapisanym evidence.

## 2. Owner
`STATUS: RESILIENCE PLANE` — Resilience Plane (sub-deliverable b).

## 3. Source of Truth
Git = desired state (indeks game day'ów, checklisty przygotowania). Faktyczne wyniki ćwiczeń to actual state (tabela `game_days`, migration 0014).

## 4. Contains
Indeks game day'ów (tabela GD-01..GD-03), checklista przygotowania (środowisko, obsada, dokumentacja i metryki, po game day'u), zasady ogólne, szczegóły scenariuszy (np. `game-day-01.md`).

## 5. Does Not Contain
Nie zawiera wyników ćwiczeń (te trafiają do tabeli `game_days`), nie zawiera procedur operacyjnych (te są w `docs/resilience/runbook/`), nie zawiera danych produkcyjnych.

## 6. Dependencies
`tools/resilience/restore-drill/restore-drill.sh`, `state.sh` (backup/restore), `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age`), tabela `game_days` (migration 0014), runbook (`docs/resilience/runbook/`).

## 7. Consumers
Zespół operacyjny (wykonawcy, obserwatorzy), Suweren (decydent), facilitator, Resilience Plane.

## 8. Synchronization
`CANONICAL` — indeks i checklisty są źródłem prawdy w git; wyniki ćwiczeń synchronizowane do tabeli `game_days` po każdym game day'u.

## 9. Lifecycle
Powstaje przy planowaniu game day'ów, aktualizowany po każdym ćwiczeniu (wyniki, odstępstwa), wycofywany gdy scenariusz przestaje być istotny.

## 10. Security
Awarie wstrzykujemy wyłącznie w środowisku scratch, nigdy na produkcji. Separacja ról: wykonawca ≠ obserwator. Zasada "czerwony przycisk" (warunki przerwania) ogłoszona przed ćwiczeniem.

## 11. Recovery
Odzyskiwane z git (checkout). Wyniki ćwiczeń odzyskiwane z tabeli `game_days` (StateStore).

## 12. Drift Detection
Drift wykrywany przez walidację: wyniki w tabeli `game_days` odbiegają od celów RTO/RPO w `config/registry.yaml`; runbook nieaktualny względem faktycznego przebiegu ćwiczenia.

---

## 1. Indeks game day'ów

| ID | Scenariusz | Data | Wynik | RTO | RPO | Evidence |
|---|---|---|---|---|---|---|
| GD-01 | Utrata control plane'u tier-0 (restore drill end-to-end) | planowany | — | ≤ 15 min (cel) | 0 (cel) | `game_days` + JSON |
| GD-02 | *(do zaplanowania)* | — | — | — | — | — |
| GD-03 | *(do zaplanowania)* | — | — | — | — | — |

> Po każdym game day'u uzupełnij wiersz wynikami z tabeli `game_days` (migration 0014).

### 1.1 Szczegóły

- **GD-01** — pełny scenariusz krok po kroku: [game-day-01.md](game-day-01.md)

---

## 2. Checklista przygotowania (przed każdym game day'em)

### 2.1 Środowisko

- [ ] Środowisko scratch / testowe przygotowane (osobny katalog, osobna baza stanu, osobne dane).
- [ ] Potwierdzone, że **NIE** pracujemy na produkcji.
- [ ] Backup stanu wykonany: `state.sh backup` → zapisany `SID`.
- [ ] Backup zweryfikowany: `state.sh backup-verify SID` → PASS.
- [ ] Pipeline `tools/resilience/restore-drill/restore-drill.sh` dostępny (lub udokumentowany fallback ręczny).

### 2.2 Obsada

- [ ] Facilitator wyznaczony (nie wykonawca).
- [ ] Suweren (decydent) wyznaczony.
- [ ] Wykonawca wyznaczony.
- [ ] Obserwator wyznaczony (nie wykonawca).
- [ ] Zasada "nikt nie łączy ról wykonawca + obserwator" potwierdzona.

### 2.3 Dokumentacja i metryki

- [ ] Metryki sukcesu (RTO/RPO) znane wszystkim uczestnikom.
- [ ] "Czerwony przycisk" (warunki przerwania) ogłoszony.
- [ ] Runbook (`docs/resilience/runbook/`) aktualny i dostępny.
- [ ] Tabela `game_days` (migration 0014) gotowa na zapis wyników.
- [ ] Klucze resilience w `config/registry.yaml` (`rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier) zgodne z celami.

### 2.4 Po game day'u

- [ ] Wyniki zapisane do `game_days`.
- [ ] Evidence (JSON) zapisany i wskazany w tabeli.
- [ ] Runbook zaktualizowany o odstępstwa.
- [ ] Root cause (jeśli FAIL) przeanalizowany, akcje zaplanowane.
- [ ] Kolejny game day zaplanowany (jeśli wymagany).

---

## 3. Zasady ogólne

- **RULE ZERO:** każde odwołanie do "systemu" wskazuje konkretny skrypt/komendę (`state.sh`, `restore-drill.sh`).
- **NO FALSE GREEN:** zaliczenie wymaga twardych, mierzalnych kryteriów — nie "wygląda dobrze".
- **Bezpieczeństwo:** awarie wstrzykujemy wyłącznie w środowisku scratch, nigdy na produkcji.
- **Separacja ról:** wykonawca ≠ obserwator.
