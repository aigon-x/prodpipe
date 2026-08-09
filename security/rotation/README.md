# rotation

> Katalog polityk rotacji kluczy — definicje cykli rotacji i procedur.

## 1. Purpose
Przechowuje polityki rotacji kluczy i sekretów — definicje cykli rotacji, procedur i harmonogramów.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (polityki rotacji). Faktyczna rotacja to actual state (Runtime/automation).

## 4. Contains
Polityki rotacji, harmonogramy, procedury, definicje cykli życia kluczy.

## 5. Does Not Contain
Nie zawiera samych kluczy, sekretów, stanu runtime.

## 6. Dependencies
`security/keys`, `secrets/rotation`, `secrets/schemas`.

## 7. Consumers
Zespół bezpieczeństwa, narzędzia automatyzacji (`tools/automation`), zespół platformy.

## 8. Synchronization
`CANONICAL` — polityki rotacji są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych kluczy, zmienia się przy zmianach cykli, wycofywany gdy klucz znika.

## 10. Security
Wysoka wrażliwość — polityki rotacji definiują cykle życia sekretów. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: klucze nie są rotowane zgodnie z polityką.

## Examples
`STATUS: UNDEFINED`
