# HUMAN PLANE — Friction Score (warstwa 150% A)

> Design doc — definicja pomiaru tarcia per journey z przykładem.
> Status: DESIGN (do implementacji).
> Wariant (b) HUMAN PLANE — patrz `human-plane-design.md`.

## Cel

Tarcie to **koszt poznawczy użytkownika** — mierzalny, nie opinia. Każda krytyczna ścieżka ma budżet tarcia (z configu). Przekroczenie = FAIL. Ten dokument definiuje, **jak policzyć** tarcie, **jak je zmierzyć**, **jak je zapisać** i **co zrobić**, gdy przekroczy budżet.

Friction score jest jednym z trzech wariantów warstwy 150% (ponad 100% pokrycia):

| Wariant | Co | Dokument |
|---|---|---|
| (a) charter + evidence | template charteru + format evidence sesji | `human-plane-design.md` |
| **(b) friction score** | **definicja pomiaru per journey z przykładem** | **ten dokument** |
| (c) AUDYT v1.0 | audyt na bazie SONDA + sekcja P | osobny |

## 1. Definicja

### 1.1 Wzór

```
friction(ścieżka) = kliknięcia + pola formularza + zmiany kontekstu + czas oczekiwania
```

Cztery składowe, każda precyzyjnie zdefiniowana:

| Składowa | Definicja | Jednostka |
|---|---|---|
| `kliknięcia` | liczba kliknięć/akcji wymaganych do ukończenia ścieżki (od startu do celu) — przyciski, linki, tapy, wybory z listy, drag-and-drop | liczba |
| `pola formularza` | liczba pól do wypełnienia — inputy tekstowe, selecty, checkboxy, radio, przełączniki, pola daty | liczba |
| `zmiany kontekstu` | liczba przejść między ekranami/kontekstami — page loads, modale, nawigacja, przeładowania widoku, zmiany zakładki | liczba |
| `czas oczekiwania` | sumaryczny czas oczekiwania (loading, round-tripy, spinnery, skeleton) w sekundach, znormalizowany | sekundy → liczba |

**Zasada liczenia:** każda składowa liczona jest **od startu do celu** — od momentu, gdy użytkownik zaczyna ścieżkę, do momentu, gdy osiąga cel (np. potwierdzenie zamówienia, zalogowanie, zapis). Kroki poza ścieżką (np. eksploracja, cofanie się) nie są liczone — mierzymy **minimalną ścieżkę sukcesu**, nie dowolną wędrówkę.

### 1.2 Normalizacja — jak składowe sumują się w jedną liczbę

Składowe mają różne jednostki (liczby vs sekundy), więc **nie można ich zsumować wprost**. Normalizacja sprowadza wszystko do **liczby równoważnych akcji** (count-equivalent):

```
friction(ścieżka) = kliknięcia
                  + pola formularza
                  + zmiany kontekstu
                  + ceil(czas_oczekiwania_s / T_wait)
```

gdzie `T_wait` to **próg równoważności czasu** — liczba sekund oczekiwania, która "kosztuje" tyle samo co jedna akcja. Domyślnie `T_wait = 2.0 s` (z configu, patrz 1.4).

**Dlaczego `ceil`:** każdy pełny próg `T_wait` sekund to jedna "akcja" — 1.9 s to 0 akcji (nie odczuwalne), 2.0 s to 1 akcja, 4.5 s to 3 akcje. Zaokrąglenie w górę karze długie, pojedyncze czekania (gorzej niż wiele krótkich), bo długie czekanie jest poznawczo droższe niż suma krótkich.

**Wagi:** domyślnie wszystkie cztery składowe mają wagę 1 (każda akcja kosztuje tyle samo). Wagi są **konfigurowalne per tier** — np. dla tier-1 (krytyczny) `zmiany kontekstu` może dostać wagę 1.5, bo przejścia między ekranami w krytycznej ścieżce są droższe poznawczo (ryzyko zgubienia kontekstu). Wagi definiuje się w configu:

```yaml
human:
  friction_weights:            # domyślne (wszystkie 1.0)
    clicks: 1.0
    form_fields: 1.0
    context_changes: 1.0
    wait_time: 1.0
  friction_weights_tier1:      # tier-1: przejścia droższe
    clicks: 1.0
    form_fields: 1.0
    context_changes: 1.5
    wait_time: 1.0
```

Wzór z wagami:

```
friction(ścieżka) = w_klik × kliknięcia
                  + w_pola × pola formularza
                  + w_kontekst × zmiany kontekstu
                  + w_czas × ceil(czas_oczekiwania_s / T_wait)
```

### 1.3 Budżet tarcia

Budżet to **maksymalny dozwolony friction score** dla danej ścieżki. Przekroczenie = FAIL (gate blokuje release dla tej ścieżki).

Budżet pochodzi z configu — klucz `human.friction_budget_default` w `config/canonical/registry.yaml` (warstwa L0, default). Per-tier floors (L1) definiują twarde minimum, którego serwis nie może obniżyć bez waivera:

```yaml
human:
  friction_budget_default: 20      # L0: domyślny budżet dla ścieżki
  friction_budget_floor: 12        # L1: floor — nie da się obniżyć bez waivera
  friction_budget_tier1: 15        # tier-1 (krytyczny): ciaśniejszy budżet
  friction_budget_tier3: 30        # tier-3: luźniejszy
  friction_wait_threshold_s: 2.0   # T_wait — próg równoważności czasu
```

**Zasady budżetu (zgodne z 4 prawami configu):**
- **Tighten zawsze przechodzi** — serwis może ustawić budżet ciaśniejszy niż default bez zgody.
- **Relax wymaga waivera** — budżet luźniejszy niż floor = REJECTED bez waivera (z `expires_at`).
- **Ratchet** — osiągnięty (zmierzony) friction per ścieżka może TYLKO maleć; nowy pomiar gorszy niż poprzedni = FAIL (anti-entropy, system sam się dokręca).

### 1.4 Skąd biorą się stałe

| Stała | Klucz configu | Default | Uwagi |
|---|---|---|---|
| Budżet domyślny | `human.friction_budget_default` | 20 | L0 |
| Floor budżetu | `human.friction_budget_floor` | 12 | L1 |
| Budżet tier-1 | `human.friction_budget_tier1` | 15 | ciaśniejszy dla krytycznych |
| Budżet tier-3 | `human.friction_budget_tier3` | 30 | luźniejszy |
| Próg czasu `T_wait` | `human.friction_wait_threshold_s` | 2.0 s | sekundy na 1 "akcję" |
| Wagi składowych | `human.friction_weights*` | 1.0 | per tier |

## 2. Metodologia pomiaru

### 2.1 Jak mierzyć każdą składową

Trzy źródła pomiaru, w kolejności rosnącej wierności:

| Źródło | Co mierzy | Kiedy używać |
|---|---|---|
| **Manual walkthrough** | wszystkie 4 składowe — człowiek przechodzi ścieżkę i liczy kliknięcia, pola, konteksty, mierzy czas | baseline, ścieżki bez automatyzacji, walidacja syntetyka |
| **Synthetic journey robot** | wszystkie 4 składowe — robot (synthetic user) chodzi po ścieżce na produkcji i loguje każdą akcję + timing | regularny pomiar, warstwa 150% B |
| **RUM** (Real User Monitoring) | `czas oczekiwania` + `zmiany kontekstu` z prawdziwych sesji; `kliknięcia`/`pola` z session replay | ciągły monitoring, detekcja regresji |

**Manual walkthrough** — protokół:
1. Tester (nie autor — SoD, MAN-07) przechodzi ścieżkę od startu do celu.
2. Liczy: każdy klik, każde pole, każdą zmianę kontekstu.
3. Mierzy czas oczekiwania (suma wszystkich loadingów/round-tripów).
4. Zapisuje wynik w `friction_baselines` (patrz 2.3).

**Synthetic journey robot** — protokół:
1. Robot wykonuje tę samą ścieżkę na produkcji (nie w testach — łapie prawdziwe dane, opóźnienia, stany).
2. Instrumentacja loguje każdą akcję (klik, pole, kontekst) + timestamp.
3. Suma czasów oczekiwania liczona z różnic timestampów między akcją a odpowiedzią.
4. Wynik porównywany z budżetem → `WITHIN_BUDGET` / `OVER_BUDGET`.

**RUM** — protokół:
1. Zbieranie z prawdziwych sesji (rage clicks, dead clicks, u-turns — UX-R-05).
2. `czas oczekiwania` = percentyl (np. p75) czasu od akcji do renderu.
3. `zmiany kontekstu` = liczba nawigacji w sesji na ścieżce.
4. RUM nie zastępuje syntetyka — uzupełnia go o prawdziwe rozkłady.

### 2.2 Kiedy mierzyć

| Kiedy | Co | Cadence |
|---|---|---|
| **Per release** | każda krytyczna ścieżka dotknięta zmianą | przy każdym releasie tier-1 |
| **Per journey** | każda ścieżka z aktywnym charterem | wg rytmu eksploracji per tier (MAN-05) |
| **Ciągły** | RUM + synthetic robot | codziennie / co release |

Reguła świeżości (z HUMAN PLANE): **pomiar bez świeżości = nieważny**. Friction baseline starszy niż budżet wieku per tier nie liczy się do gate'a — ścieżka jest traktowana jak niezmierzona (FAIL).

### 2.3 Jak zapisywany jest wynik

Wynik zapisywany jest w tabeli `friction_baselines` (migracja 0010):

```sql
CREATE TABLE friction_baselines (     -- warstwa 150% A: budżety tarcia
  journey_id      TEXT PRIMARY KEY,
  service_id      TEXT NOT NULL,
  friction_budget INTEGER NOT NULL,   -- suma kliknięć+pól+kontekstów+czasu
  measured_friction INTEGER,
  status          TEXT NOT NULL DEFAULT 'WITHIN_BUDGET',
  measured_at     TEXT
);
```

- `friction_budget` — budżet z configu (po resolve, z przypiętego snapshotu configu).
- `measured_friction` — zmierzony friction score (po normalizacji).
- `status` — `WITHIN_BUDGET` | `OVER_BUDGET` (liczone przy zapisie).
- `measured_at` — timestamp pomiaru (do reguły świeżości).

Każdy pomiar wskazuje `snapshot_id` configu (wzorzec z Config Plane) — reprodukowalność: wiadomo, z jakim budżetem porównywano.

## 3. Przykład (worked example)

### Ścieżka: "Zamówienie produktu w sklepie" (tier-1)

Krytyczna ścieżka e-commerce: użytkownik wybiera produkt, dodaje do koszyka, składa zamówienie. Cel = **potwierdzenie zamówienia**.

### 3.1 Kroki ścieżki

| # | Krok | Klik | Pole | Kontekst | Czekanie |
|---|---|---|---|---|---|
| 1 | Otwarcie strony produktu | 1 (link z listy) | 0 | 1 (page load) | 1.2 s |
| 2 | Wybór rozmiaru | 1 (select) | 1 (select) | 0 | 0 |
| 3 | Dodanie do koszyka | 1 (przycisk) | 0 | 1 (modal koszyka) | 0.4 s |
| 4 | Przejście do kasy | 1 (przycisk) | 0 | 1 (page load) | 1.8 s |
| 5 | Formularz dostawy | 0 | 4 (imię, adres, miasto, kod) | 0 | 0 |
| 6 | Wybór dostawy | 1 (radio) | 1 (radio) | 0 | 0 |
| 7 | Formularz płatności | 0 | 3 (karta, data, CVV) | 0 | 0 |
| 8 | Złożenie zamówienia | 1 (przycisk) | 0 | 1 (page load) | 2.6 s |
| 9 | Potwierdzenie | 0 | 0 | 1 (strona potwierdzenia) | 0.5 s |
| **Suma** | **6** | **9** | **5** | **6.5 s** |

### 3.2 Surowe składowe

```
kliknięcia        = 6
pola formularza   = 9
zmiany kontekstu  = 5
czas oczekiwania  = 6.5 s
```

### 3.3 Normalizacja i wynik

Tier-1 → wagi `friction_weights_tier1` (kontekst × 1.5), `T_wait = 2.0 s`:

```
czas_oczekiwania_znormalizowany = ceil(6.5 / 2.0) = ceil(3.25) = 4

friction = 1.0 × 6        (kliknięcia)
         + 1.0 × 9        (pola formularza)
         + 1.5 × 5        (zmiany kontekstu)
         + 1.0 × 4        (czas oczekiwania)
         = 6 + 9 + 7.5 + 4
         = 26.5
```

### 3.4 Porównanie z budżetem

Budżet tier-1 = **15** (z configu). Zmierzony friction = **26.5**.

```
26.5 > 15  →  OVER_BUDGET  →  FAIL
```

### 3.5 Która składowa dominuje i jak redukować

| Składowa | Wkład | % | Dominacja |
|---|---|---|---|
| pola formularza | 9 | 34% | **dominuje** |
| zmiany kontekstu | 7.5 | 28% | wysoka |
| kliknięcia | 6 | 23% | średnia |
| czas oczekiwania | 4 | 15% | niska |

**Dominuje `pola formularza` (9, 34%)** — formularz dostawy (4 pola) + płatności (3 pola) + 2 selecty to największy koszt poznawczy.

**Konkretne rekomendacje redukcji:**

1. **Autouzupełnianie adresu** (krok 5): 4 pola → 1 pole (kod pocztowy → reszta z API). Redukcja: −3 pola.
2. **Zapisana karta / płatność jednym kliknięciem** (krok 7): 3 pola → 0 (powracający klient). Redukcja: −3 pola.
3. **Połączenie kroków 4–6 w jeden ekran** (kasa + dostawa + płatność w jednym widoku z sekcjami): redukcja kontekstów −2 (z 5 do 3). Redukcja: −3.0 (2 × 1.5).
4. **Skeleton + prefetch** (krok 8, 2.6 s): skrócenie do < 2 s → czas znormalizowany 4 → 3. Redukcja: −1.

**Po redukcji:**

```
friction = 6 + (9−6) + 1.5×3 + 3
         = 6 + 3 + 4.5 + 3
         = 16.5
```

Nadal **OVER_BUDGET** (16.5 > 15) — potrzebna dalsza redukcja, np.:
5. **Koszyk jako drawer zamiast modala** (krok 3): kontekst 5 → 4. Redukcja: −1.5 → **15.0 = WITHIN_BUDGET** (na granicy).

Wniosek: ścieżka wymaga **przeprojektowania formularza** (autouzupełnianie + zapisana karta) — to nie jest problem wydajności (czas oczekiwania jest niski), tylko **nadmiar pól i przejść**. Redukcja pól z 9 do 3 i kontekstów z 5 do 4 sprowadza ścieżkę do budżetu.

## 4. Interpretacja i akcja

### 4.1 Co oznacza wysoki friction score

| Wynik | Znaczenie | Interpretacja |
|---|---|---|
| `WITHIN_BUDGET` | ścieżka w budżecie | koszt poznawczy akceptowalny |
| `OVER_BUDGET` (lekko, < 1.5×) | ścieżka na granicy | wymaga triage, nie blokuje od razu |
| `OVER_BUDGET` (znacznie, ≥ 1.5×) | ścieżka przeciążona | FAIL — blokuje release, wymaga redukcji |
| `OVER_BUDGET` + dominująca składowa | diagnoza | patrz 4.2 |

**Dominująca składowa = diagnoza problemu:**

| Dominuje | Co to znaczy | Typowa przyczyna |
|---|---|---|
| `pola formularza` | za dużo pytań | formularz zbiera za dużo danych, brak autouzupełniania |
| `zmiany kontekstu` | za dużo przejść | rozbita ścieżka na zbyt wiele ekranów, brak kontekstu |
| `kliknięcia` | za dużo akcji | brak skrótów, nadmiarowe kroki |
| `czas oczekiwania` | za wolno | backend, brak skeletonów, brak prefetchu |

### 4.2 Triage

1. **Zidentyfikuj dominującą składową** (największy % wkładu).
2. **Sprawdź, czy to regresja** — porównaj z poprzednim pomiarem (ratchet). Jeśli wzrosło od ostatniego release'u → znajdź zmianę, która to spowodowała (git blame na ścieżce).
3. **Zdecyduj: naprawa vs waiver** — jeśli redukcja wymaga czasu, a ścieżka jest krytyczna, waiver (z `expires_at`) pozwala przejść release, ale zobowiązuje do naprawy.
4. **Przekuj na test automatyczny** (MAN-06) — dodaj synthetic journey z asercją na friction, żeby regresja nie wróciła.

### 4.3 Jak redukować

| Składowa | Techniki redukcji |
|---|---|
| `pola formularza` | autouzupełnianie, zapisane dane, mniej pól (tylko to, co konieczne), progressive disclosure |
| `zmiany kontekstu` | łączenie ekranów, drawer zamiast modala, wizard w jednym widoku, zachowanie kontekstu |
| `kliknięcia` | skróty, domyślne wartości, jeden przycisk zamiast wielu, bulk actions |
| `czas oczekiwania` | skeleton, prefetch, optymalizacja backendu, cache, streaming |

### 4.4 Jak friction zasila UX escape analysis (warstwa 150% C)

Friction score jest **sygnałem wejściowym** do UX escape analysis. Gdy użytkownik skarży się na ścieżkę:

1. **Sprawdź friction baseline** — jeśli `OVER_BUDGET`, to nie jest "pojedyncza skarga", to **potwierdzony, zmierzony problem**.
2. **Klasyfikacja escape'a** (z HUMAN PLANE, warstwa 150% C):

| Klasa | Znaczenie | Akcja |
|---|---|---|
| gate istniał i przeszedł | friction był `WITHIN_BUDGET`, a użytkownik i tak narzeka | gate za słaby / źle zmierzony → wzmocnij (obniż budżet) |
| gate nie istniał | ścieżka bez friction baseline | dodaj pomiar + budżet |
| waiver | świadome odstępstwo od budżetu | przegląd waivera |

3. **Escape bez `closed_at` = FAIL** (wzorzec CORR-escape z wymiaru 14) — każda skarga na ścieżkę z wysokim friction musi mieć zamknięcie (naprawa lub świadoma decyzja).

### 4.5 Jak friction zasila wymiar 15

Friction nie wchodzi bezpośrednio do wzoru wymiaru 15, ale **wpływa na jego składowe**:

```
s_15 = manual_coverage × evidence_freshness × min(1, task_success_actual/task_success_target) × conversion_rate
```

- **`task_success_actual`** — wysoki friction obniża skuteczność zadań (użytkownicy porzucają ścieżkę). Ścieżka `OVER_BUDGET` to bezpośredni predyktor niskiego task success.
- **`conversion_rate`** (MAN-06) — redukcja friction przekuta na synthetic journey z asercją = nowy test automatyczny → rośnie conversion.
- **`manual_coverage`** — każda ścieżka z friction baseline ma aktywny charter (auto lub manual) → rośnie pokrycie.

Friction jest więc **wczesnym sygnałem ostrzegawczym** dla wymiaru 15: ścieżka `OVER_BUDGET` dziś = niski task success jutro. Mierzenie friction pozwala interweniować **zanim** spadnie skuteczność zadań.

## TL;DR — dlaczego ten pomiar jest kompletny

```
friction = kliknięcia + pola + konteksty + czas(normalizowany)   → jedna liczba
budżet   = z configu (human.friction_budget_default, per-tier floors)
gate     = measured > budget → OVER_BUDGET → FAIL (ratchet: może tylko maleć)
pomiar   = manual walkthrough + synthetic robot + RUM
zapis    = friction_baselines (migracja 0010), snapshot configu przypięty
akcja    = dominująca składowa → diagnoza → redukcja → waiver (wygasa)
feedback = OVER_BUDGET → UX escape analysis (150% C) → wymiar 15 (task success)
```

Tarcie jest mierzalne, ma budżet, ma gate i ma pętlę akcji. **Koszt poznawczy użytkownika przestaje być opinią — staje się liczbą, którą można przekroczyć i za to failować.**
