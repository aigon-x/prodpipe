# compliance

> Katalog rejestrów zgodności — ślad spełniania wymogów regulacyjnych i prawnych.

## 1. Purpose
Przechowuje rejestry zgodności (compliance) — ślad spełniania wymogów regulacyjnych, prawnych i branżowych przez platformę.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (rejestry zgodności). Rejestry są częścią governance jako kod.

## 4. Contains
Rejestry zgodności, mapowania wymogów na kontrole, raporty zgodności.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`governance/policies`, `governance/standards`, `security/policies`.

## 7. Consumers
Zespół compliance, audytorzy, zespół bezpieczeństwa, zarząd.

## 8. Synchronization
`CANONICAL` — rejestry zgodności są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu wymogów, zmienia się przy zmianach regulacyjnych, wycofywany gdy wymóg znika.

## 10. Security
Rejestry zgodności mogą ujawniać słabości. Dostęp ograniczony do zespołu compliance i bezpieczeństwa.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez audyt: platforma nie spełnia wymogów regulacyjnych.

## Examples
`STATUS: UNDEFINED`
