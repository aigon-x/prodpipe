# notifications

> Katalog definicji powiadomień biznesowych — schematy i szablony powiadomień.

## 1. Purpose
Przechowuje definicje powiadomień biznesowych — schematy, szablony i konfiguracje powiadomień dla warstwy biznesowej.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje powiadomień). Faktycznie wysłane powiadomienia to actual state (Runtime).

## 4. Contains
Schematy powiadomień, szablony, definicje kanałów dostarczania, konfiguracje routingu.

## 5. Does Not Contain
Nie zawiera danych biznesowych, sekretów, stanu runtime.

## 6. Dependencies
`business/contracts`, `business/users`.

## 7. Consumers
Warstwa biznesowa, Runtime (dostarczanie), zespół platformy.

## 8. Synchronization
`CANONICAL` — definicje powiadomień są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych powiadomień, zmienia się przy zmianach szablonów, wycofywany gdy powiadomienie znika.

## 10. Security
Definicje powiadomień mogą dotykać danych wrażliwych. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: dostarczane powiadomienia odbiegają od definicji.

## Examples
`STATUS: UNDEFINED`
