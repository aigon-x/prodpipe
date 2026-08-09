# policies

> Katalog polityk bezpieczeństwa jako kod — deklaratywne reguły bezpieczeństwa platformy.

## 1. Purpose
Przechowuje polityki bezpieczeństwa jako kod (security policies-as-code) — deklaratywne reguły bezpieczeństwa, które definiują, jak platforma jest chroniona i egzekwowana.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (polityki). Polityki są single-owner Source of Truth dla reguł bezpieczeństwa. Runtime = actual state (egzekwowanie).

## 4. Contains
Pliki polityk bezpieczeństwa (np. OPA/Rego, JSON Schema, YAML), reguły kontroli dostępu, definicje wymagań bezpieczeństwa.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, kluczy (te żyją w `secrets/`), danych biznesowych.

## 6. Dependencies
`governance/policies`, `security/threat-model`.

## 7. Consumers
Runtime (egzekwowanie), CI/CD pipeline, narzędzia skanujące (`security/scanning`), zespół bezpieczeństwa.

## 8. Synchronization
`CANONICAL` — polityki są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych reguł, zmienia się przez kontrolowany proces zmian, wycofywany gdy reguła przestaje obowiązywać.

## 10. Security
Polityki definiują wymagania bezpieczeństwa. Dostęp do zmian ograniczony (single-owner, brak mutacji przez agentów).

## 11. Recovery
Odzyskiwane z git (checkout).

## 12. Drift Detection
Drift wykrywany przez walidację: egzekwowanie w runtime odbiega od polityk w git.

## Examples
`STATUS: UNDEFINED`
