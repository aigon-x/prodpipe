# e2e

> Katalog testów end-to-end — weryfikacja pełnych ścieżek użytkownika przez cały stack.

## 1. Purpose
Przechowuje testy end-to-end (E2E), które weryfikują pełne ścieżki użytkownika i przepływy biznesowe przez cały stack platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod testów). Wyniki wykonania to actual state (Runtime/CI). Testy są częścią desired state w repo.

## 4. Contains
Pliki testów E2E, konfiguracje środowisk E2E, skrypty przygotowania środowiska pełnego stacku.

## 5. Does Not Contain
Nie zawiera testów jednostkowych/integracyjnych, danych produkcyjnych, sekretów.

## 6. Dependencies
Pełny stack platformy (runtime, router, usługi), środowiska testowe, `tests/fixtures`.

## 7. Consumers
CI/CD pipeline, inżynierowie QA, zespół release.

## 8. Synchronization
`CANONICAL` — kod testów jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy dodawaniu nowych ścieżek użytkownika, zmienia się przy zmianach UX/API, wycofywany gdy ścieżka znika.

## 10. Security
Testy E2E mogą dotykać środowisk testowych. Nie powinny zawierać sekretów produkcyjnych.

## 11. Recovery
Odzyskiwane z git (checkout). Środowiska E2E odtwarzane z konfiguracji.

## 12. Drift Detection
Drift wykrywany przez CI: testy E2E nie przechodzą, co sygnalizuje rozjazd między komponentami lub zmianę zachowania.

## Examples
`STATUS: UNDEFINED`
