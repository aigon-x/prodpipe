# api

> Kontrakty API — kanoniczna definicja interfejsów API.

## 1. Purpose
Przechowuje kanoniczne definicje kontraktów API jako stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state). Kanoniczne definicje kontraktów API.

## 4. Contains
Definicje kontraktów API.

## 5. Does Not Contain
Implementacje, runtime state, sekrety.

## 6. Dependencies
`shared/canonical/contracts`, `shared/canonical/schemas`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` — synchronizowane z Git.

## 9. Lifecycle
Powstaje z Git, zmienia się przez PR/commit, wycofywany przez usunięcie z Git.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
