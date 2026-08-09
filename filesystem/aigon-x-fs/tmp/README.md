# tmp

> Podkatalog AIGON-X-FS przechowujący pliki tymczasowe — efemeryczne dane robocze.

## 1. Purpose
Przechowywanie plików tymczasowych — efemerycznych danych roboczych platformy.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Pliki tymczasowe są efemeryczne i nie stanowią źródła prawdy.

## 4. Contains
Pliki tymczasowe (efemeryczne dane robocze).

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth — tmp NIE jest SoT.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), procesy / usługi tworzące pliki tymczasowe.

## 7. Consumers
Procesy / usługi platformy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `EPHEMERAL`. Pliki tymczasowe nie są synchronizowane; czyszczone okresowo.

## 9. Lifecycle
Pliki powstają w trakcie działania, czyszczone okresowo / po zakończeniu procesu. `STATUS: UNDEFINED` dla pełnego cyklu.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Pliki tymczasowe nie wymagają odzyskiwania — są odtwarzane przez procesy.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania niepożądanej zawartości tmp nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
