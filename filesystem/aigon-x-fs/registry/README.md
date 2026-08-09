# registry

> Podkatalog AIGON-X-FS przechowujący rejestry — indeksy / katalogi danych runtime'owych.

## 1. Purpose
Przechowywanie rejestrów — indeksów / katalogów danych runtime'owych w AIGON-X-FS.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Rejestry odzwierciedlają stan faktyczny danych.

## 4. Contains
Rejestry / indeksy / katalogi danych runtime'owych.

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth — rejestr AIGON-X-FS jest jedynym rejestrem danych runtime'owych.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), dane rejestrowane (bloki/chunki/shardy).

## 7. Consumers
Runtime, komponenty mesh, usługi platformy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED`. Synchronizacja rejestrów z danymi, które indeksują. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia rejestrów nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla rejestrów nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
