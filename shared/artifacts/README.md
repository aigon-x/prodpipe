# artifacts

> Artefakty platformy (manifests, digests, evidence) — pochodne, NIE SoT.

## 1. Purpose
Przechowuje artefakty (manifests, digests, evidence) jako pochodne dane. NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — artefakty są pochodne; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Podkatalogi: `manifests/`, `digests/`, `evidence/`.

## 5. Does Not Contain
Kanoniczne artefakty (te w `shared/canonical`), sekrety.

## 6. Dependencies
`shared/canonical`, Runtime.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — artefakty replikowane/cache'owane.

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
