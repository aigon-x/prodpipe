# system

> Katalog dla danych klasy SYSTEM — stan systemowy AIGON Production Platform, który żyje w Runtime (AIGON-X-FS), a nie w git.

## 1. Purpose
Przechowuje dane klasy SYSTEM: stan systemowy, topologię, rejestry, dowody (evidence), tożsamość nodów, stan wdrożenia. To dane Runtime, nie artefakty źródłowe.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Runtime (AIGON-X-FS) jest źródłem prawdy dla danych SYSTEM. Git trzyma tylko schematy/kontrakty opisujące te dane, nie same dane. `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego schematu danych SYSTEM.

## 4. Contains
Dane klasy SYSTEM: topologia, rejestry, health/evidence, tożsamość nodów, stan wdrożenia, capability registry.

## 5. Does Not Contain
Nie zawiera kodu, kontraktów, schematów ani konfiguracji deklaratywnej (te żyją w git). Nie zawiera danych TENANT/USER/SESSION/CACHE/TEMPORARY.

## 6. Dependencies
Zależy od Runtime (AIGON-X-FS) jako magazynu oraz od kontraktów/schematów w git.

## 7. Consumers
Runtime, orkiestrator, narzędzia operacyjne, obserwowalność.

## 8. Synchronization
Klasa: `REPLICATED` (stan Runtime replikowany z git jako desired state). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu sync.

## 9. Lifecycle
`STATUS: UNDEFINED`

## 10. Security
Klasyfikacja danych: SYSTEM. Wymaga kontroli dostępu; brak sekretów w git.

## 11. Recovery
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanej procedury odzyskiwania danych SYSTEM.

## 12. Drift Detection
Wykrywanie rozjazdu między desired state (git) a actual state (Runtime). `STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu.

## Examples
`STATUS: UNDEFINED`
