# metadata

> Podkatalog AIGON-X-FS przechowujący metadane — dane opisujące bloki, chunki, shardy i snapshoty.

## 1. Purpose
Przechowywanie metadanych — danych opisujących bloki, chunki, shardy i snapshoty w AIGON-X-FS.

## 2. Owner
`STATUS: UNDEFINED` — właściciel domeny AIGON-X-FS nie jest jeszcze przypisany.

## 3. Source of Truth
Runtime (actual state). Metadane opisują stan faktyczny danych.

## 4. Contains
Metadane (dane opisowe) dla bloków, chunków, shardów i snapshotów.

## 5. Does Not Contain
- Kod źródłowy / kontrakty / schematy / polityki (domena Git).
- Sekrety.
- Drugi Source of Truth.

## 6. Dependencies
AIGON-X-FS (katalog nadrzędny), bloki/chunki/shardy/snapshoty (dane opisywane).

## 7. Consumers
Runtime, komponenty mesh, usługi platformy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
Klasa: `REPLICATED`. Synchronizacja metadanych z danymi, które opisują. `STATUS: UNDEFINED` dla szczegółów.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia metadanych nie jest jeszcze zdefiniowany.

## 10. Security
Klasyfikacja danych runtime'owych. Zakaz sekretów. Granice wg tenantów/użytkowników.

## 11. Recovery
Odzyskiwanie z replik / snapshotów. `STATUS: UNDEFINED` dla procedury.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — mechanizm wykrywania driftu dla metadanych nie jest zdefiniowany.

## Examples
`STATUS: UNDEFINED`.
