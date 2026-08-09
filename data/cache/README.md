# cache

> Katalog dla danych klasy CACHE — dane cache AIGON Production Platform, żyjące w Runtime (AIGON-X-FS).

## 1. Purpose
Przechowuje dane klasy CACHE: dane cache'owane, tymczasowe kopie przyspieszające dostęp. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych CACHE. Git trzyma tylko schematy/kontrakty. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego modelu cache.

## 4. Contains
Dane klasy CACHE: cache'owane dane, tymczasowe kopie przyspieszające dostęp.

## 5. Does Not Contain
Nie zawiera kodu ani konfiguracji deklaratywnej (git). Nie zawiera danych SYSTEM/TENANT/USER/SESSION/TEMPORARY.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) oraz od modelu cache zdefiniowanego w git.

## 7. Consumers
Runtime, warstwa cache, narzędzia operacyjne.

## 8. Synchronization
Klasa: `CACHE` — dane cache są odtwarzalne i nie są trwale replikowane.

## 9. Lifecycle
Dane cache powstają i są wygaszane; nie są trwale przechowywane.

## 10. Security
Klasyfikacja danych: CACHE. Wymaga kontroli dostępu; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych CACHE (dane odtwarzalne).

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
