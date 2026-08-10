# Game Day — Indeks i przygotowanie

> **Właściciel:** Resilience Plane (sub-deliverable b)
> **Cel:** udowodnienie, że restore drill i procedury awaryjne działają end-to-end, z twardymi metrykami (RTO/RPO) i zapisanym evidence.

---

## 1. Indeks game day'ów

| ID | Scenariusz | Data | Wynik | RTO | RPO | Evidence |
|---|---|---|---|---|---|---|
| GD-01 | Utrata control plane'u tier-0 (restore drill end-to-end) | planowany | — | ≤ 15 min (cel) | 0 (cel) | `game_days` + JSON |
| GD-02 | *(do zaplanowania)* | — | — | — | — | — |
| GD-03 | *(do zaplanowania)* | — | — | — | — | — |

> Po każdym game day'u uzupełnij wiersz wynikami z tabeli `game_days` (migration 0009).

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
- [ ] Tabela `game_days` (migration 0009) gotowa na zapis wyników.
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
