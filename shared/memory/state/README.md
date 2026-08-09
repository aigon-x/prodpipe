# state

> Pamięć stanu platformy AIGON Production.

## 1. Purpose
Przechowuje pamięć stanu (stan operacyjny). NIE jest SoT — faktyczny stan żyje w Runtime.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
`STATUS: ARCHITECTURAL GAP` — pamięć stanu jest pochodna; faktyczny stan = Runtime (actual).

## 4. Contains
Pamięć stanu (stan operacyjny).

## 5. Does Not Contain
Kanoniczne artefakty, sekrety, faktyczny runtime state (ten w Runtime).

## 6. Dependencies
`shared/memory`, Runtime.

## 7. Consumers
`STATUS: UNDEFINED`

## 8. Synchronization
`REPLICATED` / `CACHE` — pamięć replikowana/cache'owana z Runtime.

## 9. Lifecycle
Powstaje z aktywności, zmienia się dynamicznie, wycofywana przez czyszczenie.

## 10. Security
Brak sekretów.

## 11. Recovery
Odzysk z Runtime (actual) i Git (desired).

## 12. Drift Detection
Porównanie z Runtime (actual) przez `shared/sync`.

## Examples
`STATUS: UNDEFINED`
