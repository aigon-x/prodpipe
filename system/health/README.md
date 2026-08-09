# health

> Katalog systemu health AIGON Production Platform — monitorowanie stanu zdrowia komponentów.

## 1. Purpose
Cel: system health — monitorowanie stanu zdrowia (health checks) komponentów platformy AIGON. Tu żyje kod, konfiguracja deklaratywna i manifesty systemu health.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, definicje health checks). Runtime = actual state (health, dowody, rejestry). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu health, definicje health checks (declarative config), konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/registry`, `system/telemetry`, `system/observability`.

## 7. Consumers
`system/self-heal`, `system/observability`, `system/control-plane`, `apps/dashboard`. `STATUS: UNDEFINED` dla pełnej listy.

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
