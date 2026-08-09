# tenants

> Katalog konfiguracji tenantów — definicje wielodostępności (multi-tenancy) platformy.

## 1. Purpose
Przechowuje konfiguracje tenantów — definicje wielodostępności (multi-tenancy), izolacji i przypisań zasobów dla poszczególnych tenantów biznesowych.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (konfiguracje tenantów). Faktyczny stan tenantów to actual state (Runtime).

## 4. Contains
Definicje tenantów, konfiguracje izolacji, przypisania zasobów, metadane tenantów.

## 5. Does Not Contain
Nie zawiera danych użytkowników (te żyją w `business/users`), sekretów, stanu runtime.

## 6. Dependencies
`business/contracts`, `business/users`.

## 7. Consumers
Runtime (egzekwowanie izolacji), warstwa biznesowa, zespół platformy.

## 8. Synchronization
`CANONICAL` — konfiguracje tenantów są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy onboardingu nowego tenanta, zmienia się przy zmianach konfiguracji, wycofywany przy offboardingu.

## 10. Security
Konfiguracje tenantów definiują granice izolacji. Dostęp ograniczony do zespołu platformy.

## 11. Recovery
Odzyskiwane z git (checkout). Stan tenantów w runtime odtwarzany z konfiguracji.

## 12. Drift Detection
Drift wykrywany przez walidację: konfiguracja tenanta odbiega od stanu w runtime.

## Examples
`STATUS: UNDEFINED`
