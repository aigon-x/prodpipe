# observability

> Katalog systemu obserwowalności AIGON Production Platform — obserwowalność i monitoring platformy.

## 1. Purpose
Cel: system observability — obserwowalność, monitoring i wizualizacja platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu observability.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, definicje dashboardów). Runtime = actual state (metryki, rejestry, health, dowody). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu observability, definicje dashboardów (declarative config), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/telemetry`, `system/health`, `system/runtime`, `system/registry`.

## 7. Consumers
`apps/dashboard`, `system/control-plane`, `system/self-heal`, operatorzy platformy. `STATUS: UNDEFINED` dla pełnej listy.

## 8. Synchronization
`STATUS: UNDEFINED` — klasa synchronizacji nieustalona.

## 9. Lifecycle
`STATUS: UNDEFINED` — cykl życia nieustalony (repo nowe, nic nie zaimplementowane).

## 10. Security
Klasyfikacja danych: `STATUS: UNDEFINED`. Zasada: brak sekretów w git, tożsamość przez `system/identity`, autoryzacja przez `system/security`.

## 11. Recovery
`STATUS: UNDEFINED` — procedura odzyskiwania nieustalona.

## 12. Drift Detection
`STATUS: ARCHITECTURAL GAP` — brak zdefiniowanego mechanizmu wykrywania driftu między desired state (git) a actual state (runtime).

## Examples
`STATUS: UNDEFINED`
