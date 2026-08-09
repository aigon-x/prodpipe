# agents

> Pamięć agentów platformy AIGON Production.

## 1. Purpose
Przechowuje pamięć agentów (kontekst, stan agentów). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — pamięć agentów jest pochodna; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Pamięć agentów (kontekst, stan).

## 5. Does Not Contain
Kanoniczne definicje agentów (te w `shared/agents/definitions`), sekrety.

## 6. Dependencies
`shared/memory`, `shared/agents`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — pamięć replikowana/cache'owana.

## 9. Lifecycle
Powstaje z aktywności agentów, zmienia się dynamicznie, wycofywana przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
