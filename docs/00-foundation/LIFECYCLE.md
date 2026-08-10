---
id: LIFECYCLE-001
type: lifecycle
title: Evidence-Driven Software Lifecycle
status: active
owner: lifecycle-owner
source_of_truth: Git
created: 2026-08-10
version: 1.0.0
consumers: [tools/verify/lifecycle/lifecycle.sh, tools/verify/gates/registry.sh, system/control-plane/state]
---

# LIFECYCLE — Evidence-Driven Software Lifecycle

> **STATUS: ACTIVE** — konstytucja cyklu życia oprogramowania.
> **Owner: lifecycle-owner**

## 1. Cel

Definiuje **wykonywalny** cykl życia oprogramowania dla AIGON Production Platform.
To NIE jest ręczna checklista do odhaczania przez ludzi. To jest system, w którym:

- **PRD generuje wymagania** (REQUIREMENT_ID)
- **wymagania generują traceability** (REQUIREMENT → CONTRACT → DESIGN → CODE → TEST → GATE → EVIDENCE)
- **kontrakty generują testy i gate'y** (CONTRACT_ID → TEST → GATE)
- **gate'y generują evidence** (GATE → EVIDENCE_ID)
- **release ciągnie tylko zweryfikowane artefakty** (RELEASE → VERIFICATION)
- **deployment automatycznie tworzy dowód tego, co jest w produkcji** (DEPLOYMENT → RUNTIME → EVIDENCE)

**Zasada nadrzędna:** *Nie przechodzimy dalej dlatego, że "skończyliśmy pracę". Przechodzimy dalej dlatego, że spełniliśmy kontrakt i mamy dowód.*

## 2. Uniwersalny state machine

Każdy artefakt (wymaganie, kontrakt, zmiana, release) przechodzi przez stany.
**Nigdy nie ma stanu "DONE"** — zawsze jest konkretny stan, z którego można
przejść dalej lub wrócić.

```text
IDEA → DISCOVERING → DEFINED → CONTRACTED → DESIGNED → IMPLEMENTING →
VERIFYING → INTEGRATING → HARDENING → RELEASING → STAGING → CERTIFIED →
CANARY → PRODUCTION → OPERATING → DEPRECATED → RETIRED
```

Stany dodatkowe (nie na ścieżce głównej):

```text
BLOCKED (z dowolnego stanu, gdy kontrakt nie jest spełniony)
```

### 2.1 Przejścia

| Z | Do | Warunek |
|---|---|---|
| IDEA | DISCOVERING | Intake zaakceptowany (G0) |
| DISCOVERING | DEFINED | Wymagania zdefiniowane (G1) |
| DEFINED | CONTRACTED | Kontrakt zatwierdzony (G2) |
| CONTRACTED | DESIGNED | Projekt zatwierdzony (G3) |
| DESIGNED | IMPLEMENTING | Implementacja rozpoczęta (G4) |
| IMPLEMENTING | VERIFYING | Kod gotowy do weryfikacji (G5) |
| VERIFYING | INTEGRATING | Testy jednostkowe/integracyjne przeszły (G6) |
| INTEGRATING | HARDENING | Integracja przeszła (G7) |
| HARDENING | RELEASING | Hardening przeszły (G8) |
| RELEASING | STAGING | Release candidate zbudowany (G9) |
| STAGING | CERTIFIED | Staging zweryfikowany (G10) |
| CERTIFIED | CANARY | Canary deployment (G11) |
| CANARY | PRODUCTION | Canary przeszło (G12) |
| PRODUCTION | OPERATING | Produkcja stabilna (G13) |
| OPERATING | DEPRECATED | Decyzja o deprecacji (G14) |
| DEPRECATED | RETIRED | Wycofanie z produkcji (G15) |
| dowolny | BLOCKED | Kontrakt niespełniony (G16) |
| BLOCKED | dowolny | Blocker usunięty, kontrakt spełniony |
| OPERATING | IDEA | Nowa iteracja (G17) |

## 3. Fazy F00-F17

Każda faza ma: cel, wejście, wyjście (artefakty), gate wyjściowy, owner.

| Faza | Nazwa | Cel | Gate wyjściowy |
|---|---|---|---|
| F00 | IDEA / INTAKE | Pomysł, problem, wartość | G0 |
| F01 | DISCOVERY | Eksploracja, research, feasibility | G1 |
| F02 | REQUIREMENTS | Wymagania (PRD/SPEC) | G2 |
| F03 | CONTRACT | Kontrakt (API, semver, schematy) | G3 |
| F04 | DESIGN | Projekt techniczny | G4 |
| F05 | IMPLEMENTATION | Kod | G5 |
| F06 | UNIT/INTEGRATION TEST | Testy | G6 |
| F07 | INTEGRATION | Integracja komponentów | G7 |
| F08 | HARDENING | Bezpieczeństwo, wydajność, odporność | G8 |
| F09 | RELEASE CANDIDATE | Build, artefakt, SBOM | G9 |
| F10 | STAGING | Weryfikacja na staging | G10 |
| F11 | CERTIFICATION | Certyfikacja baseline | G11 |
| F12 | CANARY | Canary deployment | G12 |
| F13 | PRODUCTION | Deployment do produkcji | G13 |
| F14 | OPERATIONS | Monitoring, SLO, runbook | G14 |
| F15 | DEPRECATION | Decyzja o wycofaniu | G15 |
| F16 | RETIREMENT | Wycofanie z produkcji | G16 |
| F17 | EVOLUTION | Nowa iteracja, feedback loop | G17 |

## 4. Gate'y G0-G17

Każdy gate to **wykonywalna kontrola** (nie checklista). Gate przechodzi, gdy
kontrakt fazy jest spełniony i istnieje evidence.

| Gate | Nazwa | Warunek przejścia | Evidence |
|---|---|---|---|
| G0 | IDEA | Intake zaakceptowany, problem zdefiniowany | IDEA-001 |
| G1 | DISCOVERY | Feasibility potwierdzona | DISCOVERY-001 |
| G2 | REQUIREMENTS | Wymagania zdefiniowane, mierzalne | REQUIREMENT-001 |
| G3 | CONTRACT | Kontrakt zatwierdzony, semver | CONTRACT-001 |
| G4 | DESIGN | Projekt zatwierdzony | DESIGN-001 |
| G5 | IMPLEMENTATION | Kod istnieje, pokryty testami | CODE-001 |
| G6 | TEST | Testy przechodzą | TEST-001 |
| G7 | INTEGRATION | Integracja przechodzi | INTEGRATION-001 |
| G8 | HARDENING | Bezpieczeństwo/wydajność/odporność OK | HARDENING-001 |
| G9 | RELEASE | Release candidate zbudowany, SBOM | RELEASE-001 |
| G10 | STAGING | Staging zweryfikowany | STAGING-001 |
| G11 | CERTIFICATION | Baseline certyfikowany | CERTIFICATION-001 |
| G12 | CANARY | Canary przeszło | CANARY-001 |
| G13 | PRODUCTION | Produkcja stabilna | PRODUCTION-001 |
| G14 | OPERATIONS | Monitoring/SLO/runbook aktywne | OPERATIONS-001 |
| G15 | DEPRECATION | Decyzja o deprecacji udokumentowana | DEPRECATION-001 |
| G16 | RETIREMENT | Wycofanie z produkcji | RETIREMENT-001 |
| G17 | EVOLUTION | Feedback loop zamknięty | EVOLUTION-001 |

## 5. Uniwersalny model artefaktów

Każdy artefakt ma unikalny identyfikator i traceability.

```text
CHANGE_ID → REQUIREMENT_ID → CONTRACT_ID → DESIGN_ID → CODE_ID → TEST_ID →
GATE_ID → BUILD_ID → ARTIFACT_ID → RELEASE_ID → DEPLOYMENT_ID → RUNTIME_ID →
EVIDENCE_ID → VERIFICATION_ID
```

### 5.1 Identyfikatory

| Prefix | Artefakt | Format |
|---|---|---|
| `CHG-` | Zmiana | `CHG-<seq>` |
| `REQ-` | Wymaganie | `REQ-<seq>` |
| `CONTRACT-` | Kontrakt | `CONTRACT-<seq>` |
| `DESIGN-` | Projekt | `DESIGN-<seq>` |
| `CODE-` | Kod | `CODE-<seq>` |
| `TEST-` | Test | `TEST-<seq>` |
| `GATE-` | Gate | `GATE-<seq>` |
| `BUILD-` | Build | `BUILD-<seq>` |
| `ART-` | Artefakt | `ART-<seq>` |
| `REL-` | Release | `REL-<seq>` |
| `DEP-` | Deployment | `DEP-<seq>` |
| `RUNTIME-` | Runtime | `RUNTIME-<seq>` |
| `EVIDENCE-` | Evidence | `EVIDENCE-<seq>` |
| `VER-` | Weryfikacja | `VER-<seq>` |

### 5.2 Traceability matrix

Traceability jest **generowana** z artefaktów (nie ręcznie). Każdy artefakt
deklaruje swoje powiązania w metadata.

```text
REQUIREMENT → CONTRACT → DESIGN → CODE → TEST → GATE → EVIDENCE → VERIFICATION
```

## 6. Core loop

```text
REQUIREMENT → CONTRACT → IMPLEMENTATION → TEST → GATE → EXECUTION → EVIDENCE → VERIFICATION
```

## 7. Zasady (skrót)

1. **Evidence-driven**: nie przechodzimy dalej bez dowodu.
2. **Kontrakt przed implementacją**: nie piszemy kodu bez kontraktu.
3. **Traceability generowana**: nie ręczna.
4. **State machine, nie "DONE"**: każdy artefakt ma konkretny stan.
5. **Release ciągnie tylko zweryfikowane artefakty**.
6. **Deployment tworzy dowód produkcji**.
7. **No second SoT**: LIFECYCLE.md jest dokumentem (L5), nie źródłem prawdy.
8. **Nie twórz drugiego systemu verification**: lifecycle.sh używa istniejących gate'ów.
9. **Nie twórz meta-systemu bez potrzeby**: dodajemy tylko to, czego brakuje.

## 8. Wykonywalność

Ten dokument jest **implementowany** przez:

- `tools/verify/lifecycle/lifecycle.sh` — moduł gate'ów lifecycle (GATE-032+)
- `system/control-plane/state/migrations/0017_lifecycle.sql` — tabele StateStore
- `tools/verify/gates/registry.sh` — rejestracja gate'ów lifecycle

## Status

`STATUS: ACTIVE`
