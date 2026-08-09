# audit

> Katalog rejestrów audytu governance — ślad zgodności z politykami i standardami.

## 1. Purpose
Przechowuje rejestry audytu governance — ślad zgodności platformy z politykami, standardami i decyzjami.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestry audytu). Wyniki audytów to actual state (Runtime/CI). Rejestry są częścią governance jako kod.

## 4. Contains
Raporty audytów, rejestry zgodności, wyniki przeglądów governance.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych. Wyniki audytów technicznych żyją w `artifacts/evidence`.

## 6. Dependencies
`governance/policies`, `governance/standards`, `governance/decisions`.

## 7. Consumers
Zespół governance, audytorzy, zespół bezpieczeństwa.

## 8. Synchronization
`CANONICAL` — rejestry audytu są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy każdym audycie, zmienia się przy nowych wynikach, archiwizowany gdy nieaktualny.

## 10. Security
Rejestry audytu mogą ujawniać słabości. Dostęp ograniczony do zespołu governance i bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez audyt: platforma nie spełnia polityk i standardów.

## Examples
`STATUS: UNDEFINED`
