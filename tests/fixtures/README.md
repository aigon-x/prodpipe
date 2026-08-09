# fixtures

> Katalog fixture'ów testowych — współdzielone dane syntetyczne i mocki dla wszystkich testów.

## 1. Purpose
Przechowuje współdzielone fixture'y testowe: dane syntetyczne, mocki, przykładowe ładunki, które są używane przez testy w całym drzewie `tests/`.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (fixture'y). Fixture'y są częścią desired state w repo.

## 4. Contains
Dane syntetyczne (JSON/YAML), mocki, przykładowe ładunki API, generatory danych testowych.

## 5. Does Not Contain
Nie zawiera danych produkcyjnych, sekretów, danych osobowych rzeczywistych użytkowników.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Wszystkie katalogi testów (`tests/unit`, `tests/integration`, `tests/e2e`, itd.).

## 8. Synchronization
`CANONICAL` — fixture'y są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy dodawaniu nowych scenariuszy testowych, zmienia się przy ewolucji danych, wycofywany gdy fixture przestaje być używany.

## 10. Security
Fixture'y muszą być syntetyczne — nigdy nie zawierać danych produkcyjnych ani sekretów.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez CI: fixture'y nie pasują do aktualnych schematów/kontraktów, testy używające ich nie przechodzą.

## Examples
`STATUS: UNDEFINED`
