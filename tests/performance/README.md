# performance

> Katalog testów wydajnościowych — weryfikacja wydajności, przepustowości i opóźnień.

## 1. Purpose
Przechowuje testy wydajnościowe (performance/load/stress tests), które weryfikują przepustowość, opóźnienia i zachowanie pod obciążeniem.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (skrypty testów + progi wydajności). Wyniki benchmarków to actual state (Runtime/CI).

## 4. Contains
Skrypty testów obciążeniowych, definicje progów wydajności (SLO), konfiguracje narzędzi (np. k6, JMeter).

## 5. Does Not Contain
Nie zawiera testów funkcjonalnych, danych produkcyjnych, sekretów.

## 6. Dependencies
Środowiska testowe, narzędzia obciążeniowe, komponenty platformy pod testem.

## 7. Consumers
CI/CD pipeline, zespół platformy, inżynierowie wydajności.

## 8. Synchronization
`CANONICAL` — skrypty i progi są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu SLO, zmienia się przy zmianach wymagań wydajnościowych, wycofywany gdy SLO znika.

## 10. Security
Testy obciążeniowe mogą obciążać środowiska testowe. Nie zawierają sekretów produkcyjnych.

## 11. Recovery
Odzyskiwane z git (checkout). Środowiska testowe odtwarzane z konfiguracji.

## 12. Drift Detection
Drift wykrywany przez CI: wyniki benchmarków spadają poniżej progów SLO.

## Examples
`STATUS: UNDEFINED`
