# Game Day 01 — Utrata control plane'u tier-0 (restore drill end-to-end)

> **Status:** planowany (pierwszy game day)
> **Typ:** restore drill — pełny cykl `backup → restore → walidacja → evidence → destroy`
> **Środowisko:** scratch / testowe (NIE produkcja)
> **Czas trwania (plan):** ~90 minut
> **Właściciel dokumentu:** Resilience Plane (sub-deliverable b)

---

## 1. Cel i metryki sukcesu

### 1.1 Co udowadniamy

Ten game day ma **udowodnić**, nie "zademonstrować", że:

1. **Restore drill działa end-to-end** — pipeline `tools/resilience/restore-drill/restore-drill.sh` przechodzi pełny cykl: backup → restore → walidacja → evidence → destroy, bez ręcznej interwencji w środku.
2. **RTO jest osiągalne** — od momentu wykrycia awarii do potwierdzonego przywrócenia usługi mija ≤ 15 minut.
3. **RPO jest osiągalne** — po restore nie ma utraty danych względem ostatniego zweryfikowanego backupu (zero utraty danych w oknie RPO).
4. **Evidence jest zapisywany** — wyniki trafiają do tabeli `game_days` (migration 0009) oraz do katalogu evidence pipeline'u.
5. **Ludzie znają runbook** — wykonawcy potrafią obsłużyć awarię bez czytania dokumentacji od zera; obserwatorzy potrafią mierzyć czas i odstępstwa.

### 1.2 Metryki sukcesu (twarde, mierzalne)

| Metryka | Cel (pass) | Próg (fail) | Źródło pomiaru |
|---|---|---|---|
| RTO (wykrycie → usługa przywrócona) | ≤ 15 min | > 15 min | stoper obserwatora, znaczniki czasu w logu game day |
| RPO (utrata danych) | 0 rekordów | > 0 rekordów | porównanie `backup-verify` przed/po + testy walidacyjne |
| Restore drill exit code | 0 | ≠ 0 | `tools/resilience/restore-drill/restore-drill.sh` |
| Evidence wygenerowany | plik JSON + wpis w `game_days` | brak | `backup-restore-test` (F5) + migration 0009 |
| Backup-verify po restore | PASS | FAIL | `state.sh backup-verify SID` |
| Odstępstwa od runbooka | 0 krytycznych | ≥ 1 krytyczne | checklista obserwatora |

> **NO FALSE GREEN:** "wygląda dobrze" nie jest kryterium. Każda metryka ma twardy próg i konkretne źródło pomiaru. Game day jest **niezaliczony**, jeśli którakolwiek metryka z kolumny "fail" została przekroczona — nawet jeśli usługa "wróciła".

---

## 2. Role i obsada

**Zasada nadrzędna: nikt nie łączy ról wykonawca + obserwator.** Osoba, która wykonuje restore, nie może jednocześnie oceniać, czy zrobiła to poprawnie.

| Rola | Kto | Obowiązki |
|---|---|---|
| **Facilitator** | 1 osoba (nie wykonawca) | Prowadzi przebieg, pilnuje timeline'u, ogłasza fazy, trzyma "czerwony przycisk" |
| **Suweren (decydent)** | 1 osoba (właściciel systemu) | Podejmuje decyzje o failover/restore, zatwierdza przerwanie, ocenia wynik końcowy |
| **Wykonawca** | 1–2 osoby | Wykonuje komendy `state.sh` i `restore-drill.sh`, obsługuje awarię |
| **Obserwator** | 1–2 osoby | Notuje czas każdej fazy, odstępstwa od runbooka, decyzje; NIE dotyka klawiatury |
| **Inżynier awarii (injector)** | 1 osoba (może być facilitator) | Wstrzykuje awarię w fazie 1, zna dokładnie co i kiedy zostało uszkodzone |

**Minimalna obsada:** 4 osoby (facilitator, suweren, wykonawca, obserwator). Przy mniejszej obsadzie — łączyć tylko role niekolidujące (np. facilitator + injector), **nigdy** wykonawca + obserwator.

---

## 3. Scenariusz awarii (inject)

### 3.1 Wybrany scenariusz: utrata control plane'u tier-0

Realistyczny scenariusz: **uszkodzenie bazy stanu control plane'u tier-0** — plik stanu zostaje nadpisany/usunięty, przez co `state.sh` nie może odczytać aktualnego stanu, a usługa tier-0 nie startuje.

### 3.2 Jak symulujemy (bezpiecznie, NIE na produkcji)

1. **Środowisko:** scratch / testowe — osobny katalog roboczy, osobna baza stanu, osobne dane. Nigdy nie wstrzykujemy awarii na produkcji.
2. **Przygotowanie (przed game day):**
   - Wykonawca robi **pełny backup** stanu: `state.sh backup` → otrzymuje `SID`.
   - Weryfikuje backup: `state.sh backup-verify SID` → PASS.
   - Zapamiętuje `SID` jako "ostatni dobry backup" (to jest punkt odniesienia RPO).
3. **Wstrzyknięcie awarii (faza 1, robi injector):**
   - Nadpisuje/uszkadza plik stanu w środowisku scratch (np. `truncate` lub podmiana na losowe bajty).
   - **NIE usuwa** backupu — backup jest poza zasięgiem awarii (to testuje restore, nie backup).
   - Notuje dokładny czas wstrzyknięcia (start pomiaru RTO).
4. **Zasada bezpieczeństwa:** awaria jest **odwracalna** — backup istnieje, więc zawsze można wrócić. Jeśli cokolwiek pójdzie nieprzewidzianie, facilitator naciska "czerwony przycisk".

---

## 4. Fazy game day'u (timeline)

> Timeline jest planowany na ~90 minut. Czas każdej fazy mierzy obserwator i zapisuje w logu game day.

### Faza 0 — Briefing i zasady (0–10 min)

- Facilitator przedstawia cel, metryki sukcesu, role i obsadę.
- Ogłasza **"czerwony przycisk"**: każdy może przerwać game day, jeśli:
  - istnieje ryzyko uszkodzenia danych poza środowiskiem scratch,
  - wykonawca nie wie co robi i istnieje ryzyko pogłębienia awarii,
  - przekroczono twardy limit czasu (RTO > 15 min) bez postępu.
- Ustala, że **injector nie zdradza** szczegółów awarii wykonawcy przed fazą 1 (wykonawca ma działać jak przy prawdziwej awarii).
- Potwierdza, że środowisko to scratch, a backup `SID` istnieje i jest zweryfikowany.

### Faza 1 — Wykrycie awarii (10–20 min)

- **Injector wstrzykuje awarię** (uszkodzenie pliku stanu) i notuje czas startu RTO.
- **Wykonawca wykrywa awarię** przez sygnały:
  - `state.sh backup-list` / `state.sh backup-verify` zwraca błąd odczytu stanu,
  - usługa tier-0 nie startuje / healthcheck pada,
  - logi wskazują na uszkodzony plik stanu.
- **Obserwator notuje:** czas wykrycia, jakie sygnały zostały użyte, czy wykrycie było zgodne z runbookiem.
- **Kryterium wejścia do fazy 2:** wykonawca potwierdza, że awaria dotyczy stanu control plane'u i że backup `SID` istnieje.

### Faza 2 — Eskalacja i decyzja o restore (20–30 min)

- Wykonawca **eskaluje** do suwerena: opisuje objawy, wskazuje prawdopodobną przyczynę (uszkodzony stan), proponuje restore z `SID`.
- **Suweren podejmuje decyzję:** zatwierdza restore z backupu `SID` (lub failover, jeśli architektura to przewiduje).
- **Obserwator notuje:** czas decyzji, kto zdecydował, czy decyzja była zgodna z runbookiem.
- **Kryterium wejścia do fazy 3:** suweren wydał jednoznaczną decyzję o restore.

### Faza 3 — Wykonanie restore (30–45 min)

- Wykonawca uruchamia **pipeline restore drill**:
  ```bash
  tools/resilience/restore-drill/restore-drill.sh --sid <SID> --env scratch
  ```
  Pipeline wykonuje end-to-end: backup → restore → walidacja → evidence → destroy.
- Alternatywnie (jeśli pipeline niedostępny w danym środowisku), wykonawca wykonuje ręcznie:
  ```bash
  state.sh restore <SID>
  ```
  a następnie waliduje w fazie 4.
- **Obserwator notuje:** czas startu i końca restore, exit code pipeline'u, ewentualne błędy.
- **Kryterium wejścia do fazy 4:** restore zakończony (exit code 0 lub stan przywrócony).

### Faza 4 — Walidacja (45–60 min)

- Wykonawca uruchamia walidację:
  ```bash
  state.sh backup-verify <SID>
  ```
  oraz testy walidacyjne pipeline'u (porównanie danych przed/po, testy usługi tier-0).
- **Obserwator notuje:** wyniki walidacji, czy dane są kompletne (RPO = 0 utraconych rekordów).
- **Kryterium wejścia do fazy 5:** `backup-verify` = PASS, testy usługi = PASS, RPO = 0.

### Faza 5 — Przywrócenie normalnej pracy + cleanup scratch (60–75 min)

- Wykonawca przywraca normalną pracę środowiska scratch (usługa działa, stan spójny).
- **Cleanup:** usuwa artefakty awarii i scratch (zgodnie z pipeline'em — krok `destroy`).
- **Obserwator notuje:** czas przywrócenia normalnej pracy, czy cleanup był kompletny.
- **Kryterium wejścia do fazy 6:** środowisko scratch czyste, usługa działa, brak pozostałości awarii.

### Faza 6 — Retrospektywa (75–90 min)

- Facilitator prowadzi retrospektywę: co poszło dobrze, co poszło źle, jakie akcje.
- **Obserwator prezentuje** zebrane dane (czasy faz, odstępstwa, decyzje).
- **Suweren ocenia** wynik względem metryk sukcesu (zaliczone / niezaliczone).
- Zapis wyników do `game_days` (patrz sekcja 7).

---

## 5. Checklista obserwatora

Obserwator notuje **w czasie rzeczywistym** (nie z pamięci po game day'u):

| # | Co notować | Gdzie zapisać |
|---|---|---|
| 1 | Czas startu każdej fazy (F0–F6) | log game day (tabela `game_days`) |
| 2 | Czas wykrycia awarii (start RTO) | log game day |
| 3 | Czas decyzji suwerena o restore | log game day |
| 4 | Czas startu i końca restore | log game day |
| 5 | Exit code pipeline'u `restore-drill.sh` | log game day |
| 6 | Wynik `backup-verify` (PASS/FAIL) | log game day |
| 7 | Odstępstwa od runbooka (co zrobiono inaczej niż w dokumentacji) | sekcja "odstępstwa" |
| 8 | Decyzje podjęte ad hoc (kto, co, kiedy) | sekcja "decyzje" |
| 9 | Czy użyto "czerwonego przycisku" (i dlaczego) | sekcja "przerwania" |
| 10 | Czy wykonawca czytał runbook od zera (czy znał procedurę) | sekcja "kompetencje" |

**Zasada obserwatora:** obserwator **nie dotyka klawiatury** i nie podpowiada wykonawcy. Jego rolą jest mierzyć i notować, nie naprawiać.

---

## 6. Kryteria zaliczenia / niezaliczenia

### 6.1 Zaliczenie (wszystkie poniższe muszą być spełnione)

| # | Kryterium | Twardy próg |
|---|---|---|
| 1 | RTO osiągnięty | wykrycie → usługa przywrócona ≤ 15 min |
| 2 | RPO = 0 | zero utraconych rekordów względem `SID` |
| 3 | Restore drill przeszedł | `restore-drill.sh` exit code 0 |
| 4 | Evidence wygenerowany | plik JSON + wpis w `game_days` |
| 5 | Backup-verify po restore | PASS |
| 6 | Zero krytycznych odstępstw od runbooka | checklista obserwatora |

### 6.2 Niezaliczenie (wystarczy jedno)

- RTO > 15 min.
- RPO > 0 (utracono dane).
- `restore-drill.sh` exit code ≠ 0.
- Brak evidence (brak pliku JSON lub brak wpisu w `game_days`).
- `backup-verify` po restore = FAIL.
- ≥ 1 krytyczne odstępstwo od runbooka (np. wykonawca naprawiał "na czuja" zamiast użyć pipeline'u).

> **NO FALSE GREEN:** jeśli usługa "wróciła", ale np. RTO przekroczono lub brak evidence — game day jest **niezaliczony**. Celem jest udowodnienie procesu, nie "że się udało".

---

## 7. Po game day'u

### 7.1 Zapis wyników do `game_days`

Wyniki zapisujemy do tabeli `game_days` (migration 0009). Wpis zawiera:

| Kolumna | Wartość |
|---|---|
| `game_day_id` | `GD-01` |
| `date` | data przeprowadzenia |
| `scenario` | `control-plane-tier0-loss` |
| `rto_seconds` | zmierzony RTO (sekundy) |
| `rpo_records_lost` | liczba utraconych rekordów (0 = pass) |
| `restore_drill_exit` | exit code pipeline'u |
| `evidence_path` | ścieżka do pliku JSON evidence |
| `result` | `PASS` / `FAIL` |
| `notes` | uwagi z retrospektywy |

Wpis tworzy wykonawca (lub facilitator) po zakończeniu, na podstawie logu obserwatora.

### 7.2 Aktualizacja runbooka

- Jeśli wystąpiły odstępstwa od runbooka — **aktualizujemy runbook** (`docs/resilience/runbook/`), aby odzwierciedlić faktyczny, poprawny przebieg.
- Jeśli pipeline `restore-drill.sh` wymagał ręcznej interwencji — poprawiamy pipeline (agent A) i planujemy ponowny game day.
- Jeśli RTO/RPO nie zostały osiągnięte — analizujemy root cause i aktualizujemy metryki/limity w `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier).

### 7.3 Planowanie kolejnych game day'ów

- Kolejne game day'e (GD-02, GD-03...) rejestrujemy w `docs/resilience/game-day/README.md`.
- Rekomendowana częstotliwość: co kwartał lub po każdej istotnej zmianie w pipeline'ie restore / architekturze stanu.

---

## 8. Odwołania

| Element | Ścieżka |
|---|---|
| Komendy stanu | `system/control-plane/state/state.sh` (`backup`, `restore SID`, `backup-verify SID`, `backup-list`, `backup-retention [N]`, `backup-restore-test` F5) |
| Pipeline restore drill | `tools/resilience/restore-drill/restore-drill.sh` |
| Konfiguracja resilience | `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier) |
| Tabela wyników | `system/control-plane/state/migrations/0009_resilience.sql` (tabela `game_days`) |
| Runbook | `docs/resilience/runbook/` |
| Gate walidacyjny | `tools/verify/gates/domains/resilience.sh` |
