# unit

> Katalog testów jednostkowych — weryfikacja pojedynczych funkcji/modułów w izolacji, bez zależności zewnętrznych.

## 1. Purpose
Przechowuje testy jednostkowe (unit tests) dla komponentów platformy. Testują pojedyncze funkcje/moduły w izolacji, bez sieci, baz danych i innych zależności zewnętrznych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod testów). Wyniki wykonania testów to actual state (Runtime/CI). Testy są częścią desired state w repo.

## 4. Contains
Pliki testów jednostkowych (np. `*.test.ts`, `*_test.rs`, `*.spec.ts`), konfiguracje runnerów testowych, mocki lokalne.

## 5. Does Not Contain
Nie zawiera testów integracyjnych/E2E, danych produkcyjnych, sekretów, fixture'ów współdzielonych (te żyją w `tests/fixtures`).

## 6. Dependencies
Kod źródłowy testowanych modułów, framework testowy, `tests/fixtures` (jeśli współdzielone mocki).

## 7. Consumers
CI/CD pipeline, deweloperzy, narzędzia pokrycia kodu (`tests/coverage`).

## 8. Synchronization
`CANONICAL` — kod testów jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje razem z kodem produkcyjnym (TDD lub po implementacji), zmienia się przy zmianach API, wycofywany gdy testowany moduł znika.

## 10. Security
Brak danych wrażliwych. Testy nie powinny zawierać sekretów ani danych produkcyjnych.

## 11. Recovery
Odzyskiwane z git (checkout). Nie ma stanu runtime do odzyskania.

## 12. Drift Detection
Drift wykrywany przez CI: testy nie przechodzą, pokrycie spada, testy odnoszą się do nieistniejących API.

## Examples
`STATUS: UNDEFINED`
