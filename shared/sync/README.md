# sync

> Płaszczyzna synchronizacji między Git (desired) a Runtime (actual) — NIE jest drugim SoT.

## 1. Purpose
Przechowuje plany synchronizacji (plans), stan (state), konflikty (conflicts) i audyt (audit). To jest płaszczyzna sync między Git (desired) a Runtime (actual) — NIE staje się drugim rejestrem/pamięcią/SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git (desired) i Runtime (actual). Ten katalog jest płaszczyzną synchronizacji, nie źródłem prawdy.

## 4. Contains
Podkatalogi: `plans/`, `state/`, `conflicts/`, `audit/`.

## 5. Does Not Contain
Kanoniczne artefakty (te w `shared/canonical`), sekrety, drugi SoT.

## 6. Dependencies
`shared/canonical`, Runtime.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — płaszczyzna synchronizacji replikuje stan między Git a Runtime.

## 9. Lifecycle
Powstaje z aktywności sync, zmienia się dynamicznie, wycofywany przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Ten katalog jest mechanizmem wykrywania driftu — porównuje Git (desired) vs Runtime (actual).

## Examples
`STATUS: UNDEFINED`
