# sessions

> Podkatalog AIGON-X-FS przechowujący sesje — dane sesji runtime'owych / interakcji.

## 1. Purpose
Przechowywanie sesji — danych sesji runtime'owych / interakcji użytkowników i agentów.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Sesje są stanem faktycznym interakcji.

## 4. Contains
Dane sesji (sesje runtime'owe / interakcje).

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), Runtime (źródło sesji).

## 7. Consumers
Runtime, usługi platformy, agenci. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `SESSION` / `EPHEMERAL`. Sesje są efemeryczne, wygasają po zakończeniu. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
Sesje powstają przy starcie interakcji, wygasają po zakończeniu / timeout. `STATUS: UNDEFINED` dla pełnego cyklu.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla sesji nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
