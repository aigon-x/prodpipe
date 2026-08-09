# definitions

> Kanoniczne definicje agentów.

## 1. Purpose
Przechowuje kanoniczne definicje agentów jako stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state).

## 4. Contains
Definicje agentów (deklaratywne).

## 5. Does Not Contain
Runtime state, sekrety, pamięć agentów.

## 6. Dependencies
`shared/agents`, `shared/canonical/contracts`.

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
