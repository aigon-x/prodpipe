# contracts

> Katalog kontraktów biznesowych — Public Platform Contract między biznesem a platformą.

## 1. Purpose
Przechowuje kontrakty biznesowe — Public Platform Contract, przez który warstwa biznesowa konsumuje platformę. Biznes nigdy nie implementuje wewnętrznych mechanizmów runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kontrakty). Kontrakty są single-owner Source of Truth dla interfejsu biznes↔platforma. Runtime = actual state (faktyczne odpowiedzi).

## 4. Contains
Definicje Public Platform Contract, schematy API biznesowych, kontrakty usług, SLA/SLO.

## 5. Does Not Contain
Nie zawiera wewnętrznych implementacji runtime, sekretów, danych biznesowych. Biznes → runtime internals jest FORBIDDEN.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Warstwa biznesowa (`business/tenants`, `business/users`, itd.), zewnętrzni konsumenci, zespół platformy.

## 8. Synchronization
`CANONICAL` — kontrakty są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych usług biznesowych, zmienia się przez wersjonowanie kontraktów, wycofywany gdy usługa znika.

## 10. Security
Kontrakty definiują wymagania bezpieczeństwa (auth, uprawnienia). Nie zawierają sekretów.

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez testy kontraktowe (`tests/contract`): implementacja odbiega od kontraktu.

## Examples
`STATUS: UNDEFINED`
