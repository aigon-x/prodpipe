# RUNBOOK TIER-0 — Odbudowa control plane'u z backupu

> **Wersja:** 1.0
> **Właściciel:** Resilience Plane
> **Ostatnia aktualizacja:** 2026-08-10
> **Zakres:** tier-0 control plane (baza stanu canonical state)
> **Cel RTO:** ≤ 15 min (z `config/registry.yaml` → `resilience.rto`)
> **Cel RPO:** ≤ 5 min (z `config/registry.yaml` → `resilience.rpo`)
> **Powiązane ćwiczenie:** [game-day-01.md](../game-day/game-day-01.md)

> **Jak używać tego dokumentu:** wydrukuj go i podążaj krok po kroku. Każdy krok ma checkbox `[ ]` — odhaczaj po wykonaniu. Nie pomijaj Sekcji 0.

---

## Sekcja 0 — Zasady bezpieczeństwa (przeczytaj PIERWSZE)

> Te zasady mają pierwszeństwo nad wszystkim poniżej. Ich złamanie = przerwanie procedury.

1. **NIGDY nie wykonuj restore na produkcji bez zatwierdzenia suwerena.**
   - Restore na produkcji wykonujesz **wyłącznie** po jednoznacznej, udokumentowanej decyzji suwerena (Sekcja 2).
   - W środowisku scratch/testowym możesz działać swobodniej, ale zasady 2–4 obowiązują zawsze.
2. **Awaria musi być odwracalna.**
   - Zanim cokolwiek ruszysz, potwierdź że backup `SID` istnieje i jest zweryfikowany (`state.sh backup-verify SID` → PASS).
   - Jeśli backup nie istnieje — **NIE** wykonuj restore. Przejdź do Sekcji 2.3 (failover / odbudowa od zera).
3. **"Czerwony przycisk" — przerwij natychmiast, jeśli:**
   - istnieje ryzyko uszkodzenia danych **poza** środowiskiem, w którym pracujesz,
   - wykonawca nie wie co robi i istnieje ryzyko pogłębienia awarii,
   - przekroczono twardy limit czasu (RTO > 15 min) bez postępu.
   - Każdy uczestnik może nacisnąć "czerwony przycisk". Przerwanie nie jest porażką — jest ochroną.
4. **Nie łącz ról wykonawca + obserwator.**
   - Osoba, która wykonuje restore, **nie może** jednocześnie oceniać, czy zrobiła to poprawnie.
   - Obserwator mierzy czas i notuje odstępstwa; **nie dotyka klawiatury** i nie podpowiada.

---

## Sekcja 1 — Diagnoza (co sprawdzić, zanim cokolwiek ruszysz)

> Cel: potwierdzić, że awaria dotyczy **stanu control plane'u tier-0**, a nie czegoś innego (sieć, dysk, aplikacja).

### 1.1 Objawy awarii tier-0

| # | Objaw | Jak sprawdzić |
|---|---|---|
| 1 | Usługa tier-0 nie startuje | logi usługi, `systemctl status` / `docker ps` |
| 2 | Healthcheck pada | endpoint healthcheck zwraca błąd / timeout |
| 3 | `state.sh` nie czyta stanu | `state.sh backup-list` / `state.sh backup-verify` zwraca błąd odczytu stanu |
| 4 | Logi wskazują na uszkodzony plik stanu | komunikaty o błędzie parsowania / odczytu bazy stanu |

### 1.2 Potwierdź, że to stan control plane'u

- [ ] Uruchom `state.sh status` — czy zwraca błąd odczytu stanu?
- [ ] Uruchom `state.sh backup-list` — czy lista backupów jest czytelna, czy pada na odczycie stanu?
- [ ] Sprawdź logi usługi tier-0 — czy wskazują na uszkodzony plik stanu (a nie np. na brak sieci)?
- [ ] **Jeśli** objawy wskazują na coś innego niż stan (sieć, dysk, aplikacja) — **NIE** przechodź do restore. Rozwiąż właściwą przyczynę.

> **Kryterium wejścia do Sekcji 2:** potwierdziłeś, że awaria dotyczy stanu control plane'u **i** że backup `SID` istnieje.

### 1.3 Znajdź ostatni dobry backup (SID)

- [ ] Uruchom `state.sh backup-list` — znajdź najnowszy backup ze statusem `CURRENT` i integralnością `VERIFIED`.
- [ ] Zapisz jego `SID` — to jest **punkt odniesienia RPO** (ostatni dobry stan).
- [ ] Zweryfikuj go: `state.sh backup-verify <SID>` → **PASS**.
- [ ] Zapisz `SID` tutaj: **SID = `________`**

> Jeśli `backup-list` nie działa (sam stan jest uszkodzony), backup katalog może być niedostępny — patrz Sekcja 2.3.

---

## Sekcja 2 — Decyzja (kto i kiedy)

### 2.1 Eskalacja do suwerena

- [ ] Wykonawca eskaluje do suwerena: opisuje objawy, wskazuje prawdopodobną przyczynę (uszkodzony stan), proponuje restore z `SID`.
- [ ] Suweren podejmuje decyzję o restore (lub failover, jeśli architektura to przewiduje).
- [ ] Obserwator notuje: czas decyzji, kto zdecydował, treść decyzji.

### 2.2 Kryteria zatwierdzenia restore

Suweren zatwierdza restore, **gdy wszystkie** poniższe są spełnione:

- [ ] Awaria dotyczy stanu control plane'u tier-0 (potwierdzone w Sekcji 1).
- [ ] Backup `SID` istnieje i jest zweryfikowany (`backup-verify` → PASS).
- [ ] Restore jest **odwracalny** — backup jest poza zasięgiem awarii.
- [ ] Środowisko docelowe jest znane (scratch / prod) i zgoda dotyczy właśnie tego środowiska.

### 2.3 Co zrobić, jeśli backup NIE istnieje

- [ ] **NIE** wykonuj restore — nie ma z czego.
- [ ] **Failover:** jeśli architektura przewiduje replikę / drugi węzeł — przełącz na nią (decyzja suwerena).
- [ ] **Odbudowa od zera:** jeśli brak failover — odbuduj stan od zera (`state.sh init` + `state.sh migrate`), a następnie odtwórz dane z innych źródeł (jeśli istnieją).
- [ ] Udokumentuj brak backupu jako **krytyczny finding** (tabela `spof_findings`, migration 0009) — to jest awaria procesu backupu, nie tylko awaria stanu.

---

## Sekcja 3 — Restore (krok po kroku)

> **Środowisko:** potwierdź, w którym środowisku pracujesz. `--env scratch` = testowe, `--env prod` = produkcja (**TYLKO** po zatwierdzeniu suwerena).

### 3.1 Ścieżka główna — pipeline restore drill

- [ ] Potwierdź, że pipeline istnieje: `ls tools/resilience/restore-drill/restore-drill.sh`
- [ ] Uruchom pipeline (scratch):
  ```bash
  tools/resilience/restore-drill/restore-drill.sh --sid <SID> --env scratch
  ```
- [ ] **Produkcja — TYLKO po zatwierdzeniu suwerena:**
  ```bash
  tools/resilience/restore-drill/restore-drill.sh --sid <SID> --env prod
  ```
- [ ] Zapisz exit code pipeline'u: **exit = `____`** (0 = sukces)
- [ ] Obserwator notuje czas startu i końca restore.

### 3.2 Fallback ręczny — `state.sh restore`

> Użyj, gdy pipeline `restore-drill.sh` jest niedostępny w danym środowisku.

- [ ] Uruchom ręczny restore:
  ```bash
  state.sh restore <SID>
  ```
- [ ] Potwierdź, że komenda zakończyła się bez błędu (exit 0).
- [ ] Obserwator notuje czas startu i końca restore.

### 3.3 Po restore

- [ ] Usługa tier-0 startuje (sprawdź logi / healthcheck).
- [ ] `state.sh status` działa i pokazuje spójny stan.
- [ ] Przejdź do Sekcji 4 (walidacja) — **nie kończ na tym, że "usługa wróciła"**.

---

## Sekcja 4 — Walidacja (jak udowodnić, że działa)

> **NO FALSE GREEN:** "wygląda dobrze" nie jest kryterium. Każdy punkt ma twardy wynik.

### 4.1 Weryfikacja backupu i restore

- [ ] `state.sh backup-verify <SID>` → **PASS**
- [ ] `state.sh backup-restore-test` → **exit 0** (realny test backup→restore→verify)
- [ ] `state.sh verify` → **PASS** (stan spójny)

### 4.2 Testy usługi tier-0

- [ ] Usługa tier-0 odpowiada na healthcheck.
- [ ] Podstawowe operacje usługi działają (zgodnie z testami usługi).
- [ ] Logi nie zawierają nowych błędów od momentu restore.

### 4.3 RPO = 0 (zero utraconych rekordów)

- [ ] Porównaj dane po restore z danymi w backupie `SID` (testy walidacyjne pipeline'u / porównanie `backup-verify` przed/po).
- [ ] **RPO = 0** — zero utraconych rekordów względem `SID`.
- [ ] Jeśli utracono rekordy (RPO > 0) — udokumentuj ile i przeanalizuj root cause.

### 4.4 Kryterium zaliczenia

| Metryka | Cel | Wynik |
|---|---|---|
| RTO (wykrycie → usługa przywrócona) | ≤ 15 min | `____` min |
| RPO (utracone rekordy) | 0 | `____` |
| `backup-verify` | PASS | `____` |
| `backup-restore-test` | exit 0 | `____` |
| `verify` | PASS | `____` |
| Testy usługi tier-0 | PASS | `____` |

> **Zaliczone** tylko wtedy, gdy wszystkie powyższe są spełnione. Jeśli którakolwiek nie — przejdź do retrospektywy i root cause (Sekcja 6).

---

## Sekcja 5 — Evidence (co zapisać)

> Evidence jest obowiązkowy. Bez niego procedura jest **niezaliczona**.

### 5.1 Wpis do tabeli `game_days` (migration 0009)

- [ ] Zapisz wynik do tabeli `game_days` (kolumny: `game_day_id`, `tier`, `title`, `status`, `started_at`, `completed_at`, `result`, `evidence_ref`).
- [ ] Przykładowe wartości: `tier = 'tier-0'`, `result = 'PASS'` / `'FAIL'`, `evidence_ref = <ścieżka do pliku JSON>`.

### 5.2 Plik JSON evidence

- [ ] Wygeneruj plik JSON evidence (pipeline `restore-drill.sh` robi to automatycznie; przy fallbacku ręcznym — utwórz ręcznie).
- [ ] Plik zawiera: `SID`, czasy (wykrycie, decyzja, restore), exit code, wyniki walidacji, RTO, RPO.
- [ ] Zapisz plik w: **`artifacts/evidence/resilience/`**
- [ ] Wskaż ścieżkę w tabeli `game_days` (`evidence_ref`).

### 5.3 Dodatkowe notatki

- [ ] Obserwator zapisuje: odstępstwa od runbooka, decyzje ad hoc, użycie "czerwonego przycisku".
- [ ] Jeśli wystąpiły odstępstwa — zaplanuj aktualizację runbooka (Sekcja 6).

---

## Sekcja 6 — Cleanup i powrót do normalnej pracy

- [ ] Przywróć normalną pracę środowiska (usługa działa, stan spójny).
- [ ] **Cleanup scratch:** usuń artefakty awarii i środowisko scratch (zgodnie z pipeline'em — krok `destroy`).
- [ ] Potwierdź, że nie ma pozostałości awarii (uszkodzone pliki, procesy, kontenery).
- [ ] **Retrospektywa:** co poszło dobrze, co poszło źle, jakie akcje.
- [ ] **Aktualizacja runbooka:** jeśli wystąpiły odstępstwa — zaktualizuj ten dokument, aby odzwierciedlić faktyczny, poprawny przebieg.
- [ ] **Root cause:** jeśli RTO/RPO nie zostały osiągnięte — przeanalizuj root cause i zaktualizuj metryki/limity w `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier).
- [ ] **Planowanie:** zaplanuj kolejny game day (GD-02...) w `docs/resilience/game-day/README.md`.

---

## Sekcja 7 — Checklista szybka (1 strona, do wydruku)

> Skondensowana wersja całego runbooka. Odhaczaj w trakcie awarii.

### Sekcja 0 — Bezpieczeństwo
- [ ] Restore na produkcji **tylko** po zatwierdzeniu suwerena.
- [ ] Backup `SID` istnieje i jest zweryfikowany (odwracalność).
- [ ] "Czerwony przycisk" znany wszystkim (przerwij przy ryzyku poza środowiskiem).
- [ ] Wykonawca ≠ obserwator.

### Sekcja 1 — Diagnoza
- [ ] Objawy: usługa nie startuje / healthcheck pada / `state.sh` błąd odczytu.
- [ ] Potwierdzone, że to stan control plane'u (nie sieć/dysk/aplikacja).
- [ ] `state.sh backup-list` → znaleziony ostatni dobry **SID**.
- [ ] `state.sh backup-verify <SID>` → **PASS**.

### Sekcja 2 — Decyzja
- [ ] Eskalacja do suwerena.
- [ ] Suweren zatwierdził restore (lub failover).
- [ ] Backup nie istnieje → **NIE** restore, przejdź do failover / odbudowy od zera.

### Sekcja 3 — Restore
- [ ] Środowisko potwierdzone (scratch / prod).
- [ ] Pipeline: `tools/resilience/restore-drill/restore-drill.sh --sid <SID> --env scratch` (lub `--env prod` po zgodzie).
- [ ] Fallback: `state.sh restore <SID>`.
- [ ] Exit code = 0.

### Sekcja 4 — Walidacja
- [ ] `state.sh backup-verify <SID>` → **PASS**.
- [ ] `state.sh backup-restore-test` → **exit 0**.
- [ ] `state.sh verify` → **PASS**.
- [ ] Testy usługi tier-0 → **PASS**.
- [ ] **RPO = 0** (zero utraconych rekordów).
- [ ] **RTO ≤ 15 min**.

### Sekcja 5 — Evidence
- [ ] Wpis do tabeli `game_days` (migration 0009).
- [ ] Plik JSON evidence w `artifacts/evidence/resilience/`.
- [ ] `evidence_ref` wskazany w tabeli.

### Sekcja 6 — Cleanup
- [ ] Normalna praca przywrócona.
- [ ] Cleanup scratch kompletny.
- [ ] Retrospektywa + root cause (jeśli FAIL).
- [ ] Runbook zaktualizowany o odstępstwa.

---

## Sekcja 8 — Odwołania

| Element | Ścieżka |
|---|---|
| StateStore CLI | `system/control-plane/state/state.sh` (`backup`, `restore SID`, `backup-verify SID`, `backup-list`, `backup-retention [N]`, `backup-restore-test`, `verify`, `status`) |
| Pipeline restore drill | `tools/resilience/restore-drill/restore-drill.sh` |
| Konfiguracja resilience | `config/registry.yaml` (klucze `rto`/`rpo`/`restore_drill_max_age`/`dr_game_day_max_age` + floors per tier) |
| Tabela wyników / evidence | `system/control-plane/state/migrations/0009_resilience.sql` (tabele `backup_catalog`, `resilience_requirements`, `game_days`, `spof_findings`) |
| Scenariusz ćwiczenia | `docs/resilience/game-day/game-day-01.md` |
| Gate walidacyjny | `tools/verify/gates/domains/resilience.sh` (GATE-039, checks RES-B-01..04) |
| Katalog evidence | `artifacts/evidence/resilience/` |
