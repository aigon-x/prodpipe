# cache

> Podkatalog AIGON-X-FS przechowujący cache — tymczasowe kopie danych przyspieszające dostęp.

## 1. Purpose
Przechowywanie cache — tymczasowych kopii danych runtime'owych przyspieszających dostęp / odczyt.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Cache jest kopią (CACHE), NIE źródłem prawdy — źródłem jest Runtime / dane źródłowe.

## 4. Contains
Cache — tymczasowe kopie danych runtime'owych.

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth — cache NIE jest SoT.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), dane źródłowe (bloki/chunki/shardy).

## 7. Consumers
Runtime, usługi platformy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `CACHE`. Cache jest odświeżany z danych źródłowych; może być unieważniany. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
Cache powstaje przy odczycie, unieważniany / wygasany. `STATUS: UNDEFINED` dla pełnego cyklu.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Cache jest odtwarzany z danych źródłowych — nie wymaga osobnego odzyskiwania.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania nieaktualności cache nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
