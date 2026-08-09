# chaos

> Katalog testów chaosu — weryfikacja odporności platformy na awarie i degradację.

## 1. Purpose
Przechowuje testy chaosu (chaos engineering), które weryfikują odporność platformy na awarie, degradację i nieprzewidziane warunki.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (scenariusze chaosu + hipotezy odporności). Wyniki eksperymentów to actual state (Runtime/CI).

## 4. Contains
Scenariusze chaosu (np. zabijanie procesów, opóźnienia sieci, przeciążenia), hipotezy odporności, konfiguracje narzędzi chaosu.

## 5. Does Not Contain
Nie zawiera testów funkcjonalnych, danych produkcyjnych, sekretów.

## 6. Dependencies
Środowiska testowe, narzędzia chaosu, komponenty platformy pod testem.

## 7. Consumers
CI/CD pipeline, zespół platformy, inżynierowie niezawodności (SRE).

## 8. Synchronization
`CANONICAL` — scenariusze są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu hipotez odporności, zmienia się przy ewolucji architektury, wycofywany gdy hipoteza przestaje być aktualna.

## 10. Security
Testy chaosu mogą obciążać środowiska testowe. Nie zawierają sekretów produkcyjnych.

## 11. Recovery
Odzyskiwane z git (checkout). Środowiska testowe odtwarzane z konfiguracji.

## 12. Drift Detection
Drift wykrywany przez CI: eksperymenty chaosu ujawniają, że platforma nie spełnia hipotez odporności.

## Examples
`STATUS: UNDEFINED`
