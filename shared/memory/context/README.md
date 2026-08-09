# context

> Pamięć kontekstu platformy AIGON Production.

## 1. Purpose
Przechowuje pamięć kontekstu (kontekst operacyjny). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — pamięć kontekstu jest pochodna; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Pamięć kontekstu (kontekst operacyjny).

## 5. Does Not Contain
Kanoniczne artefakty, sekrety.

## 6. Dependencies
`shared/memory`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — pamięć replikowana/cache'owana.

## 9. Lifecycle
Powstaje z aktywności, zmienia się dynamicznie, wycofywana przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
