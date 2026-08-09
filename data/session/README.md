# session

> Katalog dla danych klasy SESSION — dane sesji AIGON Production Platform, żyjące w Runtime (AIGON-X-FS).

## 1. Purpose
Przechowuje dane klasy SESSION: stany sesji, konteksty sesji, dane ulotne per-sesja. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych SESSION. Git trzyma tylko schematy/kontrakty. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego modelu sesji.

## 4. Contains
Dane klasy SESSION: stany sesji, konteksty, dane ulotne per-sesja.

## 5. Does Not Contain
Nie zawiera kodu ani konfiguracji deklaratywnej (git). Nie zawiera danych SYSTEM/TENANT/USER/CACHE/TEMPORARY.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) oraz od modelu sesji zdefiniowanego w git.

## 7. Consumers
Runtime, warstwa sesji, narzędzia operacyjne.

## 8. Synchronization
Klasa: `SESSION` — dane sesji są ulotne i nie są trwale replikowane.

## 9. Lifecycle
Dane sesji powstają i znikają wraz z sesją; nie są trwale przechowywane.

## 10. Security
Klasyfikacja danych: SESSION. Wymaga kontroli dostępu; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych SESSION (dane ulotne).

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
