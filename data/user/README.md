# user

> Katalog dla danych klasy USER — dane użytkowników AIGON Production Platform, żyjące w Runtime (AIGON-X-FS).

## 1. Purpose
Przechowuje dane klasy USER: dane użytkowników, profile, preferencje, stany per-użytkownik. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych USER. Git trzyma tylko schematy/kontrakty. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego modelu użytkownika.

## 4. Contains
Dane klasy USER: profile użytkowników, preferencje, stany per-użytkownik.

## 5. Does Not Contain
Nie zawiera kodu ani konfiguracji deklaratywnej (git). Nie zawiera danych SYSTEM/TENANT/SESSION/CACHE/TEMPORARY.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) oraz od modelu użytkownika zdefiniowanego w git.

## 7. Consumers
Runtime, warstwa użytkownika, narzędzia operacyjne.

## 8. Synchronization
Klasa: `REPLICATED`. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu sync.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: USER. Wymaga kontroli dostępu i ochrony prywatności; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych USER.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
