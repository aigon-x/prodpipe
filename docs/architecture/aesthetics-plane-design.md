---

# AESTHETICS PLANE — piękno jako mierzalne właściwości

> Design doc — źródło specyfikacji dla implementacji AESTHETICS PLANE.
> Status: DESIGN (do implementacji).

## Cel

Piękno oprogramowania przestaje być "miękką" cechą. Rozkłada się na **5 mierzalnych właściwości**, każda z automatycznie mierzalnym proxy, i dostaje gate'y z evidence. System jest piękny, gdy wszystko wygląda tak samo — bo wtedy *widać to, co ważne*.

Biznesowy powód: piękny system ma niższy cognitive load → szybszy onboarding → mniej błędów → szybsze zmiany. Piękno to najtańsza forma jakości.

## 5 właściwości piękna

```
piękno_software = konsystencja + prostota + symetria + ekspresywność + dopracowanie powierzchni
```

Każda właściwość ma proxy mierzalne automatycznie (nie opinię).

## Rodziny gate'ów

### AEST — piękno (AEST-01..11)

| ID | Check | Co mierzy |
|---|---|---|
| AEST-01 | Jeden formatter, zero drift — cały repo przechodzi `fmt --check`, reguły centralne, wersjonowane | jednolitość wizualna |
| AEST-02 | Naming lint — konwencje casing, zakazane skróty, język domeny (ubiquitous language) | nazewnictwo jak proza |
| AEST-03 | Dead code = 0, commented-out code = 0 — wykrywanie automatyczne + auto-PR z usunięciem | brak trupów w kodzie |
| AEST-04 | TODO/FIXME registry z `expires_at` — wieczne TODO = FAIL (wzorzec waiverów) | dług estetyczny wygasa |
| AEST-05 | Budżety powierzchni: długość funkcji/pliku, głębokość zagnieżdżenia, liczba parametrów | elegancja = małe powierzchnie |
| AEST-06 | Executable examples — snippet w docs uruchamiany w CI (doctest); przykład, który nie działa = FAIL | docs, które działają |
| AEST-07 | Error message quality — katalog kodów błędów, format standardowy, komunikat actionable | dopracowanie powierzchni |
| AEST-08 | API design lint (spectral/vacuum na OpenAPI): naming, paginacja, format błędów, wersjonowanie | API czytelne jak książka |
| AEST-09 | Symetria: ten sam problem = to samo rozwiązanie (fitness functions, odstępstwa = waiver) | przewidywalność |
| AEST-10 | PR hygiene — czysta historia, conventional commits, rozmiar PR | historia czytelna |
| AEST-11 | (frontend) Design system conformance — design tokens, komponenty z biblioteki, custom CSS = waiver | spójny wygląd |

### MOD — nowoczesność (MOD-01..05)

| ID | Check |
|---|---|
| MOD-01 | Modernize linters wymuszone (pyupgrade, eslint modern, gopls modernize) — nie advisory, BLOCK |
| MOD-02 | Zero deprecated API usage — własnej platformy i zależności |
| MOD-03 | Paradigm conformance — wzorce ery: structured concurrency, brak raw threads tam, gdzie framework daje abstrakcję |
| MOD-04 | Stdlib-over-custom — własny util duplikujący stdlib = flag |
| MOD-05 | Idiom ceiling — kod używa konstrukcji adekwatnych do pinowanej wersji języka |

### CONS — spójność (CONS-01..08)

| ID | Check |
|---|---|
| CONS-01 | Golden path conformance — layout projektu, struktura katalogów, standardowe targety (`make test/verify/deploy` wszędzie) |
| CONS-02 | Jeden ruleset lint/format dla całego org — wersjonowany centralnie, drift = FAIL |
| CONS-03 | Konwencje observability — te same nazwy pól logów, poziomy, correlation ID wszędzie |
| CONS-04 | Konwencja error handling per język — jeden wzorzec, odstępstwa = waiver |
| CONS-05 | API style guide org-wide — jeden ruleset OpenAPI dla wszystkich serwisów |
| CONS-06 | Docs structure contract — README 12 sekcji, ADR format, runbook format |
| CONS-07 | Konwencje config — nazwy env, layout plików, klucze registry z prefiksami domen |
| CONS-08 | Jedna biblioteka per zadanie per język (HTTP client, logger) |

### DX — doświadczenie dewelopera (DX-01..05)

| ID | Check |
|---|---|
| DX-01 | One-command setup — `make setup` / devcontainer działa; testowany w CI na czystym środowisku |
| DX-02 | Local == CI — te same profile verify uruchamialne lokalnie; "u mnie działa" = niemożliwe |
| DX-03 | Time-to-first-green mierzone — nowy dev od clone do zielonego pipeline ≤ budżetu z configu |
| DX-04 | System sam ma actionable errors — gate failuje z komunikatem "co i jak naprawić", nie stacktrace |
| DX-05 | Scaffold day-0 green — nowy serwis z template'u przechodzi WSZYSTKIE gate'y od pierwszego commita |

## 15 wymiarów doskonałości

| # | Wymiar | Rodzina | Definicja "doskonałe" | Dowód (z evidence) |
|---|---|---|---|---|
| 1 | Spójność szkieletu | INTEG | Każde połączenie zweryfikowane dwukierunkowo; zero ghostów, zero orphanów | 4-kierunkowy matrix pusty |
| 2 | Poprawność | G0–G5 + VV | Każdy check ma test pozytywny + negatywny + mutation score | VV coverage = 100% × mutation ≥ próg |
| 3 | Bezpieczeństwo | SEC D/A/R/C | 3 niezależne domeny zaufania; decyzje exploit-aware (KEV/EPSS/reachability) | macierz 12×4 pełna; detection drills = 1.0 |
| 4 | Odporność | RES B/D/H | Każda domena awarii ma świeży dowód przeżycia | restore drills, game days, RTO_actual ≤ RTO_declared |
| 5 | Uprawnienia | PERM | Minimalne I wystarczające — mierzone z obu stron | perm_health → 1.0; grants bez ścieżki = 0 |
| 6 | Konfigurowalność | CFG | 100% parametrów externalized lub explicite exempted | CFG-008 = 100%; snapshot per run |
| 7 | Świeżość | CUR | Nic nie EOL; lag wersji w budżecie; polityka trzypasmowa | currency score per serwis |
| 8 | Optymalność | OPT + EFF | Każda decyzja tech w TDR z revisit_trigger; perf mierzony, nie opinia | regresje perf = 0; kolejność gate'ów z priority(g) |
| 9 | Piękno | AEST | 5 właściwości × proxy — dead code 0, jeden formatter, docs executable | AEST scorecard |
| 10 | Nowoczesność | MOD | Idiomy ery, zero deprecated, stdlib-over-custom | MOD-01..05 |
| 11 | Spójność | CONS | Jeden styl org-wide: layout, API, logi, błędy, docs | golden path conformance % |
| 12 | DX | DX | Setup jedną komendą; local == CI; day-0 green | time-to-first-green ≤ budżet |
| 13 | Dowodliwość | META | System dowodzi sam siebie: fire drills, assurance case, VERIFY-SYSTEM | detection = 1.0; claims ze świeżym evidence |
| 14 | Uczenie się | CORR + escape | Każdy incydent → waiver/gap/missing-gate → backlog sam się pisze | escapes bez closed_at = 0 |
| 15 | Jakość ludzka | MAN + UX-A + UX-R | Człowiek jako oracle; proces zgatedowany; pokrycie charterami, świeże evidence, task success w budżecie, findings przekute na testy auto | `s_15 = manual_coverage × evidence_freshness × min(1, task_success_actual/task_success_target) × conversion_rate` |

## Quality Index (QI)

$$QI = 100 \times \prod_{i=1}^{15} s_i^{w_i}, \qquad \sum_i w_i = 1$$

**Średnia geometryczna, nie arytmetyczna** — jeden wymiar na zero → cały indeks na zero. Nie da się "nadrobić" dziurawego bezpieczeństwa pięknym kodem. Doskonałość = brak słabych ogniw.

- Wagi $w_i$ — z configu (tier 1 ma inne wagi niż tier 3).
- Metryka konkurencyjna: $\Delta QI$ tydzień do tygodnia — prędkość jakości.
- Reguła: dimension score bez świeżego evidence = 0 (nie NULL — ZERO).

## Migracja 0009: aesthetics + quality index

```sql
-- migrations/0009_aesthetics_qi.sql
CREATE TABLE aest_findings (
  id INTEGER PRIMARY KEY,
  service_id TEXT NOT NULL,
  check_id TEXT NOT NULL,            -- AEST-xx / MOD-xx / CONS-xx / DX-xx
  subject TEXT NOT NULL,             -- plik/symbol/API
  detail_json TEXT,
  expires_at TEXT,                   -- AEST-04: TODO wygasa
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE quality_index (
  id INTEGER PRIMARY KEY,
  service_id TEXT NOT NULL,
  dimension TEXT NOT NULL,           -- 15 wymiarów
  score REAL NOT NULL,               -- 0..1, wyliczone z evidence
  computed_at TEXT NOT NULL,
  UNIQUE(service_id, dimension, computed_at)
);
-- QI per serwis = średnia geometryczna ważona po wymiarach; trend do scorecarda.
-- Reguła: dimension score bez świeżego evidence = 0 (nie NULL — ZERO).
```

## Kolejność wdrożenia

AEST-01/03/04 (tani, natychmiastowy efekt wizualny) → CONS-01/02 (golden path jako nośnik wszystkiego) → DX-01/02 (prędkość zespołu) → reszta.

## Trzy warianty (wdrażane równolegle)

1. **(a) spectral AEST-08** — pełny ruleset spectral/vacuum dla API (OpenAPI): naming, paginacja, format błędów, wersjonowanie.
2. **(b) fitness CONS-01** — fitness functions dla golden path conformance (layout, struktura katalogów, standardowe targety).
3. **(c) kalkulator QI** — query + scorecard: agregacja 15 wymiarów w Quality Index (średnia geometryczna ważona).
