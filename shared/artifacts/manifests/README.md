# manifests

> Manifesty artefaktów — pochodne, NIE SoT.

## 1. Purpose
Przechowuje manifesty artefaktów (pochodne). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — manifesty pochodne; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Manifesty artefaktów (pochodne).

## 5. Does Not Contain
Kanoniczne manifesty (te w `shared/canonical/manifests`), sekrety.

## 6. Dependencies
`shared/artifacts`, `shared/canonical/manifests`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — replikowane/cache'owane.

## 9. Lifecycle
Powstaje z aktywności, zmienia się dynamicznie, wycofywany przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
