# policies

> Katalog polityk jako kod (policies-as-code) — deklaratywne reguły zarządzania platformą.

## 1. Purpose
Przechowuje polityki jako kod (policies-as-code) — deklaratywne reguły, które definiują, jak platforma jest zarządzana, weryfikowana i egzekwowana.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (polityki). Polityki są single-owner Source of Truth dla reguł zarządzania. Runtime = actual state (egzekwowanie).

## 4. Contains
Pliki polityk (np. OPA/Rego, JSON Schema, YAML), reguły walidacji, definicje wymagań.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych. Nie jest drugim SoT dla reguł — jest jedynym.

## 6. Dependencies
`STATUS: UNDEFINED`

## 7. Consumers
Runtime (egzekwowanie), CI/CD pipeline, narzędzia walidacji (`tools/validation`), zespół platformy.

## 8. Synchronization
`CANONICAL` — polityki są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych reguł, zmienia się przez kontrolowany proces zmian (approvals), wycofywany gdy reguła przestaje obowiązywać.

## 10. Security
Polityki definiują wymagania bezpieczeństwa. Dostęp do zmian ograniczony (single-owner, brak mutacji przez agentów).

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: egzekwowanie w runtime odbiega od polityk w git.

## Examples
`STATUS: UNDEFINED`
