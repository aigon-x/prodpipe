# CLEAN PLANE — automatyczne czyszczenie legacy

> **Wizja przyszłego etapu** (po MONITOR PLANE i OBSERVABILITY FACTORY).
> Data: 2026-08-10. Status: VISION (do wdrożenia w późniejszym etapie).

## Zasada

**Legacy to nie kod, który jest stary — to kod, który nie ma właściciela, nie jest używany, i nikt nie wie, dlaczego istnieje.** System, który nie czyści legacy automatycznie, dławi się własnym długiem. Każdy martwy plik, każdy deprecated endpoint, każdy nieużywany feature — to dług, który rośnie.

## Mapowanie na system

| Mechanizm | Implementacja |
|---|---|
| **Anti-entropy** | Wykrywanie martwego kodu, nieużywanych zależności, deprecated features |
| **Currency** | Aktualność dokumentacji, zależności, tooli |
| **Drift detection** | Drift między kodem a dokumentacją |
| **Deprecation** | Proces wycofywania z evidence |
| **Cleanup** | Automatyczne usuwanie z evidence |

## Mapa etapów Clean Pipeline

```
0. DETECT       → wykryj legacy (martwy kod, nieużywane zależności, deprecated features)
1. CLASSIFY     → sklasyfikuj (do usunięcia, do aktualizacji, do deprecacji)
2. PLAN         → zaplanuj (kiedy, jak, kto)
3. DEPRECATE    → deprecate (oznacz jako deprecated z datą)
4. MIGRATE      → migracja (przenieś użytkowników do nowej wersji)
5. REMOVE       → usuń (fizycznie usuń z kodu)
6. VERIFY       → zweryfikuj (czy nic nie złamaliśmy?)
7. DOCUMENT     → udokumentuj (changelog, migration guide)
8. ARCHIVE      → zarchiwizuj (evidence, retention)
```

Każdy etap ma gate'y blokujące, evidence, expires, ownera.

## Etap 0: DETECT — wykryj legacy

| Gate | Mechanizm | Negative test |
|---|---|---|
| CLEAN-D-01 | **Dead code detection**: vulture (Python), deadcode (Go), knip (JS/TS) | Martwy kod wykryty = FAIL (lub auto-PR) |
| CLEAN-D-02 | **Unused dependencies**: depcheck (JS/TS), pip-autoremove (Python), cargo-udeps (Rust) | Nieużywana zależność = FAIL (lub auto-PR) |
| CLEAN-D-03 | **Deprecated features**: feature flags bez użycia, API endpoints bez traffic | Deprecated feature bez deprecation = FAIL |
| CLEAN-D-04 | **Stale TODOs**: TODO/FIXME starsze niż N dni bez ownera | TODO bez ownera/expires = FAIL |
| CLEAN-D-05 | **Commented-out code**: zakomentowany kod (nie komentarze dokumentacyjne) | Zakomentowany kod = FAIL |
| CLEAN-D-06 | **Duplicate code**: jscpd, PMD CPD | Duplikacja > threshold = FAIL |
| CLEAN-D-07 | **Unused files**: pliki bez importów, bez referencji | Nieużywany plik = FAIL |
| CLEAN-D-08 | **Stale documentation**: dokumentacja starsza niż kod, którego dotyczy | Docs starsze niż kod = FAIL |
| CLEAN-D-09 | **Unused environment variables**: env vars w `.env.example` bez konsumentów w kodzie | Env var bez konsumenta = FAIL |
| CLEAN-D-10 | **Unused config keys**: config keys w registry bez konsumentów | Config key bez konsumenta = FAIL |

## Etap 1: CLASSIFY — sklasyfikuj

| Gate | Mechanizm |
|---|---|
| CLEAN-C-01 | **Classification**: każdy legacy item sklasyfikowany (remove, update, deprecate, keep) |
| CLEAN-C-02 | **Impact analysis**: analiza wpływu (ile miejsc używa, ile użytkowników) |
| CLEAN-C-03 | **Risk assessment**: ocena ryzyka (low, medium, high) |
| CLEAN-C-04 | **Owner assignment**: przypisanie ownera (kto odpowiada za cleanup) |
| CLEAN-C-05 | **Priority assignment**: przypisanie priorytetu (P0, P1, P2, P3) |
| CLEAN-C-06 | **Classification evidence**: klasyfikacja w StateStore |

## Etap 2: PLAN — zaplanuj

| Gate | Mechanizm |
|---|---|
| CLEAN-P-01 | **Cleanup plan**: plan dla każdego legacy item (kiedy, jak, kto) |
| CLEAN-P-02 | **Migration path**: ścieżka migracji (jeśli deprecate) |
| CLEAN-P-03 | **Rollback plan**: plan rollbacku (jeśli coś pójdzie nie tak) |
| CLEAN-P-04 | **Timeline**: timeline (kiedy zaczynamy, kiedy kończymy) |
| CLEAN-P-05 | **Dependencies**: zależności (co musi być zrobione najpierw) |
| CLEAN-P-06 | **Plan evidence**: plan w StateStore |

## Etap 3: DEPRECATE — deprecate

| Gate | Mechanizm |
|---|---|
| CLEAN-DE-01 | **Deprecation notice**: oznacz jako deprecated z datą (Sunset header, `@deprecated` annotation) |
| CLEAN-DE-02 | **Deprecation warning**: warning dla użytkowników (log, email, Slack) |
| CLEAN-DE-03 | **Deprecation documentation**: dokumentacja (dlaczego deprecated, co zamiast) |
| CLEAN-DE-04 | **Deprecation timeline**: timeline (kiedy deprecated, kiedy removed) |
| CLEAN-DE-05 | **Deprecation tracking**: tracking użycia (ile miejsc jeszcze używa) |
| CLEAN-DE-06 | **Deprecation evidence**: deprecacja w StateStore |

## Etap 4: MIGRATE — migracja

| Gate | Mechanizm |
|---|---|
| CLEAN-M-01 | **Migration guide**: przewodnik migracji (jak przejść do nowej wersji) |
| CLEAN-M-02 | **Migration tooling**: narzędzia migracji (codemod, script) |
| CLEAN-M-03 | **Migration tracking**: tracking migracji (ile miejsc zmigrowanych) |
| CLEAN-M-04 | **Migration support**: wsparcie migracji (office hours, Slack channel) |
| CLEAN-M-05 | **Migration validation**: walidacja migracji (czy migracja działa?) |
| CLEAN-M-06 | **Migration evidence**: migracja w StateStore |

## Etap 5: REMOVE — usuń

| Gate | Mechanizm |
|---|---|
| CLEAN-R-01 | **Removal**: fizyczne usunięcie z kodu |
| CLEAN-R-02 | **Removal validation**: walidacja przed usunięciem (czy nic nie używa?) |
| CLEAN-R-03 | **Removal testing**: testy przed usunięciem (czy nic nie złamiemy?) |
| CLEAN-R-04 | **Removal rollback**: rollback plan (jeśli coś pójdzie nie tak) |
| CLEAN-R-05 | **Removal approval**: approval przed usunięciem (dla high-risk items) |
| CLEAN-R-06 | **Removal evidence**: usunięcie w StateStore |

## Etap 6: VERIFY — zweryfikuj

| Gate | Mechanizm |
|---|---|
| CLEAN-V-01 | **Verification**: weryfikacja po usunięciu (czy wszystko działa?) |
| CLEAN-V-02 | **Regression testing**: testy regresji (czy nic nie złamaliśmy?) |
| CLEAN-V-03 | **Smoke testing**: smoke testy (czy krytyczne ścieżki działają?) |
| CLEAN-V-04 | **Performance testing**: testy wydajności (czy performance się nie pogorszył?) |
| CLEAN-V-05 | **Security testing**: testy bezpieczeństwa (czy security się nie pogorszyło?) |
| CLEAN-V-06 | **Verification evidence**: weryfikacja w StateStore |

## Etap 7: DOCUMENT — udokumentuj

| Gate | Mechanizm |
|---|---|
| CLEAN-DO-01 | **Changelog**: changelog (co usunięte, dlaczego, kiedy) |
| CLEAN-DO-02 | **Migration guide**: przewodnik migracji (dla użytkowników) |
| CLEAN-DO-03 | **Breaking changes**: dokumentacja breaking changes |
| CLEAN-DO-04 | **Deprecation notice**: dokumentacja deprecacji |
| CLEAN-DO-05 | **Lessons learned**: lessons learned (co się nauczyliśmy?) |
| CLEAN-DO-06 | **Documentation evidence**: dokumentacja w StateStore |

## Etap 8: ARCHIVE — zarchiwizuj

| Gate | Mechanizm |
|---|---|
| CLEAN-A-01 | **Archive**: archiwizacja usuniętego kodu (dla audytu) |
| CLEAN-A-02 | **Archive retention**: retencja archiwum (90 dni, 1 rok, 7 lat) |
| CLEAN-A-03 | **Archive storage**: storage archiwum (S3, Glacier, local) |
| CLEAN-A-04 | **Archive retrieval**: możliwość odzyskania (jeśli potrzebne) |
| CLEAN-A-05 | **Archive cleanup**: automatyczne czyszczenie (po retencji) |
| CLEAN-A-06 | **Archive evidence**: archiwizacja w StateStore |

## Automatyczne czyszczenie — auto-PR

| Mechanizm | Implementacja |
|---|---|
| **Auto-PR dla dead code** | Bot tworzy PR z usunięciem martwego kodu |
| **Auto-PR dla unused dependencies** | Bot tworzy PR z usunięciem nieużywanych zależności |
| **Auto-PR dla stale TODOs** | Bot tworzy PR z usunięciem/aktualizacją TODO |
| **Auto-PR dla commented-out code** | Bot tworzy PR z usunięciem zakomentowanego kodu |
| **Auto-PR dla duplicate code** | Bot tworzy PR z refaktoringiem duplikacji |
| **Auto-merge** | Auto-merge po przejściu wszystkich gate'ów |

## Harmonogram czyszczenia

| Kategoria | Częstotliwość |
|---|---|
| Dead code | Co tydzień (auto-PR) |
| Unused dependencies | Co miesiąc (auto-PR) |
| Stale TODOs | Co miesiąc (auto-PR) |
| Commented-out code | Co tydzień (auto-PR) |
| Duplicate code | Co miesiąc (manual review) |
| Deprecated features | Co kwartał (manual review) |
| Stale documentation | Co miesiąc (auto-PR) |
| Unused files | Co miesiąc (auto-PR) |

## Clean jako część systemu — integracje

| Integracja | Mechanizm |
|---|---|
| **Legacy = debt** | Legacy w debt registry z ownerem, expires |
| **Cleanup = gate** | Cleanup jako gate (dead code = FAIL) |
| **Auto-PR = automation** | Auto-PR dla cleanup (bot) |
| **Evidence = evidence** | Cleanup evidence w StateStore |
| **Deprecation = deprecation** | Deprecation pipeline (już mamy) |
| **Archive = retention** | Archive z retencją (jak evidence) |

## Metryka Clean health

$$CLEAN_{health} = dead\_code\_rate \times unused\_deps\_rate \times stale\_docs\_rate \times cleanup\_rate$$

Wszystkie czynniki z evidence, per serwis, do scorecarda.

## Kolejność wdrożenia

| Priorytet | Zakres |
|---|---|
| **P0** | Etap 0 (DETECT) — dead code, unused dependencies, stale TODOs |
| **P0** | Auto-PR dla dead code, unused dependencies |
| **P1** | Etap 3 (DEPRECATE) — deprecation pipeline |
| **P1** | Etap 5 (REMOVE) — removal z validation |
| **P2** | Etap 4 (MIGRATE) — migration guide, tooling |
| **P2** | Etap 6 (VERIFY) — regression, smoke, performance testing |
| **P3** | Etap 7 (DOCUMENT) — changelog, migration guide |
| **P3** | Etap 8 (ARCHIVE) — archiwizacja z retencją |

**TL;DR**: Clean plane to **automatyczna higiena systemu**: wykryj legacy, sklasyfikuj, zaplanuj, deprecate, migrate, remove, verify, document, archive. System, który nie czyści legacy automatycznie, dławi się własnym długiem. I wszystko z evidence, bo "system jest czysty" bez dowodu to "system jest czysty w teorii".
