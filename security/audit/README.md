# audit

> Katalog rejestrów audytu bezpieczeństwa — ślad zgodności z politykami bezpieczeństwa.

## 1. Purpose
Przechowuje rejestry audytu bezpieczeństwa — ślad zgodności platformy z politykami bezpieczeństwa i wymogami.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestry audytu). Wyniki audytów to actual state (Runtime/CI).

## 4. Contains
Raporty audytów bezpieczeństwa, rejestry zgodności, wyniki przeglądów bezpieczeństwa.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych. Wyniki skanów żyją w `artifacts/evidence`.

## 6. Dependencies
`security/policies`, `security/scanning`, `governance/audit`.

## 7. Consumers
Zespół bezpieczeństwa, audytorzy, zespół governance.

## 8. Synchronization
`CANONICAL` — rejestry audytu są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdym audycie, zmienia się przy nowych wynikach, archiwizowany gdy nieaktualny.

## 10. Security
Rejestry audytu mogą ujawniać słabości. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez audyt: platforma nie spełnia polityk bezpieczeństwa.

## Examples
`STATUS: UNDEFINED`
