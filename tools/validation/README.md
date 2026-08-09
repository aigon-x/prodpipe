# validation

> Katalog narzędzi walidacji — definicje walidacji zgodności i poprawności.

## 1. Purpose
Przechowuje narzędzia walidacji — definicje walidacji zgodności, poprawności i spójności platformy z desired state.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje walidacji). Wyniki walidacji to actual state (Runtime/CI).

## 4. Contains
Definicje walidacji, reguły sprawdzania zgodności, narzędzia weryfikacji.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/policies`, `governance/standards`, `tools/scripts`.

## 7. Consumers
CI/CD pipeline, zespół platformy, narzędzia automatyzacji.

## 8. Synchronization
`CANONICAL` — definicje walidacji są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych reguł, zmienia się przy zmianach wymagań, wycofywany gdy reguła znika.

## 10. Security
Walidacje mogą dotykać wymagań bezpieczeństwa. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: platforma odbiega od desired state.

## Examples
`STATUS: UNDEFINED`
