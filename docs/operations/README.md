# operations

> Katalog dokumentacji operacyjnej — procedury operacyjne i runbooki.

## 1. Purpose
Przechowuje dokumentację operacyjną — procedury operacyjne, runbooki, instrukcje obsługi i reagowania na awarie.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja opisuje procedury; faktyczne operacje to actual state (Runtime).

## 4. Contains
Runbooki, procedury operacyjne, instrukcje reagowania na awarie, checklisty.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`docs/architecture`, `docs/reference`.

## 7. Consumers
Zespół operacyjny (SRE), zespół platformy, on-call.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu procedur, zmienia się przy zmianach operacyjnych, wycofywana gdy nieaktualna.

## 10. Security
Runbooki mogą opisywać procedury bezpieczeństwa. Dostęp ograniczony do zespołu operacyjnego.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: procedury odbiegają od faktycznych operacji.

## Examples
`STATUS: UNDEFINED`
