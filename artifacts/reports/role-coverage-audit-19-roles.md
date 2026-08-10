# AUDYT POKRYCIA RÓL — 19 ról (14 rdzeniowych + 5 warunkowych)

**Data:** 2026-08-10
**Metoda:** 19 równoległych agentów audytowych (Explore), każdy sprawdzał czy quality gates + pipeline pokrywają 100% domeny jego roli. Źródła prawdy: `config/canonical/taxonomy.yaml`, `config/canonical/gates.yaml`, `tools/verify/`, `system/control-plane/state/`, `docs/00-foundation/SONDA.md`, `docs/00-foundation/human-plane-*.md`.
**Wynik:** lista gapów per domena. **Żadna rola nie ma 100% pokrycia.** Średnie pokrycie ~5-15%.

---

## ZASADA PRZEWODNIA (z masterpromptu ról)

> W tym systemie **rola = własność domeny ryzyka**, nie stanowisko. Rola ludzka istnieje tam, gdzie jest oracle (MAN/UX), taste (AEST), judgment (product/architektura), odpowiedzialność prawna (security/compliance). Quality gate = automatyczny strażnik domeny; pipeline = sekwencja gate'ów. **Pokrycie 100%** = każdy check w domenie roli ma gate, który go egzekwuje i raportuje.

---

## GŁÓWNE ODKRYCIE SYSTEMOWE (potwierdzone przez WSZYSTKIE 19 agentów)

Wymiary **VV, MAN, EXP, DATA, EDGE, BIZ, FIN, SUP, COMP, LEG, AI** są w `taxonomy.yaml` z `applicability: always` (wchodzą do QI), ale **NIE mają żadnych gate'ów**. Przez regułę `zero_rule` (brak evidence = 0) i średnią geometryczną **zerują cały QI każdego serwisu strukturalnie**. System formalnie "wie", że są niepokryte (QI=0), ale **nie ma gate'a, który by to egzekwował/raportował** — `taxonomy.sh` (TAX-001..014) waliduje TYLKO strukturę pliku, NIE pokrycie check→gate. To fatalna luka meta-gate.

---

## CZĘŚĆ A — 14 RÓL RDZENIOWYCH

### 1. Product Engineer — pokrycie ~9% (1 z 11)
- **GAP-PE-01** DX-01 one-command setup — brak modułu `dx` w gates.yaml, brak Makefile/setup.sh/devcontainer.
- **GAP-PE-02** DX-02 local==CI — brak gate'a parytetu local/CI.
- **GAP-PE-03** DX-03 time-to-first-green — brak pomiaru i budżetu.
- **GAP-PE-04** DX-04 actionable errors — brak gate'a (tylko komentarz w spectral-rules.yaml).
- **GAP-PE-05** DX-05 scaffold day-0 green — `scaffold.sh` istnieje + 9 testów, ale NIE podpięty do pipeline/CI (ghost narzędzie).
- **GAP-PE-06** Dogfooding — brak gate'a.
- **GAP-PE-07** Self-service infra — brak gate'a.
- **GAP-PE-08** CONS-02 jeden ruleset lint/format — brak gate'a.
- **GAP-PE-09** AEST-10 PR hygiene — brak gate'a.
- **GAP-PE-10** AEST-06 executable examples — brak gate'a.
- **GAP-PE-11** META-04 VERIFY-SYSTEM — ABSENT (tylko design doc).
- **Pokryty:** CONS-01 (aesthetics/fitness.sh), META-01 częściowo (SELF-001).
- **Ghost moduły:** contracts, migration, recovery.

### 2. Principal/Staff — pokrycie ~10%
- **GAP-PS-01** INTEG (spójność szkieletu, INTEG-01..04) — brak gate'a; architecture.sh sprawdza tylko dokumenty.
- **GAP-PS-02** TDR/ADR — istnieje `governance/decisions/ADR-0001`, `docs/decisions/`, tabela `decision` (schema.sql linia 403), ale **brak gate'a** wymagającego ADR dla nieodwracalnych decyzji; OPT-01 bez gate'a.
- **GAP-PS-03** Fitness functions — `aesthetics/fitness.sh` to tylko golden path layout; brak fitness functions anty-dryf (dependency rules, module boundaries).
- **GAP-PS-04** Standardy cross-serwisowe — brak gate'a (CONS-01..08 poza CONS-01).
- **GAP-PS-05** "Zabijanie projektów" (anti-project, scope control, sunset) — brak gate'a.
- **GAP-PS-06** Proporcjonalność dokumentacji — brak gate'a.
- **GAP-PS-07** Taste — brak gate'a.
- **GAP-PS-08** OPT, META — wymiary w taxonomy, brak gate'ów.
- **GAP-PS-09** Ghost moduły contracts/migration/recovery.
- **Brak tabel:** `tdr`, `fitness_function` w schema.sql.

### 3. Platform Engineer — pokrycie ~15%
- **GAP-PL-01** Brak gate'a dla infrastruktury jako kodu (IaC) — brak modułu infra/platform w gates.yaml.
- **GAP-PL-02** Brak gate'a dla środowisk (dev/staging/prod) — brak parytetu środowisk.
- **GAP-PL-03** Brak gate'a dla provisioning/teardown — brak idempotencji.
- **GAP-PL-04** Brak gate'a dla secrets management w runtime (Vault) — security/secrets.sh pokrywa tylko repo.
- **GAP-PL-05** Brak gate'a dla capacity/rightsizing (pokrywa się z FIN-03).
- **GAP-PL-06** Brak gate'a dla upgrade/patchnig cyklu.
- **Ghost moduły:** contracts, migration, recovery.

### 4. SRE — pokrycie ~15%
- **GAP-SRE-01** Brak gate'a SLO/SLI (OBS-14) — slo.yaml nie istnieje w main.
- **GAP-SRE-02** Brak gate'a alertów (OBS-05/11/12) — alerts/_template.yaml nie istnieje w main.
- **GAP-SRE-03** Brak gate'a health endpoints (OBS-10) — obs-health-endpoints.sh nie istnieje.
- **GAP-SRE-04** Brak gate'a deadman switch (OBS-10) — obs-deadman-check.sh nie istnieje.
- **GAP-SRE-05** Brak gate'a dashboards/synthetics.
- **GAP-SRE-06** Brak gate'a runbook-per-alert (OPS-01/OPS-10).
- **GAP-SRE-07** Brak gate'a blameless postmortem (OPS-08 ABSENT per SONDA).
- **Ghost moduły:** contracts, migration, recovery.

### 5. Security Engineer — pokrycie ~25% (najwyższe z rdzeniowych)
- **GAP-SEC-01** Brak gate'a SEC plane (macierz 12×4) — brak modułu security-plane.
- **GAP-SEC-02** Brak PERM (permissions) gate — SoD jako koncepcja (PERM-04, MAN-07), checki ABSENT.
- **GAP-SEC-03** Brak threat modeling gate.
- **GAP-SEC-04** Brak triage KEV/EPSS/reachability — system CVSS-centric.
- **GAP-SEC-05** Brak break-glass gate.
- **GAP-SEC-06** Brak polityk admission.
- **GAP-SEC-07** Brak reakcji na incydenty sec.
- **GAP-SEC-08** `.gitleaks.toml` nie istnieje w main (tylko worktree-sec-baseline).
- **GAP-SEC-09** Orphany: security/history.sh (SEC-101/102), security/credentials.sh (SEC-201..208), sec-secrets-scan.sh (tylko worktree).
- **GAP-SEC-10** waivers/sweeper.sh uruchamiany ale nie w gates.yaml.
- **GAP-SEC-11** Fire drills dokumentacyjny nie behavioralny (F-017).
- **GAP-SEC-12** Brak gate'a dla credential rotation/retention.

### 6. QA Architect/SDET — pokrycie ~10%
- **GAP-QA-01** Brak gate'a pokrycia testów (coverage) — brak modułu coverage.
- **GAP-QA-02** Brak gate'a mutation testing.
- **GAP-QA-03** Brak gate'a testów E2E.
- **GAP-QA-04** Brak gate'a testów regresji.
- **GAP-QA-05** Brak gate'a flaky test detection.
- **GAP-QA-06** Brak gate'a test data management.
- **GAP-QA-07** Brak gate'a quality gates per środowisko.
- **GAP-QA-08** Brak gate'a testów wydajnościowych (PERF).
- **GAP-QA-09** Brak gate'a accessibility (UX-R-04).
- **GAP-QA-10** Brak gate'a testów kontraktowych (contracts ghost).

### 7. Exploratory Tester — pokrycie ~5%
- **GAP-ET-01** Brak gate'a dla exploratory testing sessions.
- **GAP-ET-02** Brak gate'a dla bug triage → CORR.
- **GAP-ET-03** Brak gate'a dla test charters.
- **GAP-ET-04** Brak gate'a dla regression risk assessment.
- **GAP-ET-05** Brak gate'a dla edge case coverage (EDGE).
- **GAP-ET-06** Brak gate'a dla session-based testing metrics.

### 8. UX Researcher — pokrycie ~5%
- **GAP-UXR-01** Brak gate'a dla badań UX (UX-R-01..08) — wymiar UX w taxonomy, brak modułu.
- **GAP-UXR-02** Brak gate'a dla usability testing.
- **GAP-UXR-03** Brak gate'a dla accessibility research (UX-R-04).
- **GAP-UXR-04** Brak gate'a dla person/empathy maps.
- **GAP-UXR-05** Brak gate'a dla friction baselines (migracja 0010 ghost).
- **GAP-UXR-06** Brak gate'a dla UX-R sygnału do backlogu.

### 9. Product Designer — pokrycie ~5%
- **GAP-PD-01** Brak gate'a dla design system (AEST).
- **GAP-PD-02** Brak gate'a dla accessibility (UX-R-04).
- **GAP-PD-03** Brak gate'a dla design tokens.
- **GAP-PD-04** Brak gate'a dla visual regression.
- **GAP-PD-05** Brak gate'a dla UX-R-01/02 (UX-A-01/02 w taxonomy).
- **GAP-PD-06** Brak gate'a dla taste (AEST).

### 10. Product Manager — pokrycie ~0%
- **GAP-PM-01** BIZ-01..08 wszystkie ABSENT per SONDA.md (linie 564-571).
- **GAP-PM-02** EXP-01..04 wszystkie ABSENT per SONDA.md (linie 627-630).
- **GAP-PM-03** Brak modułów biz/exp w gates.yaml.
- **GAP-PM-04** taxonomy.sh waliduje tylko strukturę, nie pokrycie check→gate.
- **GAP-PM-05** UAT sign-off (MAN-03) w wymiarze MAN nie BIZ/EXP; tabela `uat_signoffs` istnieje (migracja 0010) ale 0 wierszy.
- **GAP-PM-06** Brak golden datasets, priorytetyzacji, sunset, success metrics, feature flags (BIZ-04 tylko deklaracja).

### 11. Data Engineer — pokrycie ~5%
- **GAP-DE-01** DATA-01..08 — brak gate'ów (data_classes present w taxonomy, ale brak mechanizmu deklaracji).
- **GAP-DE-02** Brak gate'a dla jakości danych.
- **GAP-DE-03** Brak gate'a dla schematów danych.
- **GAP-DE-04** Brak gate'a dla data lineage.
- **GAP-DE-05** Brak gate'a dla PII/data classification (pokrywa się z DATA-01).
- **GAP-DE-06** Brak tabel danych w StateStore.

### 12. Engineering Manager — pokrycie ~5%
- **GAP-EM-01** Wymiar MAN (15) w taxonomy, ale brak modułu/gate'a w gates.yaml.
- **GAP-EM-02** Brak gate'ów wymiarów organizacyjnych (FIN, BIZ, EXP, SUP, COMP, LEG).
- **GAP-EM-03** Brak checków dla bus factor, staffing, kadencji, blameless, DORA, zdrowia zespołu, awansów, budżetu zespołu.
- **GAP-EM-04** SoD jako koncepcja (PERM-04, MAN-07) ale checki ABSENT.
- **GAP-EM-05** Ownership częściowo pokryty (OWNERSHIP.md, ARCH-003/006/007, DEBT-105, DRIFT-006).

### 13. Tech Lead — pokrycie ~11%
- **GAP-TL-01** Brak SoD gate (approver≠autor).
- **GAP-TL-02** Brak jakości PR (AEST-10 bez skryptu).
- **GAP-TL-03** Brak mentoringu.
- **GAP-TL-04** Brak standardów dnia codziennego.
- **GAP-TL-05** Brak triage technicznego.
- **GAP-TL-06** Brak eskalacji ryzyka tech.
- **GAP-TL-07** CONS-02..08 bez checków.
- **GAP-TL-08** VV-01..04 bez gate'a.
- **GAP-TL-09** Brak mostu Principal↔zespół.
- **Ghost:** F-001..F-007 (architecture, dependencies, reproducibility, deployment, contracts, migration, recovery), shadow config.sh (CFG-001..008), orphany (git/history.sh, git/branches.sh, git/tags.sh, security/history.sh, security/credentials.sh, tools/repository-integrity.sh).

### 14. Technical Writer — pokrycie ~14%
- **GAP-TW-01** Brak CONS-06 (ADR/runbook format).
- **GAP-TW-02** Brak AEST-06 (executable examples/doctest).
- **GAP-TW-03** Brak freshness docs.
- **GAP-TW-04** Brak szablonów docs (config/templates/template.md = placeholder).
- **GAP-TW-05** Brak języka domenowego docs↔kod.
- **GAP-TW-06** Brak runbook-per-alert (OPS-01/OPS-10).
- **GAP-TW-07** Brak docs-as-code.
- **5 ghost checków:** AEST-06, AEST-02, CONS-06, OPS-01, OPS-10.

---

## CZĘŚĆ B — 5 RÓL WARUNKOWYCH

### 15. ML/AI Quality — pokrycie 0%
- **GAP-ML-01** Brak eval suites.
- **GAP-ML-02** Brak drift monitoring (tabela drift bez typu MODEL).
- **GAP-ML-03** Brak fairness slices.
- **GAP-ML-04** Brak prompt injection tests.
- **GAP-ML-05** Brak fallbacków modeli.
- **GAP-ML-06** Brak budżetów koszt/latencji.
- **GAP-ML-07** Brak kluczy ml.* w registry.yaml.
- **GAP-ML-08** Brak tabel ML w StateStore.
- **GAP-ML-09** Brak testów ML.
- **GAP-ML-10** Brak .skeleton.yaml z ml_features.
- **Wymiar AI (AI-01..08) = ghost.**

### 16. Compliance/Privacy — pokrycie 0%
- **GAP-CP-01** Brak mapowania feature→regulacja.
- **GAP-CP-02** Brak DPIA (LEG-08 ABSENT).
- **GAP-CP-03** Brak RoPA (LEG-01 ABSENT).
- **GAP-CP-04** Brak wersji zgód (LEG-03 ABSENT).
- **GAP-CP-05** Brak retencji prawnych.
- **GAP-CP-06** Brak inwentarza PII (DATA-01).
- **GAP-CP-07** Brak erasure/portability (LEG-05/06 ABSENT).
- **GAP-CP-08** LEG/COMP/DATA (28 checków) bez gate'ów.
- **GAP-CP-09** Brak tabel compliance w StateStore.
- **GAP-CP-10** Brak mechanizmu deklaracji data_classes (rola warunkowa nigdy nie aktywowana).

### 17. FinOps Analyst — pokrycie 0%
- **GAP-FO-01** Brak kosztu per serwis (FIN-01).
- **GAP-FO-02** Brak anomalii (FIN-02).
- **GAP-FO-03** Brak waste hunts (FIN-04).
- **GAP-FO-04** Brak forecast vs actual (FIN-05).
- **GAP-FO-05** Brak cost preview w PR.
- **GAP-FO-06** Brak rightsizing (FIN-03).
- **GAP-FO-07** Wymiar FIN bez gate'ów.
- **GAP-FO-08** Moduł efficiency bez kluczy registry.yaml.
- **GAP-FO-09** Brak tabel kosztowych w StateStore.
- **GAP-FO-10** GATE-028 PREDICTIVE-COST ghost+orphan (tylko worktree gateforge, brak skryptu domains/predictive-cost.sh).

### 18. DevRel/DX Advocate — pokrycie ~0%
- **GAP-DR-01** Domena DevRel NIE istnieje w taxonomy (DX/EDGE oznaczają DX wewnętrzny i frontend).
- **GAP-DR-02** Brak jakości SDK.
- **GAP-DR-03** Brak przykładów/quickstartów (AEST-06 niezaimplementowany).
- **GAP-DR-04** Brak dokumentacji zewnętrznej API (API-03).
- **GAP-DR-05** Brak kanału feedbacku społeczności.
- **GAP-DR-06** Brak time-to-first-call.
- **GAP-DR-07** Brak feedback→backlog.
- **GAP-DR-08** Brak mechanizmu mapowania check→gate.

### 19. Support/Success — pokrycie 0%
- **GAP-SS-01** Brak escape analysis.
- **GAP-SS-02** Brak reprodukcji bugów.
- **GAP-SS-03** Brak triage→CORR (CORR-01..04 tylko definicje).
- **GAP-SS-04** Brak knowledge base (shared/knowledge/ puste).
- **GAP-SS-05** Brak sygnału do UX-R.
- **GAP-SS-06** Brak domykania pętli incydent→klient.
- **GAP-SS-07** Brak kluczy SUP/CORR/EXP w registry.yaml.
- **GAP-SS-08** Brak testów.
- **GAP-SS-09** Ghost migracji 0010 (ux_studies, friction_baselines).

---

## CZĘŚĆ C — GAPY WSPÓLNE (potwierdzone przez wielu agentów)

1. **Wymiary "ludzkie"/"organizacyjne"/"dane" (VV, MAN, EXP, DATA, EDGE, BIZ, FIN, SUP, COMP, LEG, AI) z `applicability: always` bez gate'ów → zerują cały QI** (zero_rule + średnia geometryczna). **Najpoważniejszy, systemowy gap.**
2. **Ghost moduły:** contracts, migration, recovery — zadeklarowane w gates.yaml, skrypty nie istnieją w tools/verify/.
3. **Luka w numeracji migracji StateStore:** 0001-0008, brak 0004 i 0005.
4. **canonical-state.db nie istnieje w main** — StateStore nie zainicjalizowany.
5. **Brak modułu human/data/vv w gates.yaml.**
6. **taxonomy.sh nie weryfikuje check→gate** — fatalna luka meta-gate pozwalająca na setki niezaimplementowanych checków.
7. **SELF-001 nie wykrywa wymiarów bez deklaracji** — tylko ghost moduły (skrypt zadeklarowany bez pliku), nie wymiary bez gate'a.
8. **Rozjazd worktree gateforge vs main:** migracja 0010, sekcja `human:` w registry — istnieją w worktree, nie w main.
9. **Orphany:** obs-*/sec-* w worktree'ach; debt/drift/history/reconcile/waivers/config w main — pliki istnieją, ale nie zadeklarowane w pipeline.
10. **Brak CI dla narzędzi deweloperskich** — .github/workflows/* nie uruchamiają scaffold.sh, gen-profiles.sh, ani testów.

---

## CZĘŚĆ D — REKOMENDACJE PRIORYTETOWE (P0)

1. **P0 — Naprawić meta-gate:** rozszerzyć `taxonomy.sh` o weryfikację check→gate (każdy check z `applicability: always` musi mieć gate). To jedyny sposób, by system sam wykrywał niepokryte wymiary zamiast cicho zerować QI.
2. **P0 — Rozwiązać ghost moduły:** contracts, migration, recovery — albo zaimplementować skrypty, albo usunąć z gates.yaml.
3. **P0 — Zainicjalizować StateStore w main** (canonical-state.db) i uzupełnić migracje 0004/0005.
4. **P0 — Zdecydować o wymiarach bez gate'ów:** dla każdego z 11 wymiarów (VV, MAN, EXP, DATA, EDGE, BIZ, FIN, SUP, COMP, LEG, AI) — albo dodać gate, albo wyłączyć z QI (zmienić applicability), albo oznaczyć jako "human-gated" (oracle).
5. **P1 — Podpiąć scaffold.sh do pipeline** (ghost narzędzie, w pełni zaimplementowane).
6. **P1 — Zbudować SEC plane** (macierz 12×4) i PERM gate (SoD).
7. **P1 — Zbudować OBS baseline** (SLO, alerts, health, deadman, runbook-per-alert).
8. **P1 — Zbudować contracts.sh** (F-005) — odblokowuje ghost contracts.
9. **P2 — Zbudować coverage/mutation/E2E gates** (QA).
10. **P2 — Zbudować biz/exp/data/compliance/fin gates** (role warunkowe + PM/Data/Compliance/FinOps).

---

## METRYKI POKRYCIA (per rola)

| Rola | Pokrycie | Status |
|---|---|---|
| Security Engineer | ~25% | Najwyższe |
| Platform Engineer | ~15% | |
| SRE | ~15% | |
| Technical Writer | ~14% | |
| Tech Lead | ~11% | |
| Principal/Staff | ~10% | |
| QA Architect/SDET | ~10% | |
| Product Engineer | ~9% | |
| Exploratory Tester | ~5% | |
| UX Researcher | ~5% | |
| Product Designer | ~5% | |
| Data Engineer | ~5% | |
| Engineering Manager | ~5% | |
| Product Manager | ~0% | |
| ML/AI Quality | 0% | |
| Compliance/Privacy | 0% | |
| FinOps Analyst | 0% | |
| DevRel/DX Advocate | ~0% | |
| Support/Success | 0% | |
