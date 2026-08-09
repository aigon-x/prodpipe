# audit

> Audyt synchronizacji — pochodny, NIE SoT.

## 1. Purpose
Przechowuje audyt synchronizacji (pochodny). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — audyt pochodny; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Audyt synchronizacji (logi, raporty).

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
Audyt dokumentuje wykryty drift między Git (desired) a Runtime (actual).

## Examples
`STATUS: UNDEFINED`
