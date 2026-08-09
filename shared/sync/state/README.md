# state

> Stan synchronizacji — pochodny, NIE SoT.

## 1. Purpose
Przechowuje stan synchronizacji (pochodny). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — stan sync pochodny; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Stan synchronizacji.

## 5. Does Not Contain
Kanoniczne artefakty, sekrety.

## 6. Dependencies
`shared/sync`, Runtime.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — replikowane/cache'owane.

## 9. Lifecycle
Powstaje z aktywności sync, zmienia się dynamicznie, wycofywany przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
