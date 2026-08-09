# security

> Katalog dokumentacji bezpieczeństwa — opisy modelu bezpieczeństwa platformy.

## 1. Purpose
Przechowuje dokumentację bezpieczeństwa — opisy modelu bezpieczeństwa platformy, procedur i wymagań.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (dokumentacja). Dokumentacja opisuje polityki; faktyczne egzekwowanie to actual state (Runtime).

## 4. Contains
Dokumenty bezpieczeństwa, opisy modelu bezpieczeństwa, procedury, wymagania.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`security/policies`, `security/threat-model`, `docs/architecture`.

## 7. Consumers
Zespół bezpieczeństwa, zespół platformy, audytorzy.

## 8. Synchronization
`CANONICAL` — dokumentacja jest źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy zmianach modelu bezpieczeństwa, zmienia się przy ewolucji, wycofywana gdy nieaktualna.

## 10. Security
Wysoka wrażliwość — dokumentacja bezpieczeństwa może ujawniać słabości. Dostęp ograniczony do zespołu bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez przegląd: dokumentacja odbiega od faktycznego modelu bezpieczeństwa.

## Examples
`STATUS: UNDEFINED`
