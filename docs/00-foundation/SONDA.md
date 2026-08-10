# SONDA — Self-ONboarding Diagnostic Audit

> Samodiagnostyczny audyt gotowości platformy. SONDA ocenia, czy platforma jest gotowa do onboardingu — nie czy jest "idealna", tylko czy każdy wymiar ma **sprawdzalny dowód** (evidence) albo **udokumentowaną lukę**.
> Status: TEMPLATE (diagnostyczny szkielet — nie deklaracja gotowości).

## Cel

SONDA to **samodiagnostyczny audyt** (self-onboarding diagnostic audit). Odpowiada na jedno pytanie:

> **Czy nowy zespół / nowy serwis może wejść na platformę i dostać wszystkie gwarancje, które platforma deklaruje?**

SONDA nie jest raportem "wszystko działa". Jest **szablonem diagnostycznym**: dla każdego wymiaru i każdego itemu podaje status, kryteria i wymagany dowód. Pusty status `ABSENT` jest **akceptowalny** na świeżej platformie — SONDA ma pokazać *gdzie* jest luka, nie udawać, że jej nie ma.

## Jak używać

1. **Uruchom** SONDA jako checklist przy onboardingu nowego serwisu / zespołu / domeny.
2. **Dla każdego itemu** ustaw status zgodnie z legendą i podaj dowód (evidence_ref / artefakt / ścieżka).
3. **Nie uzupełniaj** statusów na "COMPLETE" bez dowodu — SONDA wymaga evidence, nie deklaracji.
4. **Wynik** to mapa luk (gaps), nie ocena. Każda luka `ABSENT`/`PARTIAL` staje się pozycją backlogu.
5. **Powtarzaj** przy każdym releasie tier-1 i przy zmianie architektury.

## Legenda statusów

| Status | Znaczenie | Wymagany dowód |
|---|---|---|
| **COMPLETE** | W pełni spełnione | Evidence (artefakt, wynik gate'a, ścieżka do dowodu) |
| **ABSENT** | Nieobecne — wymaga **dowodu (dowód)**, że nieobecność jest akceptowalna | Uzasadnienie + akceptacja (waiver / decyzja) |
| **PARTIAL** | Częściowo obecne — **lista** tego, czego brakuje | Lista braków + co już jest |

> **Reguła kanoniczna:** dimension score bez świeżego evidence = **0 (nie NULL — ZERO)**. Status bez dowodu nie jest "COMPLETE" — jest `ABSENT` lub `PARTIAL`.

---

## SEKCJE A–O — 14 wymiarów doskonałości

Sekcje A–O mapują się na 14 wymiarów tabeli doskonałości (z `aesthetics-plane-design.md`). Każda sekcja zawiera kilka itemów diagnostycznych ze statusem.

---

### SEKCJA A — INTEG (Spójność szkieletu)

> Wymiar 1: Każde połączenie zweryfikowane dwukierunkowo; zero ghostów, zero orphanów. Dowód: 4-kierunkowy matrix pusty.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| A-01 | 4-kierunkowy matrix połączeń (service ↔ config ↔ runtime ↔ docs) jest pusty (zero ghostów, zero orphanów) | ABSENT | brak matrixa — do zbudowania |
| A-02 | Każde połączenie zweryfikowane dwukierunkowo (nie jednostronnie) | ABSENT | brak weryfikacji dwukierunkowej |
| A-03 | Zero ghost modułów (zadeklarowane, ale nie wykonane) | ABSENT | brak audytu ghostów |
| A-04 | Zero orphanów (wykonane, ale nie zadeklarowane) | ABSENT | brak audytu orphanów |

---

### SEKCJA B — VV (Poprawność)

> Wymiar 2: Każdy check ma test pozytywny + negatywny + mutation score. Dowód: VV coverage = 100% × mutation ≥ próg.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| B-01 | Każdy check ma test pozytywny | ABSENT | brak testów checków |
| B-02 | Każdy check ma test negatywny | ABSENT | brak testów negatywnych |
| B-03 | Mutation score ≥ próg z configu | ABSENT | brak mutation testing |
| B-04 | VV coverage = 100% | ABSENT | brak pomiaru VV coverage |

---

### SEKCJA C — SEC (Bezpieczeństwo)

> Wymiar 3: 3 niezależne domeny zaufania; decyzje exploit-aware (KEV/EPSS/reachability). Dowód: macierz 12×4 pełna; detection drills = 1.0.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| C-01 | 3 niezależne domeny zaufania zdefiniowane i rozdzielone | ABSENT | brak definicji domen zaufania |
| C-02 | Decyzje exploit-aware (KEV/EPSS/reachability) | ABSENT | brak feedu KEV/EPSS |
| C-03 | Macierz 12×4 (domena × kontrola) pełna | ABSENT | brak macierzy |
| C-04 | Detection drills = 1.0 (wykrywanie ataków testowane) | ABSENT | brak detection drills |

---

### SEKCJA D — RES (Odporność)

> Wymiar 4: Każda domena awarii ma świeży dowód przeżycia. Dowód: restore drills, game days, RTO_actual ≤ RTO_declared.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| D-01 | Każda domena awarii ma świeży dowód przeżycia | ABSENT | brak restore drills |
| D-02 | Restore drills wykonywane w rytmie per tier | ABSENT | brak rytmu drilli |
| D-03 | Game days (symulacje awarii) | ABSENT | brak game days |
| D-04 | RTO_actual ≤ RTO_declared (zmierzone, nie deklarowane) | ABSENT | brak pomiaru RTO |

---

### SEKCJA E — PERM (Uprawnienia)

> Wymiar 5: Minimalne i wystarczające — mierzone z obu stron. Dowód: perm_health → 1.0; grants bez ścieżki = 0.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| E-01 | perm_health → 1.0 (uprawnienia minimalne i wystarczające) | ABSENT | brak pomiaru perm_health |
| E-02 | Grants bez ścieżki użycia = 0 | ABSENT | brak audytu grants |
| E-03 | Uprawnienia mierzone z obu stron (nadane vs używane) | ABSENT | brak pomiaru dwustronnego |
| E-04 | Separation of duties (SoD) na poziomie uprawnień | ABSENT | brak SoD |

---

### SEKCJA F — CFG (Konfigurowalność)

> Wymiar 6: 100% parametrów externalized lub explicite exempted. Dowód: CFG-008 = 100%; snapshot per run.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| F-01 | 100% parametrów externalized lub explicite exempted | ABSENT | brak registry configu |
| F-02 | CFG-008 = 100% (pokrycie parametrów) | ABSENT | brak pomiaru CFG-008 |
| F-03 | Snapshot per run (każdy run przypięty do configu) | ABSENT | brak snapshotów |
| F-04 | Jednokanałowy dostęp do configu (`config_get`, zakaz getenv) | ABSENT | brak jednokanałowości |

---

### SEKCJA G — CUR (Świeżość)

> Wymiar 7: Nic nie EOL; lag wersji w budżecie; polityka trzypasmowa. Dowód: currency score per serwis.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| G-01 | Zero zależności EOL | ABSENT | brak skanu EOL |
| G-02 | Lag wersji w budżecie (per tier) | ABSENT | brak pomiaru lagu |
| G-03 | Polityka trzypasmowa (stable/current/legacy) wdrożona | ABSENT | brak polityki |
| G-04 | Currency score per serwis | ABSENT | brak scorecarda świeżości |

---

### SEKCJA H — OPT (Optymalność)

> Wymiar 8: Każda decyzja tech w TDR z revisit_trigger; perf mierzony, nie opinia. Dowód: regresje perf = 0; kolejność gate'ów z priority(g).

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| H-01 | Każda decyzja tech w TDR z revisit_trigger | ABSENT | brak TDR |
| H-02 | Perf mierzony, nie opinia (budżety perf) | ABSENT | brak pomiaru perf |
| H-03 | Regresje perf = 0 | ABSENT | brak testów regresji perf |
| H-04 | Kolejność gate'ów z priority(g) | ABSENT | brak priorytetyzacji gate'ów |

---

### SEKCJA I — AEST (Piękno)

> Wymiar 9: 5 właściwości × proxy — dead code 0, jeden formatter, docs executable. Dowód: AEST scorecard.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| I-01 | Jeden formatter, zero drift (fmt --check w CI) | ABSENT | brak formattera |
| I-02 | Dead code = 0, commented-out code = 0 | ABSENT | brak skanu dead code |
| I-03 | TODO/FIXME registry z `expires_at` | ABSENT | brak registry TODO |
| I-04 | Executable examples (docs uruchamiane w CI) | ABSENT | brak doctestów |
| I-05 | AEST scorecard (5 właściwości × proxy) | ABSENT | brak scorecarda |

---

### SEKCJA J — MOD (Nowoczesność)

> Wymiar 10: Idiomy ery, zero deprecated, stdlib-over-custom. Dowód: MOD-01..05.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| J-01 | Modernize linters wymuszone (nie advisory, BLOCK) | ABSENT | brak modernize linterów |
| J-02 | Zero deprecated API usage (własnych i zależności) | ABSENT | brak skanu deprecated |
| J-03 | Paradigm conformance (structured concurrency, brak raw threads) | ABSENT | brak audytu paradygmatu |
| J-04 | Stdlib-over-custom (własny util duplikujący stdlib = flag) | ABSENT | brak reguły stdlib |

---

### SEKCJA K — CONS (Spójność)

> Wymiar 11: Jeden styl org-wide: layout, API, logi, błędy, docs. Dowód: golden path conformance %.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| K-01 | Golden path conformance (layout, struktura, standardowe targety) | ABSENT | brak golden path |
| K-02 | Jeden ruleset lint/format dla całego org | ABSENT | brak centralnego rulesetu |
| K-03 | Konwencje observability (nazwy pól, poziomy, correlation ID) | ABSENT | brak konwencji logów |
| K-04 | Docs structure contract (README 12 sekcji, ADR format) | ABSENT | brak kontraktu docs |
| K-05 | Golden path conformance % zmierzony | ABSENT | brak pomiaru |

---

### SEKCJA L — DX (Doświadczenie dewelopera)

> Wymiar 12: Setup jedną komendą; local == CI; day-0 green. Dowód: time-to-first-green ≤ budżet.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| L-01 | One-command setup (`make setup` / devcontainer) | ABSENT | brak setupu |
| L-02 | Local == CI (te same profile verify lokalnie) | ABSENT | brak parytetu local/CI |
| L-03 | Time-to-first-green mierzone ≤ budżet | ABSENT | brak pomiaru |
| L-04 | System sam ma actionable errors (nie stacktrace) | ABSENT | brak actionable errors |
| L-05 | Scaffold day-0 green (nowy serwis przechodzi wszystkie gate'y) | ABSENT | brak scaffoldu |

---

### SEKCJA M — META (Dowodliwość)

> Wymiar 13: System dowodzi sam siebie: fire drills, assurance case, VERIFY-SYSTEM. Dowód: detection = 1.0; claims ze świeżym evidence.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| M-01 | System dowodzi sam siebie (self-certification) | ABSENT | brak self-certification |
| M-02 | Fire drills (wykrywanie testowane) | ABSENT | brak fire drills |
| M-03 | Assurance case (mapa claims → evidence) | ABSENT | brak assurance case |
| M-04 | VERIFY-SYSTEM (weryfikacja całego systemu) | ABSENT | brak VERIFY-SYSTEM |
| M-05 | Claims ze świeżym evidence (detection = 1.0) | ABSENT | brak świeżości claims |

---

### SEKCJA N — CORR (Uczenie się)

> Wymiar 14: Każdy incydent → waiver/gap/missing-gate → backlog sam się pisze. Dowód: escapes bez closed_at = 0.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| N-01 | Każdy incydent → klasyfikacja (waiver/gap/missing-gate) | ABSENT | brak klasyfikacji incydentów |
| N-02 | Escapes bez `closed_at` = 0 | ABSENT | brak śledzenia escapes |
| N-03 | Backlog sam się pisze z findings | ABSENT | brak auto-backlogu |
| N-04 | Pętla uczenia się domknięta (finding → gate) | ABSENT | brak pętli |

---

### SEKCJA O — QI (Quality Index)

> Wymiar 15 (rozszerzenie): QI = średnia geometryczna ważona po wymiarach. Dowód: QI per serwis + trend ΔQI.

| ID | Item | STATUS | Dowód / Lista |
|---|---|---|---|
| O-01 | QI per serwis wyliczany (14 wymiarów) | ABSENT | brak kalkulatora QI |
| O-02 | Wagi $w_i$ z configu (per tier) | ABSENT | brak wag |
| O-03 | Trend ΔQI tydzień do tygodnia | ABSENT | brak trendu |
| O-04 | Reguła: dimension score bez świeżego evidence = 0 | ABSENT | brak reguły zero |

---

## SEKCJA P — TESTY MANUALNE I UX

> Nowa sekcja (delta do SONDA) — mapuje się na **HUMAN PLANE** (`docs/architecture/human-plane-design.md`). Człowiek jest **oracle** (jedynym źródłem prawdy dla tego, czego automat nie zmierzy), proces jest **gate'em**.
>
> Dwie zasady kanoniczne HUMAN PLANE:
> - **Aktywność manualna bez evidence = nie odbyła się.**
> - **Evidence manualne bez świeżości = nieważne.**

### P-01 — Pokrycie manualne

| Pole | Wartość |
|---|---|
| **ID** | P-01 |
| **Nazwa** | Pokrycie manualne |
| **Gate** | MAN-01 |
| **Opis** | Każda wymagana ścieżka użytkownika (journey) ma **albo** test automatyczny, **albo** udokumentowany charter manualny. Sprawdza kompletność pokrycia — nie ma ścieżek "nikt nie pilnuje". |
| **Kryterium COMPLETE** | 100% wymaganych ścieżek ma aktywny charter (auto lub manual) w `manual_charters`; zero ścieżek bez pokrycia. |
| **Kryterium ABSENT** | Brak jakichkolwiek charterów; brak rejestru `manual_charters`; brak mapy ścieżek wymaganych. Dowód akceptowalności: platforma nie ma jeszcze zdefiniowanych wymaganych ścieżek (pre-P0). |
| **Kryterium PARTIAL** | Część ścieżek ma charter, część nie. Lista: [ścieżki bez pokrycia]. |

### P-02 — Sesje testowe z evidence

| Pole | Wartość |
|---|---|
| **ID** | P-02 |
| **Nazwa** | Sesje testowe z evidence |
| **Gate** | MAN-02 |
| **Opis** | Testy manualne odbywają się w **sesjach** (nie "klikam coś"), każda sesja ma charter + evidence (kroki, oczekiwane, faktyczne, artefakt). Sprawdza dyscyplinę procesu. |
| **Kryterium COMPLETE** | Każda sesja w `manual_sessions` ma charter_id, testera, wynik (PASS/FAIL/FINDINGS) i evidence_ref; zero sesji bez evidence. |
| **Kryterium ABSENT** | Brak sesji; brak formatu evidence; brak rejestru `manual_sessions`. Dowód akceptowalności: brak wymaganych ścieżek do testowania (pre-P0). |
| **Kryterium PARTIAL** | Sesje istnieją, ale część bez evidence lub bez charteru. Lista: [sesje bez evidence]. |

### P-03 — UAT na digest

| Pole | Wartość |
|---|---|
| **ID** | P-03 |
| **Nazwa** | UAT na digest |
| **Gate** | MAN-03 |
| **Opis** | Akceptacja (UAT sign-off) jest **podpisana na konkretny digest artefaktu** (nie "wersja ogólnie"). Sprawdza niepodrabialność akceptacji — nie da się podpisać czegoś, co się zmieniło. |
| **Kryterium COMPLETE** | Każdy `uat_signoffs` ma artifact_digest, approvera, tier, signed_at, evidence_ref; zero sign-offów bez digesta. |
| **Kryterium ABSENT** | Brak rejestru `uat_signoffs`; brak mechanizmu wiązania akceptacji z digestem. Dowód akceptowalności: brak artefaktów do akceptacji (pre-P0). |
| **Kryterium PARTIAL** | Część akceptacji na digest, część "ogólnie". Lista: [sign-offy bez digesta]. |

### P-04 — Świeżość przy releasie

| Pole | Wartość |
|---|---|
| **ID** | P-04 |
| **Nazwa** | Świeżość przy releasie |
| **Gate** | MAN-04 |
| **Opis** | Release tier-1 **nie przechodzi** bez świeżego dowodu manualnego. Sprawdza świeżość przy releasie — evidence manualne ma budżet wieku per tier. |
| **Kryterium COMPLETE** | Każdy release tier-1 ma świeże evidence manualne (w budżecie wieku); brak świeżego dowodu = release zablokowany. |
| **Kryterium ABSENT** | Brak mechanizmu blokady release bez świeżego evidence; brak budżetu wieku. Dowód akceptowalności: brak releasów tier-1 (pre-P0). |
| **Kryterium PARTIAL** | Mechanizm istnieje, ale nie egzekwowany dla wszystkich releasów. Lista: [releasy bez świeżego evidence]. |

### P-05 — Rytm eksploracji

| Pole | Wartość |
|---|---|
| **ID** | P-05 |
| **Nazwa** | Rytm eksploracji |
| **Gate** | MAN-05 |
| **Opis** | Rytm eksploracji zależny od tieru (tier-0 częściej). Sprawdza rytm, nie jednorazowość — eksploracja jest cykliczna, nie "raz na zawsze". |
| **Kryterium COMPLETE** | Cadence per tier zdefiniowany w configu i egzekwowany; sesje eksploracyjne w rytmie; zero opóźnień ponad budżet. |
| **Kryterium ABSENT** | Brak definicji cadence; brak harmonogramu eksploracji. Dowód akceptowalności: brak tierów z wymaganym rytmem (pre-P0). |
| **Kryterium PARTIAL** | Cadence zdefiniowany, ale nie egzekwowany. Lista: [tier bez rytmu]. |

### P-06 — Konwersja manual→auto

| Pole | Wartość |
|---|---|
| **ID** | P-06 |
| **Nazwa** | Konwersja manual→auto |
| **Gate** | MAN-06 |
| **Opis** | **Serce HUMAN PLANE.** Findings manualne są przekute na testy automatyczne; mierzone `conversion_rate`. Sprawdza pętlę uczenia się — system sam się automatyzuje. |
| **Kryterium COMPLETE** | `conversion_rate` ≥ próg z configu; każdy finding ma `converted_test_id`; pętla domknięta. |
| **Kryterium ABSENT** | Brak pomiaru `conversion_rate`; brak mechanizmu konwersji findings → testy. Dowód akceptowalności: brak findings manualnych (pre-P0). |
| **Kryterium PARTIAL** | Część findings przekuta, część nie. Lista: [findings bez konwersji] + aktualny `conversion_rate`. |

### P-07 — A11y automatyczna

| Pole | Wartość |
|---|---|
| **ID** | P-07 |
| **Nazwa** | A11y automatyczna |
| **Gate** | UX-A-01 |
| **Opis** | Dostępność automatyczna — axe-core/pa11y, WCAG 2.2 AA. Sprawdza, czy automatyzowalna część dostępności jest w CI. |
| **Kryterium COMPLETE** | axe-core/pa11y w CI na wszystkich ekranach; zero naruszeń WCAG 2.2 AA; regresja a11y = FAIL. |
| **Kryterium ABSENT** | Brak skanera a11y; brak integracji z CI. Dowód akceptowalności: brak frontendu (pre-P0). |
| **Kryterium PARTIAL** | Skaner jest, ale nie na wszystkich ekranach lub nie w CI. Lista: [ekrany bez skanu]. |

### P-08 — Core Web Vitals

| Pole | Wartość |
|---|---|
| **ID** | P-08 |
| **Nazwa** | Core Web Vitals |
| **Gate** | UX-A-02 |
| **Opis** | Wydajność odczuwalna — LCP/INP/CLS w budżecie. Sprawdza, czy kluczowe metryki wydajności mieszczą się w budżecie z configu. |
| **Kryterium COMPLETE** | LCP/INP/CLS w budżecie na wszystkich krytycznych ścieżkach; pomiar w CI; regresja CWV = FAIL. |
| **Kryterium ABSENT** | Brak pomiaru CWV; brak budżetu. Dowód akceptowalności: brak frontendu (pre-P0). |
| **Kryterium PARTIAL** | Część metryk w budżecie, część nie. Lista: [metryki poza budżetem]. |

### P-09 — Badania użyteczności

| Pole | Wartość |
|---|---|
| **ID** | P-09 |
| **Nazwa** | Badania użyteczności |
| **Gate** | UX-R-01 / UX-R-02 / UX-R-04 |
| **Opis** | Governance UX nieautomatyzowalne — rytm badań użyteczności (UX-R-01), task success rate (UX-R-02), SUS/UMUX-Lite tracking (UX-R-04). Sprawdza, czy użyteczność jest mierzona, nie tylko "działa". |
| **Kryterium COMPLETE** | Cadence badań per tier; task success rate ≥ target; SUS/UMUX-Lite śledzone; wyniki w `ux_studies` z evidence. |
| **Kryterium ABSENT** | Brak badań; brak rejestru `ux_studies`; brak task success / SUS. Dowód akceptowalności: brak użytkowników / brak frontendu (pre-P0). |
| **Kryterium PARTIAL** | Część badań wykonana, część nie. Lista: [brakujące badania] + aktualne task success / SUS. |

---

## Podsumowanie sekcji P

| ID | Gate | Nazwa | STATUS |
|---|---|---|---|
| P-01 | MAN-01 | Pokrycie manualne | ABSENT |
| P-02 | MAN-02 | Sesje testowe z evidence | ABSENT |
| P-03 | MAN-03 | UAT na digest | ABSENT |
| P-04 | MAN-04 | Świeżość przy releasie | ABSENT |
| P-05 | MAN-05 | Rytm eksploracji | ABSENT |
| P-06 | MAN-06 | Konwersja manual→auto | ABSENT |
| P-07 | UX-A-01 | A11y automatyczna | ABSENT |
| P-08 | UX-A-02 | Core Web Vitals | ABSENT |
| P-09 | UX-R-01/02/04 | Badania użyteczności | ABSENT |

> **Uwaga:** Na świeżej platformie (pre-P0) wszystkie itemy sekcji P są `ABSENT` — to **oczekiwane i akceptowalne**. Dowód akceptowalności dla każdego `ABSENT` to brak wymaganych ścieżek / brak frontendu / brak releasów tier-1. Gdy pojawią się pierwsze artefakty, statusy przechodzą na `PARTIAL` (z listą braków) i docelowo `COMPLETE` (z evidence).

## Wymiar 15 — HUMAN PLANE w QI

```
s_15 = manual_coverage × evidence_freshness × min(1, task_success_actual/task_success_target) × conversion_rate
```

- `manual_coverage` — % wymaganych ścieżek z aktywnym charterem (auto lub manual) → P-01.
- `evidence_freshness` — % świeżych evidence (w budżecie wieku per tier) → P-04.
- `task_success_actual/task_success_target` — skuteczność zadań (cap na 1) → P-09.
- `conversion_rate` — MAN-06 → P-06.

QI aktualizuje się do **15 wymiarów**:

$$QI = 100 \times \prod_{i=1}^{15} s_i^{w_i}, \qquad \sum_i w_i = 1$$

---

## Status dokumentu

`STATUS: TEMPLATE` — diagnostyczny szkielet. Sekcje A–O i P są wypełnione statusami `ABSENT` jako stan wyjściowy świeżej platformy. Wypełnianie evidence → aktualizacja statusów → SONDA staje się raportem gotowości.
