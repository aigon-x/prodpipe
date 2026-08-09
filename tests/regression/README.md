# regression

> Katalog testów regresyjnych — ochrona przed ponownym pojawieniem się znanych błędów.

## 1. Purpose
Przechowuje testy regresyjne, które chronią przed ponownym pojawieniem się wcześniej naprawionych błędów i niepożądanych zmian zachowania.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod testów). Wyniki wykonania to actual state (Runtime/CI). Testy są częścią desired state w repo.

## 4. Contains
Pliki testów regresyjnych, przypadki testowe dla znanych bugów, konfiguracje.

## 5. Does Not Contain
Nie zawiera testów nowych funkcji (te żyją w unit/integration), danych produkcyjnych, sekretów.

## 6. Dependencies
Kod produkcyjny pod testem, framework testowy, `tests/fixtures`.

## 7. Consumers
CI/CD pipeline, deweloperzy, inżynierowie QA.

## 8. Synchronization
`CANONICAL` — kod testów jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje po naprawie błędu (test zapobiega regresji), zmienia się przy ewolucji zachowania, wycofywany gdy testowany scenariusz przestaje istnieć.

## 10. Security
Brak danych wrażliwych. Testy nie powinny zawierać sekretów.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez CI: testy regresyjne nie przechodzą, co sygnalizuje ponowne pojawienie się błędu.

## Examples
`STATUS: UNDEFINED`
