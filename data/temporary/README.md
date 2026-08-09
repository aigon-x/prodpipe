# temporary

> Katalog dla danych klasy TEMPORARY — dane tymczasowe AIGON Production Platform, żyjące w Runtime (AIGON-X-FS).

## 1. Purpose
Przechowuje dane klasy TEMPORARY: dane tymczasowe, pliki robocze, artefakty ulotne. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych TEMPORARY. Git trzyma tylko schematy/kontrakty. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego modelu danych tymczasowych.

## 4. Contains
Dane klasy TEMPORARY: dane tymczasowe, pliki robocze, artefakty ulotne.

## 5. Does Not Contain
Nie zawiera kodu ani konfiguracji deklaratywnej (git). Nie zawiera danych SYSTEM/TENANT/USER/SESSION/CACHE.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) oraz od modelu danych tymczasowych zdefiniowanego w git.

## 7. Consumers
Runtime, narzędzia operacyjne.

## 8. Synchronization
Klasa: `EPHEMERAL` — dane tymczasowe nie są replikowane ani trwale przechowywane.

## 9. Lifecycle
Dane tymczasowe powstają i są usuwane; nie są trwale przechowywane.

## 10. Security
Klasyfikacja danych: TEMPORARY. Wymaga kontroli dostępu; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych TEMPORARY (dane ulotne).

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
