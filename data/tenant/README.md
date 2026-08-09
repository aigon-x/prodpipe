# tenant

> Katalog dla danych klasy TENANT — dane dzierżawców (tenantów) AIGON Production Platform, żyjące w Runtime (AIGON-X-FS).

## 1. Purpose
Przechowuje dane klasy TENANT: dane dzierżawców, izolowane per-tenant zasoby i stany. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych TENANT. Git trzyma tylko schematy/kontrakty. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego modelu dzierżawców.

## 4. Contains
Dane klasy TENANT: stany dzierżawców, izolowane zasoby per-tenant, konfiguracja tenantów.

## 5. Does Not Contain
Nie zawiera kodu ani konfiguracji deklaratywnej (git). Nie zawiera danych SYSTEM/USER/SESSION/CACHE/TEMPORARY.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) oraz od modelu dzierżawców zdefiniowanego w git.

## 7. Consumers
Runtime, warstwa multi-tenant, narzędzia operacyjne.

## 8. Synchronization
Klasa: `REPLICATED`. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu sync.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: TENANT. Wymaga izolacji między dzierżawcami; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych TENANT.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu.

## Examples
`STATUS: UNDEFINED`
