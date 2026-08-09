# aigon-x-fs

> AIGON-X-FS — warstwa przechowywania danych runtime'owych platformy AIGON Production Platform. Przechowuje DANE RUNTIME / WIEDZĘ / PAMIĘĆ / ARTEFAKTY / ZDARZENIA / DOWODY / DANE UŻYTKOWNIKÓW / DANE TENANTÓW / SNAPSHOTY. NIE jest usługą biznesową i NIE jest kolejnym repozytorium git.

## 1. Purpose
Warstwa przechowywania danych runtime'owych (RUNTIME DATA / KNOWLEDGE / MEMORY / ARTIFACTS / EVENTS / EVIDENCE / USER DATA / TENANT DATA / SNAPSHOTS). Jest to magazyn stanu faktycznego (actual state) platformy, odrębny od Git (desired state).

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany w CODEOWNERS / OWNERSHIP.md.

## 3. Source of Truth
Runtime (actual state). AIGON-X-FS jest źródłem prawdy dla danych runtime'owych. **Git = desired state, Runtime = actual state** — Git NIE jest źródłem prawdy dla zawartości tego katalogu. Ostra granica: Git = SOURCE/CONTRACTS/DECLARATIONS/SCHEMAS/DEPLOYMENT/POLICIES/TESTS; AIGON-X-FS = RUNTIME DATA.

## 4. Contains
Dane runtime'owe: bloki, chunki, snapshoty, shardy, metadane, rejestry, zdarzenia, dowody, dane tenantów, dane użytkowników, sesje, cache, pliki tymczasowe (patrz podkatalogi).

## 5. Does Not Contain
- Kod źródłowy, kontrakty, deklaracje, schematy, polityki, testy, manifesty, dokumentacja (to domena Git).
- Sekrety (klucze, tokeny, hasła) — tylko schematy/templates/referencje/polityki rotacji.
- Drugi Source of Truth / rejestr / pamięć — AIGON-X-FS jest JEDYNYM SoT dla danych runtime'owych.

## 6. Dependencies
Runtime (actual state), warstwa transportu/komunikacji, mechanizmy snapshotów i replikacji. Zależności szczegółowe w podkatalogach.

## 7. Consumers
Runtime, komponenty mesh, usługi platformy, agenci. `STATUS: UNDEFINED` dla pełnej listy konsumentów.

## 8. Synchronization
Klasa: `REPLICATED` / `CACHE` / `EPHEMERAL` w zależności od podkatalogu. Synchronizacja z Runtime (actual state) i replikacja między nodami. Szczegóły w podkatalogach.

## 9. Lifecycle
Dane powstają w Runtime, zmieniają się w trakcie działania, są wycofywane przez polityki retencji / snapshoty. `STATUS: UNDEFINED` dla pełnego cyklu życia.

## 10. Security
Klasyfikacja danych: runtime data / user data / tenant data. Zakaz przechowywania sekretów. Granice dostępu wg tenantów i użytkowników.

## 11. Recovery
Odzyskiwanie z snapshotów / replik / shardów. `STATUS: UNDEFINED` dla pełnej procedury odzyskiwania.

## 12. Drift Detection
Porównanie stanu faktycznego (Runtime) ze stanem pożądanym. `STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla AIGON-X-FS nie jest jeszcze zdefiniowany.

## Examples
`STATUS: UNDEFINED` — brak znanych przykładów użycia.
