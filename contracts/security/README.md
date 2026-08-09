# security

> Kontrakty bezpieczeństwa — kanoniczna definicja wymagań bezpieczeństwa.

## 1. Purpose
Przechowuje kanoniczne definicje kontraktów bezpieczeństwa jako stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne definicje kontraktów bezpieczeństwa.

## 4. Contains
Definicje kontraktów bezpieczeństwa.

## 5. Does Not Contain
Implementacje, runtime state, sekrety.

## 6. Dependencies
`shared/canonical/contracts`, `shared/canonical/schemas`, `shared/canonical/policies`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów — tylko definicje wymagań bezpieczeństwa.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
