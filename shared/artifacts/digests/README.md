# digests

> Digesty artefaktów — pochodne, NIE SoT.

## 1. Purpose
Przechowuje digesty (hashe) artefaktów (pochodne). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — digesty pochodne; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Digesty (hashe) artefaktów.

## 5. Does Not Contain
Kanoniczne artefakty, sekrety.

## 6. Dependencies
`shared/artifacts`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — replikowane/cache'owane.

## 9. Lifecycle
Powstaje z artefaktów, zmienia się dynamicznie, wycofywany przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
