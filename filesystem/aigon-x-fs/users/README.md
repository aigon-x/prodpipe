# users

> Podkatalog AIGON-X-FS przechowujący dane użytkowników — izolowane dane runtime'owe poszczególnych użytkowników.

## 1. Purpose
Przechowywanie danych użytkowników — izolowanych danych runtime'owych poszczególnych użytkowników platformy.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Git = desired state, Runtime = actual state.

## 4. Contains
Dane użytkowników (izolowane dane runtime'owe per użytkownik).

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), mechanizm izolacji użytkowników.

## 7. Consumers
Runtime, usługi platformy, użytkownicy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED`. Replikacja danych użytkowników między nodami. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia danych użytkowników nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja: dane użytkowników. Wymagana izolacja między użytkownikami. Zakaz sekretów.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla danych użytkowników nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
