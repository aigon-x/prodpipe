# sessions

> Pamięć sesji platformy AIGON Production.

## 1. Purpose
Przechowuje pamięć sesji (kontekst sesji). NIE jest SoT.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — pamięć sesji jest pochodna; prawda w Git (desired) i Runtime (actual).

## 4. Contains
Pamięć sesji (kontekst sesji).

## 5. Does Not Contain
Kanoniczne artefakty, sekrety.

## 6. Dependencies
`shared/memory`.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`SESSION` — pamięć sesji jest specyficzna dla sesji.

## 9. Lifecycle
Powstaje z sesji, zmienia się dynamicznie, wycofywana po zakończeniu sesji.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Git (desired) i Runtime (actual).

## 12. Drift Detection
Porównanie z Git (desired) vs Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
