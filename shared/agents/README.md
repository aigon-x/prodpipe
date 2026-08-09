# agents

> Definicje, rejestr i stan agentów platformy AIGON Production.

## 1. Purpose
Przechowuje definicje agentów (definitions), rejestr (registry) i stan (state). Definicje i rejestr = stan pożądany; stan = pochodny.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired state) dla definicji i rejestru; faktyczny stan agentów = Runtime (actual).

## 4. Contains
Podkatalogi: `definitions/`, `registry/`, `state/`.

## 5. Does Not Contain
Runtime state (ten w Runtime), sekrety, pamięć agentów (ta w `shared/memory/agents`).

## 6. Dependencies
`shared/canonical/contracts`, `shared/canonical/registry`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`CANONICAL` (definitions/registry) + `REPLICATED` (state) — synchronizowane z Git i Runtime.

## 9. Lifecycle
Definicje powstają z Git; stan zmienia się dynamicznie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (definitions/registry) i Runtime (state).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
