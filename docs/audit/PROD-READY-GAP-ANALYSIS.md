# PROD-READY-GAP-ANALYSIS

> **Etap 1: DISCOVER + AUDIT** — raport deliverable (masterprompt §37).
> Data: 2026-08-10. Metoda: READ-ONLY audyt przez 4 równoległe subagenty Explore.
> Cel: zidentyfikować luki między stanem faktycznym a wymaganym (certyfikacja Prod-ready → materializacja prod-skel).

## 1. Podsumowanie luk

| # | Luka | Ważność | Obszar |
|---|---|---|---|
| G-01 | Pipeline↔gate disconnect (dwa światy) | **CRITICAL** | Architektura wykonawcza |
| G-02 | Placeholdery system/ (14) + top-level (14) | HIGH | Struktura |
| G-03 | Kontrakty genesis (STATUS: UNDEFINED) | HIGH | Kontrakty |
| G-04 | 12 PROPOSED gate'ów (GATE-026..037) | MEDIUM | Gate system |
| G-05 | verify.sh evidence 11 FAIL | **CRITICAL** | Certyfikacja |
| G-06 | 6 dead skryptów | MEDIUM | Martwy kod |
| G-07 | Stale komentarze "P-001..P-051" | LOW | Kosmetyka |
| G-08 | Statusy WIRED/EXECUTED/ENFORCED/CERTIFIED nieużywane | LOW | Lifecycle |
| G-09 | Martwa subkomenda `verify.sh pipelines` | MEDIUM | Entry pointy |
| G-10 | Taksonomie klasa↔profil niezmapowane | MEDIUM | Architektura |

## 2. Szczegóły luk

### G-01 — Pipeline↔gate disconnect (CRITICAL)

Pipeline'y (P-XXX) i gate'y (GATE-XXX) to **dwa osobne światy** bez jawnego połączenia wykonawczego. Szczegóły w PROD-READY-CONNECTION-MATRIX.md i PROD-READY-EXECUTOR-MODEL.md.

**Skutek:** Nie ma mechanizmu "pipeline P-XXX przechodzi przez gate GATE-YYY". Hooki/CI uruchamiają tylko gate'y; pipeline'y uruchamiane tylko ręcznie. Brak wspólnego orchestratora.

**Remediacja:** Zbudować jawny most: mapowanie klasa↔profil + deklaratywne powiązanie P-XXX→GATE-YYY w źródłach prawdy + wspólny orchestrator (np. `verify.sh all`) + podpięcie do hooków/CI.

### G-02 — Placeholdery system/ + top-level (HIGH)

14 podkatalogów `system/` README-only + 14 katalogów top-level FOUNDATION PLACEHOLDER. Szczegóły w PROD-READY-CERTIFICATION-REPORT.md.

**Remediacja:** Decyzja per komponent: zaimplementować / oznaczyć PROPOSED / przenieść do prod-skel jako szkielety. Nie zostawiać niejawnych placeholderów.

### G-03 — Kontrakty genesis (HIGH)

`contracts/contract.md` ma placeholdery ze STATUS: UNDEFINED. Kontrakty nie są zdefiniowane.

**Remediacja:** Zdefiniować realne kontrakty (README/API) dla każdego komponentu.

### G-04 — 12 PROPOSED gate'ów (MEDIUM)

GATE-026..037 (BEHAVIORAL-DRIFT, PREDICTIVE-RESOURCE, PREDICTIVE-COST, CONTEXT-HEALTH, MEMORY-INTEGRITY, DEPENDENCY-GRAPH, PRE-MORTEM, COUNTERFACTUAL, CHANGE-RISK, COMPLEXITY-GOVERNOR, AGENT-TRUST, AUTONOMY-LEVEL) są PROPOSED — zarejestrowane, nie zaimplementowane. To świadomy stan lifecycle, ale blokuje pełną certyfikację RELEASE.

**Remediacja:** Zaimplementować lub jawnie odroczyć (z dokumentacją).

### G-05 — verify.sh evidence 11 FAIL (CRITICAL)

Z poprzedniej sesji: `verify.sh` raportuje 11 FAIL w evidence. To blokuje certyfikację Prod-ready.

**Remediacja:** Zdiagnozować i naprawić 11 FAIL evidence przed certyfikacją.

### G-06 — 6 dead skryptów (MEDIUM)

`monitor.sh`, `display-pipeline.sh`, `display-html.sh`, `repository-integrity.sh`, `verify/config/config.sh`, `verify/core/config.sh` — zero referencji.

**Remediacja:** Usunąć / podpiąć / oznaczyć DEPRECATED.

### G-07 — Stale komentarze "P-001..P-051" (LOW)

W `automation.sh:15`, `pipelines.sh:4`, `gen-pipelines.sh:126`, `tests/README.md:6`, `tests/test_pipelines.sh:7` — katalog faktycznie zawiera P-001..P-098.

**Remediacja:** Zaktualizować komentarze do P-001..P-098.

### G-08 — Statusy lifecycle nieużywane (LOW)

WIRED/EXECUTED/ENFORCED/CERTIFIED zdefiniowane, ale wszystkie gate'y mają status IMPLEMENTED.

**Remediacja:** Wprowadzić przejścia statusów lub uprościć model.

### G-09 — Martwa subkomenda `verify.sh pipelines` (MEDIUM)

Subkomenda deleguje do automation.sh, ale nikt jej nie wywołuje.

**Remediacja:** Podpiąć do hooków/CI lub usunąć.

### G-10 — Taksonomie klasa↔profil niezmapowane (MEDIUM)

Pipeline'y używają klas (FAST/STANDARD/DEEP/RELEASE/CONTINUOUS); gate'y używają profili (LOCAL_FAST/PRE_PUSH/CI/RELEASE). Brak konwersji.

**Remediacja:** Zdefiniować mapowanie klasa↔profil.

## 3. Priorytety remediacji (kolejność)

1. **G-05** (evidence 11 FAIL) — blokuje certyfikację.
2. **G-01** (pipeline↔gate disconnect) — fundament architektury.
3. **G-02, G-03** (placeholdery, kontrakty) — struktura.
4. **G-04, G-06, G-09, G-10** (PROPOSED gate'y, dead skrypty, martwa subkomenda, taksonomie).
5. **G-07, G-08** (kosmetyka, lifecycle).

## 4. Kryteria certyfikacji Prod-ready (do Etapu 3)

- [ ] G-05: verify.sh evidence 0 FAIL.
- [ ] G-01: jawny most pipeline↔gate + wspólny orchestrator.
- [ ] G-02: brak niejawnych placeholderów (zdecydowane per komponent).
- [ ] G-03: kontrakty zdefiniowane (STATUS != UNDEFINED).
- [ ] G-04: PROPOSED gate'y zaimplementowane lub jawnie odroczone.
- [ ] G-06: brak dead skryptów.
- [ ] G-07: komentarze P-001..P-098.
- [ ] G-08: model statusów spójny.
- [ ] G-09: `verify.sh pipelines` podpięty lub usunięty.
- [ ] G-10: mapowanie klasa↔profil zdefiniowane.

Po spełnieniu kryteriów → Etap 3 (CERTIFICATION) → Etap 4 (CREATE prod-skel).
