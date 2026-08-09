# migration

> Katalog narzędzi migracji — skrypty i procedury migracji danych i schematów.

## 1. Purpose
Przechowuje narzędzia migracji — skrypty, procedury i definicje migracji danych i schematów.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (definicje migracji). Faktyczny stan po migracji to actual state (Runtime).

## 4. Contains
Skrypty migracji, definicje migracji schematów, procedury migracji danych.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/scripts`, `tools/validation`.

## 7. Consumers
Zespół platformy, zespół operacyjny, deweloperzy.

## 8. Synchronization
`CANONICAL` — definicje migracji są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy zmianach schematów, zmienia się przy ewolucji danych, wycofywany gdy migracja wykonana.

## 10. Security
Migracje mogą dotykać wrażliwych danych. Dostęp ograniczony do zespołu.

## 11. Recovery
Odzyskiwane z git (checkout). Migracje powinny być idempotentne i odwracalne.

## 12. Drift Detection
Drift wykrywany przez walidację: stan po migracji odbiega od oczekiwanego.

## Examples
`STATUS: UNDEFINED`
