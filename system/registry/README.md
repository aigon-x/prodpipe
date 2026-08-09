# registry

> Katalog systemu rejestru AIGON Production Platform — rejestr komponentów i usług platformy.

## 1. Purpose
Cel: system registry — rejestr komponentów/usług platformy AIGON (service discovery). Tu żyje kod, konfiguracja deklaratywna i manifesty systemu registry.

## 2. Owner
`STATUS: UNDEFINED`

## 3. Source of Truth
Git = desired state (kod, konfiguracja deklaratywna, schematy rejestru). Runtime = actual state (rejestry, topologia, health, dowody). `STATUS: ARCHITECTURAL GAP` — brak wskazanego pojedynczego właściciela domeny.

## 4. Contains
Kod źródłowy systemu registry, schematy rejestru, konfiguracja deklaratywna, manifesty wdrożeniowe, testy, dokumentacja.

## 5. Does Not Contain
Brak runtime state (żyje w AIGON-X-FS), brak sekretów, brak drugiego Source of Truth.

## 6. Dependencies
Zależne od: `system/runtime`, `system/identity`, `system/events`, `system/health`, `system/security`.

## 7. Consumers
Wszystkie `apps/*`, `system/router`, `system/gateway`, `system/control-plane`, `system/observability`. `STATUS: UNDEFINED` dla pełnej listy.

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
