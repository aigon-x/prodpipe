# conflicts

> Konflikty synchronizacji — pochodne, NIE SoT.

## 1. Purpose
Przechowuje konflikty synchronizacji (pochodne). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — konflikty pochodne; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Konflikty synchronizacji.

## 5. Does Not Contain
Kanoniczne artefakty, sekrety.

## 6. Dependencies
`shared/sync`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — replikowane/cache'owane.

## 9. Lifecycle
Powstaje z konfliktów sync, zmienia się dynamicznie, wycofywany po rozwiązaniu.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Konflikty są wynikiem wykrytego driftu między Git (desired) a Runtime (actual).

## Examples
`STATUS: UNDEFINED`
