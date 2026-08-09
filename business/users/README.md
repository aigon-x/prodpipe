# users

> Katalog definicji użytkowników biznesowych — schematy i konfiguracje kont użytkowników.

## 1. Purpose
Przechowuje definicje użytkowników biznesowych — schematy, konfiguracje i szablony kont użytkowników platformy.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (schematy/definicje). Faktyczne konta użytkowników to actual state (Runtime).

## 4. Contains
Schematy kont użytkowników, definicje ról i uprawnień, szablony onboardingu.

## 5. Does Not Contain
Nie zawiera danych osobowych rzeczywistych użytkowników, sekretów, haseł, stanu runtime.

## 6. Dependencies
`business/contracts`, `business/tenants`.

## 7. Consumers
Runtime (egzekwowanie tożsamości), warstwa biznesowa, zespół platformy.

## 8. Synchronization
`CANONICAL` — schematy są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych typów użytkowników, zmienia się przy zmianach ról, wycofywany gdy typ znika.

## 10. Security
Wysoka wrażliwość — definicje ról i uprawnień. Dostęp ograniczony do zespołu platformy.

## 11. Recovery
Odzyskiwane z git (checkout). Konta w runtime odtwarzane z definicji.

## 12. Drift Detection
Drift wykrywany przez walidację: definicje ról odbiegają od stanu w runtime.

## Examples
`STATUS: UNDEFINED`
