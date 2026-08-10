# PROD-READY-PIPELINE-MATRIX

> **Etap 1: DISCOVER + AUDIT** — raport deliverable (masterprompt §37).
> Data: 2026-08-10. Metoda: READ-ONLY audyt przez 4 równoległe subagenty Explore.
> Źródła prawdy: `config/canonical/pipelines.yaml` (kanon), `tools/automation/core/pipelines.sh` (generowany), `tools/automation/core/gen-pipelines.sh` (generator), `tools/automation/automation.sh` (orchestrator).

## 1. Podsumowanie

| Kryterium | Wynik |
|---|---|
| Pipeline'y łącznie | **98** (P-001..P-098) |
| Ghost pipeline'y (skrypt nie istnieje) | **0** |
| Mock/placeholder pipeline'y | **0** |
| Dead pipeline'y (nieosiągalne) | **0** |
| Pipeline'y bez kontraktu | **0** |
| Złamane/cykliczne zależności | **0** |
| Rodziny | **13** |
| Klasy wykonania | FAST=4, STANDARD=42, DEEP=23, RELEASE=11, CONTINUOUS=18 |

**Werdykt:** katalog pipeline'ów jest w pełni spójny — `pipelines.yaml` (kanon) ↔ `pipelines.sh` (generowany) ↔ skrypty w `tools/automation/` ↔ klasy wykonania ↔ orchestrator `automation.sh`. Wszystkie 98 pipeline'ów jest zaimplementowanych, realnych, posiada pełny 8-fazowy kontrakt i jest osiągalnych przez orchestrator.

## 2. Pełna lista pipeline'ów (98)

| Zakres | Rodzina | Pipeline'y | Liczba |
|---|---|---|---|
| P-001..P-007 | PRODUCT | discovery, requirements, traceability, prioritization, roadmap, backlog, acceptance | 7 |
| P-008..P-014 | DESIGN | architecture, design-doc, contracts, interface, data-model, tech-debt, change-impact | 7 |
| P-015..P-020 | SECURITY | threat-model, secrets, dependency-scan, static-analysis, penetration, compliance | 6 |
| P-021..P-028 | CODE | unit-tests, integration-tests, e2e-tests, lint, format, coverage, performance, review | 8 |
| P-029..P-033 | BUILD | build, artifact, sbom, reproducibility, release | 5 |
| P-034..P-038 | DEPLOYMENT | deploy, rollback, canary, blue-green, infrastructure | 5 |
| P-039..P-050 | RUNTIME | pipeline-governance, gap-discovery, temporal-assurance, knowledge-consistency, self-certification, continuous-certification, change-risk, selective-verification, unknown-management, source-of-truth, generated-artifact, documentation | 12 |
| P-051 | RECOVERY | max-decomposition | 1 |
| P-052..P-060 | GTM | discover, validate, design, build, prep, launch, adopt, scale, learn | 9 |
| P-061..P-069 | AI | data-prep, train, eval, validate, package, deploy, observe, retrain, retire | 9 |
| P-070..P-078 | OFFENSIVE-SECURITY | recon, scan, exploit, persist, exfil, detect, respond, remediate, learn | 9 |
| P-079..P-089 | HUMAN-SIMULATION | setup, navigate, wait, screenshot, interact, assert, record, report, replay, terminal, vm | 11 |
| P-090..P-098 | SIMULATION | scenario, prepare, execute, observe, measure, evaluate, remediate, document, repeat | 9 |

**Suma: 98** (7+7+6+8+5+5+12+1+9+9+9+11+9 = 98 ✓)

## 3. Klasy wykonania

Każdy pipeline należy do dokładnie jednej klasy (klasy w `pipelines.yaml` i `pipelines.sh` są identyczne):

| Klasa | Liczba |
|---|---|
| FAST | 4 |
| STANDARD | 42 |
| DEEP | 23 |
| RELEASE | 11 |
| CONTINUOUS | 18 |

## 4. MON-* pipeline'y

**NIE istnieją jako osobne pipeline'y.** Monitor Plane definiuje 70 gate'ów (MON-R-01..MON-A-08) oraz metadane MON-* (schedule/control/monitor/notify) jako pola każdego pipeline'a P-001..P-098. Wszystkie 98 pipeline'ów ma kompletne metadane MON-* (schedule=manual, timeout=300, retries=3, priority=NORMAL).

## 5. Ghost pipeline'y — 0

Wszystkie 98 ścieżek `script` z pipelines.yaml istnieje w `tools/automation/`. Zweryfikowano każdą rodzinę (m.in. `git ls-files` potwierdza śledzenie skryptów BUILD).

## 6. Mock/placeholder pipeline'y — 0

Przeszukano wszystkie skrypty w `tools/automation/` pod kątem markerów `TODO`, `placeholder`, `not implemented`, `stub`, `FIXME`, `XXX`, `not yet`, `coming soon` — **zero trafień** w skryptach pipeline'ów. Wszystkie skrypty mają substancjalną logikę (61–380 linii), np. `recovery/max-decomposition.sh` (380), `offsec/recon.sh` (136), `human/setup.sh` (135), `runtime/pipeline-governance.sh` (116), `build/build.sh` (109).

## 7. Dead pipeline'y — 0

- Wszystkie 98 pipeline'ów jest w `pipelines.sh` (tablica `PIPELINES`).
- Wszystkie 98 jest w listach klas `pipeline_class_modules()` (98 unikalnych ID = 98 w YAML).
- Orchestrator `automation.sh` uruchamia wszystkie klasy przez `run_class_modules()` → `run_pipeline_dag()` → `run_pipeline()`.
- `tools/verify/verify.sh:202` wywołuje `automation.sh` jako orchestrator weryfikacji.
- Brak skryptów-orphanów: każdy skrypt w katalogach rodzin odpowiada dokładnie jednemu pipeline'owi z YAML.

## 8. Pipeline'y bez kontraktu — 0

Wszystkie 98 pipeline'ów ma pole `contract:` z pełnym 8-fazowym kontraktem `[DISCOVER, CONTRACT, EXECUTE, TEST, EVIDENCE, VERIFY, REGISTER, REPORT]`.

## 9. Zależności — 0 złamanych, 0 cykli

- Wszystkie `depends` wskazują na istniejące ID (P-001..P-098).
- Brak cykli: każdy pipeline zależy wyłącznie od pipeline'ów o niższym numerze (P-XXX → P-YYY, YYY < XXX), co gwarantuje DAG bez cykli.
- Korzenie DAG (bez zależności): P-001, P-016, P-024, P-039, P-052, P-061, P-070, P-079, P-090.
- Zależności międzyrodzinne (cross-family): P-008→P-002, P-014→P-003, P-015→P-008, P-021→P-010, P-045→P-014, P-051→P-003 — wszystkie poprawne.

## 10. Uwagi / kosmetyka

- **Stale komentarze "P-001..P-051"** w nagłówkach `automation.sh:15`, `pipelines.sh:4`, `gen-pipelines.sh:126`, `tests/README.md:6`, `tests/test_pipelines.sh:7` — katalog faktycznie zawiera P-001..P-098. To przestarzałe komentarze, nie błąd wykonania. **Do remediacji w Etapie 2.**
- Artefakt narzędzia `list_directory` dla katalogu `build/` (zgłaszał "5 git-ignored") — `git check-ignore` zwraca pusto, `git ls-files` potwierdza śledzenie. Nie jest to realny problem.
