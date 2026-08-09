# decisions

> Rejestr decyzji architektonicznych (ADR) platformy AIGON Production.

## 1. Purpose
Przechowuje rejestr decyzji architektonicznych (ADR) jako stan pożądany.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state).

## 4. Contains
Dokumenty decyzji architektonicznych (ADR).

## 5. Does Not Contain
Runtime state, sekrety.

## 6. Dependencies
`shared/knowledge`.

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
