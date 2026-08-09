# reference

> Katalog dokumentacji referencyjnej — szczegółowe opisy techniczne i API.

## 1. Purpose
Przechowuje dokumentację referencyjną — szczegółowe opisy techniczne, referencje API, specyfikacje i słowniki.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja opisuje kontrakty; faktyczne zachowanie to actual state (Runtime).

## 4. Contains
Referencje API, specyfikacje techniczne, słowniki, szczegółowe opisy komponentów.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`docs/architecture`, `business/contracts`.

## 7. Consumers
Deweloperzy, zespół platformy, zespół wsparcia.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych API, zmienia się przy zmianach specyfikacji, wycofywana gdy nieaktualna.

## 10. Security
Referencje API mogą opisywać wymagania bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: dokumentacja odbiega od faktycznych API.

## Examples
`STATUS: UNDEFINED`
