# manifests

> Katalog manifestów wdrożeniowych — deklaratywne definicje wdrożeń.

## 1. Purpose
Przechowuje manifesty wdrożeniowe — deklaratywne definicje wdrożeń, konfiguracje deploymentu i definicje zasobów.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (manifesty). Faktyczny stan wdrożenia to actual state (Runtime).

## 4. Contains
Manifesty Kubernetes/Helm, definicje deploymentu, konfiguracje zasobów, definicje usług.

## 5. Does Not Contain
Nie zawiera stanu runtime, sekretów, danych biznesowych.

## 6. Dependencies
`tools/ci`, `tools/automation`.

## 7. Consumers
Runtime (wdrożenie), CI/CD pipeline, zespół operacyjny.

## 8. Synchronization
`CANONICAL` — manifesty są źródłem prawdy w git; synchronizacja przez normalny workflow commit/push.

## 9. Lifecycle
Powstaje przy definiowaniu nowych wdrożeń, zmienia się przy zmianach konfiguracji, wycofywany gdy wdrożenie znika.

## 10. Security
Manifesty mogą definiować wymagania bezpieczeństwa. Nie zawierają sekretów.

## 11. Recovery
Odzyskiwane z git (checkout). Wdrożenia odtwarzane z manifestów.

## 12. Drift Detection
Drift wykrywany przez walidację: stan wdrożenia odbiega od manifestów.

## Examples
`STATUS: UNDEFINED`
