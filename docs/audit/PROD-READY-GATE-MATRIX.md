# PROD-READY-GATE-MATRIX

> **Etap 1: DISCOVER + AUDIT** — raport deliverable (masterprompt §37).
> Data: 2026-08-10. Metoda: READ-ONLY audyt przez 4 równoległe subagenty Explore.
> Źródła prawdy: `tools/verify/gates/registry.sh` (registry), `tools/verify/gates/enforcement.sh` (wiring), `tools/verify/gates/domains/` (implementacje), `artifacts/evidence/gates/` (evidence).

## 1. Podsumowanie

| Kryterium | Wynik |
|---|---|
| Gate'y łącznie | **43** (GATE-001..GATE-043) |
| Ghost gate'y (wśród IMPLEMENTED) | **0** |
| Mock/placeholder gate'y | **0** |
| Dead gate'y (nie egzekwowane) | **0** |
| Shadow gate'y (egzekwowane, nie w registry) | **0** |
| Gate'y bez evidence (wśród IMPLEMENTED) | **0** |
| Profile | LOCAL_FAST=6, PRE_PUSH=13, CI=1, RELEASE=23 |
| Status | IMPLEMENTED=31, PROPOSED=12 |

**Werdykt:** system gate'ów jest spójny — registry (43) == implementacje (31 IMPLEMENTED + 12 PROPOSED) == wiring (wszystkie mają profil) == evidence (31/31 IMPLEMENTED ma evidence). Jedyna "anomalia" to 12 PROPOSED gate'ów (GATE-026..037) bez skryptów i bez evidence — ale to **świadomy stan lifecycle** (PROPOSED → IMPLEMENTED), jawnie obsłużony w `enforcement.sh` (pominięcie) i `gate-integrity.sh`.

## 2. Pełna lista gate'ów (43)

| ID | Domain | Name | Sev | Profile | Command | Stage | Blocking | Status |
|----|--------|------|-----|---------|---------|-------|----------|--------|
| GATE-001 | GATE-INTEGRITY | Registry==Implemented==Wired==Executed | critical | RELEASE | `tools/verify/gates/gate-integrity.sh` | certify | true | IMPLEMENTED |
| GATE-002 | SOURCE-OF-TRUTH | SoT git==desired state | critical | PRE_PUSH | `domains/source-of-truth.sh` | pre-push | true | IMPLEMENTED |
| GATE-003 | CANONICALITY | config/canonical jedynym źródłem | high | PRE_PUSH | `domains/canonicality.sh` | pre-push | true | IMPLEMENTED |
| GATE-004 | CONFIGURATION | Każdy element ma źródło konfiguracji | high | PRE_PUSH | `domains/configuration.sh` | pre-push | true | IMPLEMENTED |
| GATE-005 | SECURITY | Brak hardcoded sekretów | critical | LOCAL_FAST | `domains/security.sh` | pre-commit | true | IMPLEMENTED |
| GATE-006 | STRUCTURE | Struktura katalogów zgodna | high | LOCAL_FAST | `domains/structure.sh` | pre-commit | true | IMPLEMENTED |
| GATE-007 | ARCHITECTURE | Architektura zgodna z deklaracją | high | PRE_PUSH | `domains/architecture.sh` | pre-push | true | IMPLEMENTED |
| GATE-008 | DEPENDENCIES | Brak nieznanych zależności | medium | PRE_PUSH | `domains/dependencies.sh` | pre-push | false | IMPLEMENTED |
| GATE-009 | REPRODUCIBILITY | Reprodukowalność build/deploy | medium | RELEASE | `domains/reproducibility.sh` | release | false | IMPLEMENTED |
| GATE-010 | DEPLOYMENT | Deploy zgodny z kontraktem | medium | RELEASE | `domains/deployment.sh` | release | false | IMPLEMENTED |
| GATE-011 | CONTRACTS | Kontrakty README/API spełnione | high | PRE_PUSH | `domains/contracts.sh` | pre-push | true | IMPLEMENTED |
| GATE-012 | MIGRATION | Migracje StateStore spójne | high | PRE_PUSH | `domains/migration.sh` | pre-push | true | IMPLEMENTED |
| GATE-013 | RECOVERY | Backup/restore działa | high | RELEASE | `domains/recovery.sh` | release | true | IMPLEMENTED |
| GATE-014 | TESTING | Testy istnieją, nie puste | high | PRE_PUSH | `domains/testing.sh` | pre-push | true | IMPLEMENTED |
| GATE-015 | PERFORMANCE | Progi wydajności | low | LOCAL_FAST | `domains/performance.sh` | pre-commit | false | IMPLEMENTED |
| GATE-016 | DOCUMENTATION | Dokumentacja zgodna z kontraktem | medium | PRE_PUSH | `domains/documentation.sh` | pre-push | false | IMPLEMENTED |
| GATE-017 | CI | Workflow CI wywołują verify.sh | high | CI | `domains/ci.sh` | ci | true | IMPLEMENTED |
| GATE-018 | GIT-HOOKS | pre-commit/pre-push/validate-sot działają | high | LOCAL_FAST | `domains/git-hooks.sh` | pre-commit | true | IMPLEMENTED |
| GATE-019 | STATE | StateStore spójny | high | PRE_PUSH | `domains/state.sh` | pre-push | true | IMPLEMENTED |
| GATE-020 | EVIDENCE | Każdy gate ma evidence | high | RELEASE | `domains/evidence.sh` | release | true | IMPLEMENTED |
| GATE-021 | SYSTEM-TWIN | System Twin / Canonical State Graph | critical | RELEASE | `domains/system-twin.sh` | release | true | IMPLEMENTED |
| GATE-022 | INVARIANT-ENGINE | Invariant Engine | critical | RELEASE | `domains/invariant-engine.sh` | release | true | IMPLEMENTED |
| GATE-023 | ACTION-PROOF | Action Proof Engine | critical | RELEASE | `domains/action-proof.sh` | release | true | IMPLEMENTED |
| GATE-024 | POSTCONDITION | Postcondition Verification | critical | RELEASE | `domains/postcondition.sh` | release | true | IMPLEMENTED |
| GATE-025 | EFFECTIVE-CONFIG | Effective Config vs Declared State | critical | RELEASE | `domains/effective-config.sh` | release | true | IMPLEMENTED |
| GATE-026 | BEHAVIORAL-DRIFT | Behavioral Drift Engine | high | RELEASE | `domains/behavioral-drift.sh` | release | true | PROPOSED |
| GATE-027 | PREDICTIVE-RESOURCE | Predictive Resource Engine | high | RELEASE | `domains/predictive-resource.sh` | release | true | PROPOSED |
| GATE-028 | PREDICTIVE-COST | Predictive Cost Engine | high | RELEASE | `domains/predictive-cost.sh` | release | true | PROPOSED |
| GATE-029 | CONTEXT-HEALTH | Context Health Score | high | RELEASE | `domains/context-health.sh` | release | true | PROPOSED |
| GATE-030 | MEMORY-INTEGRITY | Memory Integrity Engine | high | RELEASE | `domains/memory-integrity.sh` | release | true | PROPOSED |
| GATE-031 | DEPENDENCY-GRAPH | Dependency + Compatibility Graph | high | RELEASE | `domains/dependency-graph.sh` | release | true | PROPOSED |
| GATE-032 | PRE-MORTEM | Pre-Mortem Engine | medium | RELEASE | `domains/pre-mortem.sh` | release | true | PROPOSED |
| GATE-033 | COUNTERFACTUAL | Counterfactual Engine | medium | RELEASE | `domains/counterfactual.sh` | release | true | PROPOSED |
| GATE-034 | CHANGE-RISK | Change Risk Score | medium | RELEASE | `domains/change-risk.sh` | release | true | PROPOSED |
| GATE-035 | COMPLEXITY-GOVERNOR | Complexity Governor | medium | RELEASE | `domains/complexity-governor.sh` | release | true | PROPOSED |
| GATE-036 | AGENT-TRUST | Agent Trust Score | medium | RELEASE | `domains/agent-trust.sh` | release | true | PROPOSED |
| GATE-037 | AUTONOMY-LEVEL | Adaptive Autonomy Level | medium | RELEASE | `domains/autonomy-level.sh` | release | true | PROPOSED |
| GATE-038 | WIRING | G-INTEG dwukierunkowa macierz | critical | LOCAL_FAST | `domains/wiring.sh` | pre-commit | true | IMPLEMENTED |
| GATE-039 | RESILIENCE | RESILIENCE PLANE HA/DR/Backup | critical | LOCAL_FAST | `domains/resilience.sh` | pre-commit | true | IMPLEMENTED |
| GATE-040 | LIFECYCLE | LIFECYCLE PLANE | critical | RELEASE | `tools/verify/lifecycle/lifecycle.sh` | release | true | IMPLEMENTED |
| GATE-041 | HUMAN-SIMULATION | HUMAN SIMULATION PLANE | high | PRE_PUSH | `domains/human.sh` | pre-push | true | IMPLEMENTED |
| GATE-042 | SIMULATION | SIMULATION PLANE | high | PRE_PUSH | `domains/simulation.sh` | pre-push | true | IMPLEMENTED |
| GATE-043 | OBSERVABILITY | OBSERVABILITY & KNOWLEDGE EXPLORER | high | PRE_PUSH | `domains/observability.sh` | pre-push | true | IMPLEMENTED |

## 3. Ghost gate'y

**Wśród IMPLEMENTED: 0.** Wszystkie 31 skryptów implementacji istnieje na dysku (29 w `domains/` + `gate-integrity.sh` + `lifecycle.sh`).

**Wśród PROPOSED: 12** — ale to **zgodne z designem** (PROPOSED = zarejestrowane, nie zaimplementowane; `enforcement.sh` jawnie pomija PROPOSED). Brakujące ścieżki: `domains/{behavioral-drift,predictive-resource,predictive-cost,context-health,memory-integrity,dependency-graph,pre-mortem,counterfactual,change-risk,complexity-governor,agent-trust,autonomy-level}.sh`.

## 4. Mock/placeholder gate'y — 0

Przeszukano wszystkie skrypty w `domains/` pod kątem TODO/stub/placeholder/not implemented. Wszystkie trafienia to **legalna logika detekcji** (gate'y, które *wykrywają* placeholdery w docs/CI/README), a nie placeholderowe implementacje.

## 5. Dead gate'y — 0

Wszystkie 43 gate'y mają przypisany profil (pole 7 niepuste). Mechanizm mapowania (`registry_gates_for_profile` w `registry.sh:578`):
- **RELEASE** → zwraca **WSZYSTKIE** gate'y (nadzbiór).
- **LOCAL_FAST / PRE_PUSH / CI** → zwraca gate'y, których profil == dany profil **LUB** profil == RELEASE.

Egzekwowanie per profil:

| Profil | Gate'y egzekwowane |
|--------|--------------------|
| **LOCAL_FAST** | GATE-005, 006, 015, 018, 038, 039 (własne) + wszystkie RELEASE (001, 009, 010, 013, 020-025, 026-037, 040) = **23 gate'y** |
| **PRE_PUSH** | GATE-002, 003, 004, 007, 008, 011, 012, 014, 016, 019, 041, 042, 043 (własne) + wszystkie RELEASE = **36 gate'ów** |
| **CI** | GATE-017 (własny) + wszystkie RELEASE = **24 gate'y** |
| **RELEASE** | **wszystkie 43 gate'y** |

Uwaga: PROPOSED gate'y (026-037) są w RELEASE, ale `enforcement.sh` **pomija je** (status PROPOSED → `continue`), więc realnie egzekwowanych jest 31 gate'ów.

## 6. Shadow gate'y — 0

`enforcement.sh` iteruje wyłącznie po `registry_gates_for_profile`, który zwraca tylko ID z registry. Brak shadow gate'ów z konstrukcji.

## 7. Gate'y bez evidence — 0

Wszystkie 31 gate'ów IMPLEMENTED ma plik `artifacts/evidence/gates/GATE-XXX.evidence` (GATE-001..025, GATE-038..043). PROPOSED gate'y (026-037) nie mają evidence — zgodne z designem.

## 8. Profile distribution

| Profil | Liczba | Gate'y |
|--------|--------|--------|
| LOCAL_FAST | 6 | GATE-005, 006, 015, 018, 038, 039 |
| PRE_PUSH | 13 | GATE-002, 003, 004, 007, 008, 011, 012, 014, 016, 019, 041, 042, 043 |
| CI | 1 | GATE-017 |
| RELEASE | 23 | GATE-001, 009, 010, 013, 020-025, 026-037, 040 |
| **Suma** | **43** | |

## 9. Status distribution

| Status | Liczba | Gate'y |
|--------|--------|--------|
| IMPLEMENTED | 31 | GATE-001..025, GATE-038..043 |
| PROPOSED | 12 | GATE-026..037 |
| WIRED | 0 | — |
| EXECUTED | 0 | — |
| ENFORCED | 0 | — |
| CERTIFIED | 0 | — |
| DEPRECATED | 0 | — |
| RETIRED | 0 | — |
| **Suma** | **43** | |

## 10. Uwagi / niejednoznaczności

- **Statusy WIRED/EXECUTED/ENFORCED/CERTIFIED zdefiniowane, ale nieużywane.** Wszystkie zaimplementowane gate'y mają status IMPLEMENTED, mimo że są w pełni zintegrowane i mają evidence. Sugeruje to, że lifecycle statusów nie jest w pełni egzekwowany (brak przejść IMPLEMENTED→WIRED→EXECUTED→ENFORCED→CERTIFIED). **Do rozważenia w Etapie 2.**
- **GATE-040 (LIFECYCLE)** jako jedyny ma command poza `domains/` (`tools/verify/lifecycle/lifecycle.sh`) — istnieje, nie jest ghost.
- **GATE-001 (GATE-INTEGRITY)** jako jedyny ma command w `gates/` root (`gate-integrity.sh`) — istnieje, nie jest ghost.
