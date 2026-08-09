# state

> Stan agentów — pochodny, NIE SoT.

## 1. Purpose
Przechowuje stan agentów (pochodny). NIE jest SoT — faktyczny stan agentów żyje w Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — stan agentów jest pochodny; faktyczny stan = Runtime (actual).

## 4. Contains
Stan agentów (pochodny).

## 5. Does Not Contain
Kanoniczne definicje agentów (te w `shared/agents/definitions`), sekrety, faktyczny runtime state.

## 6. Dependencies
`shared/agents`, Runtime.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — stan replikowany/cache'owany z Runtime.

## 9. Lifecycle
Powstaje z aktywności agentów, zmienia się dynamicznie, wycofywany przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Runtime (actual) i Git (desired).

## 12. Drift Detection
Porównanie z Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
