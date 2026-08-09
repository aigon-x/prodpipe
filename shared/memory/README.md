# memory

> Współdzielona pamięć platformy (agents, sessions, context, state) — NIE jest SoT.

## 1. Purpose
Przechowuje współdzieloną pamięć (agents, sessions, context, state). Uwaga: to NIE jest drugi SoT/rejestr — to warstwa pamięci, a prawda żyje w Git (desired) i Runtime (actual).

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — pamięć jest pochodna; prawda leży w Git (desired) i Runtime (actual), nie w tym katalogu.

## 4. Contains
Podkatalogi: `agents/`, `sessions/`, `context/`, `state/`.

## 5. Does Not Contain
Kanoniczne kontrakty/config (te w `shared/canonical`), sekrety.

## 6. Dependencies
`shared/canonical`, `shared/knowledge`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — pamięć jest replikowana/cache'owana, nie jest źródłem prawdy.

## 9. Lifecycle
Powstaje z aktywności agentów, zmienia się dynamicznie, wycofywana przez czyszczenie.

## 10. Security
Brak sekretów; pamięć może zawierać referencje, nie sekrety.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual) — pamięć jest odtwarzalna.

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
