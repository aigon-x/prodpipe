# tenants

> Podkatalog AIGON-X-FS przechowujący dane tenantów — izolowane dane runtime'owe poszczególnych tenantów.

## 1. Purpose
Przechowywanie danych tenantów — izolowanych danych runtime'owych poszczególnych tenantów platformy.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Git = desired state, Runtime = actual state.

## 4. Contains
Dane tenantów (izolowane dane runtime'owe per tenant).

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), mechanizm izolacji tenantów.

## 7. Consumers
Runtime, usługi platformy, tenanci. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED`. Replikacja danych tenantów między nodami. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia danych tenantów nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: dane tenantów. Wymagana izolacja między tenantami. Zakaz sekretów.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla danych tenantów nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
