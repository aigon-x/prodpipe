# rotation

> Katalog polityk rotacji sekretów — definicje cykli rotacji i procedur.

## 1. Purpose
Przechowuje polityki rotacji sekretów — definicje cykli rotacji, procedur i harmonogramów. Zasada: **no secrets in git** — same sekrety NIGDY nie trafiają do tego katalogu.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (polityki rotacji). Faktyczna rotacja to actual state (Runtime/automation).

## 4. Contains
Polityki rotacji, harmonogramy, procedury, definicje cykli życia sekretów.

## 5. Does Not Contain
NIE zawiera samych sekretów, kluczy, haseł, tokenów. Same sekrety żyją w secrets manager (Vault).

## 6. Dependencies
`secrets/schemas`, `secrets/references`, `security/rotation`.

## 7. Consumers
Zespół bezpieczeństwa, narzędzia automatyzacji (`tools/automation`), zespół platformy.

## 8. Synchronization
`CANONICAL` — polityki rotacji są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych sekretów, zmienia się przy zmianach cykli, wycofywany gdy sekret znika.

## 10. Security
Wysoka wrażliwość — polityki rotacji definiują cykle życia sekretów. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout). Same sekrety odzyskiwane z secrets manager (backup).

## 12. Drift Detection
Drift wykrywany przez walidację: sekrety nie są rotowane zgodnie z polityką.

## Examples
`STATUS: UNDEFINED`
